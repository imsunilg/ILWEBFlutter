import 'package:flutter/material.dart';

import '../../shared/angular_module_view.dart';

/// Travel insurance is an Angular module rendered inside the Flutter shell.
class TravelScreen extends StatelessWidget {
  const TravelScreen({super.key});

  @override
  Widget build(BuildContext context) => const AngularModuleView(module: 'travel');
}
