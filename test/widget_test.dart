import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:il_portal/core/api.dart';
import 'package:il_portal/core/config.dart';
import 'package:il_portal/features/auth/demo_users.dart';
import 'package:il_portal/main.dart';
import 'package:il_portal/shell/menu.dart';
import 'package:provider/provider.dart';

Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(
    ChangeNotifierProvider.value(value: ApiClient(), child: const PortalApp()));

String fieldText(WidgetTester tester, String key) =>
    tester.widget<TextFormField>(find.byKey(Key(key))).controller!.text;

void main() {
  testWidgets('shows login form when signed out', (tester) async {
    await pumpApp(tester);
    expect(find.text('Login'), findsOneWidget);
    expect(find.byKey(const Key('username')), findsOneWidget);
    expect(find.byKey(const Key('password')), findsOneWidget);
  });

  testWidgets('register mode adds full name field', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('New here? Create an account'));
    await tester.pump();
    expect(find.byType(TextFormField), findsNWidgets(3));
  });

  testWidgets('demo login section is controlled by environment', (tester) async {
    await pumpApp(tester);
    if (enableDemoLogin) {
      expect(find.text('Demo Login'), findsOneWidget);
      for (final u in demoUsers) {
        expect(find.byKey(Key('demo-${u.role}')), findsOneWidget);
      }
    } else {
      // production / QA without opt-in: no demo UI and no demo credentials on screen
      expect(find.text('Demo Login'), findsNothing);
      expect(find.byKey(const Key('demo-ADMIN')), findsNothing);
    }
  });

  testWidgets('selecting a demo role auto-fills credentials and shows the role', (tester) async {
    if (!enableDemoLogin) return;
    await pumpApp(tester);
    for (final u in demoUsers) {
      await tester.ensureVisible(find.byKey(Key('demo-${u.role}')));
      await tester.tap(find.byKey(Key('demo-${u.role}')));
      await tester.pump();
      expect(fieldText(tester, 'username'), u.username);
      expect(fieldText(tester, 'password'), u.password);
      expect(find.text('Demo Account: ${u.role}'), findsOneWidget);
    }
  });

  testWidgets('editing a field clears the demo account label', (tester) async {
    if (!enableDemoLogin) return;
    await pumpApp(tester);
    await tester.ensureVisible(find.byKey(const Key('demo-ADMIN')));
    await tester.tap(find.byKey(const Key('demo-ADMIN')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('username')), 'someone');
    await tester.pump();
    expect(find.text('Demo Account: ADMIN'), findsNothing);
  });

  testWidgets('password is hidden until the visibility toggle is pressed', (tester) async {
    await pumpApp(tester);
    bool obscured() => tester.widget<EditableText>(
        find.descendant(of: find.byKey(const Key('password')), matching: find.byType(EditableText))).obscureText;
    expect(obscured(), isTrue);
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();
    expect(obscured(), isFalse);
  });

  group('role menus (permissions come from the API)', () {
    const perms = <String, List<String>>{
      'ADMIN': ['dashboard.view', 'motor.quote', 'home.quote', 'travel.quote', 'liability.quote', 'customers.view',
        'quotes.view', 'users.manage', 'roles.manage', 'reports.view'],
      'AGENT': ['dashboard.view', 'motor.quote', 'home.quote', 'travel.quote', 'liability.quote', 'customers.view', 'quotes.view'],
      'UNDERWRITER': ['dashboard.view', 'quotes.view', 'underwriting.view', 'reports.view', 'travel.quote', 'liability.quote'],
      'MANAGER': ['dashboard.view', 'quotes.view', 'customers.view', 'reports.view', 'travel.quote', 'liability.quote'],
      'CUSTOMER': ['dashboard.view', 'profile.view', 'quotes.own', 'policies.view'],
    };

    List<String> labels(String role) => menuFor(perms[role]!.contains).map((m) => m.label).toList();

    test('admin', () => expect(labels('ADMIN'),
        ['Dashboard', 'Motor', 'Home', 'Travel', 'Liability', 'Customers', 'Quotes', 'Users', 'Roles', 'Reports']));
    test('agent', () => expect(labels('AGENT'),
        ['Dashboard', 'Motor', 'Home', 'Travel', 'Liability', 'Customers', 'Quotes']));
    test('underwriter', () => expect(labels('UNDERWRITER'),
        ['Dashboard', 'Travel', 'Liability', 'Quotes', 'Underwriting', 'Reports']));
    test('manager', () => expect(labels('MANAGER'),
        ['Dashboard', 'Travel', 'Liability', 'Customers', 'Quotes', 'Reports']));
    test('customer', () => expect(labels('CUSTOMER'), ['Dashboard', 'My Profile', 'My Quotes', 'My Policies']));
    test('role titles', () => expect(roleTitle('UNDERWRITER'), 'Underwriter Dashboard'));
  });
}

