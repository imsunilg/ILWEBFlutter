import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;

import '../core/api.dart';
import '../core/config.dart';

var _nextViewId = 0;

/// Renders an Angular module ("travel" or "liability") in the content area of the portal shell.
///
/// Session handoff (no tokens in URLs):
///   1. the Angular page posts `{type: 'il-ready'}` to this window;
///   2. we ask the API for a one-time token and post `{type: 'il-handoff', token}` back,
///      with `targetOrigin` limited to the Angular origin;
///   3. Angular exchanges the token for its own session.
/// Messages are only accepted from the Angular origin and the iframe's own window.
class AngularModuleView extends StatefulWidget {
  const AngularModuleView({super.key, required this.module});

  final String module;

  @override
  State<AngularModuleView> createState() => _AngularModuleViewState();
}

class _AngularModuleViewState extends State<AngularModuleView> {
  late final String _viewType = 'il-angular-${widget.module}-${_nextViewId++}';
  late final web.HTMLIFrameElement _iframe;
  late final JSFunction _listener = _onMessage.toJS;
  late final ApiClient _api = context.read<ApiClient>();

  @override
  void initState() {
    super.initState();
    _iframe = web.HTMLIFrameElement()
      ..src = '$angularUrl/${widget.module}'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.background = '#faf8ff';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) => _iframe);
    web.window.addEventListener('message', _listener);
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _listener);
    super.dispose();
  }

  void _onMessage(web.MessageEvent event) {
    // Only the Angular origin may ask for a token. (event.source is not compared: touching a
    // cross-origin window object from Dart throws a SecurityError.)
    if (event.origin != angularOrigin) return;
    final data = event.data.dartify();
    if (data is! Map || data['type'] != 'il-ready') return;
    _sendToken();
  }

  Future<void> _sendToken() async {
    try {
      final token = await _api.createFrontendSession();
      _iframe.contentWindow?.postMessage({'type': 'il-handoff', 'token': token}.jsify(), angularOrigin.toJS);
    } catch (_) {
      // The module shows "Session unavailable"; the user can reopen it from the menu.
    }
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
