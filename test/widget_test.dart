import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:il_portal/api.dart';
import 'package:il_portal/main.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows login screen when signed out', (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider.value(value: ApiClient(), child: const PortalApp()));
    expect(find.text('Sign in'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('register mode adds full name field', (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider.value(value: ApiClient(), child: const PortalApp()));
    await tester.tap(find.text('New here? Create an account'));
    await tester.pump();
    expect(find.byType(TextFormField), findsNWidgets(3));
  });
}
