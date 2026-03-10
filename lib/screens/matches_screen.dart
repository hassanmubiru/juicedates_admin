import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../theme.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});
  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final _svc = AdminService();
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AdminMatch> _filter(List<AdminMatch> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((m) =>
        m.name1.toLowerCase().contains(q) ||
        m.name2.toLowerCase().contains(q) ||
        m.uid1.contains(q) ||
        m.uid2.contains(q)).toList();
  }

  Future<void> _confirmDelete(AdminMatch match) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('Delete Match?',
            style: TextStyle(color: Colors.white)),
        content: Text(
            'This will unmatch ${match.name1} and ${match.name2}.',
            style: const TextStyle(color: kMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kDanger),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _svc.deleteMatch(match.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Match deleted'),
            backgroundColor: kSuccess),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: AppBar(
        backgroundColor: kDarkBg,
        elevation: 0,
        title: const Text('Matches',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by user name or UID…',
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
          Expanded(
            child: StreamBuilder<List<AdminMatch>>(
              stream: _svc.getMatches(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: kTangerine));
                }
                final all = snap.data ?? [];
                final matches = _filter(all);

                if (all.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('💞', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 16),
                        Text('No matches yet',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }
                if (matches.isEmpty) {
                  return const Center(
                      child: Text('No matches found.',
                          style: TextStyle(color: kMuted)));
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 4),
                      child: Row(
                        children: [
                          Text('${all.length} total matches',
                              style: const TextStyle(
                                  color: kMuted, fontSize: 12)),
                          if (_query.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text('(${matches.length} shown)',
                                style: const TextStyle(
                                    color: kMuted, fontSize: 12)),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: matches.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) =>
                            _MatchTile(match: matches[i], onDelete: () => _confirmDelete(matches[i])),
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

class _MatchTile extends StatelessWidget {
  final AdminMatch match;
  final VoidCallback onDelete;
  const _MatchTile({required this.match, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final ts = match.matchedAt != null
        ? DateFormat('MMM d, y — HH:mm').format(match.matchedAt!)
        : '—';
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kSuccess.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.favorite_rounded,
              color: kSuccess, size: 20),
        ),
        title: RichText(
          text: TextSpan(
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600),
            children: [
              TextSpan(
                  text: match.name1.isNotEmpty ? match.name1 : match.uid1.substring(0, 8)),
              const TextSpan(
                  text: '  💞  ',
                  style: TextStyle(color: kMuted, fontSize: 16)),
              TextSpan(
                  text: match.name2.isNotEmpty ? match.name2 : match.uid2.substring(0, 8)),
            ],
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  color: kMuted, size: 12),
              const SizedBox(width: 4),
              Text(ts,
                  style: const TextStyle(color: kMuted, fontSize: 11)),
              if (match.hasConversation) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B68EE).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF7B68EE)
                            .withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${match.messageCount} msgs',
                    style: const TextStyle(
                        color: Color(0xFF7B68EE), fontSize: 10),
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: kDanger, size: 20),
          tooltip: 'Delete match',
          onPressed: onDelete,
        ),
      ),
    );
  }
}
