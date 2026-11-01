import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/consumption_entry.dart';
import '../data/food_item.dart';
import '../data/log_repository.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

final selectedDateProvider =
    StateProvider<DateTime>((_) => _dateOnly(DateTime.now()));

final lastCategoryProvider =
    StateProvider<MealCategory>((_) => MealCategory.breakfast);

final usedFoodNamesProvider =
    AsyncNotifierProvider<UsedFoodNamesNotifier, Set<String>>(
        UsedFoodNamesNotifier.new);

class UsedFoodNamesNotifier extends AsyncNotifier<Set<String>> {
  static const _key = 'used_food_names';

  @override
  Future<Set<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).toSet();
  }

  Future<void> add(String foodName) async {
    final current = await future;
    if (current.contains(foodName)) return;
    final updated = {...current, foodName};
    state = AsyncData(updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated.toList());
  }
}

final logRepositoryProvider = Provider((_) => LogRepository());

final logProvider =
    AsyncNotifierProvider<DailyLogNotifier, DailyLog>(DailyLogNotifier.new);

class DailyLogNotifier extends AsyncNotifier<DailyLog> {
  @override
  Future<DailyLog> build() async {
    final date = ref.watch(selectedDateProvider);
    return ref.read(logRepositoryProvider).loadLog(date);
  }

  Future<void> addEntry(FoodItem food, double portions, MealCategory category) async {
    final date = ref.read(selectedDateProvider);
    final entry = ConsumptionEntry(
      id: const Uuid().v4(),
      foodName: food.name,
      foodGl: food.gl,
      foodCalories: food.calories,
      foodServing: food.serving,
      portions: portions,
      category: category,
    );
    final repo = ref.read(logRepositoryProvider);
    await repo.saveEntry(date, entry);
    await ref.read(usedFoodNamesProvider.notifier).add(food.name);
    state = AsyncData(await repo.loadLog(date));
  }

  Future<void> deleteEntry(String id) async {
    final date = ref.read(selectedDateProvider);
    final repo = ref.read(logRepositoryProvider);
    await repo.deleteEntry(date, id);
    state = AsyncData(await repo.loadLog(date));
  }

  Future<void> moveEntry(String id, MealCategory newCategory) async {
    final date = ref.read(selectedDateProvider);
    final repo = ref.read(logRepositoryProvider);
    await repo.updateEntryCategory(date, id, newCategory);
    state = AsyncData(await repo.loadLog(date));
  }

  Future<void> clearLog() async {
    final date = ref.read(selectedDateProvider);
    final repo = ref.read(logRepositoryProvider);
    await repo.clearLog(date);
    state = AsyncData(DailyLog(date: date, entries: []));
  }
}
