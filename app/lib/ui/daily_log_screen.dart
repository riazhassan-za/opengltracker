import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/consumption_entry.dart';
import '../providers/log_provider.dart';
import 'add_food_sheet.dart';
import 'widgets/gl_badge.dart';
import 'widgets/log_entry_tile.dart';

class DailyLogScreen extends ConsumerWidget {
  const DailyLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(logProvider);

    return logAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (log) => Column(
        children: [
          _LogHeader(log: log),
          Expanded(
            child: ListView(
              children: [
                for (final category in MealCategory.values)
                  _CategorySection(
                    category: category,
                    gl: log.glFor(category),
                    calories: log.caloriesFor(category),
                    entries: log.entriesFor(category),
                    onDelete: (id) =>
                        ref.read(logProvider.notifier).deleteEntry(id),
                    onMove: (id, newCategory) =>
                        ref.read(logProvider.notifier).moveEntry(id, newCategory),
                  ),
              ],
            ),
          ),
          if (log.entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextButton(
                onPressed: () => _confirmClear(context, ref),
                child: const Text('Clear today\'s log'),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear log?'),
        content: const Text('All entries for today will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(logProvider.notifier).clearLog();
              Navigator.of(ctx).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final MealCategory category;
  final double gl;
  final int calories;
  final List<ConsumptionEntry> entries;
  final void Function(String id) onDelete;
  final void Function(String id, MealCategory newCategory) onMove;

  const _CategorySection({
    required this.category,
    required this.gl,
    required this.calories,
    required this.entries,
    required this.onDelete,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final glStr = gl == gl.truncateToDouble()
        ? gl.toInt().toString()
        : gl.toStringAsFixed(1);

    return DragTarget<ConsumptionEntry>(
      onWillAcceptWithDetails: (details) =>
          details.data.category != category,
      onAcceptWithDetails: (details) =>
          onMove(details.data.id, category),
      builder: (context, candidateData, _) {
        final isHighlighted = candidateData.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: isHighlighted
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)
                  : Theme.of(context).colorScheme.surfaceContainerHigh,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Text(category.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isHighlighted
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          )),
                  const Spacer(),
                  Text('$glStr GL · $calories kcal',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            for (final entry in entries)
              _DraggableEntry(
                entry: entry,
                onDelete: () => onDelete(entry.id),
              ),
          ],
        );
      },
    );
  }
}

class _LogHeader extends ConsumerWidget {
  final DailyLog log;
  const _LogHeader({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final isToday = date == today;
    final isFuture = date.isAfter(today);
    final dateSuffix =
        isToday ? ' (today)' : isFuture ? ' (future)' : '';
    final dateLabel =
        '${_weekday(date.weekday)} ${date.day} ${_month(date.month)}$dateSuffix';

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () =>
                    ref.read(selectedDateProvider.notifier).state =
                        date.subtract(const Duration(days: 1)),
              ),
              Expanded(
                child: Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () =>
                    ref.read(selectedDateProvider.notifier).state =
                        date.add(const Duration(days: 1)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
            child: Row(
              children: [
                // On narrow phones a three-digit total doesn't fit beside the
                // badge and Add Food button; shrink it rather than overflow.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total GL: ${log.totalGl.toStringAsFixed(1)}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          '${log.totalCalories} kcal',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GlBadge(gl: log.totalGl, glClass: log.glClass, large: true),
                const Spacer(),
                InkWell(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    useSafeArea: true,
                    builder: (_) => const AddFoodSheet(),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_circle_outline),
                        const SizedBox(height: 2),
                        Text('Add Food',
                            style:
                                Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _weekday(int d) =>
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1];
  String _month(int m) => [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
}

class _DraggableEntry extends StatelessWidget {
  final ConsumptionEntry entry;
  final VoidCallback onDelete;

  const _DraggableEntry({required this.entry, required this.onDelete});

  Widget _feedback(BuildContext context) => Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: const BoxConstraints(maxWidth: 280),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            entry.foodName,
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );

  Widget _ghost() => Opacity(
        opacity: 0.3,
        child: LogEntryTile(entry: entry, onDelete: onDelete),
      );

  @override
  Widget build(BuildContext context) {
    final tile = LogEntryTile(entry: entry, onDelete: onDelete);
    if (kIsWeb) {
      return Draggable<ConsumptionEntry>(
        data: entry,
        feedback: _feedback(context),
        childWhenDragging: _ghost(),
        child: tile,
      );
    }
    return LongPressDraggable<ConsumptionEntry>(
      data: entry,
      feedback: _feedback(context),
      childWhenDragging: _ghost(),
      child: tile,
    );
  }
}
