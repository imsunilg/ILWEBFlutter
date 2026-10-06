import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../shell/menu.dart';
import '../../shell/portal_shell.dart';
import '../api.dart';

/// Flutter owns every route. The browser URL (hash) tracks them, so back/forward move between
/// Dashboard, Motor, Home, Travel, Liability, ... without leaving the app.
GoRouter buildRouter(ApiClient api) => GoRouter(
      initialLocation: '/dashboard',
      refreshListenable: api,
      redirect: (context, state) {
        final loc = state.matchedLocation;
        if (!api.isLoggedIn) return loc == '/login' ? null : '/login';
        if (loc == '/login' || loc == '/') return '/dashboard';
        final matches = allMenuItems.where((m) => m.route == loc);
        // unknown path, or a page this user has no permission for
        if (matches.isEmpty || !matches.any((m) => api.has(m.permission))) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        ShellRoute(
          builder: (_, state, child) => PortalShell(location: state.matchedLocation, child: child),
          routes: [
            for (final item in allMenuItems)
              GoRoute(
                path: item.route,
                pageBuilder: (_, state) => NoTransitionPage(key: state.pageKey, child: item.build()),
              ),
          ],
        ),
      ],
    );

