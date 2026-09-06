import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

// Flutter's test runner picks this file up automatically and wraps every
// test in this directory tree with testExecutable. Without this, each
// widget test that renders GoogleFonts-styled text (most of the app's UI —
// see app_theme.dart) attempts a real network fetch for the font on first
// use; in this sandboxed test environment that fetch can't succeed, so the
// text silently renders with a fallback font (Roboto) whose metrics differ
// from the real Merriweather/Inter used in production. That can shift
// layout enough to produce spurious RenderFlex overflow errors that
// wouldn't necessarily occur — or occur to a different degree — on a real
// device with the actual font loaded. Disabling runtime fetching here
// makes every test's font fallback deterministic (no network-timing race),
// matching the one-off fix `test/widget_test.dart` already applied locally
// — this hoists it repo-wide instead of requiring every new test file to
// remember it.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
