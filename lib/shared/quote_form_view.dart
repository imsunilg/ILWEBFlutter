import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';

enum FieldType { text, number, integer, date, select }

class QuoteField {
  const QuoteField(this.key, this.label, this.type, {this.initial, this.options});
  final String key;
  final String label;
  final FieldType type;
  final String? initial;
  final List<(String, String)>? options;
}

final _year = DateTime.now().year;

final Map<String, (String, List<QuoteField>)> quoteDefs = {
  'motor': ('Motor quote', [
    const QuoteField('make', 'Make', FieldType.text),
    const QuoteField('model', 'Model', FieldType.text),
    QuoteField('year', 'Year', FieldType.integer, initial: '${_year - 3}'),
    const QuoteField('vehicleValue', 'Vehicle value', FieldType.number),
    const QuoteField('driverAge', 'Driver age', FieldType.integer),
    const QuoteField('claimsLast5Years', 'Claims in last 5 years', FieldType.integer, initial: '0'),
    const QuoteField('coverageCode', 'Coverage', FieldType.select,
        initial: 'COMPREHENSIVE', options: [('COMPREHENSIVE', 'Comprehensive'), ('THIRD_PARTY', 'Third party only')]),
  ]),
  'home': ('Home quote', [
    const QuoteField('propertyType', 'Property type', FieldType.select,
        initial: 'House', options: [('House', 'House'), ('Flat', 'Flat'), ('Bungalow', 'Bungalow')]),
    const QuoteField('postcode', 'Postcode', FieldType.text),
    const QuoteField('yearBuilt', 'Year built', FieldType.integer),
    const QuoteField('rebuildValue', 'Rebuild value', FieldType.number),
    const QuoteField('contentsValue', 'Contents value', FieldType.number, initial: '0'),
  ]),
  'travel': ('Travel quote', [
    const QuoteField('destinationCode', 'Destination', FieldType.select, initial: 'FR', options: [
      ('GB', 'United Kingdom'), ('US', 'United States'), ('FR', 'France'), ('DE', 'Germany'),
      ('ES', 'Spain'), ('AU', 'Australia'), ('IN', 'India'), ('JP', 'Japan'),
    ]),
    const QuoteField('startDate', 'Start date', FieldType.date),
    const QuoteField('endDate', 'End date', FieldType.date),
    const QuoteField('travellers', 'Travellers', FieldType.integer, initial: '1'),
    const QuoteField('tripCost', 'Trip cost', FieldType.number),
  ]),
  'liability': ('Public liability quote', [
    const QuoteField('businessType', 'Business type', FieldType.text),
    const QuoteField('annualTurnover', 'Annual turnover', FieldType.number),
    const QuoteField('employees', 'Employees', FieldType.integer, initial: '0'),
    const QuoteField('limitAmount', 'Limit of cover', FieldType.number, initial: '1000000'),
  ]),
};

class QuoteFormView extends StatefulWidget {
  const QuoteFormView({super.key, required this.productCode});
  final String productCode;

  @override
  State<QuoteFormView> createState() => _QuoteFormViewState();
}

class _QuoteFormViewState extends State<QuoteFormView> {
  final _form = GlobalKey<FormState>();
  final Map<String, TextEditingController> _ctl = {};
  final Map<String, String> _select = {};
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _result;

  (String, List<QuoteField>)? get _def => quoteDefs[widget.productCode];

  @override
  void initState() {
    super.initState();
    for (final f in _def?.$2 ?? const <QuoteField>[]) {
      if (f.type == FieldType.select) {
        _select[f.key] = f.initial ?? f.options!.first.$1;
      } else {
        _ctl[f.key] = TextEditingController(text: f.initial ?? '');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _ctl.values) {
      c.dispose();
    }
    super.dispose();
  }

  Object _value(QuoteField f) => switch (f.type) {
        FieldType.select => _select[f.key]!,
        FieldType.number => num.parse(_ctl[f.key]!.text),
        FieldType.integer => int.parse(_ctl[f.key]!.text),
        _ => _ctl[f.key]!.text.trim(),
      };

  Future<void> _pickDate(QuoteField f) async {
    final now = DateTime.now();
    final d = await showDatePicker(context: context, initialDate: now, firstDate: now, lastDate: DateTime(now.year + 3));
    if (d != null) _ctl[f.key]!.text = d.toIso8601String().substring(0, 10);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final body = {for (final f in _def!.$2) f.key: _value(f)};
      final r = await context.read<ApiClient>().post('/api/quotes/${widget.productCode}', body);
      setState(() => _result = r as Map<String, dynamic>);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validate(QuoteField f, String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (f.type == FieldType.number && num.tryParse(v) == null) return 'Enter a number';
    if (f.type == FieldType.integer && int.tryParse(v) == null) return 'Enter a whole number';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final def = _def;
    if (def == null) return const Center(child: Text('Unknown product'));
    return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _form,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Text(def.$1, style: Theme.of(context).textTheme.headlineSmall),
              for (final f in def.$2)
                if (f.type == FieldType.select)
                  DropdownButtonFormField<String>(
                    initialValue: _select[f.key],
                    decoration: InputDecoration(labelText: f.label),
                    items: [for (final o in f.options!) DropdownMenuItem(value: o.$1, child: Text(o.$2))],
                    onChanged: (v) => setState(() => _select[f.key] = v!),
                  )
                else
                  TextFormField(
                    controller: _ctl[f.key],
                    decoration: InputDecoration(labelText: f.label),
                    readOnly: f.type == FieldType.date,
                    onTap: f.type == FieldType.date ? () => _pickDate(f) : null,
                    keyboardType: f.type == FieldType.text || f.type == FieldType.date ? null : TextInputType.number,
                    validator: (v) => _validate(f, v),
                  ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _busy ? null : _submit, child: const Text('Get quote')),
              if (_result != null)
                Card(
                  margin: const EdgeInsets.only(top: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Quote ${_result!['quoteNumber']}', style: Theme.of(context).textTheme.titleMedium),
                      Text('Premium \$${(_result!['basePremium'] as num).toStringAsFixed(2)} + tax \$${(_result!['tax'] as num).toStringAsFixed(2)}'),
                      Text('Total \$${(_result!['totalPremium'] as num).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge),
                    ]),
                  ),
                ),
            ]),
          ),
        ),
    );
  }
}


