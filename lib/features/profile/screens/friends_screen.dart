import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/friends_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/junto_primitives.dart';
import '../../../l10n/app_localizations.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _searchQuery = v.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final requestsAsync = ref.watch(friendRequestsProvider);
    final pendingCount =
        requestsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(l.friendsScreenTitle,
            style: AppTheme.display(size: 20, weight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.amber,
          unselectedLabelColor: AppColors.ink3,
          indicatorColor: AppColors.amber,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: AppTheme.text(size: 13, weight: FontWeight.w600),
          tabs: [
            Tab(text: l.friendsTabFriends),
            Tab(
              text: pendingCount > 0
                  ? l.friendsTabRequestsBadge(pendingCount)
                  : l.friendsTabRequests,
            ),
            Tab(text: l.friendsTabSearch),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FriendsList(),
          _RequestsList(),
          _SearchTab(
            controller: _searchCtrl,
            query: _searchQuery,
            onChanged: _onSearchChanged,
          ),
        ],
      ),
    );
  }
}

class _FriendsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(friendsListProvider);
    return async.when(
      data: (list) {
        if (list.isEmpty) {
          return _EmptyState(title: l.friendsEmpty, desc: l.friendsEmptyDesc);
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: list.length,
          separatorBuilder: (_, _) =>
              const Divider(color: AppColors.hairline, height: 1),
          itemBuilder: (ctx, i) => _FriendRow(friendship: list[i]),
        );
      },
      loading: () => const _Loading(),
      error: (e, _) => _Error('$e'),
    );
  }
}

class _RequestsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(friendRequestsProvider);
    return async.when(
      data: (list) {
        if (list.isEmpty) {
          return _EmptyState(title: l.friendsRequestsEmpty, desc: '');
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: list.length,
          separatorBuilder: (_, _) =>
              const Divider(color: AppColors.hairline, height: 1),
          itemBuilder: (ctx, i) => _RequestRow(friendship: list[i]),
        );
      },
      loading: () => const _Loading(),
      error: (e, _) => _Error('$e'),
    );
  }
}

class _SearchTab extends ConsumerWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;

  const _SearchTab({
    required this.controller,
    required this.query,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(userSearchProvider(query));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: l.friendsSearchHint,
              prefixIcon:
                  const Icon(Icons.search_rounded, color: AppColors.ink3),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.r2),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: async.when(
            data: (hits) {
              if (query.isEmpty) {
                return const SizedBox.shrink();
              }
              if (hits.isEmpty) {
                return _EmptyState(title: l.friendsSearchEmpty, desc: '');
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: hits.length,
                separatorBuilder: (_, _) =>
                    const Divider(color: AppColors.hairline, height: 1),
                itemBuilder: (ctx, i) => _SearchRow(hit: hits[i]),
              );
            },
            loading: () => const _Loading(),
            error: (e, _) => _Error('$e'),
          ),
        ),
      ],
    );
  }
}

class _FriendRow extends ConsumerWidget {
  final Friendship friendship;
  const _FriendRow({required this.friendship});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          JuntoAvatar(name: friendship.peer.username, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              friendship.peer.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.text(size: 15, weight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () async {
              final ok = await _confirmRemove(context, l);
              if (ok != true) return;
              await ref
                  .read(friendActionsProvider)
                  .remove(friendship.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l.friendsActionRemove),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmRemove(BuildContext context, AppLocalizations l) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.r2)),
        title: Text(l.friendsRemoveConfirm,
            style: AppTheme.display(size: 16, weight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.profileLogoutCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.friendsActionRemove,
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _RequestRow extends ConsumerWidget {
  final Friendship friendship;
  const _RequestRow({required this.friendship});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final actions = ref.read(friendActionsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          JuntoAvatar(name: friendship.peer.username, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              friendship.peer.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.text(size: 15, weight: FontWeight.w500),
            ),
          ),
          IconButton(
            tooltip: l.friendsActionDecline,
            onPressed: () => actions.remove(friendship.id),
            icon: const Icon(Icons.close_rounded, color: AppColors.ink3),
          ),
          IconButton(
            tooltip: l.friendsActionAccept,
            onPressed: () => actions.accept(friendship.id),
            icon: const Icon(Icons.check_rounded, color: AppColors.amber),
          ),
        ],
      ),
    );
  }
}

class _SearchRow extends ConsumerStatefulWidget {
  final UserSearchHit hit;
  const _SearchRow({required this.hit});

  @override
  ConsumerState<_SearchRow> createState() => _SearchRowState();
}

class _SearchRowState extends ConsumerState<_SearchRow> {
  // Local override so the row flips to "Заявка отправлена" instantly after
  // tap, without waiting for the search list to re-fetch.
  PeerRelation? _localRelation;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final relation = _localRelation ?? widget.hit.relation;

    Widget action;
    switch (relation) {
      case PeerRelation.accepted:
        action = Icon(Icons.check_rounded, color: AppColors.success, size: 18);
        break;
      case PeerRelation.pendingOutgoing:
        action = Text(l.friendsActionPending,
            style: AppTheme.text(size: 13, color: AppColors.ink3));
        break;
      case PeerRelation.pendingIncoming:
        action = TextButton(
          onPressed: () async {
            // Without the friendshipId we can't accept here directly —
            // bump the user to the Requests tab. The list provider will
            // pick it up on next focus.
            DefaultTabController.maybeOf(context)?.animateTo(1);
          },
          child: Text(l.friendsActionAccept),
        );
        break;
      case PeerRelation.none:
        action = TextButton(
          onPressed: () async {
            setState(() => _localRelation = PeerRelation.pendingOutgoing);
            try {
              await ref
                  .read(friendActionsProvider)
                  .sendRequest(widget.hit.peer.id);
            } catch (_) {
              if (mounted) setState(() => _localRelation = null);
            }
          },
          child: Text(l.friendsActionAdd),
        );
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          JuntoAvatar(name: widget.hit.peer.username, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.hit.peer.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.text(size: 15, weight: FontWeight.w500),
            ),
          ),
          action,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String desc;
  const _EmptyState({required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MonoLabel(title, color: AppColors.ink2, letterSpacing: 1.5, size: 11),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(desc,
                  textAlign: TextAlign.center,
                  style: AppTheme.text(size: 13, color: AppColors.ink3)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.amber));
}

class _Error extends StatelessWidget {
  final String message;
  const _Error(this.message);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message,
          style: AppTheme.text(size: 13, color: AppColors.ink3)),
    );
  }
}
