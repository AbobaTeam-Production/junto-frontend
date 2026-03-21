import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/room_ws_provider.dart';
import '../../rooms/providers/room_providers.dart';

class ChatPanel extends ConsumerStatefulWidget {
  final String roomId;

  const ChatPanel({super.key, required this.roomId});

  @override
  ConsumerState<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<ChatPanel> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref.read(roomWsProvider(widget.roomId).notifier).sendChat(text);
    _messageController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Build a map of username → avatar_url from room detail data.
  Map<String, String?> _buildAvatarMap(AsyncValue<Map<String, dynamic>> roomAsync) {
    final avatarMap = <String, String?>{};
    roomAsync.whenData((roomData) {
      final members = (roomData['members'] as List?) ?? [];
      for (final member in members) {
        final m = member as Map<String, dynamic>;
        final user = m['user'] as Map<String, dynamic>;
        final username = user['username'] as String? ?? '';
        final avatarUrl = user['avatar_url'] as String?;
        avatarMap[username] = avatarUrl;
      }
    });
    return avatarMap;
  }

  @override
  Widget build(BuildContext context) {
    final wsState = ref.watch(roomWsProvider(widget.roomId));
    final messages = wsState.messages;
    final currentUser = ref.watch(currentUserProvider);
    final myName = currentUser?.username ?? 'Гость';
    final roomAsync = ref.watch(roomDetailProvider(widget.roomId));
    final avatarMap = _buildAvatarMap(roomAsync);

    // Auto-scroll when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return Column(
      children: [
        // Messages
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 40, color: AppColors.textHint),
                      const SizedBox(height: 8),
                      Text(
                        'Пока нет сообщений',
                        style: TextStyle(color: AppColors.textHint),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.username == myName;
                    final avatarUrl = avatarMap[msg.username];
                    return _buildMessage(msg, isMe, avatarUrl);
                  },
                ),
        ),

        // Input area
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Сообщение...',
                    hintStyle: const TextStyle(fontSize: 14),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(ChatMessage msg, bool isMe, String? avatarUrl) {
    final color = isMe ? AppColors.success : _colorForName(msg.username);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          if (avatarUrl != null)
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(avatarUrl),
            )
          else
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Text(
                msg.username.isNotEmpty ? msg.username[0].toUpperCase() : '?',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isMe ? 'Вы' : msg.username,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      msg.time,
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  msg.text,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForName(String name) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.warning,
      const Color(0xFF4CAF50),
      const Color(0xFF00BCD4),
      const Color(0xFFFF9800),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }
}
