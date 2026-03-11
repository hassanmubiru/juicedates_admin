import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _svc = AdminService();
  int _rangeDays = 14;
  late Future<_AnalyticsData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _dataFuture = Future.wait([
        _svc.getAdminStats(),
        _svc.getSignupsByDay(_rangeDays),
        _svc.getMatchesByDay(_rangeDays),
        _svc.getSubscriptionBreakdown(),
      ]).then((r) => _AnalyticsData(
            stats: r[0] as Map<String, dynamic>,
            signups: r[1] as List<Map<String, dynamic>>,
            matches: r[2] as List<Map<String, dynamic>>,
            subBreakdown: r[3] as Map<String, int>,
          ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: AppBar(
        backgroundColor: kDarkBg,
        elevation: 0,
        title: const Text('Analytics',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          // Range selector
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 7, label: Text('7d')),
              ButtonSegment(value: 14, label: Text('14d')),
              ButtonSegment(value: 30, label: Text('30d')),
            ],
            selected: {_rangeDays},
            onSelectionChanged: (s) {
              _rangeDays = s.first;
              _load();
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: kSidebar,
              foregroundColor: kMuted,
              selectedBackgroundColor: kTangerine,
              selectedForegroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kMuted),
            onPressed: _load,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<_AnalyticsData>(
        future: _dataFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kTangerine));
          }
          if (snap.hasError) {
            return Center(
                child: Text('Error: ${snap.error}',
                    style: const TextStyle(color: kDanger)));
          }
          final d = snap.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI cards
                LayoutBuilder(builder: (_, box) {
                  final cols = box.maxWidth >= 1000
                      ? 4
                      : box.maxWidth >= 600
                          ? 2
                          : 1;
                  final total = d.stats['totalUsers'] as int? ?? 0;
                  final premium = d.stats['premiumUsers'] as int? ?? 0;
                  final tmatch = d.stats['totalMatches'] as int? ?? 0;
                  final matchRate = total > 0
                      ? (tmatch / total * 100).toStringAsFixed(1)
                      : '0.0';
                  final convRate = tmatch > 0
                      ? ((d.stats['moments'] as int? ?? 0) /
                              tmatch *
                              100)
                          .toStringAsFixed(1)
                      : '0.0';
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _KpiCard('Total Users', '$total', kTangerine,
                          Icons.people_rounded, box.maxWidth, cols),
                      _KpiCard('Premium Users', '$premium', kWarning,
                          Icons.star_rounded, box.maxWidth, cols),
                      _KpiCard('Match Rate', '$matchRate%', kSuccess,
                          Icons.favorite_rounded, box.maxWidth, cols),
                      _KpiCard('Conversion Rate', '$convRate%',
                          const Color(0xFF7B68EE),
                          Icons.trending_up_rounded, box.maxWidth, cols),
                    ],
                  );
                }),

                const SizedBox(height: 32),

                // Signups chart
                _ChartSection(
                  title: 'New Signups — last $_rangeDays days',
                  data: d.signups,
                  color: kTangerine,
                ),

                const SizedBox(height: 32),

                // Matches chart
                _ChartSection(
                  title: 'New Matches — last $_rangeDays days',
                  data: d.matches,
                  color: kSuccess,
                ),

                const SizedBox(height: 32),

                // Subscription breakdown
                const Text('Subscription Breakdown',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                const SizedBox(height: 16),
                LayoutBuilder(builder: (_, box) {
                  final wide = box.maxWidth >= 600;
                  final plus = d.subBreakdown['plus'] ?? 0;
                  final gold = d.subBreakdown['gold'] ?? 0;
                  final platinum = d.subBreakdown['platinum'] ?? 0;
                  final total = plus + gold + platinum;
                  return wide
                      ? Row(
                          children: [
                            Expanded(
                              child: _SubBreakdownChart(
                                  plus: plus,
                                  gold: gold,
                                  platinum: platinum),
                            ),
                            const SizedBox(width: 32),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _SubLegend('Plus', plus, total,
                                    const Color(0xFF4FC3F7)),
                                const SizedBox(height: 12),
                                _SubLegend('Gold', gold, total,
                                    kWarning),
                                const SizedBox(height: 12),
                                _SubLegend('Platinum', platinum, total,
                                    const Color(0xFFCE93D8)),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _SubBreakdownChart(
                                plus: plus,
                                gold: gold,
                                platinum: platinum),
                            const SizedBox(height: 16),
                            _SubLegend('Plus', plus, total,
                                const Color(0xFF4FC3F7)),
                            _SubLegend('Gold', gold, total, kWarning),
                            _SubLegend('Platinum', platinum, total,
                                const Color(0xFFCE93D8)),
                          ],
                        );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AnalyticsData {
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> signups;
  final List<Map<String, dynamic>> matches;
  final Map<String, int> subBreakdown;
  const _AnalyticsData({
    required this.stats,
    required this.signups,
    required this.matches,
    required this.subBreakdown,
  });
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final IconData icon;
  final double parentWidth;
  final int cols;
  const _KpiCard(this.label, this.value, this.accent, this.icon,
      this.parentWidth, this.cols);
  @override
  Widget build(BuildContext context) {
    final w = (parentWidth - (cols - 1) * 16) / cols;
    return SizedBox(
      width: w,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style:
                            const TextStyle(color: kMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(value,
                        style: TextStyle(
                            color: accent,
                            fontSize: 26,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;
  final Color color;
  const _ChartSection(
      {required this.title, required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        const SizedBox(height: 16),
        if (data.isEmpty)
          Card(
            child: SizedBox(
              height: 80,
              child: Center(
                  child: Text('No data for this range.',
                      style: const TextStyle(color: kMuted))),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
              child: SizedBox(
                height: 200,
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
                          interval: (data.length / 4).ceilToDouble().clamp(1.0, double.infinity),
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
                    minY: 0,
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (int i = 0; i < data.length; i++)
                            FlSpot(i.toDouble(),
                                (data[i]['count'] as int).toDouble()),
                        ],
                        isCurved: data.length > 2,
                        color: color,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                            show: true,
                            color: color.withValues(alpha: 0.12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SubBreakdownChart extends StatelessWidget {
  final int plus;
  final int gold;
  final int platinum;
  const _SubBreakdownChart(
      {required this.plus, required this.gold, required this.platinum});
  @override
  Widget build(BuildContext context) {
    final total = plus + gold + platinum;
    if (total == 0) {
      return const SizedBox(
        height: 180,
        child: Center(
            child: Text('No subscribers yet.',
                style: TextStyle(color: kMuted))),
      );
    }
    return SizedBox(
      height: 180,
      child: PieChart(
        PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 50,
          sections: [
            PieChartSectionData(
                value: plus.toDouble(),
                color: const Color(0xFF4FC3F7),
                title: plus > 0 ? '$plus' : '',
                radius: 60,
                titleStyle:
                    const TextStyle(color: Colors.white, fontSize: 12)),
            PieChartSectionData(
                value: gold.toDouble(),
                color: kWarning,
                title: gold > 0 ? '$gold' : '',
                radius: 60,
                titleStyle:
                    const TextStyle(color: Colors.white, fontSize: 12)),
            PieChartSectionData(
                value: platinum.toDouble(),
                color: const Color(0xFFCE93D8),
                title: platinum > 0 ? '$platinum' : '',
                radius: 60,
                titleStyle:
                    const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _SubLegend extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _SubLegend(this.label, this.count, this.total, this.color);
  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';
    return Row(
      children: [
        Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text('$label: $count ($pct%)',
            style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }
}
