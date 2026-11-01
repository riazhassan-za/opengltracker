import 'dart:convert';
import 'food_item.dart';

enum MealCategory { breakfast, lunch, dinner, snacks }

extension MealCategoryLabel on MealCategory {
  String get label => switch (this) {
        MealCategory.breakfast => 'Breakfast',
        MealCategory.lunch => 'Lunch',
        MealCategory.dinner => 'Dinner',
        MealCategory.snacks => 'Snacks',
      };
}

class ConsumptionEntry {
  final String id;
  final String foodName;
  final double foodGl;
  final int foodCalories;
  final String foodServing;
  final double portions;
  final MealCategory category;

  const ConsumptionEntry({
    required this.id,
    required this.foodName,
    required this.foodGl,
    required this.foodCalories,
    required this.foodServing,
    required this.portions,
    required this.category,
  });

  double get glContribution => foodGl * portions;
  int get calorieContribution => (foodCalories * portions).round();

  ConsumptionEntry copyWith({MealCategory? category}) => ConsumptionEntry(
        id: id,
        foodName: foodName,
        foodGl: foodGl,
        foodCalories: foodCalories,
        foodServing: foodServing,
        portions: portions,
        category: category ?? this.category,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'foodName': foodName,
        'foodGl': foodGl,
        'foodCalories': foodCalories,
        'foodServing': foodServing,
        'portions': portions,
        'category': category.name,
      };

  factory ConsumptionEntry.fromJson(Map<String, dynamic> json) =>
      ConsumptionEntry(
        id: json['id'] as String,
        foodName: json['foodName'] as String,
        foodGl: (json['foodGl'] as num).toDouble(),
        foodCalories: (json['foodCalories'] as num?)?.toInt() ?? 0,
        foodServing: json['foodServing'] as String,
        portions: (json['portions'] as num).toDouble(),
        category: MealCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => MealCategory.snacks,
        ),
      );
}

class DailyLog {
  final DateTime date;
  final List<ConsumptionEntry> entries;

  const DailyLog({required this.date, required this.entries});

  double get totalGl =>
      entries.fold(0.0, (sum, e) => sum + e.glContribution);

  int get totalCalories =>
      entries.fold(0, (sum, e) => sum + e.calorieContribution);

  List<ConsumptionEntry> entriesFor(MealCategory category) =>
      entries.where((e) => e.category == category).toList();

  double glFor(MealCategory category) =>
      entriesFor(category).fold(0.0, (sum, e) => sum + e.glContribution);

  int caloriesFor(MealCategory category) =>
      entriesFor(category).fold(0, (sum, e) => sum + e.calorieContribution);

  GlClass get glClass {
    if (totalGl <= 80) return GlClass.low;
    if (totalGl <= 120) return GlClass.medium;
    return GlClass.high;
  }

  String get classification => switch (glClass) {
        GlClass.low => 'Low',
        GlClass.medium => 'Medium',
        GlClass.high => 'High',
      };

  String toJsonString() => jsonEncode(entries.map((e) => e.toJson()).toList());

  factory DailyLog.fromJsonString(DateTime date, String raw) {
    final list = (jsonDecode(raw) as List)
        .map((e) => ConsumptionEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return DailyLog(date: date, entries: list);
  }
}
