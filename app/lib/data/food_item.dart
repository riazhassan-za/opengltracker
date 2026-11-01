enum GlClass { low, medium, high }

enum FoodSort { glAsc, glDesc, giAsc, giDesc, nameAsc, nameDesc }

class FoodItem {
  final String name;
  final int gi;
  final double gl;
  final int calories;
  final String serving;

  const FoodItem({
    required this.name,
    required this.gi,
    required this.gl,
    required this.calories,
    required this.serving,
  });

  factory FoodItem.fromCsvRow(List<dynamic> row) {
    return FoodItem(
      name: row[0].toString().trim(),
      gi: int.parse(row[1].toString().trim()),
      gl: double.parse(row[2].toString().trim()),
      calories: int.parse(row[3].toString().trim()),
      serving: row[4].toString().trim(),
    );
  }

  GlClass get glClass {
    if (gl <= 10) return GlClass.low;
    if (gl <= 19) return GlClass.medium;
    return GlClass.high;
  }
}
