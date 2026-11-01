import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/food_item.dart';
import '../providers/food_provider.dart';
import 'food_detail_panel.dart';
import 'widgets/food_list_tile.dart';

final _selectedFoodProvider = StateProvider<FoodItem?>((_) => null);

class FoodListScreen extends ConsumerWidget {
  const FoodListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 600;
      if (isWide) {
        return Row(children: [
          SizedBox(width: 360, child: _FoodList(isWide: true)),
          const VerticalDivider(width: 1),
          Expanded(child: _WideDetailPanel()),
        ]);
      }
      return _FoodList(isWide: false);
    });
  }
}

class _WideDetailPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final food = ref.watch(_selectedFoodProvider);
    if (food == null) {
      return const Center(child: Text('Select a food to see details'));
    }
    return SingleChildScrollView(child: FoodDetailPanel(food: food));
  }
}

class _FoodList extends ConsumerStatefulWidget {
  final bool isWide;
  const _FoodList({required this.isWide});

  @override
  ConsumerState<_FoodList> createState() => _FoodListState();
}

class _FoodListState extends ConsumerState<_FoodList> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foodsAsync = ref.watch(filteredFoodsProvider);

    return Column(
      children: [
        _SearchAndControls(searchController: _searchController),
        Expanded(
          child: foodsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorView(error: e.toString()),
            data: (foods) => foods.isEmpty
                  ? const Center(child: Text('No foods match your search.'))
                  : ListView.builder(
                      itemCount: foods.length,
                      itemBuilder: (context, i) {
                        final food = foods[i];
                        final selected =
                            ref.watch(_selectedFoodProvider) == food;
                        return FoodListTile(
                          food: food,
                          number: i + 1,
                          selected: selected && widget.isWide,
                          onTap: () {
                            ref
                                .read(_selectedFoodProvider.notifier)
                                .state = food;
                            if (!widget.isWide) {
                              showModalBottomSheet(
                                context: context,
                                showDragHandle: true,
                                useSafeArea: true,
                                builder: (_) => FoodDetailPanel(food: food),
                              );
                            }
                          },
                        );
                      },
                    ),
          ),
        ),
      ],
    );
  }
}

class _SearchAndControls extends ConsumerWidget {
  final TextEditingController searchController;
  const _SearchAndControls({required this.searchController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(foodSortProvider);
    final filter = ref.watch(foodFilterProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search foods...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        ref
                            .read(foodSearchQueryProvider.notifier)
                            .state = '';
                      },
                    )
                  : null,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) =>
                ref.read(foodSearchQueryProvider.notifier).state = v,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Sort:', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                DropdownButton<FoodSort>(
                  value: sort,
                  isDense: true,
                  onChanged: (v) =>
                      ref.read(foodSortProvider.notifier).state = v!,
                  items: const [
                    DropdownMenuItem(
                        value: FoodSort.glAsc, child: Text('GL ↑')),
                    DropdownMenuItem(
                        value: FoodSort.glDesc, child: Text('GL ↓')),
                    DropdownMenuItem(
                        value: FoodSort.giAsc, child: Text('GI ↑')),
                    DropdownMenuItem(
                        value: FoodSort.giDesc, child: Text('GI ↓')),
                    DropdownMenuItem(
                        value: FoodSort.nameAsc, child: Text('A–Z')),
                    DropdownMenuItem(
                        value: FoodSort.nameDesc, child: Text('Z–A')),
                  ],
                ),
              ]),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Filter:', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                DropdownButton<GlClass?>(
                  value: filter,
                  isDense: true,
                  onChanged: (v) =>
                      ref.read(foodFilterProvider.notifier).state = v,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(
                        value: GlClass.low, child: Text('Low GL')),
                    DropdownMenuItem(
                        value: GlClass.medium, child: Text('Med GL')),
                    DropdownMenuItem(
                        value: GlClass.high, child: Text('High GL')),
                  ],
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends ConsumerWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 8),
          Text('Failed to load foods'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => ref.read(foodProvider.notifier).reload(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
