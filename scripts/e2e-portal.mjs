// End-to-end check of the integrated portal (Flutter shell + Angular Travel/Liability modules).
// Needs the API (5080), Angular (4200) and Flutter (8080) running and puppeteer-core installed.
// Usage: node e2e-portal.mjs [role] [screenshotDir]
import puppeteer from 'puppeteer-core';

const ROLE = process.argv[2] ?? 'Admin';
const SHOTS = process.argv[3] ?? '.';
const CHROME = process.env.CHROME ?? 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const PORTAL = 'http://localhost:8080';

let failures = 0;
let navigations = 0; // product pages visited via the menu
const check = (name, ok) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}`); if (!ok) failures++; };
const sleep = ms => new Promise(r => setTimeout(r, ms));

const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox'], defaultViewport: { width: 1400, height: 900 } });
const page = await browser.newPage();
const consoleErrors = [];
page.on('pageerror', e => consoleErrors.push(String(e)));
const urlsSeen = [];
page.on('framenavigated', f => urlsSeen.push(f.url()));

async function semantics() {
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
}
/** All visible text exposed by Flutter's semantics tree. */
const flutterText = () => page.evaluate(() => [...document.querySelectorAll('flt-semantics')].map(e => (e.getAttribute('aria-label') || e.textContent || '').trim()).filter(Boolean));
async function waitFlutter(text, timeout = 15000) {
  const end = Date.now() + timeout;
  while (Date.now() < end) { if ((await flutterText()).some(t => t === text || t.includes(text))) return true; await sleep(300); }
  return false;
}
async function clickFlutter(text) {
  const box = await page.evaluate(t => {
    const els = [...document.querySelectorAll('flt-semantics')].filter(e => ((e.getAttribute('aria-label') || e.textContent || '').trim()) === t);
    const e = els.find(x => x.getBoundingClientRect().width > 0);
    if (!e) return null;
    const r = e.getBoundingClientRect();
    return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
  }, text);
  if (!box) return false;
  await page.mouse.click(box.x, box.y);
  return true;
}
const angularFrame = () => page.frames().find(f => f.url().startsWith('http://localhost:4200'));
async function waitFrame(pathPart, text, timeout = 20000) {
  const end = Date.now() + timeout;
  while (Date.now() < end) {
    const f = angularFrame();
    if (f && f.url().includes(pathPart)) {
      const body = await f.evaluate(() => document.body.innerText).catch(() => '');
      if (body.includes(text)) return f;
    }
    await sleep(400);
  }
  return null;
}

try {
  await page.goto(PORTAL, { waitUntil: 'load' });
  await sleep(4000);
  await semantics();
  await sleep(1000);

  // 1-2 login screen
  check('Flutter login screen appears', await waitFlutter('Insurance Portal Login'));
  // 3 login as role via demo chip
  check(`demo chip ${ROLE} clickable`, await clickFlutter(ROLE));
  check(`Demo Account label for ${ROLE}`, await waitFlutter(`Demo Account: ${ROLE.toUpperCase()}`, 5000));
  await clickFlutter('Login');
  // 4 dashboard
  const title = `${ROLE} Dashboard`;
  check(`Flutter ${title} appears`, await waitFlutter(title));
  await page.screenshot({ path: `${SHOTS}/${ROLE}-1-dashboard.png` });
  check('no Angular iframe on dashboard', !angularFrame());

  const has = async label => (await flutterText()).includes(label);
  for (const m of ['Motor', 'Home']) {
    if (!(await has(m))) { console.log(`INFO  ${ROLE} has no ${m} menu`); continue; }
    await clickFlutter(m); navigations++;
    check(`${m}: Flutter page appears`, await waitFlutter(`${m} quote`));
    check(`${m}: header kept (${title})`, await has(title) || (await flutterText()).some(t => t.includes(title)));
    check(`${m}: no Angular iframe`, !angularFrame());
    await page.screenshot({ path: `${SHOTS}/${ROLE}-2-${m}.png` });
  }

  for (const [m, path, heading] of [['Travel', '/travel', 'Travel quote'], ['Liability', '/liability', 'Public liability quote']]) {
    if (!(await has(m))) { console.log(`INFO  ${ROLE} has no ${m} menu`); continue; }
    await clickFlutter(m); navigations++;
    const f = await waitFrame(path, heading);
    check(`${m}: Angular module renders inside the shell`, !!f);
    check(`${m}: URL carries no token`, !urlsSeen.some(u => /token|eyJ/i.test(u)));
    check(`${m}: Flutter header still visible`, (await flutterText()).some(t => t.includes(title)));
    if (f) {
      const text = await f.evaluate(() => document.body.innerText);
      check(`${m}: Angular shows no header/login/logout/dashboard`, !/Sign out|Sign in|IL Insurance Portal|Dashboard|Logout/i.test(text));
      check(`${m}: Angular has no <header>/<nav>`, await f.evaluate(() => !document.querySelector('header, nav')));
    }
    await page.screenshot({ path: `${SHOTS}/${ROLE}-3-${m}.png` });
  }

  // quote through Angular Travel, then back/forward
  if (await has('Travel')) {
    await clickFlutter('Travel');
    const f = await waitFrame('/travel', 'Travel quote');
    if (f) {
      await f.evaluate(() => {
        const set = (id, v) => { const e = document.getElementById(id); e.value = v; e.dispatchEvent(new Event('input', { bubbles: true })); e.dispatchEvent(new Event('change', { bubbles: true })); };
        set('startDate', '2027-02-01'); set('endDate', '2027-02-07'); set('travellers', '2'); set('tripCost', '3000');
      });
      await f.evaluate(() => document.querySelector('button.primary').click());
      const r = await waitFrame('/travel/result', 'Total');
      check('Travel quote generated via API (result page shows total)', !!r);
      await page.screenshot({ path: `${SHOTS}/${ROLE}-4-travel-result.png` });
      await page.evaluate(() => history.back());
      check('Back from result returns to Travel form inside the shell', !!(await waitFrame('/travel', 'Get quote')) && !(await page.evaluate(() => location.pathname)).includes('login'));
    }
  }
  if (await has('Liability')) {
    await clickFlutter('Liability');
    const f = await waitFrame('/liability', 'Public liability quote');
    if (f) {
      await f.evaluate(() => {
        const set = (id, v) => { const e = document.getElementById(id); e.value = v; e.dispatchEvent(new Event('input', { bubbles: true })); };
        set('businessType', 'Retail'); set('annualTurnover', '500000');
      });
      await f.evaluate(() => document.querySelector('button.primary').click());
      check('Liability quote generated via API', !!(await waitFrame('/liability/result', 'Total')));
    }
  }

  // 15-16 dashboard, history
  await clickFlutter('Dashboard');
  check('Dashboard returns (Flutter)', await waitFlutter('Get quote') || await waitFlutter('Your quotes') || await waitFlutter('Recent quotes'));
  check('Angular iframe removed on dashboard', !angularFrame());
  const hashBefore = await page.evaluate(() => location.pathname);
  await page.evaluate(() => history.back()); await sleep(1500);
  const hashAfter = await page.evaluate(() => location.pathname);
  check(`browser back changes Flutter route (${hashBefore} -> ${hashAfter})`, (hashBefore !== hashAfter || navigations === 0) && !hashAfter.includes('login'));
  await page.evaluate(() => history.forward()); await sleep(1500);
  check('browser forward returns to dashboard', (await page.evaluate(() => location.pathname)).includes('dashboard'));

  // 17-18 logout
  await clickFlutter('Sign out');
  check('Logout shows Flutter login', await waitFlutter('Insurance Portal Login'));
  check('no Angular login page was ever shown', !urlsSeen.some(u => u.includes(':4200/login')));
} finally {
  if (consoleErrors.length) console.log('page errors:', consoleErrors.slice(0, 3));
  await browser.close();
}
console.log(`\n${failures} failure(s)`);
process.exit(failures ? 1 : 0);


