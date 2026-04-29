import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../domain/match_item.dart';
import '../providers/match_provider.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key, required this.match});

  final MatchItem match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelAsync = ref.watch(chatChannelProvider(match.id));

    return Scaffold(
      appBar: _MatchAppBar(match: match),
      bottomNavigationBar: const AppBottomNav(),
      body: channelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _ErrorState(
          onRetry: () => ref.invalidate(chatChannelProvider(match.id)),
        ),
        data: (channel) => _ChatBody(match: match, channel: channel),
      ),
    );
  }
}

// ─── App bar ──────────────────────────────────────────────────────────────────

class _MatchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _MatchAppBar({required this.match});

  final MatchItem match;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final animal = match.theirAnimal;
    final breederName = match.contact.breederName;

    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: animal.imagePath.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: animal.imagePath,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => _avatarPlaceholder(),
                    errorWidget: (_, _, _) => _avatarPlaceholder(),
                  )
                : _avatarPlaceholder(),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                breederName.isNotEmpty ? breederName : animal.name,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (breederName.isNotEmpty)
                Text(
                  animal.name,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder() => Container(
        width: 36,
        height: 36,
        color: AppColors.primary.withValues(alpha: 0.12),
        child: const Icon(Icons.pets, size: 18, color: AppColors.primary),
      );
}

// ─── Chat body ────────────────────────────────────────────────────────────────

class _ChatBody extends ConsumerWidget {
  const _ChatBody({required this.match, required this.channel});

  final MatchItem match;
  final Channel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.read(streamChatServiceProvider).client;

    return StreamChat(
      client: client,
      streamChatThemeData: StreamChatThemeData(
        colorTheme: StreamColorTheme.light(
          accentPrimary: AppColors.primary,
        ),
        ownMessageTheme: StreamMessageThemeData(
          messageBackgroundColor: AppColors.primary,
          messageTextStyle: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white,
            height: 1.4,
          ),
        ),
        otherMessageTheme: StreamMessageThemeData(
          messageTextStyle: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.onSurface,
            height: 1.4,
          ),
        ),
      ),
      child: StreamChannel(
        channel: channel,
        child: const Column(
          children: [
            Expanded(child: StreamMessageListView()),
            StreamMessageInput(),
          ],
        ),
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: AppColors.muted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Não foi possível abrir o chat',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Verifique sua conexão e tente novamente.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
