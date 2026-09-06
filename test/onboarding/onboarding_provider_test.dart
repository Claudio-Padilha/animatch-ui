import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:animatch/features/onboarding/providers/onboarding_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Hive.init() (unlike Hive.initFlutter()) takes a plain path string, so
    // it doesn't need path_provider — this app's Hive usage is entirely
    // key/value flags, not platform-specific file locations.
    Hive.init('.dart_tool/test_hive_onboarding');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  test('defaults to false and stays false after load() with nothing persisted',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(hasSeenOnboardingProvider), isFalse);
    await container.read(hasSeenOnboardingProvider.notifier).load();
    expect(container.read(hasSeenOnboardingProvider), isFalse);
  });

  test('markSeen() flips state immediately and persists to disk', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final result = container.read(hasSeenOnboardingProvider.notifier).markSeen();
    // State flips synchronously (before the persistence await resolves) so
    // navigation logic reading it right after calling markSeen() is correct.
    expect(container.read(hasSeenOnboardingProvider), isTrue);
    await result;
  });

  test('persists across a fresh provider instance (simulates app restart)',
      () async {
    final container1 = ProviderContainer();
    await container1.read(hasSeenOnboardingProvider.notifier).markSeen();
    container1.dispose();

    final container2 = ProviderContainer();
    addTearDown(container2.dispose);
    expect(container2.read(hasSeenOnboardingProvider), isFalse); // not loaded yet
    await container2.read(hasSeenOnboardingProvider.notifier).load();
    expect(container2.read(hasSeenOnboardingProvider), isTrue);
  });
}
