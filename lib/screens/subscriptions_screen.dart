import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../theme.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});
  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final _svc = AdminService();
  late Future<List<AdminUser>> _future;
  String _tierFilter = 'all';
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _future = _svc.getPremiumUsers());

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AdminUser> _filter(List<AdminUser> all) {
    return all.where((u) {
      if (_tierFilter != 'all' && u.subscriptionTier != _tierFilter) {
        return false;
      }
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return u.displayName.toLowerCase().contains(q) ||
          (u.email?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'plus':
        return const Color(0xFF4FC3F7);
      case 'gold':
        return kWarning;
      case 'platinum':
        return const Color(0xFFCE93D8);
      default:
        return kMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: AppBar(
        backgroundColor: kDarkBg,
        elevation: 0,
        title: const Text('Subscriptions',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kMuted),
            onPressed: _load,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search subscribers…',
                      prefixIcon:
                          const Icon(Icons.search_rounded, color: kMuted),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: kMuted),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              })
                          : null,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(width: 12),
                _TierChip(
                    label: 'All',
                    active: _tierFilter == 'all',
                    color: kMuted,
                    onTap: () => setState(() => _tierFilter = 'all')),
                const SizedBox(width: 8),
                _TierChip(
                    label: 'Plus',
                    active: _tierFilter == 'plus',
                    color: const Color(0xFF4FC3F7),
                    onTap: () => setState(() => _tierFilter = 'plus')),
                const SizedBox(width: 8),
                _TierChip(
                    label: 'Gold',
                    active: _tierFilter == 'gold',
                    color: kWarning,
                    onTap: () => setState(() => _tierFilter = 'gold')),
                const SizedBox(width: 8),
                _TierChip(
                    label: 'Platinum',
                    active: _tierFilter == 'platinum',
                    color: const Color(0xFFCE93D8),
                    onTap: () => setState(() => _tierFilter = 'platinum')),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<AdminUser>>(
              future: _future,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: kTangerine));
                }
                final all = snap.data ?? [];
                final users = _filter(all);

                if (all.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('⭐', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 16),
                        Text('No premium subscribers yet.',
                            style: TextStyle(color: Colors.white, fontSize: 18)),
                      ],
                    ),
                  );
                }

                if (users.isEmpty) {
                  return const Center(
                      child: Text('No subscribers match the filter.',
                          style: TextStyle(color: kMuted)));
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Text('${users.length} subscribers',
                              style: const TextStyle(
                                  color: kMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount: users.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) =>
                            _SubscriberTile(user: users[i], svc: _svc,
                                tierColor: _tierColor(users[i].subscriptionTier),
                                onChanged: _load),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriberTile extends StatelessWidget {
  final AdminUser user;
  final AdminService svc;
  final Color tierColor;
  final VoidCallback onChanged;
  const _SubscriberTile(
      {required this.user, required this.svc, required this.tierColor, required this.onChanged});

  String get _expiryStr {
    if (user.subscriptionExpiry == null) return 'No expiry';
    final expired = DateTime.now().isAfter(user.subscriptionExpiry!);
    final s = DateFormat('MMM d, y').format(user.subscriptionExpiry!);
    return expired ? 'Expired $s' : 'Expires $s';
  }

  bool get _isExpired =>
      user.subscriptionExpiry != null &&
      DateTime.now().isAfter(user.subscriptionExpiry!);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: kTangerine,
          backgroundImage:
              (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                  ? CachedNetworkImageProvider(user.photoUrl!)
                      as ImageProvider
                  : null,
          child: (user.photoUrl == null || user.photoUrl!.isEmpty)
              ? const Icon(Icons.person, color: Colors.white, size: 20)
              : null,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(user.displayName,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: tierColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                user.subscriptionTier.toUpperCase(),
                style: TextStyle(
                    color: tierColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email ?? user.uid,
                style: const TextStyle(color: kMuted, fontSize: 12)),
            const SizedBox(height: 2),
            Text(_expiryStr,
                style: TextStyle(
                    color: _isExpired ? kDanger : kSuccess,
                    fontSize: 11)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: kMuted),
          color: kCard,
          onSelected: (action) async {
            switch (action) {
              case 'revoke':
                await svc.revokePremium(user.uid);
                onChanged();
              case 'extend_plus':
                await svc.grantPremium(user.uid, tier: 'plus');
                onChanged();
              case 'extend_gold':
                await svc.grantPremium(user.uid, tier: 'gold');
                onChanged();
              case 'extend_platinum':
                await svc.grantPremium(user.uid, tier: 'platinum');
                onChanged();
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
                value: 'extend_plus',
                child: Text('Set Plus (30d)',
                    style: TextStyle(color: Color(0xFF4FC3F7)))),
            const PopupMenuItem(
                value: 'extend_gold',
                child: Text('Set Gold (30d)',
                    style: TextStyle(color: kWarning))),
            const PopupMenuItem(
                value: 'extend_platinum',
                child: Text('Set Platinum (30d)',
                    style: TextStyle(color: Color(0xFFCE93D8)))),
            const PopupMenuDivider(),
            const PopupMenuItem(
                value: 'revoke',
                child: Text('Revoke Premium',
                    style: TextStyle(color: kDanger))),
          ],
        ),
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _TierChip(
      {required this.label,
      required this.active,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              active ? color.withValues(alpha: 0.15) : kSidebar,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : kBorder),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? color : kMuted,
                fontSize: 12,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}
