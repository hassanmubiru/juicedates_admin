import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _svc = AdminService();
  late Future<Map<String, dynamic>> _stats;
  late Future<List<Map<String, dynamic>>> _chart;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _stats = _svc.getAdminStats();
      _chart = _svc.getSignupsByDay(14);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: AppBar(
        backgroundColor: kDarkBg,
        title: const Text('Dashboard',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded, color: kMuted),
              tooltip: 'Refresh',
              onPressed: _refresh),
          const SizedBox(width: 8),
        ],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stat cards row ──────────────────────────────────────
            FutureBuilder<Map<String, dynamic>>(
              future: _stats,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: kTangerine));
                }
                final s = snap.data!;
                return LayoutBuilder(builder: (ctx, box) {
                  final cols = box.maxWidth >= 900
                      ? 3
                      : box.maxWidth >= 600
                          ? 2
                          : 1;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _StatCard('👥 Total Users',
                          '${s['totalUsers']}', kTangerine, box.maxWidth, cols),
                      _StatCard('⭐ Premium',
                          '${s['premiumUsers']}', kWarning, box.maxWidth, cols),
                      _StatCard('💞 Matches',
                          '${s['totalMatches']}', kSuccess, box.maxWidth, cols),
                      _StatCard('🚩 Open Reports',
                          '${s['openReports']}', kDanger, box.maxWidth, cols),
                      _StatCard('📖 Moments',
                          '${s['moments']}', const Color(0xFF7B68EE), box.maxWidth, cols),
                      _StatCard('👋 Winks',
                          '${s['winks']}', const Color(0xFF00BCD4), box.maxWidth, cols),
                    ],
                  );
                });
              },
            ),

            const SizedBox(height: 32),

            // ── Signups chart ────────────────────────────────────────
            Text('New Signups — last 14 days',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _chart,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: kTangerine));
                }
                final data = snap.data!;
                if (data.isEmpty) {
                  return const _EmptyState(label: 'No signup data yet');
                }
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
                    child: SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            getDrawingHorizontalLine: (_) =>
                                const FlLine(color: kBorder, strokeWidth: 1),
                            getDrawingVerticalLine: (_) =>
                                const FlLine(color: kBorder, strokeWidth: 1),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (v, _) => Text(
                                    v.toInt().toString(),
                                    style: const TextStyle(
                                        color: kMuted, fontSize: 10)),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 22,
                                interval: (data.length / 4).ceilToDouble(),
                                getTitlesWidget: (v, _) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= data.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final d = data[i]['date'] as String;
                                  return Text(d.substring(5),
                                      style: const TextStyle(
                                          color: kMuted, fontSize: 10));
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                for (int i = 0; i < data.length; i++)
                                  FlSpot(i.toDouble(),
                                      (data[i]['count'] as int).toDouble()),
                              ],
                              isCurved: true,
                              color: kTangerine,
                              barWidth: 2.5,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                  show: true,
                                  color: kTangerine.withOpacity(0.12)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat card ────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final double parentWidth;
  final int cols;

  const _StatCard(this.label, this.value, this.accent, this.parentWidth,
      this.cols);

  @override
  Widget build(BuildContext context) {
    final w = (parentWidth - (cols - 1) * 16) / cols;
    return SizedBox(
      width: w,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: kMuted, fontSize: 13)),
              const SizedBox(height: 10),
              Text(value,
                  style: TextStyle(
                      color: accent,
                      fontSize: 32,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Center(
          child: Text(label, style: const TextStyle(color: kMuted))),
    );
  }
}
