import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../menu.dart';
import 'data_list_screen.dart';
import 'quote_screen.dart';

/// Role-aware shell: one screen for every role, with a menu built from the user's permissions.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selected = 0;

  Future<void> _openAngular() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final url = await context.read<ApiClient>().angularHandoffUrl();
      await launchUrl(url, webOnlyWindowName: '_blank');
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _select(List<MenuItem> items, int i) {
    final item = items[i];
    Navigator.of(context).maybePop(); // close the drawer on narrow screens
    if (item.kind == MenuKind.product) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuoteScreen(productCode: item.product!)));
    } else {
      setState(() => _selected = i);
    }
  }

  Widget _body(MenuItem item, ApiClient api) {
    switch (item.kind) {
      case MenuKind.dashboard:
        return DashboardHome(key: ValueKey(api.role));
      case MenuKind.policies:
        return const Center(child: Text('You have no policies yet.'));
      default:
        return DataListView(key: ValueKey(item.label), title: item.label, path: item.path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiClient>();
    final items = menuFor(api.has);
    final index = _selected < items.length ? _selected : 0;
    final wide = MediaQuery.of(context).size.width >= 800;

    final menu = [
      for (var i = 0; i < items.length; i++)
        ListTile(
          key: Key('menu-${items[i].label}'),
          leading: Icon(items[i].icon),
          title: Text(items[i].label),
          selected: i == index && items[i].kind != MenuKind.product,
          onTap: () => _select(items, i),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(roleTitle(api.role)),
        actions: [
          Center(child: Text('${api.userName} (${api.role})')),
          IconButton(tooltip: 'Open web portal', icon: const Icon(Icons.open_in_new), onPressed: _openAngular),
          IconButton(tooltip: 'Sign out', icon: const Icon(Icons.logout), onPressed: api.logout),
        ],
      ),
      drawer: wide ? null : Drawer(child: ListView(children: menu)),
      body: Row(children: [
        if (wide) SizedBox(width: 220, child: ListView(children: menu)),
        if (wide) const VerticalDivider(width: 1),
        Expanded(child: items.isEmpty ? const Center(child: Text('No access configured for this account.')) : _body(items[index], api)),
      ]),
    );
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
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
