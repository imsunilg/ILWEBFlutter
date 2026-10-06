import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';

/// Generic read-only table for any list endpoint (customers, users, roles, reports, ...).
class DataListView extends StatelessWidget {
  const DataListView({super.key, required this.title, required this.path});

  final String title;
  final String path;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: context.read<ApiClient>().get(path),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('${snap.error}', style: TextStyle(color: Theme.of(context).colorScheme.error)));
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final data = snap.data;
        final rows = <Map<String, dynamic>>[
          if (data is List) ...data.cast<Map<String, dynamic>>() else if (data is Map<String, dynamic>) data,
        ];
        return ListView(padding: const EdgeInsets.all(16), children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            const Text('Nothing to show.')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [for (final k in rows.first.keys) DataColumn(label: Text(k))],
                rows: [
                  for (final r in rows)
                    DataRow(cells: [for (final k in rows.first.keys) DataCell(Text('${r[k] ?? ''}'))]),
                ],
              ),
            ),
        ]);
      },
    );
  }
}

