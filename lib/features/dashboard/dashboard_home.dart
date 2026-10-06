import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api.dart';

/// The one and only portal dashboard (Angular has none).
class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  late final Future<List<dynamic>> _products;
  late final Future<List<dynamic>> _quotes;

  @override
  void initState() {
    super.initState();
    final api = context.read<ApiClient>();
    _products = api.get('/api/products').then((v) => v as List<dynamic>);
    _quotes = api.get('/api/quotes').then((v) => v as List<dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiClient>();
    return ListView(padding: const EdgeInsets.all(16), children: [
      FutureBuilder<List<dynamic>>(
        future: _products,
        builder: (c, s) {
          if (s.hasError) return Text('${s.error}');
          if (!s.hasData) return const LinearProgressIndicator();
          // only products this user may quote
          final allowed = [for (final p in s.data!) if (api.has('${(p['code'] as String).toLowerCase()}.quote')) p];
          if (allowed.isEmpty) return const SizedBox.shrink();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Get a quote', style: Theme.of(context).textTheme.titleLarge),
            Wrap(spacing: 12, runSpacing: 12, children: [
              for (final p in allowed)
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
                          // /motor, /home are Flutter pages; /travel, /liability open the Angular modules
                          onPressed: () => context.go('/${(p['code'] as String).toLowerCase()}'),
                          child: const Text('Start quote'),
                        ),
                      ]),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 24),
          ]);
        },
      ),
      Text(api.has('quotes.view') ? 'Recent quotes' : 'Your quotes', style: Theme.of(context).textTheme.titleLarge),
      FutureBuilder<List<dynamic>>(
        future: _quotes,
        builder: (c, s) {
          if (s.hasError) return Text('${s.error}');
          if (!s.hasData) return const LinearProgressIndicator();
          if (s.data!.isEmpty) return const Text('No quotes yet.');
          return Column(children: [
            for (final q in s.data!.take(20))
              ListTile(
                title: Text('${q['quoteNumber']}  ·  ${q['productName']}'),
                subtitle: Text('${q['status']}'),
                trailing: Text('\$${(q['totalPremium'] as num).toStringAsFixed(2)}'),
              ),
          ]);
        },
      ),
    ]);
  }
}
