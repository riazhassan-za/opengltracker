# OpenGLTracker — Design Document

## 1. Overview

OpenGLTracker is a cross-platform app (web and Android) that lets users browse and search the foods in `FoodsList.csv` and view their Glycemic Index (GI), Glycemic Load (GL), and typical serving size. The food database is bundled with the app and read locally — there is no network fetch, cache, or refresh.

> **iOS / iPadOS:** Flutter supports iOS as a first-class target. Adding it in future requires only an Apple Developer account and a Mac build machine — no code changes needed.

---

## 2. Tech Stack

### Single Codebase: Flutter

Flutter is the chosen framework. One Dart codebase compiles natively to:

| Target   | Output           | Notes                          |
|----------|------------------|--------------------------------|
| Web      | WASM / JS bundle | PWA-installable in browser     |
| Android  | APK / AAB        | Play Store or direct install   |
| iOS      | IPA              | Future — needs Mac + Xcode     |

**Why Flutter over alternatives:**
- Single codebase covers web, Android, and iOS without duplication.
- React Native lacks a mature web target; Capacitor/Ionic has weaker native performance.
- Flutter's web and Android targets are first-class and share 100% of business logic with a future iOS build.

### Supporting Libraries

| Purpose              | Package                        |
|----------------------|--------------------------------|
| Local persistence    | `shared_preferences` (daily logs only) |
| CSV parsing          | `csv`                          |
| State management     | `riverpod` (or `provider`)     |

---

## 3. Data Source

The food database is `app/db/FoodsList.csv`, committed to this repo and bundled into the app as a Flutter asset. It is the single source of truth — the app never looks food data up online.

Updating the food list means editing the CSV and shipping a new release.

---

## 4. Data Model

CSV columns map directly to this model:

```dart
class FoodItem {
  final String name;       // "Food Item" column
  final int gi;            // "Glycemic Index (GI)" column
  final double gl;         // "Glycemic Load (GL)" column
  final String serving;    // "Typical Serving Size / Notes" column
}
```

GL classification (used for colour coding throughout the UI):

| GL Range | Classification | Colour  |
|----------|----------------|---------|
| 0–10     | Low            | Green   |
| 11–19    | Medium         | Amber   |
| 20+      | High           | Red     |

---

## 5. Data Loading

```
App launch
  └─ load bundled asset db/FoodsList.csv (rootBundle)
       ├─ SUCCESS → parse, hold in memory, display
       └─ FAIL    → show error with retry button (reloads the asset)
```

There is no caching layer, no network lookup, and no refresh timer. The asset is parsed once per app start and kept in memory for the session.

---

## 6. UI / UX Design

### 6.1 Layout — All Platforms

The app uses a single adaptive layout. On narrow screens (phone) it is single-column; on wider screens (tablet, web) the list and detail panel sit side by side.

```
┌──────────────────────────────────────────────┐
│  OpenGLTracker                               │  ← App Bar
├──────────────────────────────────────────────┤
│  🔍 Search foods...                          │  ← Search bar
│  Sort: [GL ▾]  Filter: [All ▾]              │  ← Controls row
├──────────────────────────────────────────────┤
│  Spinach / Kale / Lettuce    GI 10  GL 0.0  │  ← List item (green dot)
│  Broccoli / Cauliflower      GI 15  GL 0.5  │
│  Peanuts                     GI 7   GL 1.0  │
│  ...                                         │
└──────────────────────────────────────────────┘
```

Tapping a row opens a detail panel (bottom sheet on mobile, right panel on wide screens):

```
┌──────────────────────────────┐
│  Spinach / Kale / Lettuce    │
│  ●  LOW GL                   │
│  ──────────────────────────  │
│  Glycemic Index (GI)   10    │
│  Glycemic Load (GL)    0.0   │
│  Serving Size          1 cup │
└──────────────────────────────┘
```

### 6.2 Sort Options

- GL ascending (default — shows healthiest first)
- GL descending
- GI ascending / descending
- Alphabetical A–Z / Z–A

### 6.3 Filter Options

- All items (default)
- Low GL only (0–10)
- Medium GL only (11–19)
- High GL only (20+)

### 6.4 Platform Adaptations

| Feature            | Web                    | Android            | iOS (future)        |
|--------------------|------------------------|--------------------|---------------------|
| Layout             | Responsive (CSS-like)  | Single column      | Single column       |
| Navigation         | URL routing            | Navigator 2.0      | Navigator 2.0       |
| Log storage        | IndexedDB via sp       | SharedPrefs        | NSUserDefaults sp   |
| Install            | Browser / PWA          | APK / Play Store   | App Store / TestFlight |

---

## 7. Daily Consumption Tracker

### 7.1 Overview

Users can log food items they consumed during the day, specify how many portions, and see their running total GL. This feature is entirely local — no backend or account required.

### 7.2 Data Model

```dart
class ConsumptionEntry {
  final String id;         // UUID, for deletion
  final FoodItem food;
  final double portions;   // user-entered (e.g. 1.5 = 1.5 servings)

  double get glContribution => food.gl * portions;
  double get giValue => food.gi.toDouble();
}

class DailyLog {
  final DateTime date;           // date only (no time)
  final List<ConsumptionEntry> entries;

  double get totalGL => entries.fold(0.0, (sum, e) => sum + e.glContribution);
  String get totalGLClassification {  // "Low" / "Medium" / "High" based on totalGL
    if (totalGL <= 80) return 'Low';
    if (totalGL <= 120) return 'Medium';
    return 'High';
  }
}
```

Daily total GL classification thresholds (standard dietary guidelines):

| Total Daily GL | Classification |
|----------------|----------------|
| ≤ 80           | Low (ideal)    |
| 81–120         | Medium         |
| > 120          | High           |

### 7.3 UI — Daily Log Screen

The app gains a bottom navigation bar with two tabs:

```
[ Foods ]     [ Today's Log ]
```

**Today's Log tab:**

```
┌──────────────────────────────────────────────┐
│  Today's GL Log          Mon 30 Jun 2026     │
├──────────────────────────────────────────────┤
│  Total GL: 47.5   ●  LOW                    │  ← summary chip
├──────────────────────────────────────────────┤
│  [+ Add Food]                                │  ← FAB or inline button
├──────────────────────────────────────────────┤
│  Spinach / Kale / Lettuce                    │
│  1 portion × GL 0.0 = 0.0            [🗑]   │
│                                              │
│  Banana (Yellow, ripe)                       │
│  2 portions × GL 11.0 = 22.0         [🗑]   │
│                                              │
│  Brown Rice (Steamed)                        │
│  1.5 portions × GL 16.0 = 24.0       [🗑]   │
└──────────────────────────────────────────────┘
```

**Add Food flow (bottom sheet / dialog):**

1. Search field — same search as Foods tab, filtered live.
2. Tap a food item to select it.
3. Enter portions (numeric field, default 1, supports decimals).
4. Confirm → entry added to today's log, total GL updates instantly.

### 7.4 Log Persistence

- Stored in `shared_preferences` as a JSON-encoded list keyed by date string (`"log_2026-06-30"`).
- Each day's log is independent; past days are read-only (for review).
- No automatic deletion — user can clear via a "Clear today's log" button.
- Future extension point: export log as CSV or view history by date (not in initial scope).

### 7.5 Portion Logic

The CSV "Typical Serving Size / Notes" column defines what 1 portion equals. The app displays this string as a reminder next to the portions field so the user knows what 1 serving means (e.g. "1 cup", "1 oz (28g)").

---

## 8. Project Structure (Flutter)

```
gl_tracker/
├── docs/                        ← this folder
└── app/                         ← Flutter project root
    ├── db/FoodsList.csv         ← bundled food database (source of truth)
    ├── lib/
    │   ├── main.dart
    │   ├── data/
    │   │   ├── food_item.dart          ← food model
    │   │   ├── consumption_entry.dart  ← consumption + daily log models
    │   │   ├── csv_parser.dart         ← parse raw CSV → List<FoodItem>
    │   │   ├── food_repository.dart    ← load bundled CSV asset
    │   │   └── log_repository.dart     ← read/write daily logs to storage
    │   ├── providers/
    │   │   ├── food_provider.dart      ← Riverpod: food list + search/sort/filter
    │   │   └── log_provider.dart       ← Riverpod: today's log + total GL
    │   └── ui/
    │       ├── app.dart                ← MaterialApp, routing, bottom nav
    │       ├── food_list_screen.dart
    │       ├── food_detail_panel.dart
    │       ├── daily_log_screen.dart
    │       ├── add_food_sheet.dart     ← search + portions entry
    │       └── widgets/
    │           ├── food_list_tile.dart
    │           ├── gl_badge.dart       ← colour-coded GL chip
    │           └── log_entry_tile.dart
    ├── pubspec.yaml
    └── (platform folders: android/, web/, ios/ [when added])
```

---

## 9. Accessibility & Performance

- Semantic labels on all interactive elements (screen reader support).
- List uses `ListView.builder` (lazy rendering) — future-proof regardless of how many items the CSV grows to.
- Search filters the in-memory list (no network call); instant response.
- The bundled CSV is parsed once at startup; the app works fully offline.
- Portion input validates numeric-only and rejects negative/zero values.
