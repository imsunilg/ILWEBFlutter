import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  await api.load();
  runApp(ChangeNotifierProvider.value(value: api, child: const PortalApp()));
}

class PortalApp extends StatelessWidget {
  const PortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<ApiClient>().isLoggedIn;
    return MaterialApp(
      title: 'IL Insurance Portal',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF0B3D91), useMaterial3: true),
      home: loggedIn ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
