# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-11-02

### Added

- **Add your own foods.** On the Foods tab, tap "Add your own" to add a food
  that isn't in the database. Enter its GI and either its carbs per serving
  (the app works out the GL as GI × carbs ÷ 100) or its GL directly. Your
  foods are marked "My food", appear in the food list and when adding to your
  log, and can be edited or deleted. They're stored only on your device.
  Editing or deleting a food doesn't change entries already in your log.

### Fixed

- **The Log tab's total no longer overflows on narrow phones.** On a 360 px
  wide screen the day's total GL, its badge and the Add Food button didn't
  fit, by up to about 50 px with a three-digit total. The total now shrinks
  to fit.

## [1.0.1] - 2026-11-02

### Fixed

- **The "Dashboard" tab label is no longer cut off on phones.** Five
  equal-width tabs left it too little room. On narrow screens the tabs now
  size to their labels.
- **The dashboard's top axis labels no longer overlap.** The top of the axis
  could land between labels (e.g. 96 just above 95), drawing two numbers on
  top of each other. It now rounds up to a whole step (0, 20, … 100), with
  fewer, evenly spaced labels.

## [1.0.0] - 2026-11-01

First public release.

### Added

- **Food browser** with more than 5,000 foods. Search by name, sort by
  glycemic load (GL), glycemic index (GI) or name, and filter by GL tier
  (low / medium / high). Each food shows its GI, GL, calories and typical
  serving.
- **Daily log** grouped into breakfast, lunch, dinner and snacks. Add a food
  with a portion count, and see the GL and calorie totals for each meal and
  for the whole day, colour-coded against the daily GL bands (≤ 80 low,
  81–120 medium, > 120 high).
- **Move entries between meals** by dragging them (long-press on mobile).
- **Dashboard** charting daily total GL, highest single-meal GL and calories
  over time. Tap a day to open its log.
- **Works offline and keeps your data private.** The food database is bundled
  with the app, it makes no network connections, and your log is stored only
  on your device.
- Builds for **Android** (APK) and the **web**.

[Unreleased]: https://github.com/riazhassan-za/opengltracker/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/riazhassan-za/opengltracker/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/riazhassan-za/opengltracker/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/riazhassan-za/opengltracker/releases/tag/v1.0.0
