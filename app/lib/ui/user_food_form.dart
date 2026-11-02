import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/food_item.dart';
import '../providers/food_provider.dart';
import 'widgets/gl_badge.dart';

/// Opens the form to add a food of your own, or to edit [editing]. Returns
/// the saved food, or null if the form was dismissed.
Future<FoodItem?> showUserFoodForm(BuildContext context, {FoodItem? editing}) =>
    showModalBottomSheet<FoodItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => UserFoodForm(editing: editing),
    );

enum _GlInput { carbs, gl }

/// GL = GI × grams of carbohydrate ÷ 100, to one decimal place.
double glFromCarbs(int gi, double carbs) => (gi * carbs / 10).round() / 10;

class UserFoodForm extends ConsumerStatefulWidget {
  final FoodItem? editing;
  const UserFoodForm({super.key, this.editing});

  @override
  ConsumerState<UserFoodForm> createState() => _UserFoodFormState();
}

class _UserFoodFormState extends ConsumerState<UserFoodForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _serving;
  late final TextEditingController _gi;
  late final TextEditingController _amount; // carbs (g) or GL
  late final TextEditingController _calories;
  late _GlInput _input;

  @override
  void initState() {
    super.initState();
    final f = widget.editing;
    _input = f != null && f.carbs == null ? _GlInput.gl : _GlInput.carbs;
    _name = TextEditingController(text: f?.name);
    _serving = TextEditingController(text: f?.serving);
    _gi = TextEditingController(text: f?.gi.toString());
    _amount = TextEditingController(
        text: f == null ? null : _fmt(f.carbs ?? f.gl));
    _calories = TextEditingController(text: f?.calories.toString());
  }

  @override
  void dispose() {
    for (final c in [_name, _serving, _gi, _amount, _calories]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  int? get _giValue => int.tryParse(_gi.text.trim());
  double? get _amountValue => double.tryParse(_amount.text.trim());

  /// The GL this food will be saved with, or null until the inputs are valid.
  double? get _gl {
    final gi = _giValue, amount = _amountValue;
    if (amount == null || amount < 0) return null;
    if (_input == _GlInput.gl) return amount;
    if (gi == null || gi < 0 || gi > 100) return null;
    return glFromCarbs(gi, amount);
  }

  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Required' : null;

  String? _validateName(String? v) {
    final missing = _required(v);
    if (missing != null) return missing;
    final name = v!.trim().toLowerCase();
    final mine = ref.read(userFoodsProvider).valueOrNull ?? [];
    final clash = mine.any(
        (f) => f != widget.editing && f.name.toLowerCase() == name);
    return clash ? 'You already have a food with this name' : null;
  }

  String? _validateGi(String? v) {
    final gi = int.tryParse(v?.trim() ?? '');
    return gi == null || gi < 0 || gi > 100 ? 'Enter a whole number from 0 to 100' : null;
  }

  String? _validateAmount(String? v) {
    final n = double.tryParse(v?.trim() ?? '');
    return n == null || n < 0 ? 'Enter a number, 0 or more' : null;
  }

  String? _validateCalories(String? v) {
    final n = int.tryParse(v?.trim() ?? '');
    return n == null || n < 0 ? 'Enter a whole number, 0 or more' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final food = FoodItem(
      name: _name.text.trim(),
      gi: _giValue!,
      gl: _gl!,
      calories: int.parse(_calories.text.trim()),
      serving: _serving.text.trim(),
      carbs: _input == _GlInput.carbs ? _amountValue : null,
      custom: true,
    );
    await ref
        .read(userFoodsProvider.notifier)
        .save(food, replacing: widget.editing);
    if (mounted) Navigator.of(context).pop(food);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gl = _gl;
    final field = InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: true,
    );
    const gap = SizedBox(height: 12);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Form(
          key: _formKey,
          // Recompute the GL preview as the user types.
          onChanged: () => setState(() {}),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.editing == null ? 'Add your own food' : 'Edit food',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                autofocus: widget.editing == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: field.copyWith(labelText: 'Name'),
                validator: _validateName,
              ),
              gap,
              TextFormField(
                controller: _serving,
                decoration: field.copyWith(
                    labelText: 'Serving size', hintText: 'e.g. 1 cup / 150g'),
                validator: _required,
              ),
              gap,
              TextFormField(
                controller: _gi,
                keyboardType: TextInputType.number,
                decoration: field.copyWith(labelText: 'Glycemic index (GI)'),
                validator: _validateGi,
              ),
              gap,
              SegmentedButton<_GlInput>(
                segments: const [
                  ButtonSegment(
                      value: _GlInput.carbs, label: Text('I know the carbs')),
                  ButtonSegment(value: _GlInput.gl, label: Text('I know the GL')),
                ],
                selected: {_input},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() {
                  _input = s.first;
                  _amount.clear();
                }),
              ),
              gap,
              TextFormField(
                key: ValueKey(_input),
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: field.copyWith(
                  labelText: _input == _GlInput.carbs
                      ? 'Carbohydrate per serving (g)'
                      : 'Glycemic load (GL) per serving',
                  helperText: _input == _GlInput.carbs
                      ? 'GL is worked out as GI × carbs ÷ 100'
                      : null,
                ),
                validator: _validateAmount,
              ),
              gap,
              TextFormField(
                controller: _calories,
                keyboardType: TextInputType.number,
                decoration: field.copyWith(labelText: 'Calories per serving'),
                validator: _validateCalories,
              ),
              const SizedBox(height: 16),
              Row(children: [
                Text('GL per serving', style: theme.textTheme.bodyMedium),
                const Spacer(),
                if (gl == null)
                  Text('—', style: theme.textTheme.bodyMedium)
                else
                  GlBadge(gl: gl, glClass: glClassFor(gl)),
              ]),
              const SizedBox(height: 20),
              FilledButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
