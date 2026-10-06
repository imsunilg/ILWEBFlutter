import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import 'quote_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<dynamic>> _products;
  late Future<List<dynamic>> _quotes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final api = context.read<ApiClient>();
    _products = api.get('/api/products').then((v) => v as List<dynamic>);
    _quotes = api.get('/api/quotes').then((v) => v as List<dynamic>);
  }

  Future<void> _openAngular() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final url = await context.read<ApiClient>().angularHandoffUrl();
      await launchUrl(url, webOnlyWindowName: '_blank');
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiClient>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('IL Insurance Portal'),
        actions: [
          Center(child: Text(api.userName)),
          IconButton(tooltip: 'Open web portal', icon: const Icon(Icons.open_in_new), onPressed: _openAngular),
          IconButton(tooltip: 'Sign out', icon: const Icon(Icons.logout), onPressed: api.logout),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Get a quote', style: Theme.of(context).textTheme.titleLarge),
        FutureBuilder<List<dynamic>>(
          future: _products,
          builder: (c, s) {
            if (s.hasError) return Text('${s.error}');
            if (!s.hasData) return const LinearProgressIndicator();
            return Wrap(spacing: 12, runSpacing: 12, children: [
              for (final p in s.data!)
                SizedBox(
                  width: 240,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p['name'] as String, style: Theme.of(context).textTheme.titleMedium),
                        Text((p['description'] as String?) ?? ''),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () async {
                            await Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => QuoteScreen(productCode: (p['code'] as String).toLowerCase())));
                            setState(_load);
                          },
                          child: const Text('Start quote'),
                        ),
                      ]),
                    ),
                  ),
                ),
            ]);
          },
        ),
        const SizedBox(height: 24),
        Text('Your quotes', style: Theme.of(context).textTheme.titleLarge),
        FutureBuilder<List<dynamic>>(
          future: _quotes,
          builder: (c, s) {
            if (s.hasError) return Text('${s.error}');
            if (!s.hasData) return const LinearProgressIndicator();
            if (s.data!.isEmpty) return const Text('No quotes yet.');
            return Column(children: [
              for (final q in s.data!)
                ListTile(
                  title: Text('${q['quoteNumber']}  ·  ${q['productName']}'),
                  subtitle: Text('${q['status']}'),
                  trailing: Text('\$${(q['totalPremium'] as num).toStringAsFixed(2)}'),
                ),
            ]);
          },
        ),
      ]),
    );
  }
}
