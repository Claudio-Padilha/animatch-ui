# Memory Index

- [Animatch Test Infrastructure Notes](project_test_infrastructure.md) — mocktail/http_mock_adapter added 2026-08-13; AuthRepository/CloudinaryUploader DI fixed; StreamChatService/NotificationService still blocked; integration_test/ still doesn't exist
- [Riverpod invalidate() testing idiom](feedback_riverpod_invalidate_testing.md) — use `container.pump()` or re-read `.future`, not `Future.delayed(Duration.zero)`, to await ref.invalidate() side effects
- [Herd test batch review](project_herd_batch_review.md) — FakeHerdRepository.getAnimals doesn't capture breederId; Update/Toggle notifiers missing failure-path tests; K-1 reading confirmed correct
- [Discover/matches/locations batch review](project_discover_matches_locations_batch_review.md) — mocktail exact-key-set named-arg matching, http_mock_adapter strict signature matching, CardSwiper.none() confirmed via source; getMatches animalId-forwarding gap
- [Matches batch 2 review](project_matches_batch2_review.md) — K-3 confirmed correct; GestureDetector.at(1) safe despite InkWell internals; cancelMatchProvider is dead code; profile_provider_test.dart flaky teardown
- [Profile batch review](project_profile_batch_review.md) — Riverpod 3.x default AsyncNotifier retry confirmed real+idiomatic fix; K-2 re-confirmed; herd my_animal_detail_screen_test.dart flake (unrelated)
- [Herd UI batch review](project_herd_ui_batch_review.md) — K-4 & whenData-no-crash independently reproduced/reconfirmed; index-based dropdown helper is fragile; 430pt viewport unneeded in 2/4 files
- [Batch K final review](project_batch_k_final_review.md) — editAnimal/myAnimalDetail "declaration-order" collision is fictional (confirmed via go_router source + empirical swap test); FakeHerdRepository lacks a getAnimal (singular) counter, making one animal_detail_loader_test.dart assertion vacuous
