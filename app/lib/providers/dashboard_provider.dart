import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/consumption_entry.dart';
import 'log_provider.dart';

enum DashboardPeriod { weekly, monthly }

enum DashboardMetric { totalGl, maxMealGl, sumCalories }

class DashboardPoint {
  final DateTime date;
  final double value;
  const DashboardPoint({required this.date, required this.value});
}

final dashboardPeriodProvider =
    StateProvider<DashboardPeriod>((_) => DashboardPeriod.weekly);

final dashboardMetricProvider =
    StateProvider<DashboardMetric>((_) => DashboardMetric.totalGl);

final dashboardDataProvider =
    FutureProvider<List<DashboardPoint>>((ref) async {
  final period = ref.watch(dashboardPeriodProvider);
  final metric = ref.watch(dashboardMetricProvider);
  final days = period == DashboardPeriod.weekly ? 7 : 30;
  final repo = ref.read(logRepositoryProvider);
  final today =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  final points = <DashboardPoint>[];
  for (int i = days - 1; i >= 0; i--) {
    final date = today.subtract(Duration(days: i));
    final log = await repo.loadLog(date);
    final value = switch (metric) {
      DashboardMetric.totalGl => log.totalGl,
      DashboardMetric.maxMealGl => MealCategory.values
          .map((c) => log.glFor(c))
          .fold(0.0, (a, b) => a > b ? a : b),
      DashboardMetric.sumCalories => log.totalCalories.toDouble(),
    };
    points.add(DashboardPoint(date: date, value: value));
  }
  return points;
});
