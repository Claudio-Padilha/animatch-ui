import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class StreamChatService {
  static const _apiKey = 'chbd9fpt9qxu';

  final StreamChatClient client = StreamChatClient(
    _apiKey,
    logLevel: Level.OFF,
  );

  /// Connects the user to Stream Chat. No-ops if the same user is already
  /// connected. Disconnects any different user first.
  Future<void> connectUser({
    required String userId,
    required String userName,
    required String token,
  }) async {
    if (client.state.currentUser?.id == userId) return;
    if (client.state.currentUser != null) {
      await client.disconnectUser();
    }
    await client.connectUser(
      User(id: userId, name: userName),
      token,
    );
  }

  Future<Channel> openChannel(String type, String id) async {
    final channel = client.channel(type, id: id);
    await channel.watch();
    return channel;
  }

  Future<void> dispose() => client.dispose();
}
