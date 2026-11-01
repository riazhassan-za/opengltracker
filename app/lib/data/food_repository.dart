import 'package:flutter/services.dart';
import 'constants.dart';
import 'csv_parser.dart';
import 'food_item.dart';

class FoodRepository {
  Future<List<FoodItem>> loadFoods() async {
    final raw = await rootBundle.loadString(kFoodsCsvAsset);
    return parseFoodsCsv(raw);
  }
}
