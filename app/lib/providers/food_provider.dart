import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/food_item.dart';
import '../data/food_repository.dart';
import '../data/user_food_repository.dart';

final foodRepositoryProvider = Provider((_) => FoodRepository());
final userFoodRepositoryProvider = Provider((_) => UserFoodRepository());

final foodSearchQueryProvider = StateProvider<String>((_) => '');
final foodSortProvider = StateProvider<FoodSort>((_) => FoodSort.glAsc);
final foodFilterProvider = StateProvider<GlClass?>((_) => null);

// Parsed once; adding a food of your own doesn't re-parse the bundled CSV.
final _bundledFoodsProvider = FutureProvider<List<FoodItem>>(
    (ref) => ref.read(foodRepositoryProvider).loadFoods());

final userFoodsProvider =
    AsyncNotifierProvider<UserFoodsNotifier, List<FoodItem>>(
        UserFoodsNotifier.new);

class UserFoodsNotifier extends AsyncNotifier<List<FoodItem>> {
  @override
  Future<List<FoodItem>> build() => ref.read(userFoodRepositoryProvider).load();

  /// Adds [food], or replaces [replacing] with it when editing.
  Future<void> save(FoodItem food, {FoodItem? replacing}) async {
    final current = await future;
    await _store([...current.where((f) => f != replacing), food]);
  }

  Future<void> delete(FoodItem food) async {
    final current = await future;
    await _store(current.where((f) => f != food).toList());
  }

  Future<void> _store(List<FoodItem> foods) async {
    state = AsyncData(foods);
    await ref.read(userFoodRepositoryProvider).save(foods);
  }
}

/// The bundled database plus the user's own foods.
final foodProvider =
    AsyncNotifierProvider<FoodListNotifier, List<FoodItem>>(FoodListNotifier.new);

class FoodListNotifier extends AsyncNotifier<List<FoodItem>> {
  @override
  Future<List<FoodItem>> build() async {
    final bundled = await ref.watch(_bundledFoodsProvider.future);
    final mine = await ref.watch(userFoodsProvider.future);
    return [...mine, ...bundled];
  }

  Future<void> reload() async {
    ref.invalidate(_bundledFoodsProvider);
    ref.invalidate(userFoodsProvider);
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
