/// Build-time environment, e.g.
///   flutter run -d chrome                                  (development: demo login on)
///   flutter build web --dart-define=APP_ENV=qa --dart-define=ENABLE_DEMO_LOGIN=true
///   flutter build web --dart-define=APP_ENV=production     (demo login can never be enabled)
const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'development');

const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:5080');
const angularUrl = String.fromEnvironment('ANGULAR_URL', defaultValue: 'http://localhost:4200');

/// Development: on by default. QA/UAT: opt in with ENABLE_DEMO_LOGIN=true. Production: always off.
const enableDemoLogin = appEnv != 'production' &&
    bool.fromEnvironment('ENABLE_DEMO_LOGIN', defaultValue: appEnv == 'development');
