# OpenGLTracker — Execution Plan

> Prerequisites: Flutter SDK ≥ 3.22 installed, Android SDK (for Android builds).
>
> **iOS note:** Adding iOS later requires only an Apple Developer account and a Mac with Xcode — the codebase needs no changes.

---

## Phase 1 — Project Bootstrap

**Goal:** A running Flutter app on both targets (web and Android) with nothing but a placeholder screen.

### Steps

1. **Create Flutter project**
   ```
   flutter create --platforms=android,web app
   ```
   Verify: `flutter run -d chrome` and `flutter run -d <android-device>` both open a blank app.

2. **Add dependencies to `pubspec.yaml`**
   ```yaml
   dependencies:
     flutter_riverpod: ^2.x
     csv: ^6.x
     shared_preferences: ^2.x
     uuid: ^4.x
   ```
   Verify: `flutter pub get` completes with no conflicts.

3. **Bundle the CSV**
   - Commit `app/db/FoodsList.csv` to the repo and list it under `flutter: assets:` in `pubspec.yaml`.
   - Define the asset path as a constant in `lib/data/constants.dart`:
     ```dart
     const String kFoodsCsvAsset = 'db/FoodsList.csv';
     ```
   Verify: `flutter pub get` succeeds and the asset is included in the build.

4. **Set up bottom navigation shell**
   - `app.dart`: `MaterialApp` with a `Scaffold` containing a `BottomNavigationBar` with two tabs: "Foods" and "Today's Log".
   - Each tab shows a placeholder `Center(child: Text('...'))`.
   Verify: Tab switching works on both platforms.

---

## Phase 2 — Data Layer

**Goal:** The bundled CSV is loaded and parsed. No network lookup, caching, or refresh. No UI beyond a loading indicator.

### Steps

5. **Implement `FoodItem` model** (`lib/data/food_item.dart`)
   - Fields: `name`, `gi`, `gl`, `serving`
   - Factory constructor `FoodItem.fromCsvRow(List<dynamic> row)`
   - Helper getter `GLClassification get glClass` returns enum `{low, medium, high}`
   Verify: Unit test — parse a hand-crafted CSV row and assert field values.

6. **Implement `csv_parser.dart`**
   - Function `List<FoodItem> parseFoodsCsv(String rawCsv)`
   - Skips header row, handles quoted fields (the `csv` package does this)
   - Skips any blank/malformed rows
   Verify: Unit test — parse the real `FoodsList.csv` content (read from assets), confirm all rows are parsed, spot-check Russet Potato GL = 33.0.

7. **Implement `food_repository.dart`**
   ```
   loadFoods()
     → rootBundle.loadString(kFoodsCsvAsset) → parse → return items
   ```
   Verify: Unit test — call `loadFoods()`, confirm the bundled foods are returned and known items are present.

8. **Implement `food_provider.dart`** (Riverpod)
   - `AsyncNotifierProvider<FoodListNotifier, List<FoodItem>>`
   - On build: calls `loadFoods()` once and holds the list in memory.
   - `reload()` method, used only by the error view's Retry button.
   Verify: Widget test — state transitions loading → data.

---

## Phase 3 — Food Browser UI

**Goal:** Foods tab is fully functional — list, search, sort, filter, detail panel.

### Steps

9. **`gl_badge.dart` widget**
   - Displays GL value as a coloured chip (green / amber / red based on `glClass`).
   - Used in both list tiles and the detail panel.
   Verify: Widget test — GL 5.0 renders green, GL 15.0 amber, GL 25.0 red.

10. **`food_list_tile.dart`**
    - Shows food name, GI value, and `GlBadge`.
    - `onTap` callback.
    Verify: Widget test — tap fires callback with correct `FoodItem`.

11. **`food_list_screen.dart`**
    - Watches `foodProvider` — shows `CircularProgressIndicator` while loading, error widget on failure, `ListView.builder` when data is ready.
    - Search bar filters `name` case-insensitively (in-memory, instant).
    - Sort dropdown: GL asc (default), GL desc, GI asc, GI desc, A–Z, Z–A.
    - Filter dropdown: All, Low GL, Medium GL, High GL.
    - Error view with a Retry button if the bundled CSV fails to load.
    Verify: Manual test on both platforms — search "rice" returns relevant items, sort by GL desc puts Russet Potato first.

12. **`food_detail_panel.dart`**
    - On mobile (width < 600 px): opens as a `DraggableScrollableSheet` (bottom sheet).
    - On wide screens (≥ 600 px): renders inline in a right-side panel (use `Row` + `AnimatedSwitcher`).
    - Shows: name, GL badge + classification label, GI value, GL value, serving size.
    Verify: Manual test — on Chrome (wide), selecting a food shows the panel alongside the list without navigation. On Android (narrow), it slides up from the bottom.

---

## Phase 4 — Daily Log UI

**Goal:** Today's Log tab is fully functional — add entries, view total GL, delete entries.

### Steps

13. **`ConsumptionEntry` and `DailyLog` models** (`lib/data/consumption_entry.dart`)
    - `ConsumptionEntry`: `id` (UUID), `foodName`, `foodGL`, `foodServing`, `portions` → `glContribution` getter
    - Store food fields by value (not reference) so log entries survive CSV updates.
    - `DailyLog`: `date`, `List<ConsumptionEntry>` → `totalGL` getter → `totalGLClassification` getter
    Verify: Unit test — DailyLog with two entries calculates correct totalGL.

14. **`log_repository.dart`**
    - `saveEntry(DateTime date, ConsumptionEntry entry)` — appends to the day's JSON list in `shared_preferences`.
    - `deleteEntry(DateTime date, String entryId)` — removes entry by id.
    - `loadLog(DateTime date)` → `DailyLog`
    - `clearLog(DateTime date)`
    Verify: Unit test — save two entries, delete one by id, load and assert only one remains.

15. **`log_provider.dart`** (Riverpod)
    - `AsyncNotifierProvider<DailyLogNotifier, DailyLog>` scoped to today's date.
    - Methods: `addEntry(FoodItem, double portions)`, `deleteEntry(String id)`, `clearLog()`.
    Verify: Widget test — addEntry updates totalGL reactively.

16. **`add_food_sheet.dart`**
    - Search field (same logic as food list, reuses `foodProvider`).
    - Tapping a result shows: food name, serving size reminder, and a numeric portions field (default "1", decimal allowed, min 0.1).
    - "Add" button calls `logProvider.notifier.addEntry(food, portions)` and closes the sheet.
    Verify: Manual test — search "banana", select it, enter 2 portions, confirm total GL increases by 22.0.

17. **`daily_log_screen.dart`**
    - Watches `logProvider`.
    - Header: date label, total GL value, classification badge.
    - "Add Food" button (or FAB on mobile).
    - `ListView` of `LogEntryTile` widgets — each shows food name, portions, GL contribution, delete icon.
    - "Clear today's log" text button at the bottom (with confirmation dialog).
    Verify: Manual test on both platforms — add three foods, delete one, total updates correctly. Clear log resets to zero.

---

## Phase 5 — Platform Polish & Build

**Goal:** Each platform target is production-quality and buildable to a distributable artifact.

### Steps

18. **Responsive layout pass**
    - Wrap `food_list_screen` and `daily_log_screen` in a `LayoutBuilder`.
    - At ≥ 600 px width: show detail panel inline (food tab) and use a two-column log layout if space allows.
    - Confirm bottom navigation bar remains consistent across all widths.

19. **Web PWA setup**
    - Edit `web/manifest.json` — set app name "OpenGLTracker", theme colour, icons.
    - Test offline: after first load, confirm the food list is visible without network (service worker caches the app shell, which includes the bundled CSV asset).

20. **Android release build**
    - Set `applicationId`, version name/code in `android/app/build.gradle`.
    - `flutter build apk --release` → distribute via direct APK install or Play Store.

21. **Web release build**
    - `flutter build web --release --wasm` (Wasm for better performance) or `--web-renderer html` for compatibility.
    - Deploy `build/web/` to GitHub Pages, Netlify, or Cloudflare Pages.

22. **iOS build (future)**
    - Run `flutter create --platforms=ios .` from the `app/` directory to add the iOS platform folder.
    - Requires a Mac with Xcode and an Apple Developer account.
    - `flutter build ipa --release` → distribute via TestFlight or App Store.

---

## Phase 6 — Testing & QA

23. **Unit tests** — models, CSV parser, repository logic (Phases 2 & 4 verify steps).
24. **Widget tests** — all widgets listed above.
25. **Integration test** (golden path):
    - Launch app → data loads → search "rice" → select "Brown Rice" → detail panel shows GL 16.0 (amber).
    - Switch to Today's Log → add "Brown Rice" × 2 → total GL = 32.0 (Low) → delete entry → total = 0.
26. **Manual regression** on both platforms after any change to providers or repositories.

---

## Milestone Summary

| Milestone       | Phases    | Outcome                                                    |
|-----------------|-----------|------------------------------------------------------------|
| M1: Shell       | 1         | Blank app runs on web and Android                          |
| M2: Data        | 2         | Bundled CSV loaded and parsed                              |
| M3: Browse      | 3         | Food search, sort, filter, detail fully working            |
| M4: Log         | 4         | Daily consumption log with GL total working                |
| M5: Ship        | 5–6       | Polished, tested, built for web and Android                |
| M6: iOS         | Future    | iOS build added when Apple dev account is available        |
