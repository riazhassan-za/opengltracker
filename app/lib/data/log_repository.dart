import 'package:shared_preferences/shared_preferences.dart';
import 'consumption_entry.dart';

class LogRepository {
  String _key(DateTime date) =>
      'log_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<DailyLog> loadLog(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(date));
    if (raw == null) return DailyLog(date: date, entries: []);
    return DailyLog.fromJsonString(date, raw);
  }

  Future<void> saveEntry(DateTime date, ConsumptionEntry entry) async {
    final log = await loadLog(date);
    final updated = DailyLog(
      date: date,
      entries: [...log.entries, entry],
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(date), updated.toJsonString());
  }

  Future<void> deleteEntry(DateTime date, String id) async {
    final log = await loadLog(date);
    final updated = DailyLog(
      date: date,
      entries: log.entries.where((e) => e.id != id).toList(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(date), updated.toJsonString());
  }

  Future<void> updateEntryCategory(
      DateTime date, String id, MealCategory newCategory) async {
    final log = await loadLog(date);
    final updated = DailyLog(
      date: date,
      entries: log.entries
          .map((e) => e.id == id ? e.copyWith(category: newCategory) : e)
          .toList(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(date), updated.toJsonString());
  }

  Future<void> clearLog(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(date));
  }
}
