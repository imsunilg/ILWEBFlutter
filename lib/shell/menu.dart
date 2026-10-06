import 'package:flutter/material.dart';

import '../features/dashboard/dashboard_home.dart';
import '../features/home/home_screen.dart';
import '../features/liability/liability_screen.dart';
import '../features/motor/motor_screen.dart';
import '../features/travel/travel_screen.dart';
import '../shared/data_list_view.dart';

/// One menu entry and the route it owns. It is shown only when the signed-in user holds [permission]
/// (permissions come from the API, which enforces them again on every call).
class MenuItem {
  const MenuItem(this.label, this.icon, this.route, this.permission, this.build);

  final String label;
  final IconData icon;
  final String route;
  final String permission;
  final Widget Function() build;
}

Widget _list(String title, String path) => DataListView(key: ValueKey(path), title: title, path: path);

final allMenuItems = <MenuItem>[
  MenuItem('Dashboard', Icons.dashboard, '/dashboard', 'dashboard.view', () => const DashboardHome()),
  MenuItem('Motor', Icons.directions_car, '/motor', 'motor.quote', () => const MotorScreen()),
  MenuItem('Home', Icons.home, '/home', 'home.quote', () => const HomeScreen()),
  MenuItem('Travel', Icons.flight, '/travel', 'travel.quote', () => const TravelScreen()), // Angular module
  MenuItem('Liability', Icons.business, '/liability', 'liability.quote', () => const LiabilityScreen()), // Angular module
  MenuItem('Customers', Icons.people, '/customers', 'customers.view', () => _list('Customers', '/api/customers')),
  MenuItem('Quotes', Icons.request_quote, '/quotes', 'quotes.view', () => _list('Quotes', '/api/quotes')),
  MenuItem('Underwriting', Icons.fact_check, '/underwriting', 'underwriting.view',
      () => _list('Underwriting', '/api/underwriting/queue')),
  MenuItem('Users', Icons.manage_accounts, '/users', 'users.manage', () => _list('Users', '/api/users')),
  MenuItem('Roles', Icons.admin_panel_settings, '/roles', 'roles.manage', () => _list('Roles', '/api/roles')),
  MenuItem('Reports', Icons.bar_chart, '/reports', 'reports.view', () => _list('Reports', '/api/reports/summary')),
  MenuItem('My Profile', Icons.person, '/profile', 'profile.view', () => _list('My Profile', '/api/v1/auth/me')),
  MenuItem('My Quotes', Icons.request_quote, '/my-quotes', 'quotes.own', () => _list('My Quotes', '/api/quotes')),
  MenuItem('My Policies', Icons.policy, '/policies', 'policies.view',
      () => const Center(child: Text('You have no policies yet.'))),
];

List<MenuItem> menuFor(bool Function(String permission) has) =>
    [for (final m in allMenuItems) if (has(m.permission)) m];

String roleTitle(String role) => role.isEmpty ? 'Dashboard' : '${role[0]}${role.substring(1).toLowerCase()} Dashboard';
