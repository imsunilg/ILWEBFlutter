import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api.dart';
import 'core/routing/router.dart';

Future<void> main() async {
  usePathUrlStrategy(); // /liability instead of /#/liability (the host must serve index.html for unknown paths)
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  await api.load();
  runApp(ChangeNotifierProvider.value(value: api, child: const PortalApp()));
}

class PortalApp extends StatefulWidget {
  const PortalApp({super.key});

  @override
  State<PortalApp> createState() => _PortalAppState();
}

class _PortalAppState extends State<PortalApp> {
  late final GoRouter _router = buildRouter(context.read<ApiClient>());

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'IL Insurance Portal',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF0B3D91), useMaterial3: true),
      routerConfig: _router,
    );
  }
}

