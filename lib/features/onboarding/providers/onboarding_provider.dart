import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/local/onboarding_store.dart';

class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> load() async {
    state = await OnboardingStore.hasSeenOnboarding();
  }

  Future<void> markSeen() async {
    state = true;
    await OnboardingStore.markSeen();
  }
}

final hasSeenOnboardingProvider =
    NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);
