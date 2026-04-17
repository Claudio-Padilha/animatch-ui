// Configure environment at build/run time:
//   flutter run --dart-define=ENV=local
//   flutter run --dart-define=ENV=staging
//   flutter run --dart-define=ENV=production
//
// Defaults to "local" when ENV is not set.

import 'dart:io';

import 'package:flutter/foundation.dart';

enum _Env { local, staging, production }

abstract final class AppConfig {
  static const _rawEnv = String.fromEnvironment('ENV', defaultValue: 'local');

  static final _env = switch (_rawEnv) {
    'production' => _Env.production,
    'staging' => _Env.staging,
    _ => _Env.local,
  };

  // Android emulator reaches the host machine via 10.0.2.2, not localhost.
  static String get _localHost =>
      !kIsWeb && Platform.isAndroid ? '10.0.2.2' : 'localhost';

  static String get apiBaseUrl => switch (_env) {
    _Env.local => 'http://$_localHost:3000',
    _Env.staging => 'https://staging-api.animatch.com.br',
    _Env.production => 'https://api.animatch.com.br',
  };

  static bool get isLocal => _env == _Env.local;
}
