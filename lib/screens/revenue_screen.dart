import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../theme.dart';

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({super.key});

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  final _svc = AdminService();
  bool _loading = true;
  String? _error;

  Map<String, double> _prices = {'plus': 9.99, 'gold': 19.99, 'platinum': 29.99};

  Map<String, int> _tierBreakdown = {};
  List<Map<String, dynamic>> _subscriptionsByDay = [];
  int _totalUsers = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _svc.getSubscriptionBreakdown(),
        _svc.getSubscriptionsByDay(30),
        _svc.getUserCount(),
        _svc.getAppConfig(),
      ]);
      setState(() {
        _tierBreakdown = results[0] as Map<String, int>;
        _subscriptionsByDay = results[1] as List<Map<String, dynamic>>;
        _totalUsers = results[2] as int;
        final cfg = results[3] as AppConfig;
        _prices = {
          'plus': cfg.plusMonthlyUsd,
          'gold': cfg.goldMonthlyUsd,
          'platinum': cfg.platinumMonthlyUsd,
        };
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  int get _totalSubs =>
      (_tierBreakdown['plus'] ?? 0) +
      (_tierBreakdown['gold'] ?? 0) +
      (_tierBreakdown['platinum'] ?? 0);

  double get _mrr {
    double total = 0;
    for (final tier in _prices.keys) {
      total += (_tierBreakdown[tier] ?? 0) * _prices[tier]!;
    }
    return total;
  }

  double get _arpu => _totalSubs == 0 ? 0 : _mrr / _totalSubs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: AppBar(
        backgroundColor: kSidebar,
        title: const Text('Revenue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 48, color: kDanger),
                      const SizedBox(height: 12),
                      Text('Failed to load revenue data',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(_error!,
                            style: const TextStyle(
                                color: kMuted, fontSize: 12),
                            textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── KPI cards ───────────────────────────────────────────
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _KpiCard(
                          label: 'MRR',
                          value: '\$${_mrr.toStringAsFixed(2)}',
                          sub: 'Monthly Recurring',
                          color: kSuccess),
                      _KpiCard(
                          label: 'ARR',
                          value: '\$${(_mrr * 12).toStringAsFixed(2)}',
                          sub: 'Annual Run Rate',
                          color: kTangerine),
                      _KpiCard(
                          label: 'Subscribers',
                          value: '$_totalSubs',
                          sub: 'Active premium',
                          color: Colors.blue),
                      _KpiCard(
                          label: 'ARPU',
                          value: '\$${_arpu.toStringAsFixed(2)}',
                          sub: 'Per subscriber / mo',
                          color: kWarning),
                      _KpiCard(
                          label: 'Conversion',
                          value: _totalUsers == 0
                              ? '—'
                              : '${(_totalSubs / _totalUsers * 100).toStringAsFixed(1)}%',
                          sub: 'Users → premium',
                          color: Colors.purple),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Revenue by tier table ────────────────────────────────
                  const Text('Revenue by Tier',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _TierTable(
                      tierBreakdown: _tierBreakdown, prices: _prices),

                  const SizedBox(height: 28),

                  // ── New subscriptions chart ──────────────────────────────
                  Row(children: [
                    const Text('New Subscriptions',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text('last 30 days',
                        style: const TextStyle(
                            fontSize: 13, color: kMuted)),
                  ]),
                  const SizedBox(height: 10),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                    ),
                    child: _SubsChart(data: _subscriptionsByDay),
                  ),

                  const SizedBox(height: 28),

                  // ── Revenue breakdown bar ────────────────────────────────
                  const Text('Revenue Split',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _RevenueSplitBar(
                      tierBreakdown: _tierBreakdown, prices: _prices),
                ],
              ),
            ),
    );
  }
}

// ── KPI card ──────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _KpiCard(
      {required this.label,
      required this.value,
      required this.sub,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: kMuted, fontSize: 12)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(sub,
                style: const TextStyle(color: kMuted, fontSize: 11)),
          ],
        ),
      );
}

// ── Tier table ────────────────────────────────────────────────────────────
class _TierTable extends StatelessWidget {
  final Map<String, int> tierBreakdown;
  final Map<String, double> prices;

  const _TierTable(
      {required this.tierBreakdown, required this.prices});

  static const _colors = <String, Color>{
    'plus': Colors.blue,
    'gold': kWarning,
    'platinum': Colors.purple,
  };

  @override
  Widget build(BuildContext context) {
    const tiers = ['plus', 'gold', 'platinum'];
    final totalMrr = tiers.fold<double>(
        0.0, (s, t) => s + (tierBreakdown[t] ?? 0) * (prices[t] ?? 0));

    return Container(
      decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorder)),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(1.5),
          3: FlexColumnWidth(2),
          4: FlexColumnWidth(1.5),
        },
        children: [
          TableRow(
            decoration:
                const BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
            children: ['Tier', 'Subscribers', 'Unit Price', 'Monthly Revenue', 'Share']
                .map((h) => _Cell(h,
                    style: const TextStyle(
                        color: kMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)))
                .toList(),
          ),
          ...tiers.map((tier) {
            final count = tierBreakdown[tier] ?? 0;
            final price = prices[tier] ?? 0;
            final mrr = count * price;
            final share = totalMrr == 0
                ? 0.0
                : mrr / totalMrr * 100;
            return TableRow(children: [
              _Cell(
                Row(children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: _colors[tier] ?? kMuted,
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${tier[0].toUpperCase()}${tier.substring(1)}',
                    style:
                        const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ]),
              ),
              _Cell('$count'),
              _Cell('\$${price.toStringAsFixed(2)}'),
              _Cell('\$${mrr.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: kSuccess, fontWeight: FontWeight.w600)),
              _Cell('${share.toStringAsFixed(1)}%',
                  style: const TextStyle(color: kMuted)),
            ]);
          }),
          TableRow(
            decoration:
                const BoxDecoration(border: Border(top: BorderSide(color: kBorder))),
            children: [
              _Cell('Total',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              _Cell(
                  '${tiers.fold(0, (s, t) => s + (tierBreakdown[t] ?? 0))}',
                  style:
                      const TextStyle(fontWeight: FontWeight.bold)),
              _Cell(''),
              _Cell('\$${totalMrr.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: kSuccess,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              _Cell('100%',
                  style: const TextStyle(color: kMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final dynamic content;
  final TextStyle? style;

  const _Cell(this.content, {this.style});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: content is Widget
          ? content as Widget
          : Text(content as String, style: style),
    );
  }
}

// ── Subscriptions chart ───────────────────────────────────────────────────
class _SubsChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _SubsChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No subscription data for this period',
            style: TextStyle(color: kMuted)),
      );
    }

    final spots = data
        .asMap()
        .entries
        .map((e) =>
            FlSpot(e.key.toDouble(), (e.value['count'] as int).toDouble()))
        .toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: kBorder, strokeWidth: 1),
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(color: kMuted, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (data.length / 5).ceilToDouble().clamp(1, double.infinity),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox();
                final parts = (data[i]['date'] as String).split('-');
                return Text('${parts[1]}/${parts[2]}',
                    style:
                        const TextStyle(color: kMuted, fontSize: 9));
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
            spots: spots,
            isCurved: spots.length > 2,
            color: kTangerine,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: kTangerine.withAlpha(40),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Revenue split bar ─────────────────────────────────────────────────────
class _RevenueSplitBar extends StatelessWidget {
  final Map<String, int> tierBreakdown;
  final Map<String, double> prices;

  const _RevenueSplitBar(
      {required this.tierBreakdown, required this.prices});

  static const _colors = <String, Color>{
    'plus': Colors.blue,
    'gold': kWarning,
    'platinum': Colors.purple,
  };

  @override
  Widget build(BuildContext context) {
    const tiers = ['plus', 'gold', 'platinum'];
    final revenues = {
      for (final t in tiers) t: (tierBreakdown[t] ?? 0) * (prices[t] ?? 0),
    };
    final total = revenues.values.fold(0.0, (a, b) => a + b);

    if (total == 0) {
      return const Text('No revenue data',
          style: TextStyle(color: kMuted));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          // stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: tiers.map((t) {
                final frac = revenues[t]! / total;
                return Expanded(
                  flex: (frac * 1000).round(),
                  child: Container(
                    height: 24,
                    color: _colors[t] ?? kMuted,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: tiers.map((t) {
              final rev = revenues[t]!;
              final pct = rev / total * 100;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: _colors[t] ?? kMuted,
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${t[0].toUpperCase()}${t.substring(1)}  '
                    '\$${rev.toStringAsFixed(0)}  '
                    '(${pct.toStringAsFixed(1)}%)',
                    style:
                        const TextStyle(color: kMuted, fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
