import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/config/auth0_config.dart';
import 'firebase_options.dart';

void main() async {
  // Intentionally not `assert()` — those are stripped in release builds, which
  // is exactly the build type this check exists to protect.
  if (Auth0Config.domain.isEmpty || Auth0Config.clientId.isEmpty || Auth0Config.audience.isEmpty) {
    throw StateError(
      'AUTH0_DOMAIN, AUTH0_CLIENT_ID, and AUTH0_AUDIENCE must be set via --dart-define '
      '(or --dart-define-from-file). Refusing to start with missing Auth0 config.',
    );
  }
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  if (!kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  runApp(const ProviderScope(child: AnimatchApp()));
}
