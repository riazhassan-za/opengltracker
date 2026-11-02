import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'food_item.dart';

/// Foods the user added themselves, stored on the device next to their log.
class UserFoodRepository {
  static const _key = 'user_foods';

  Future<List<FoodItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<FoodItem> foods) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(foods.map((f) => f.toJson()).toList()));
  }
}
