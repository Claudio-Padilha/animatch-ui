import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import '../../../core/network/api_client.dart';
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
  final breeder = ref.read(authNotifierProvider)!;
  final repo = ref.read(matchRepositoryProvider);
  final chatService = ref.read(streamChatServiceProvider);

  final tokenData = await repo.getChatToken(matchId, breederId: breeder.id);
  final token = tokenData['token'] as String;
  final channelId = tokenData['channelId'] as String;
  final channelType = tokenData['channelType'] as String;

  await chatService.connectUser(
    userId: breeder.id,
    userName: breeder.name,
    token: token,
  );

  return chatService.openChannel(channelType, channelId);
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
