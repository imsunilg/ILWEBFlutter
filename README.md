# ILWEBFlutter

Flutter web **portal shell** of the IL Insurance Portal. It owns login, header, menu, dashboard, profile, logout, Motor and Home. Travel and Liability are Angular modules (repository **ILWEBAngular**) shown in an iframe in the content area. Backend: **ILAPI**.

```
lib/
  core/      api client, config, routing (go_router, clean path URLs)
  shell/     portal shell (header + menu), menu definition
  features/  auth, dashboard, motor, home, travel, liability
  shared/    quote form, data list, Angular module host (iframe + postMessage handoff)
```

## Run
Needs ILAPI on http://localhost:5080 and ILWEBAngular on http://localhost:4200.
```
flutter pub get
flutter run -d chrome --web-port 8080
```
Open http://localhost:8080. Demo login buttons (development only): Admin, Agent, Underwriter, Manager, Customer.

Environments (`--dart-define`): `APP_ENV=development|qa|production`, `ENABLE_DEMO_LOGIN=true` (QA opt-in; always off in production), `API_URL`, `ANGULAR_URL`.
Production hosting must return `index.html` for unknown paths (SPA fallback) because URLs have no `#`.

Tests: `flutter analyze && flutter test`. Browser end-to-end (portal running as a release build on 8080): `node scripts/e2e-portal.mjs <Admin|Agent|Underwriter|Manager|Customer> <screenshot-dir>` (needs `puppeteer-core`).
