import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import 'menu.dart';

/// The single portal shell: header (title, user, sign out) and menu stay put while [child]
/// (a Flutter page, or an embedded Angular module) changes underneath.
class PortalShell extends StatelessWidget {
  const PortalShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiClient>();
    final items = menuFor(api.has);
    final wide = MediaQuery.of(context).size.width >= 800;

    final menu = [
      for (final item in items)
        ListTile(
          key: Key('menu-${item.label}'),
          leading: Icon(item.icon),
          title: Text(item.label),
          selected: location == item.route,
          onTap: () {
            Navigator.of(context).maybePop(); // closes the drawer on narrow screens
            context.go(item.route);
          },
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(roleTitle(api.role)),
        actions: [
          Center(child: Text('${api.userName} (${api.role})')),
          IconButton(tooltip: 'Sign out', icon: const Icon(Icons.logout), onPressed: api.logout),
        ],
      ),
      drawer: wide ? null : Drawer(child: ListView(children: menu)),
      body: Row(children: [
        if (wide) SizedBox(width: 220, child: ListView(children: menu)),
        if (wide) const VerticalDivider(width: 1),
        Expanded(child: child),
      ]),
    );
  }
}
