import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart' show FlutterNativeSplash;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui/app.dart';

Future<void> _seedDebugData() async {
  if (!kDebugMode) return;
  final prefs = await SharedPreferences.getInstance();
  final today = DateTime.now();

  final keys = prefs.getKeys().where((k) => k.startsWith('log_')).toList();
  for (final k in keys) {
    await prefs.remove(k);
  }

  // Each day: list of {foodName, foodGl, foodCalories, foodServing, portions, category}
  final days = [
    // 6 days ago
    [
      {'foodName': 'Oats', 'foodGl': 13.0, 'foodCalories': 150, 'foodServing': '40g', 'portions': 1.0, 'category': 'breakfast'},
      {'foodName': 'Banana', 'foodGl': 12.0, 'foodCalories': 90, 'foodServing': '1 medium', 'portions': 1.0, 'category': 'breakfast'},
      {'foodName': 'Chicken Rice', 'foodGl': 35.0, 'foodCalories': 520, 'foodServing': '1 plate', 'portions': 1.0, 'category': 'lunch'},
      {'foodName': 'Apple', 'foodGl': 6.0, 'foodCalories': 80, 'foodServing': '1 medium', 'portions': 1.0, 'category': 'snacks'},
    ],
    // 5 days ago
    [
      {'foodName': 'White Toast', 'foodGl': 20.0, 'foodCalories': 200, 'foodServing': '2 slices', 'portions': 1.0, 'category': 'breakfast'},
      {'foodName': 'Pasta', 'foodGl': 42.0, 'foodCalories': 650, 'foodServing': '1 bowl', 'portions': 1.0, 'category': 'lunch'},
      {'foodName': 'Soft Drink', 'foodGl': 16.0, 'foodCalories': 140, 'foodServing': '330ml', 'portions': 1.0, 'category': 'lunch'},
      {'foodName': 'Grilled Salmon', 'foodGl': 0.0, 'foodCalories': 400, 'foodServing': '150g', 'portions': 1.0, 'category': 'dinner'},
      {'foodName': 'Chocolate Bar', 'foodGl': 18.0, 'foodCalories': 230, 'foodServing': '50g', 'portions': 1.0, 'category': 'snacks'},
    ],
    // 4 days ago
    [
      {'foodName': 'Eggs', 'foodGl': 0.0, 'foodCalories': 140, 'foodServing': '2 eggs', 'portions': 1.0, 'category': 'breakfast'},
      {'foodName': 'Whole Wheat Bread', 'foodGl': 9.0, 'foodCalories': 140, 'foodServing': '2 slices', 'portions': 1.0, 'category': 'breakfast'},
      {'foodName': 'Caesar Salad', 'foodGl': 5.0, 'foodCalories': 320, 'foodServing': '1 bowl', 'portions': 1.0, 'category': 'lunch'},
      {'foodName': 'Pizza', 'foodGl': 60.0, 'foodCalories': 800, 'foodServing': '2 slices', 'portions': 1.0, 'category': 'dinner'},
    ],
    // 3 days ago
    [
      {'foodName': 'Yogurt', 'foodGl': 10.0, 'foodCalories': 120, 'foodServing': '200g', 'portions': 1.0, 'category': 'breakfast'},
      {'foodName': 'Sandwich', 'foodGl': 25.0, 'foodCalories': 450, 'foodServing': '1 sandwich', 'portions': 1.0, 'category': 'lunch'},
      {'foodName': 'Steak', 'foodGl': 0.0, 'foodCalories': 500, 'foodServing': '200g', 'portions': 1.0, 'category': 'dinner'},
      {'foodName': 'Mashed Potato', 'foodGl': 45.0, 'foodCalories': 250, 'foodServing': '1 cup', 'portions': 1.0, 'category': 'dinner'},
      {'foodName': 'Nuts', 'foodGl': 2.0, 'foodCalories': 180, 'foodServing': '30g', 'portions': 1.0, 'category': 'snacks'},
    ],
    // 2 days ago
    [
      {'foodName': 'Cornflakes', 'foodGl': 32.0, 'foodCalories': 200, 'foodServing': '40g', 'portions': 1.5, 'category': 'breakfast'},
      {'foodName': 'Orange Juice', 'foodGl': 15.0, 'foodCalories': 110, 'foodServing': '250ml', 'portions': 1.0, 'category': 'breakfast'},
      {'foodName': 'Burger', 'foodGl': 28.0, 'foodCalories': 700, 'foodServing': '1 burger', 'portions': 1.0, 'category': 'lunch'},
      {'foodName': 'French Fries', 'foodGl': 38.0, 'foodCalories': 400, 'foodServing': 'medium', 'portions': 1.0, 'category': 'lunch'},
      {'foodName': 'Ice Cream', 'foodGl': 12.0, 'foodCalories': 270, 'foodServing': '2 scoops', 'portions': 1.0, 'category': 'snacks'},
    ],
    // yesterday
    [
      {'foodName': 'Muesli', 'foodGl': 18.0, 'foodCalories': 320, 'foodServing': '60g', 'portions': 1.0, 'category': 'breakfast'},
      {'foodName': 'Sushi', 'foodGl': 48.0, 'foodCalories': 550, 'foodServing': '8 pieces', 'portions': 1.0, 'category': 'lunch'},
      {'foodName': 'Chicken Curry', 'foodGl': 22.0, 'foodCalories': 620, 'foodServing': '1 plate', 'portions': 1.0, 'category': 'dinner'},
      {'foodName': 'Basmati Rice', 'foodGl': 35.0, 'foodCalories': 280, 'foodServing': '1 cup', 'portions': 1.0, 'category': 'dinner'},
      {'foodName': 'Protein Bar', 'foodGl': 10.0, 'foodCalories': 200, 'foodServing': '1 bar', 'portions': 1.0, 'category': 'snacks'},
    ],
    // today
    [
      {'foodName': 'Boiled Eggs', 'foodGl': 0.0, 'foodCalories': 140, 'foodServing': '2 eggs', 'portions': 1.0, 'category': 'breakfast'},
      {'foodName': 'Avocado Toast', 'foodGl': 8.0, 'foodCalories': 280, 'foodServing': '1 slice', 'portions': 1.0, 'category': 'breakfast'},
      {'foodName': 'Tuna Wrap', 'foodGl': 20.0, 'foodCalories': 480, 'foodServing': '1 wrap', 'portions': 1.0, 'category': 'lunch'},
      {'foodName': 'Diet Coke', 'foodGl': 0.0, 'foodCalories': 2, 'foodServing': '330ml', 'portions': 1.0, 'category': 'lunch'},
      {'foodName': 'Almonds', 'foodGl': 1.0, 'foodCalories': 160, 'foodServing': '30g', 'portions': 1.0, 'category': 'snacks'},
    ],
  ];

  for (int i = 0; i < 7; i++) {
    final date = DateTime(today.year, today.month, today.day - (6 - i));
    final key =
        'log_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final entries = days[i].asMap().entries.map((e) {
      final data = Map<String, dynamic>.from(e.value);
      data['id'] = 'seed-$i-${e.key}';
      return data;
    }).toList();
    await prefs.setString(key, jsonEncode(entries));
  }
}

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) FlutterNativeSplash.preserve(widgetsBinding: binding);
  await _seedDebugData();
  if (!kIsWeb) FlutterNativeSplash.remove();
  runApp(const ProviderScope(child: OpenGlTrackerApp()));
}
