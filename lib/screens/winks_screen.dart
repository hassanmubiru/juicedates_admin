import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../theme.dart';

class WinksScreen extends StatelessWidget {
  const WinksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = AdminService();
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: AppBar(
        backgroundColor: kDarkBg,
        elevation: 0,
        title: const Text('Winks',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: svc.getWinks(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kTangerine));
          }
          final winks = snap.data ?? [];
          if (winks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('👋', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text('No winks yet',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: winks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (_, i) => _WinkTile(data: winks[i]),
          );
        },
      ),
    );
  }
}

class _WinkTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _WinkTile({required this.data});

  @override
  Widget build(BuildContext context) {
    DateTime? ts;
    final raw = data['createdAt'];
    if (raw != null) {
      try {
        ts = (raw as dynamic).toDate() as DateTime;
      } catch (_) {}
    }
    final timeStr =
        ts != null ? DateFormat('MMM d, y — HH:mm').format(ts) : '—';
    final seen = data['seen'] as bool? ?? false;

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF00BCD4).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('👋', style: TextStyle(fontSize: 22)),
        ),
        title: RichText(
          text: TextSpan(
            style: const TextStyle(
                color: Colors.white, fontSize: 14),
            children: [
              TextSpan(
                  text: (data['fromName'] as String?) ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(
                  text: '  →  ',
                  style: TextStyle(color: kMuted)),
              TextSpan(
                  text: (data['toUid'] as String? ?? '').length > 8
                      ? '${(data['toUid'] as String).substring(0, 8)}…'
                      : (data['toUid'] as String? ?? '—')),
            ],
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(timeStr,
              style: const TextStyle(color: kMuted, fontSize: 11)),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: seen
                ? kSuccess.withValues(alpha: 0.12)
                : kWarning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: seen
                    ? kSuccess.withValues(alpha: 0.4)
                    : kWarning.withValues(alpha: 0.4)),
          ),
          child: Text(
            seen ? 'Seen' : 'Unseen',
            style: TextStyle(
                color: seen ? kSuccess : kWarning, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
