import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../domain/match_item.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.match});

  final MatchItem match;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                match.theirAnimal.imagePath,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.contact.breederName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  match.theirAnimal.name,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
      body: Column(
        children: [
          Expanded(
            child: _MessageList(match: match),
          ),
          _ComingSoonBar(),
        ],
      ),
    );
  }
}

// ─── Message list ─────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  const _MessageList({required this.match});

  final MatchItem match;

  @override
  Widget build(BuildContext context) {
    final messages = _stubMessages(match);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final prev = index > 0 ? messages[index - 1] : null;
        final showDate = prev == null || prev.date != msg.date;
        return Column(
          children: [
            if (showDate) _DateDivider(label: msg.date),
            _MessageBubble(message: msg),
          ],
        );
      },
    );
  }

  static List<_Message> _stubMessages(MatchItem match) {
    final them = match.contact.breederName.split(' ').first;
    return [
      _Message(
        text: 'Olá! Vi que temos um match entre o ${match.theirAnimal.name} e o ${match.yourAnimal.name}. Interesse em conversar sobre uma parceria?',
        isMe: false,
        time: '09:14',
        date: 'Ontem',
        senderName: them,
      ),
      _Message(
        text: 'Olá $them! Sim, com certeza. Os índices do ${match.theirAnimal.name} são excelentes. Qual seria a modalidade que você tem em mente?',
        isMe: true,
        time: '09:32',
        date: 'Ontem',
      ),
      _Message(
        text: 'Estamos pensando em IA com sêmen fresco. Temos algumas vacas prontas para o protocolo.',
        isMe: false,
        time: '09:45',
        date: 'Ontem',
        senderName: them,
      ),
      _Message(
        text: 'Faz sentido. Pode me enviar o pedigree e os DEPs completos do ${match.theirAnimal.name}? Quero avaliar antes de confirmar.',
        isMe: true,
        time: '10:03',
        date: 'Ontem',
      ),
      _Message(
        text: 'Claro, vou te passar o registro ABCZ e o laudo de avaliação genética. Quando você estaria disponível para uma visita técnica?',
        isMe: false,
        time: '10:21',
        date: 'Ontem',
        senderName: them,
      ),
      _Message(
        text: 'Próxima semana tenho disponibilidade. Posso ir até a fazenda na quarta ou quinta.',
        isMe: true,
        time: '10:35',
        date: 'Ontem',
      ),
      _Message(
        text: 'Quinta fica ótimo. Te mando o endereço e o contato do meu veterinário.',
        isMe: false,
        time: '10:40',
        date: 'Ontem',
        senderName: them,
      ),
      _Message(
        text: 'Combinado. Até quinta então!',
        isMe: true,
        time: '10:41',
        date: 'Ontem',
      ),
    ];
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _Message message;

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withAlpha(20),
              child: Text(
                message.senderName?.substring(0, 1) ?? '?',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: isMe
                    ? null
                    : Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isMe ? Colors.white : AppColors.onSurface,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.time,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withAlpha(160)
                          : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─── Date divider ─────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.muted.withAlpha(60))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: AppColors.muted.withAlpha(60))),
        ],
      ),
    );
  }
}

// ─── Coming soon input bar ────────────────────────────────────────────────────

class _ComingSoonBar extends StatelessWidget {
  const _ComingSoonBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                'Chat em breve...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.muted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.muted.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.send_rounded,
              color: AppColors.muted,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────

class _Message {
  const _Message({
    required this.text,
    required this.isMe,
    required this.time,
    required this.date,
    this.senderName,
  });

  final String text;
  final bool isMe;
  final String time;
  final String date;
  final String? senderName; // only for incoming messages
}
