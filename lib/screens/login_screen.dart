import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../config.dart';
import '../demo_users.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _registering = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;
  String? _demoRole;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  void _pickDemo(DemoUser u) {
    setState(() {
      _registering = false;
      _demoRole = u.role;
      _username.text = u.username;
      _password.text = u.password;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final api = context.read<ApiClient>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_registering) {
        await api.register(_username.text.trim(), _password.text, _name.text.trim());
      } else {
        await api.login(_username.text.trim(), _password.text);
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Cannot reach the server. Is the API running?');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Insurance Portal Login')),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(_registering ? 'Create account' : 'Sign in', style: Theme.of(context).textTheme.headlineSmall),
                  if (_registering)
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  TextFormField(
                    key: const Key('username'),
                    controller: _username,
                    decoration: InputDecoration(labelText: _registering ? 'Email' : 'Username or email'),
                    onChanged: (_) => setState(() => _demoRole = null),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  TextFormField(
                    key: const Key('password'),
                    controller: _password,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        tooltip: _showPassword ? 'Hide password' : 'Show password',
                        icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    obscureText: !_showPassword,
                    onChanged: (_) => setState(() => _demoRole = null),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : (_registering && v.length < 8 ? 'At least 8 characters' : null),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_error!, style: TextStyle(color: scheme.error)),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _busy ? null : _submit, child: Text(_registering ? 'Register' : 'Login')),
                  TextButton(
                    onPressed: () => setState(() => _registering = !_registering),
                    child: Text(_registering ? 'Have an account? Sign in' : 'New here? Create an account'),
                  ),
                  if (enableDemoLogin) ..._demoSection(context),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _demoSection(BuildContext context) => [
        const SizedBox(height: 8),
        const Row(children: [
          Expanded(child: Divider()),
          Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Demo Login')),
          Expanded(child: Divider()),
        ]),
        const SizedBox(height: 12),
        Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
          for (final u in demoUsers)
            ChoiceChip(
              key: Key('demo-${u.role}'),
              label: Text(u.label),
              selected: _demoRole == u.role,
              onSelected: (_) => _pickDemo(u),
            ),
        ]),
        if (_demoRole != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('Demo Account: $_demoRole',
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
          ),
      ];
}

