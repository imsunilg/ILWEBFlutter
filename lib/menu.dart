import 'package:flutter/material.dart';

/// One menu entry. It is shown only when the signed-in user holds [permission]
/// (permissions come from the API; the API enforces them again on every call).
class MenuItem {
  const MenuItem(this.label, this.icon, this.permission, {this.path, this.product, this.kind = MenuKind.list});

  final String label;
  final IconData icon;
  final String permission;
  final String? path; // API endpoint for list screens
  final String? product; // quote form product (opens the quote screen)
  final MenuKind kind;
}

enum MenuKind { dashboard, list, product, profile, policies }

const allMenuItems = [
  MenuItem('Dashboard', Icons.dashboard, 'dashboard.view', kind: MenuKind.dashboard),
  MenuItem('Motor', Icons.directions_car, 'motor.quote', product: 'motor', kind: MenuKind.product),
  MenuItem('Home', Icons.home, 'home.quote', product: 'home', kind: MenuKind.product),
  MenuItem('Travel', Icons.flight, 'travel.quote', product: 'travel', kind: MenuKind.product),
  MenuItem('Liability', Icons.business, 'liability.quote', product: 'liability', kind: MenuKind.product),
  MenuItem('Customers', Icons.people, 'customers.view', path: '/api/customers'),
  MenuItem('Quotes', Icons.request_quote, 'quotes.view', path: '/api/quotes'),
  MenuItem('Underwriting', Icons.fact_check, 'underwriting.view', path: '/api/underwriting/queue'),
  MenuItem('Users', Icons.manage_accounts, 'users.manage', path: '/api/users'),
  MenuItem('Roles', Icons.admin_panel_settings, 'roles.manage', path: '/api/roles'),
  MenuItem('Reports', Icons.bar_chart, 'reports.view', path: '/api/reports/summary'),
  MenuItem('My Profile', Icons.person, 'profile.view', path: '/api/v1/auth/me', kind: MenuKind.profile),
  MenuItem('My Quotes', Icons.request_quote, 'quotes.own', path: '/api/quotes'),
  MenuItem('My Policies', Icons.policy, 'policies.view', kind: MenuKind.policies),
];

List<MenuItem> menuFor(bool Function(String permission) has) =>
    [for (final m in allMenuItems) if (has(m.permission)) m];

String roleTitle(String role) => role.isEmpty ? 'Dashboard' : '${role[0]}${role.substring(1).toLowerCase()} Dashboard';
