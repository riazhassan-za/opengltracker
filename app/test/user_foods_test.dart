import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengltracker/data/food_item.dart';
import 'package:opengltracker/data/food_repository.dart';
import 'package:opengltracker/providers/food_provider.dart';
import 'package:opengltracker/ui/app.dart';
import 'package:opengltracker/ui/user_food_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A tiny bundled database, so the tests don't parse the 9,000-row CSV.
class _FakeFoodRepository extends FoodRepository {
  @override
  Future<List<FoodItem>> loadFoods() async => const [
        FoodItem(name: 'Apple', gi: 36, gl: 5, calories: 95, serving: '1 medium'),
      ];
}

Future<List<dynamic>> _stored() async {
  final prefs = await SharedPreferences.getInstance();
  return jsonDecode(prefs.getString('user_foods') ?? '[]') as List;
}

Future<void> _pumpFoodsTab(WidgetTester t) async {
  t.view.physicalSize = const Size(360, 740);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(ProviderScope(
    overrides: [foodRepositoryProvider.overrideWithValue(_FakeFoodRepository())],
    child: const OpenGlTrackerApp(),
  ));
  await t.tap(find.widgetWithText(Tab, 'Foods'));
  await t.pumpAndSettle();
}

Future<void> _fill(WidgetTester t, String label, String text) =>
    t.enterText(find.widgetWithText(TextFormField, label), text);

Future<void> _save(WidgetTester t) async {
  final save = find.widgetWithText(FilledButton, 'Save');
  await t.ensureVisible(save);
  await t.tap(save);
  await t.pumpAndSettle();
}

Future<void> _addOatBars(WidgetTester t) async {
  await t.tap(find.text('Add your own'));
  await t.pumpAndSettle();
  await _fill(t, 'Name', 'Oat bars');
  await _fill(t, 'Serving size', '1 bar');
  await _fill(t, 'Glycemic index (GI)', '60');
  await _fill(t, 'Carbohydrate per serving (g)', '20');
  await _fill(t, 'Calories per serving', '150');
  await _save(t);
}

// Real fonts, as in layout_test.dart: the default test font's square glyphs
// make every label far wider than on a device.
Future<void> _loadFonts() async {
  Future<ByteData> read(String f) async =>
      ByteData.sublistView(File('test/fonts/$f').readAsBytesSync());
  await (FontLoader('Roboto')
        ..addFont(read('roboto-regular.ttf'))
        ..addFont(read('roboto-medium.ttf'))
        ..addFont(read('roboto-bold.ttf')))
      .load();
}

void main() {
  setUpAll(_loadFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('GL from carbs is GI × carbs ÷ 100, to one decimal', () {
    expect(glFromCarbs(60, 20), 12.0);
    expect(glFromCarbs(72, 6), 4.3); // watermelon: high GI, low GL
    expect(glFromCarbs(0, 50), 0.0);
  });

  testWidgets('add a food by carbs; it is listed, computed and saved',
      (t) async {
    await _pumpFoodsTab(t);
    await _addOatBars(t);

    expect(find.text('Oat bars'), findsOneWidget);
    expect(find.text('GI 60 · My food'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget); // bundled foods still there
    expect(await _stored(), [
      {'name': 'Oat bars', 'gi': 60, 'gl': 12.0, 'calories': 150,
       'serving': '1 bar', 'carbs': 20.0},
    ]);
  });

  testWidgets('add a food by GL directly', (t) async {
    await _pumpFoodsTab(t);
    await t.tap(find.text('Add your own'));
    await t.pumpAndSettle();
    await _fill(t, 'Name', 'Rye crispbread');
    await _fill(t, 'Serving size', '2 slices');
    await _fill(t, 'Glycemic index (GI)', '64');
    await t.tap(find.text('I know the GL'));
    await t.pump();
    await _fill(t, 'Glycemic load (GL) per serving', '7.5');
    await _fill(t, 'Calories per serving', '70');
    await _save(t);

    final stored = (await _stored()).single as Map;
    expect(stored['gl'], 7.5);
    expect(stored.containsKey('carbs'), isFalse);
  });

  testWidgets('invalid input and duplicate names are rejected', (t) async {
    await _pumpFoodsTab(t);
    await _addOatBars(t);

    await t.tap(find.text('Add your own'));
    await t.pumpAndSettle();
    await _fill(t, 'Name', 'oat BARS');
    await _fill(t, 'Glycemic index (GI)', '101');
    await _save(t);

    expect(find.text('You already have a food with this name'), findsOneWidget);
    expect(find.text('Enter a whole number from 0 to 100'), findsOneWidget);
    expect(find.text('Required'), findsOneWidget); // serving size
    expect(await _stored(), hasLength(1));
  });

  testWidgets('edit then delete your own food', (t) async {
    await _pumpFoodsTab(t);
    await _addOatBars(t);

    await t.tap(find.text('Oat bars'));
    await t.pumpAndSettle();
    await t.tap(find.text('Edit'));
    await t.pumpAndSettle();
    expect(find.text('Edit food'), findsOneWidget);
    await _fill(t, 'Glycemic index (GI)', '50');
    await _save(t);

    expect(find.text('GI 50 · My food'), findsOneWidget);
    expect(((await _stored()).single as Map)['gl'], 10.0);

    await t.tap(find.text('Oat bars'));
    await t.pumpAndSettle();
    await t.tap(find.text('Delete'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(FilledButton, 'Delete'));
    await t.pumpAndSettle();

    expect(find.text('Oat bars'), findsNothing);
    expect(await _stored(), isEmpty);
  });

  testWidgets('bundled foods have no edit or delete', (t) async {
    await _pumpFoodsTab(t);
    await t.tap(find.text('Apple'));
    await t.pumpAndSettle();
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);
  });

  test('saved foods are loaded back after a restart', () async {
    SharedPreferences.setMockInitialValues({
      'user_foods': jsonEncode([
        {'name': 'Oat bars', 'gi': 60, 'gl': 12.0, 'calories': 150,
         'serving': '1 bar', 'carbs': 20.0},
      ]),
    });
    final c = ProviderContainer(overrides: [
      foodRepositoryProvider.overrideWithValue(_FakeFoodRepository()),
    ]);
    addTearDown(c.dispose);
    final foods = await c.read(foodProvider.future);
    expect(foods.map((f) => f.name), ['Oat bars', 'Apple']);
    expect(foods.first.custom, isTrue);
    expect(foods.last.custom, isFalse);
  });
}
