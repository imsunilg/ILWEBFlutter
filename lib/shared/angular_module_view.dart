// Hosts an Angular product module (Travel / Liability) inside the Flutter portal shell.
// Web builds embed an iframe; other platforms (unit tests) get a placeholder.
export 'angular_module_view_stub.dart' if (dart.library.js_interop) 'angular_module_view_web.dart';
