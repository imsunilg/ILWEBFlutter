import 'package:flutter/material.dart';

class AngularModuleView extends StatelessWidget {
  const AngularModuleView({super.key, required this.module});

  final String module;

  @override
  Widget build(BuildContext context) =>
      Center(child: Text('The $module module is available in the web build.'));
}
