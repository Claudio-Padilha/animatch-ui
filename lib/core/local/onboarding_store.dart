import 'package:hive_flutter/hive_flutter.dart';

/// Persists whether the user has already been shown the onboarding
/// carousel, so a returning-but-logged-out user (e.g. after logout) lands
/// on the login screen instead of replaying the slides.
class OnboardingStore {
  static const _boxName = 'settings';
  static const _hasSeenOnboardingKey = 'hasSeenOnboarding';

  static Future<bool> hasSeenOnboarding() async {
    final box = await Hive.openBox<bool>(_boxName);
    return box.get(_hasSeenOnboardingKey, defaultValue: false)!;
  }

  static Future<void> markSeen() async {
    final box = await Hive.openBox<bool>(_boxName);
    await box.put(_hasSeenOnboardingKey, true);
  }
}
