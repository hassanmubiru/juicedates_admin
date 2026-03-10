import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _svc           = AdminService();
  bool _unresolvedOnly = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: AppBar(
        backgroundColor: kDarkBg,
        elevation: 0,
        title: const Text('Reports',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Row(
            children: [
              const Text('Open only', style: TextStyle(color: kMuted, fontSize: 13)),
              Switch(
                value: _unresolvedOnly,
                activeThumbColor: kTangerine,
                onChanged: (v) => setState(() => _unresolvedOnly = v),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<List<AdminReport>>(
        stream: _svc.getReports(unresolvedOnly: _unresolvedOnly),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kTangerine));
          }
          final reports = snap.data ?? [];
          if (reports.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🚩', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text('No reports found',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('All clear!', style: TextStyle(color: kMuted)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: reports.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _ReportCard(
              report: reports[i],
              onResolve: () => _svc.resolveReport(reports[i].id),
              onDismiss: () => _svc.dismissReport(reports[i].id),
              onBanReporter: () async {
                await _svc.banUser(reports[i].reporterUid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reporter banned'),
                      backgroundColor: kDanger,
                    ),
                  );
                }
              },
              onBanReported: () async {
                await _svc.banUser(reports[i].reportedUid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reported user banned'),
                      backgroundColor: kDanger,
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final AdminReport report;
  final VoidCallback onResolve;
  final VoidCallback onDismiss;
  final VoidCallback onBanReporter;
  final VoidCallback onBanReported;
  const _ReportCard(
      {required this.report, required this.onResolve, required this.onDismiss,
       required this.onBanReporter, required this.onBanReported});

  @override
  Widget build(BuildContext context) {
    final ts = report.timestamp != null
        ? DateFormat('MMM d, y — HH:mm').format(report.timestamp!)
        : '—';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kDanger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.flag_rounded, color: kDanger, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.reason,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  _UidRow('Reporter', report.reporterUid),
                  _UidRow('Reported', report.reportedUid),
                  const SizedBox(height: 2),
                  Text(ts, style: const TextStyle(color: kMuted, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (!report.resolved) ...[
              _ActionButton(
                label: 'Resolve',
                color: kSuccess,
                onPressed: onResolve,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                label: 'Dismiss',
                color: kMuted,
                onPressed: onDismiss,
              ),              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: kMuted, size: 20),
                color: kCard,
                onSelected: (v) {
                  if (v == 'ban_reporter') onBanReporter();
                  if (v == 'ban_reported') onBanReported();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'ban_reporter',
                      child: Text('Ban Reporter',
                          style: TextStyle(color: kDanger))),
                  const PopupMenuItem(
                      value: 'ban_reported',
                      child: Text('Ban Reported User',
                          style: TextStyle(color: kDanger))),
                ],
              ),            ] else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kSuccess.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Resolved',
                    style: TextStyle(color: kSuccess, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  const _ActionButton(
      {required this.label, required this.color, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color.withValues(alpha: 0.4))),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}
