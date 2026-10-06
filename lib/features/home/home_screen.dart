import 'package:flutter/material.dart';

import '../../shared/quote_form_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const QuoteFormView(productCode: 'home');
}
