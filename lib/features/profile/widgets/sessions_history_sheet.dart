// Bottom-sheet "Последние сеансы" — paginated list of the user's
// watch sessions. Opens from a tap on the `sessions_count` stat in
// the profile card.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/watch_history_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class SessionsHistorySheet extends ConsumerStatefulWidget {
  const SessionsHistorySheet({super.key});

  @override
  ConsumerState<SessionsHistorySheet> createState() =>
      _SessionsHistorySheetState();
}

class _SessionsHistorySheetState extends ConsumerState<SessionsHistorySheet> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    // Kick the first page off after the first frame so the
    // .autoDispose notifier is wired before we touch it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(watchHistoryProvider.notifier).loadFirstPage();
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      ref.read(watchHistoryProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(watchHistoryProvider);
    final maxHeight = MediaQuery.of(context).size.height * 0.78;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.r3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.ink4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  l.sessionsHistoryTitle,
                  style: AppTheme.display(size: 18, weight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(child: _buildBody(state, l)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(WatchHistoryState state, AppLocalizations l) {
    if (state.error != null && state.items.isEmpty) {
      return _CenteredMessage(text: l.sessionsHistoryError);
    }
    if (state.loading && state.items.isEmpty) {
      return const _CenteredMessage.spinner();
    }
    if (state.items.isEmpty) {
      return _CenteredMessage(text: l.sessionsHistoryEmpty);
    }

    final showFooter = state.loading || !state.hasMore;
    return ListView.separated(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: state.items.length + (showFooter ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        if (i >= state.items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: state.loading
                ? const Center(
                    child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const SizedBox.shrink(),
          );
        }
        return _SessionCard(session: state.items[i]);
      },
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final String? text;
  final bool spinner;

  const _CenteredMessage({this.text}) : spinner = false;
  const _CenteredMessage.spinner()
      : text = null,
        spinner = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Center(
        child: spinner
            ? const CircularProgressIndicator(strokeWidth: 2)
            : Text(
                text!,
                style: AppTheme.text(
                    size: 14, color: AppColors.ink3, weight: FontWeight.w400),
              ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final WatchSession session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final title = l.sessionsHistoryRoomTitle(session.roomInviteCode);
    final ago = _formatRelative(l, session.joinedAt);
    final dur = _formatDuration(l, session.durationSec);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppTheme.r2),
        border: Border.all(color: AppColors.hairline),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.text(size: 14, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '$ago · $dur',
                  style: AppTheme.text(
                      size: 12,
                      color: AppColors.ink3,
                      weight: FontWeight.w400),
                ),
              ],
            ),
          ),
          if (session.isRoomActive)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/room/${session.roomId}');
              },
              child: Text(l.sessionsHistoryEnter),
            ),
        ],
      ),
    );
  }

  static String _formatRelative(AppLocalizations l, DateTime joinedAt) {
    final diff = DateTime.now().difference(joinedAt);
    if (diff.inMinutes < 1) return l.sessionsHistoryAgoJustNow;
    if (diff.inMinutes < 60) return l.sessionsHistoryAgoMinutes(diff.inMinutes);
    if (diff.inHours < 24) return l.sessionsHistoryAgoHours(diff.inHours);
    return l.sessionsHistoryAgoDays(diff.inDays);
  }

  static String _formatDuration(AppLocalizations l, int seconds) {
    if (seconds < 60) return l.sessionsHistoryDurationSeconds(seconds);
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return l.sessionsHistoryDurationHours(h, m);
    return l.sessionsHistoryDurationMinutes(m);
  }
}
