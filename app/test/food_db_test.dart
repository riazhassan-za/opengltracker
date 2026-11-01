import 'package:flutter_test/flutter_test.dart';
import 'package:opengltracker/data/food_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled food db loads and parses', () async {
    final foods = await FoodRepository().loadFoods();
    expect(foods.length, greaterThan(5000));
    final names = foods.map((f) => f.name).toSet();
    expect(names, containsAll(['Beef steak', 'Baked Beans', 'Gruyère cheese']));
  });
}
