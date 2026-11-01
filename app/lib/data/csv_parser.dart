import 'package:csv/csv.dart';
import 'food_item.dart';

List<FoodItem> parseFoodsCsv(String rawCsv) {
  // Normalize line endings (\r\n → \n, lone \r → \n)
  final normalized = rawCsv.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final rows = const CsvToListConverter().convert(normalized, eol: '\n');
  final items = <FoodItem>[];
  for (final row in rows.skip(1)) {
    if (row.length < 5) continue;
    try {
      final serving = row[4].toString();
      if (serving.contains('(GI/GL unavailable)')) continue;
      items.add(FoodItem.fromCsvRow(row));
    } catch (_) {
      // skip malformed rows
    }
  }
  return items;
}
