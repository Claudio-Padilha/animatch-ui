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
  if (kDebugMode) {
    debugPrint('[Chat] building chatChannelProvider for match $matchId');
  }

  final breeder = ref.read(authNotifierProvider)!;
  final repo = ref.read(matchRepositoryProvider);
  final chatService = ref.read(streamChatServiceProvider);

  try {
    if (kDebugMode) {
      debugPrint('[Chat] fetching chat token...');
    }
    final tokenData = await repo.getChatToken(matchId);
    final token = tokenData['token'] as String;
    final channelId = tokenData['channelId'] as String;
    final channelType = tokenData['channelType'] as String;
    if (kDebugMode) {
      debugPrint('[Chat] token fetched. channelId=$channelId');
    }

    if (kDebugMode) {
      debugPrint('[Chat] connecting user ${breeder.id}...');
    }
    await chatService.connectUser(
      userId: breeder.id,
      userName: breeder.name,
      token: token,
    );
    if (kDebugMode) {
      debugPrint('[Chat] user connected.');
    }

    if (kDebugMode) {
      debugPrint('[Chat] opening channel...');
    }
    final channel = await chatService.openChannel(channelType, channelId);
    if (kDebugMode) {
      debugPrint('[Chat] channel open. Done.');
    }

    // Register FCM token with Stream (mobile only).
    if (!kIsWeb) {
      try {
        final fcmToken = await ref.read(notificationServiceProvider).getToken();
        if (fcmToken != null) {
          await chatService.client.addDevice(fcmToken, PushProvider.firebase, pushProviderName: 'firebase-service-account');
          if (kDebugMode) {
            debugPrint('[Chat] addDevice ok.');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Chat] addDevice error (non-fatal): $e');
        }
      }
    }

    return channel;
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[Chat] ERROR in chatChannelProvider: $e\n$st');
    }
    rethrow;
  }
});

final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => MatchRepository(ref.watch(dioProvider)),
);

final matchesProvider = FutureProvider.autoDispose
    .family<List<MatchItem>, String>((ref, animalId) =>
        ref.read(matchRepositoryProvider).getMatches(animalId));

/// A single match by id, fetched fresh from `GET /matches/:id` — the source of
/// truth for the match-detail and chat screens (status and breeder contact go
/// stale the instant the other party acts). Also recovers these screens on a
/// cold deep-link / push-tap / OS restoration, where no in-memory match exists.
final matchDetailProvider = FutureProvider.autoDispose
    .family<MatchItem, String>((ref, matchId) =>
        ref.read(matchRepositoryProvider).getMatch(matchId));

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
