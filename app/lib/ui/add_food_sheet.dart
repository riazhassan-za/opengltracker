import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/consumption_entry.dart';
import '../data/food_item.dart';
import '../providers/food_provider.dart';
import '../providers/log_provider.dart';
import 'widgets/gl_badge.dart';

class AddFoodSheet extends ConsumerStatefulWidget {
  const AddFoodSheet({super.key});

  @override
  ConsumerState<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends ConsumerState<AddFoodSheet> {
  final _searchController = TextEditingController();
  final _portionsController = TextEditingController(text: '1');
  FoodItem? _selected;
  String _query = '';
  late MealCategory _category;

  @override
  void initState() {
    super.initState();
    _category = ref.read(lastCategoryProvider);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _portionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _selected == null
            ? _searchView(key: const ValueKey('search'))
            : _portionsView(key: const ValueKey('portions')),
      ),
    );
  }

  Widget _searchView({Key? key}) {
    final foodsAsync = ref.watch(foodProvider);
    final usedNames = ref.watch(usedFoodNamesProvider).valueOrNull ?? {};

    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          height: 4,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search foods...',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        SizedBox(
          height: 320,
          child: foodsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (foods) {
              final filtered = _query.isEmpty
                  ? foods
                  : foods
                      .where((f) => f.name
                          .toLowerCase()
                          .contains(_query.toLowerCase()))
                      .toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('No matches'));
              }

              // Previously used foods first (alphabetically), then rest (alphabetically)
              final used = filtered
                  .where((f) => usedNames.contains(f.name))
                  .toList()
                ..sort((a, b) => a.name.compareTo(b.name));
              final rest = filtered
                  .where((f) => !usedNames.contains(f.name))
                  .toList()
                ..sort((a, b) => a.name.compareTo(b.name));
              final sorted = [...used, ...rest];

              return ListView.builder(
                itemCount: sorted.length,
                itemBuilder: (_, i) {
                  final food = sorted[i];
                  final isUsed = usedNames.contains(food.name);
                  return ListTile(
                    leading: isUsed
                        ? Icon(Icons.history,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary)
                        : const SizedBox(width: 16),
                    title: Text(food.name),
                    subtitle: Text(
                        food.custom
                            ? '${food.calories} kcal · My food'
                            : '${food.calories} kcal',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                    trailing:
                        GlBadge(gl: food.gl, glClass: food.glClass),
                    onTap: () => setState(() => _selected = food),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _portionsView({Key? key}) {
    final food = _selected!;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Padding(
      key: key,
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selected = null),
            ),
            Expanded(
              child: Text(food.name,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ]),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              '1 serving = ${food.serving} · ${food.calories} kcal · GL ${food.gl}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),
          Text('Meal', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: MealCategory.values
                .map((c) => ChoiceChip(
                      label: Text(c.label),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _portionsController,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Number of servings',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _confirm,
              child: const Text('Add to Log'),
            ),
          ),
        ],
      ),
    );
  }

  void _confirm() {
    final portions = double.tryParse(_portionsController.text.trim());
    if (portions == null || portions <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid number of servings')),
      );
      return;
    }
    ref.read(lastCategoryProvider.notifier).state = _category;
    ref.read(logProvider.notifier).addEntry(_selected!, portions, _category);
    Navigator.of(context).pop();
  }
}
