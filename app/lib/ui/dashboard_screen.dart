import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  final void Function(DateTime) onDateSelected;
  const DashboardScreen({super.key, required this.onDateSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(dashboardPeriodProvider);
    final metric = ref.watch(dashboardMetricProvider);
    final dataAsync = ref.watch(dashboardDataProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PeriodToggle(period: period, ref: ref),
          const SizedBox(height: 12),
          _MetricToggle(metric: metric, ref: ref),
          const SizedBox(height: 24),
          Expanded(
            child: dataAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (points) => _Chart(
                points: points,
                period: period,
                metric: metric,
                onDateSelected: onDateSelected,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  final DashboardPeriod period;
  final WidgetRef ref;
  const _PeriodToggle({required this.period, required this.ref});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<DashboardPeriod>(
      segments: const [
        ButtonSegment(value: DashboardPeriod.weekly, label: Text('Weekly')),
        ButtonSegment(value: DashboardPeriod.monthly, label: Text('Monthly')),
      ],
      selected: {period},
      onSelectionChanged: (v) =>
          ref.read(dashboardPeriodProvider.notifier).state = v.first,
    );
  }
}

class _MetricToggle extends StatelessWidget {
  final DashboardMetric metric;
  final WidgetRef ref;
  const _MetricToggle({required this.metric, required this.ref});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<DashboardMetric>(
      segments: const [
        ButtonSegment(
            value: DashboardMetric.totalGl, label: Text('Daily Sum(GL)')),
        ButtonSegment(
            value: DashboardMetric.maxMealGl, label: Text('Daily Max(GL)')),
        ButtonSegment(
            value: DashboardMetric.sumCalories, label: Text('Sum(calories)')),
      ],
      selected: {metric},
      onSelectionChanged: (v) =>
          ref.read(dashboardMetricProvider.notifier).state = v.first,
    );
  }
}

class _Chart extends StatelessWidget {
  final List<DashboardPoint> points;
  final DashboardPeriod period;
  final DashboardMetric metric;
  final void Function(DateTime) onDateSelected;

  const _Chart({
    required this.points,
    required this.period,
    required this.metric,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final baseline = switch (metric) {
      DashboardMetric.totalGl => 80.0,
      DashboardMetric.maxMealGl => 25.0,
      DashboardMetric.sumCalories => 2000.0,
    };
    final labelStep = period == DashboardPeriod.weekly ? 1 : 5;

    final spots = points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    final baselineSpots = [
      FlSpot(0, baseline),
      FlSpot((points.length - 1).toDouble(), baseline),
    ];

    final maxY = ([
      ...points.map((p) => p.value),
      baseline,
    ].fold(0.0, (a, b) => a > b ? a : b) * 1.2)
        .clamp(baseline * 1.2, double.infinity);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: const Color(0xFF333333),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox();
                if (i % labelStep != 0) return const SizedBox();
                final date = points[i].date;
                final label = period == DashboardPeriod.weekly
                    ? _weekdayShort(date.weekday)
                    : '${date.day}/${date.month}';
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(label,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            if (event is! FlTapUpEvent) return;
            final spot = response?.lineBarSpots?.firstOrNull;
            if (spot == null || spot.barIndex != 0) return;
            final idx = spot.x.toInt();
            if (idx >= 0 && idx < points.length) {
              onDateSelected(points[idx].date);
            }
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              if (s.barIndex != 0) return null;
              return LineTooltipItem(
                s.y.toStringAsFixed(1),
                const TextStyle(color: Colors.white),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          // Data line — yellow
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: Colors.yellow,
            barWidth: 1.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 3,
                color: Colors.yellow,
                strokeWidth: 0,
              ),
            ),
          ),
          // Baseline — dotted
          LineChartBarData(
            spots: baselineSpots,
            isCurved: false,
            color: Colors.white38,
            barWidth: 1,
            dotData: const FlDotData(show: false),
            dashArray: [6, 4],
          ),
        ],
      ),
    );
  }

  static String _weekdayShort(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1) % 7];
  }
}
