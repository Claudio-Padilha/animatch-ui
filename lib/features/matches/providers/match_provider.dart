import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/stream_chat_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/match_repository.dart';
import '../domain/match_item.dart';

// ─── Stream Chat ──────────────────────────────────────────────────────────────

final streamChatServiceProvider = Provider<StreamChatService>((ref) {
  final service = StreamChatService();
  ref.onDispose(service.dispose);
  return service;
});

final chatChannelProvider = FutureProvider.autoDispose
    .family<Channel, String>((ref, matchId) async {
  // ignore: avoid_print
  print('[Chat] building chatChannelProvider for match $matchId');

  final breeder = ref.read(authNotifierProvider)!;
  final repo = ref.read(matchRepositoryProvider);
  final chatService = ref.read(streamChatServiceProvider);

  try {
    // ignore: avoid_print
    print('[Chat] fetching chat token...');
    final tokenData = await repo.getChatToken(matchId, breederId: breeder.id);
    final token = tokenData['token'] as String;
    final channelId = tokenData['channelId'] as String;
    final channelType = tokenData['channelType'] as String;
    // ignore: avoid_print
    print('[Chat] token fetched. channelId=$channelId');

    // ignore: avoid_print
    print('[Chat] connecting user ${breeder.id}...');
    await chatService.connectUser(
      userId: breeder.id,
      userName: breeder.name,
      token: token,
    );
    // ignore: avoid_print
    print('[Chat] user connected.');

    // ignore: avoid_print
    print('[Chat] opening channel...');
    final channel = await chatService.openChannel(channelType, channelId);
    // ignore: avoid_print
    print('[Chat] channel open. Done.');

    // Register FCM token with Stream (mobile only).
    if (!kIsWeb) {
      try {
        final fcmToken = await ref.read(notificationServiceProvider).getToken();
        if (fcmToken != null) {
          await chatService.client.addDevice(fcmToken, PushProvider.firebase, pushProviderName: 'firebase-service-account');
          // ignore: avoid_print
          print('[Chat] addDevice ok.');
        }
      } catch (e) {
        // ignore: avoid_print
        print('[Chat] addDevice error (non-fatal): $e');
      }
    }

    return channel;
  } catch (e, st) {
    // ignore: avoid_print
    print('[Chat] ERROR in chatChannelProvider: $e\n$st');
    rethrow;
  }
});

final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => MatchRepository(ref.watch(dioProvider)),
);

final matchesProvider = FutureProvider.autoDispose
    .family<List<MatchItem>, String>((ref, animalId) =>
        ref.read(matchRepositoryProvider).getMatches(animalId));

// ─── Cancel match ─────────────────────────────────────────────────────────────

class CancelMatchNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> cancel(String matchId, {required String animalId}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(matchRepositoryProvider).rejectMatch(matchId),
    );
    if (state is! AsyncError) {
      ref.invalidate(matchesProvider(animalId));
    }
  }
}

final cancelMatchProvider =
    AsyncNotifierProvider<CancelMatchNotifier, void>(CancelMatchNotifier.new);

// ─── Delete match ─────────────────────────────────────────────────────────────

class DeleteMatchNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> deleteMatch(String matchId, {required String animalId}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(matchRepositoryProvider).deleteMatch(matchId),
    );
    if (state is! AsyncError) {
      ref.invalidate(matchesProvider(animalId));
    }
  }
}

final deleteMatchProvider =
    AsyncNotifierProvider<DeleteMatchNotifier, void>(DeleteMatchNotifier.new);
