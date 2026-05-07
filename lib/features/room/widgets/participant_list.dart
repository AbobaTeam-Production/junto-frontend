import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/server_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/room_ws_provider.dart';
import '../../rooms/providers/room_providers.dart';
import '../../../l10n/app_localizations.dart';

class ParticipantList extends ConsumerWidget {
  final String roomId;

  const ParticipantList({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final roomAsync = ref.watch(roomDetailProvider(roomId));
    final onlineUsers = ref.watch(
      roomWsProvider(roomId).select((s) => s.onlineUsers),
    );
    final currentUser = ref.watch(currentUserProvider);

    return roomAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Text(l.participantLoadError,
            style: const TextStyle(color: AppColors.textHint)),
      ),
      data: (roomData) {
        final members = (roomData['members'] as List?) ?? [];

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          separatorBuilder: (_, _) => const Divider(
            color: AppColors.divider,
            height: 1,
          ),
          itemBuilder: (context, index) {
            final member = members[index] as Map<String, dynamic>;
            final user = member['user'] as Map<String, dynamic>;
            final username = user['username'] as String? ?? '';
            // Backend returns relative '/media/avatars/...' — promote to
            // a full URL so NetworkImage can resolve it.
            final rawAvatar = user['avatar_url'] as String?;
            final avatarUrl = (rawAvatar != null && rawAvatar.startsWith('/'))
                ? '${ServerConfig.mediaBaseUrl}$rawAvatar'
                : rawAvatar;
            final isHost = member['is_host'] as bool? ?? false;
            final isMe = currentUser?.username == username;
            final isOnline = onlineUsers.containsKey(username);

            return _ParticipantTile(
              name: isMe ? l.chatYouLabel : username,
              avatarUrl: avatarUrl,
              isHost: isHost,
              isOnline: isOnline,
              color: isMe
                  ? AppColors.success
                  : _colorForName(username),
            );
          },
        );
      },
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

class _ParticipantTile extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool isHost;
  final bool isOnline;
  final Color color;

  const _ParticipantTile({
    required this.name,
    this.avatarUrl,
    required this.isHost,
    required this.isOnline,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              if (avatarUrl != null)
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(avatarUrl!),
                )
              else
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Text(
                    name[0].toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              // Online indicator
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.online,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (isHost) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l.participantHostLabel,
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isHost ? l.participantHostRole : l.participantViewerRole,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
