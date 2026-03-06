import 'package:cached_network_image/cached_network_image.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../theme.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _svc         = AdminService();
  final _searchCtrl  = TextEditingController();
  String _query      = '';
  bool _bannedOnly   = false;
  bool _premiumOnly  = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AdminUser> _filter(List<AdminUser> all) {
    return all.where((u) {
      if (_bannedOnly  && !u.isBanned)  return false;
      if (_premiumOnly && !u.isPremium) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return u.displayName.toLowerCase().contains(q) ||
             (u.email?.toLowerCase().contains(q) ?? false) ||
             u.city.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: AppBar(
        backgroundColor: kDarkBg,
        elevation: 0,
        title: const Text('Users',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          // Filter chips
          _FilterChip(
            label: 'Banned',
            active: _bannedOnly,
            onTap: () => setState(() => _bannedOnly = !_bannedOnly),
            activeColor: kDanger,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Premium ⭐',
            active: _premiumOnly,
            onTap: () => setState(() => _premiumOnly = !_premiumOnly),
            activeColor: kWarning,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name, email or city…',
                prefixIcon: const Icon(Icons.search_rounded, color: kMuted),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: kMuted),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          // Table
          Expanded(
            child: StreamBuilder<List<AdminUser>>(
              stream: _svc.getAllUsers(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: kTangerine));
                }
                final users = _filter(snap.data ?? []);
                if (users.isEmpty) {
                  return const Center(
                      child: Text('No users found.',
                          style: TextStyle(color: kMuted)));
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 0,
                    minWidth: 720,
                    headingRowHeight: 42,
                    dataRowHeight: 58,
                    columns: const [
                      DataColumn2(label: Text('User'), size: ColumnSize.L),
                      DataColumn2(label: Text('City'),  size: ColumnSize.S),
                      DataColumn2(label: Text('Joined'), size: ColumnSize.S),
                      DataColumn2(label: Text('Status'), size: ColumnSize.S),
                      DataColumn2(label: Text('Actions'), size: ColumnSize.M),
                    ],
                    rows: users.map((u) => _buildRow(u)).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  DataRow2 _buildRow(AdminUser u) {
    final joined = u.createdAt != null
        ? DateFormat('MMM d, y').format(u.createdAt!)
        : '—';
    return DataRow2(
      cells: [
        // User
        DataCell(Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: kTangerine,
              backgroundImage: (u.photoUrl != null && u.photoUrl!.isNotEmpty)
                  ? CachedNetworkImageProvider(u.photoUrl!) as ImageProvider
                  : null,
              child: (u.photoUrl == null || u.photoUrl!.isEmpty)
                  ? const Icon(Icons.person, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.displayName,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  Text(u.email ?? '',
                      style: const TextStyle(color: kMuted, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        )),
        DataCell(Text(u.city, style: const TextStyle(color: kMuted))),
        DataCell(Text(joined, style: const TextStyle(color: kMuted, fontSize: 12))),
        // Status badges
        DataCell(Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            if (u.isPremium) _Badge('⭐', kWarning),
            if (u.isAdmin)   _Badge('🛡️ Admin', kTangerine),
            if (u.isBanned)  _Badge('🚫 Banned', kDanger),
          ],
        )),
        // Actions
        DataCell(Row(
          children: [
            // Ban / unban
            _ActionBtn(
              icon: u.isBanned
                  ? Icons.lock_open_rounded
                  : Icons.block_rounded,
              color: u.isBanned ? kSuccess : kDanger,
              tooltip: u.isBanned ? 'Unban' : 'Ban',
              onPressed: () => u.isBanned
                  ? _svc.unbanUser(u.uid)
                  : _confirm(
                      context,
                      'Ban ${u.displayName}?',
                      'They will be hidden from the app.',
                      () => _svc.banUser(u.uid),
                    ),
            ),
            // Premium toggle
            _ActionBtn(
              icon: u.isPremium
                  ? Icons.star_border_rounded
                  : Icons.star_rounded,
              color: kWarning,
              tooltip: u.isPremium ? 'Revoke Premium' : 'Grant Premium',
              onPressed: () => u.isPremium
                  ? _svc.revokePremium(u.uid)
                  : _svc.grantPremium(u.uid),
            ),
            // Admin toggle
            _ActionBtn(
              icon: u.isAdmin
                  ? Icons.shield_outlined
                  : Icons.shield_rounded,
              color: kTangerine,
              tooltip: u.isAdmin ? 'Demote' : 'Make Admin',
              onPressed: () => u.isAdmin
                  ? _confirm(context, 'Demote ${u.displayName}?',
                      'They will lose admin access.',
                      () => _svc.demoteFromAdmin(u.uid))
                  : _confirm(context, 'Promote ${u.displayName}?',
                      'They will have full admin access.',
                      () => _svc.promoteToAdmin(u.uid)),
            ),
          ],
        )),
      ],
    );
  }

  Future<void> _confirm(
    BuildContext context,
    String title,
    String body,
    VoidCallback action,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        title: Text(title,
            style: const TextStyle(color: Colors.white)),
        content: Text(body, style: const TextStyle(color: kMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (ok == true) action();
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;
  const _ActionBtn({required this.icon, required this.color,
      required this.tooltip, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color activeColor;
  const _FilterChip({required this.label, required this.active,
      required this.onTap, required this.activeColor});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeColor.withValues(alpha: 0.15) : kSidebar,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? activeColor : kBorder),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? activeColor : kMuted,
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}
