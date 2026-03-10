import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../theme.dart';

class FakeProfilesScreen extends StatefulWidget {
  const FakeProfilesScreen({super.key});

  @override
  State<FakeProfilesScreen> createState() => _FakeProfilesScreenState();
}

class _FakeProfilesScreenState extends State<FakeProfilesScreen>
    with SingleTickerProviderStateMixin {
  final _svc = AdminService();
  late TabController _tab;
  List<AdminUser> _flagged = [];
  List<AdminUser> _highReports = [];
  bool _loading = true;
  bool _detecting = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final users = await _svc.getUsersOnce();
    setState(() {
      _flagged = users.where((u) => u.isSuspicious).toList();
      _highReports = users
          .where((u) => !u.isSuspicious && u.reportCount >= 3)
          .toList()
        ..sort((a, b) => b.reportCount.compareTo(a.reportCount));
      _loading = false;
    });
  }

  Future<void> _runAutoDetect() async {
    setState(() => _detecting = true);
    try {
      final users = await _svc.getUsersOnce();
      int count = 0;
      for (final u in users) {
        if (u.isBanned || u.isSuspicious) continue;
        final reasons = <String>[];
        if (u.reportCount >= 3) reasons.add('${u.reportCount} reports');
        if (u.photoUrl == null && u.isPremium) {
          reasons.add('premium with no photo');
        }
        if (u.createdAt != null) {
          final ageInDays = DateTime.now().difference(u.createdAt!).inDays;
          if (ageInDays < 7 &&
              (u.bio == null || u.bio!.isEmpty) &&
              u.photoUrl == null) {
            reasons.add('new account with no profile');
          }
        }
        if (reasons.isNotEmpty) {
          await _svc.flagAsSuspicious(u.uid, reasons.join(', '));
          count++;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-detected $count suspicious account${count == 1 ? '' : 's'}'),
          ),
        );
        _load();
      }
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  List<AdminUser> _filtered(List<AdminUser> list) {
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list
        .where((u) =>
            u.displayName.toLowerCase().contains(q) ||
            (u.email ?? '').toLowerCase().contains(q) ||
            u.uid.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _onAction(_SuspectAction action, AdminUser user) async {
    switch (action) {
      case _SuspectAction.ban:
        await _svc.banUser(user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${user.displayName} banned')));
        }
      case _SuspectAction.dismiss:
        await _svc.unflagSuspicious(user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dismissed — account is not suspicious')));
        }
      case _SuspectAction.flag:
        final reason = await _showFlagDialog();
        if (reason != null && reason.isNotEmpty && mounted) {
          await _svc.flagAsSuspicious(user.uid, reason);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${user.displayName} flagged')));
          }
        }
      case _SuspectAction.copyUid:
        await Clipboard.setData(ClipboardData(text: user.uid));
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('UID copied')));
        }
    }
    _load();
  }

  Future<String?> _showFlagDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('Flag as Suspicious'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Reason…'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              style: ElevatedButton.styleFrom(backgroundColor: kDanger),
              child: const Text('Flag')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: AppBar(
        backgroundColor: kSidebar,
        title: const Text('Fake Profile Detection'),
        actions: [
          if (_detecting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: kTangerine),
              ),
            )
          else
            TextButton.icon(
              onPressed: _runAutoDetect,
              icon: const Icon(Icons.manage_search_rounded, color: kTangerine),
              label: const Text('Run Detection',
                  style: TextStyle(color: kTangerine)),
            ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: kTangerine,
          labelColor: Colors.white,
          unselectedLabelColor: kMuted,
          tabs: [
            Tab(text: 'Flagged (${_flagged.length})'),
            Tab(text: 'High Reports (${_highReports.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, email or UID…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: kCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kBorder),
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tab,
                    children: [
                      _UserList(
                        _filtered(_flagged),
                        isFlagged: true,
                        onAction: _onAction,
                      ),
                      _UserList(
                        _filtered(_highReports),
                        isFlagged: false,
                        onAction: _onAction,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Actions ───────────────────────────────────────────────────────────────
enum _SuspectAction { ban, dismiss, flag, copyUid }

// ── User list ─────────────────────────────────────────────────────────────
class _UserList extends StatelessWidget {
  final List<AdminUser> users;
  final bool isFlagged;
  final void Function(_SuspectAction, AdminUser) onAction;

  const _UserList(this.users,
      {required this.isFlagged, required this.onAction});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFlagged
                  ? Icons.verified_user_rounded
                  : Icons.check_circle_rounded,
              size: 48,
              color: kMuted,
            ),
            const SizedBox(height: 12),
            Text(
              isFlagged ? 'No flagged accounts' : 'No high-report accounts',
              style: const TextStyle(color: kMuted),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (_, i) => _SuspectCard(
        user: users[i],
        isFlagged: isFlagged,
        onAction: onAction,
      ),
    );
  }
}

// ── Suspect card ──────────────────────────────────────────────────────────
class _SuspectCard extends StatelessWidget {
  final AdminUser user;
  final bool isFlagged;
  final void Function(_SuspectAction, AdminUser) onAction;

  const _SuspectCard(
      {required this.user,
      required this.isFlagged,
      required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: user.isBanned ? kDanger.withAlpha(80) : kBorder,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: kBorder,
            backgroundImage: user.photoUrl != null
                ? CachedNetworkImageProvider(user.photoUrl!)
                : null,
            child: user.photoUrl == null
                ? const Icon(Icons.person_rounded, color: kMuted)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.isBanned) ...[
                      const SizedBox(width: 6),
                      _Badge('BANNED', kDanger),
                    ],
                    if (user.isPremium) ...[
                      const SizedBox(width: 6),
                      _Badge('PREMIUM', kWarning),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.email ?? user.uid,
                  style: const TextStyle(color: kMuted, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    _Chip(Icons.flag_rounded,
                        '${user.reportCount} report${user.reportCount == 1 ? '' : 's'}',
                        user.reportCount >= 3 ? kDanger : kMuted),
                    if (isFlagged && user.suspicionReason != null)
                      _Chip(Icons.info_outline_rounded,
                          user.suspicionReason!, kWarning),
                    if (!isFlagged)
                      _Chip(Icons.pending_rounded, 'Unreviewed', kWarning),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<_SuspectAction>(
            onSelected: (a) => onAction(a, user),
            color: kCard,
            icon: const Icon(Icons.more_vert_rounded, color: kMuted),
            itemBuilder: (_) => [
              if (!user.isBanned)
                const PopupMenuItem(
                    value: _SuspectAction.ban,
                    child: Text('Ban User',
                        style: TextStyle(color: kDanger))),
              if (isFlagged)
                const PopupMenuItem(
                    value: _SuspectAction.dismiss,
                    child: Text('Dismiss (Not Suspicious)')),
              if (!isFlagged)
                const PopupMenuItem(
                    value: _SuspectAction.flag,
                    child: Text('Flag as Suspicious',
                        style: TextStyle(color: kWarning))),
              const PopupMenuItem(
                  value: _SuspectAction.copyUid,
                  child: Text('Copy UID')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(4)),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      );
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      );
}
