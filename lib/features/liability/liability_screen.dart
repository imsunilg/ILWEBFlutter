import 'package:flutter/material.dart';

import '../../shared/angular_module_view.dart';

/// Liability insurance is an Angular module rendered inside the Flutter shell.
class LiabilityScreen extends StatelessWidget {
  const LiabilityScreen({super.key});

  @override
  Widget build(BuildContext context) => const AngularModuleView(module: 'liability');
}
