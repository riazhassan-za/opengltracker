import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/food_item.dart';
import '../data/food_repository.dart';

final foodRepositoryProvider = Provider((_) => FoodRepository());

final foodSearchQueryProvider = StateProvider<String>((_) => '');
final foodSortProvider = StateProvider<FoodSort>((_) => FoodSort.glAsc);
final foodFilterProvider = StateProvider<GlClass?>((_) => null);

final foodProvider =
    AsyncNotifierProvider<FoodListNotifier, List<FoodItem>>(FoodListNotifier.new);

class FoodListNotifier extends AsyncNotifier<List<FoodItem>> {
  @override
  Future<List<FoodItem>> build() =>
      ref.read(foodRepositoryProvider).loadFoods();

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(ref.read(foodRepositoryProvider).loadFoods);
  }
}

final filteredFoodsProvider = Provider<AsyncValue<List<FoodItem>>>((ref) {
  final foodsAsync = ref.watch(foodProvider);
  final query = ref.watch(foodSearchQueryProvider);
  final sort = ref.watch(foodSortProvider);
  final filter = ref.watch(foodFilterProvider);

  return foodsAsync.whenData((foods) {
    var list = foods.toList();

    if (filter != null) {
      list = list.where((f) => f.glClass == filter).toList();
    }

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((f) => f.name.toLowerCase().contains(q)).toList();
    }

    switch (sort) {
      case FoodSort.glAsc:
        list.sort((a, b) => a.gl.compareTo(b.gl));
      case FoodSort.glDesc:
        list.sort((a, b) => b.gl.compareTo(a.gl));
      case FoodSort.giAsc:
        list.sort((a, b) => a.gi.compareTo(b.gi));
      case FoodSort.giDesc:
        list.sort((a, b) => b.gi.compareTo(a.gi));
      case FoodSort.nameAsc:
        list.sort((a, b) => a.name.compareTo(b.name));
      case FoodSort.nameDesc:
        list.sort((a, b) => b.name.compareTo(a.name));
    }

    return list;
  });
});
