// Regenerates the README screenshots in docs/screenshots/.
//
//   cd app
//   flutter test screenshots/readme_screenshots_test.dart
//
// Renders the real app with real fonts and a seeded week of log entries.
// Kept out of test/ so the normal `flutter test` run doesn't rewrite images.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengltracker/data/food_item.dart';
import 'package:opengltracker/providers/food_provider.dart';
import 'package:opengltracker/ui/app.dart';
import 'package:opengltracker/ui/widgets/food_list_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _outDir = '../docs/screenshots';

Future<void> _loadFonts() async {
  final fonts =
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String f) async =>
      ByteData.sublistView(File('$fonts/$f').readAsBytesSync());
  final roboto = FontLoader('Roboto')
    ..addFont(read('roboto-regular.ttf'))
    ..addFont(read('roboto-medium.ttf'))
    ..addFont(read('roboto-bold.ttf'));
  final icons = FontLoader('MaterialIcons')
    ..addFont(read('materialicons-regular.otf'));
  await roboto.load();
  await icons.load();
}

Map<String, Object> _entry(String name, double gl, int kcal, String serving,
        double portions, String category) =>
    {
      'foodName': name,
      'foodGl': gl,
      'foodCalories': kcal,
      'foodServing': serving,
      'portions': portions,
      'category': category,
    };

// A plausible week, using foods and values from db/FoodsList.csv.
final _week = [
  [
    _entry('Rolled Oats (Porridge)', 11, 150, '1 cup, cooked', 1, 'breakfast'),
    _entry('Brown Rice (Steamed)', 16, 215, '1 cup, cooked', 1, 'lunch'),
    _entry('Grilled Chicken', 0, 147, '1 medium piece', 1, 'lunch'),
    _entry('Pasta with Meat Sauce', 17, 329, '1 cup', 2, 'dinner'),
  ],
  [
    _entry('Greek yogurt (Plain)', 2, 130, '1 cup (200g)', 1, 'breakfast'),
    _entry('Lentils', 5, 115, '1/2 cup, cooked', 2, 'lunch'),
    _entry('Basmati Rice', 15, 210, '1 cup, cooked', 2, 'dinner'),
    _entry('Salmon', 0, 175, '3 oz / 85g', 1, 'dinner'),
    _entry('Bananas', 14, 105, '1 medium', 1, 'snacks'),
  ],
  [
    _entry('Whole Wheat Bread', 10, 67, '1 regular slice', 2, 'breakfast'),
    _entry('Pasta with Meat Sauce', 17, 329, '1 cup', 1.5, 'lunch'),
    _entry('Sweet Potato (Boiled)', 11, 115, '1 medium potato', 2, 'dinner'),
    _entry('Dark chocolate (70%+)', 4, 170, '30g (1 oz)', 1, 'snacks'),
  ],
  [
    _entry('Rolled Oats (Porridge)', 11, 150, '1 cup, cooked', 1, 'breakfast'),
    _entry('Bananas', 14, 105, '1 medium', 1, 'breakfast'),
    _entry('Lentils', 5, 115, '1/2 cup, cooked', 2, 'lunch'),
    _entry('Basmati Rice', 15, 210, '1 cup, cooked', 1, 'dinner'),
    _entry('Salmon', 0, 175, '3 oz / 85g', 1, 'dinner'),
  ],
  [
    _entry('Greek yogurt (Plain)', 2, 130, '1 cup (200g)', 1, 'breakfast'),
    _entry('Brown Rice (Steamed)', 16, 215, '1 cup, cooked', 2, 'lunch'),
    _entry('Basmati Rice', 15, 210, '1 cup, cooked', 2, 'dinner'),
    _entry('Bananas', 14, 105, '1 medium', 1, 'snacks'),
  ],
  [
    _entry('Whole Wheat Bread', 10, 67, '1 regular slice', 1, 'breakfast'),
    _entry('Grilled Chicken', 0, 147, '1 medium piece', 1, 'lunch'),
    _entry('Sweet Potato (Boiled)', 11, 115, '1 medium potato', 1, 'lunch'),
    _entry('Pasta with Meat Sauce', 17, 329, '1 cup', 1, 'dinner'),
    _entry('Watermelon', 4, 45, '1 cup, cubes', 2, 'snacks'),
  ],
  // Today
  [
    _entry('Rolled Oats (Porridge)', 11, 150, '1 cup, cooked', 1, 'breakfast'),
    _entry('Bananas', 14, 105, '1 medium', 0.5, 'breakfast'),
    _entry('Lentils', 5, 115, '1/2 cup, cooked', 2, 'lunch'),
    _entry('Brown Rice (Steamed)', 16, 215, '1 cup, cooked', 1, 'lunch'),
    _entry('Salmon', 0, 175, '3 oz / 85g', 1, 'dinner'),
    _entry('Sweet Potato (Boiled)', 11, 115, '1 medium potato', 1, 'dinner'),
    _entry('Watermelon', 4, 45, '1 cup, cubes', 2, 'snacks'),
    _entry('Almonds', 1, 165, '1 oz (28g)', 1, 'snacks'),
  ],
];

Map<String, Object> _seed() {
  final today = DateTime.now();
  final values = <String, Object>{};
  for (var i = 0; i < _week.length; i++) {
    final d = DateTime(today.year, today.month, today.day - (6 - i));
    final key = 'log_${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    values[key] = jsonEncode([
      for (var j = 0; j < _week[i].length; j++)
        {..._week[i][j], 'id': 'shot-$i-$j'},
    ]);
  }
  return values;
}

final _boundary = GlobalKey();

Future<void> _launch(WidgetTester t, Size size) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(_seed());
  // A cached asset load from a previous test never completes in this one.
  rootBundle.clear();
  await t.pumpWidget(RepaintBoundary(
    key: _boundary,
    child: ProviderScope(
      // A–Z rather than the default "GL ↑": the test renderer has no
      // fallback font for the arrow glyph, which devices get from the system.
      overrides: [foodSortProvider.overrideWith((_) => FoodSort.nameAsc)],
      child: const OpenGlTrackerApp(),
    ),
  ));
  // The food db loads through the asset bundle, which needs real async time.
  await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
  await t.pumpAndSettle();
}

// pumpAndSettle, but tolerant of an animation that never ends (it gives up
// after a few simulated seconds instead of failing).
Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 50 && t.binding.hasScheduledFrame; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  // ignore: avoid_print
  print('settle: transient=${t.binding.transientCallbackCount}');
}

Future<void> _shot(WidgetTester t, String name, double pixelRatio) async {
  await _settle(t);
  await t.runAsync(() async {
    final boundary = _boundary.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_outDir/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

Future<void> _openTab(WidgetTester t, String label) async {
  await t.tap(find.widgetWithText(Tab, label));
  // A tab's data (e.g. the food db) loads when first shown, off the fake
  // test clock, so give it real time until the spinner is gone.
  for (var i = 0; i < 60; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
    await t.pump(const Duration(milliseconds: 100));
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
  await _settle(t);
}

Future<void> _searchAndOpen(WidgetTester t, String query, String food) async {
  await t.enterText(find.byType(TextField).first, query);
  // A focused field's blinking cursor never lets pumpAndSettle finish.
  FocusManager.instance.primaryFocus?.unfocus();
  await _settle(t);
  // The food db loads off the fake test clock; give it real time.
  for (var i = 0; i < 80 && find.byType(FoodListTile).evaluate().isEmpty; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
    await t.pump(const Duration(milliseconds: 100));
  }
  await _settle(t);
  // Scroll the vertical food list (not the tab view's horizontal pager)
  // until the food is built, then bring it fully on screen.
  final list = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
  for (var i = 0; i < 30 && find.text(food).evaluate().isEmpty; i++) {
    await t.drag(list.first, const Offset(0, -200));
    await t.pump();
  }
  await t.ensureVisible(find.text(food).first);
  await _settle(t);
  await t.tap(find.text(food).first);
  await _settle(t);
}

void main() {
  setUpAll(() async {
    WidgetsApp.debugAllowBannerOverride = false; // no DEBUG ribbon
    await _loadFonts();
  });

  const phone = Size(412, 880);

  testWidgets('daily log (phone)', (t) async {
    await _launch(t, phone);
    await _shot(t, 'log', 2.5);
    t.view.reset();
  });

  testWidgets('food detail (phone)', (t) async {
    await _launch(t, phone);
    await _openTab(t, 'Foods');
    await _searchAndOpen(t, 'watermelon', 'Watermelon');
    await _shot(t, 'food-detail', 2.5);
    t.view.reset();
  });

  testWidgets('dashboard (phone)', (t) async {
    await _launch(t, phone);
    await _openTab(t, 'Dashboard');
    await _shot(t, 'dashboard', 2.5);
    t.view.reset();
  });

  testWidgets('foods (desktop)', (t) async {
    await _launch(t, const Size(1280, 760));
    await _openTab(t, 'Foods');
    await _searchAndOpen(t, 'brown rice', 'Brown Rice (Steamed)');
    await _shot(t, 'foods-desktop', 1.5);
    t.view.reset();
  });
}
