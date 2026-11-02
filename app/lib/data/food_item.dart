enum GlClass { low, medium, high }

enum FoodSort { glAsc, glDesc, giAsc, giDesc, nameAsc, nameDesc }

class FoodItem {
  final String name;
  final int gi;
  final double gl;
  final int calories;
  final String serving;

  /// Grams of carbohydrate per serving. Only known for foods the user added
  /// by carbs; the bundled database doesn't include it.
  final double? carbs;

  /// True for a food the user added, false for the bundled database.
  final bool custom;

  const FoodItem({
    required this.name,
    required this.gi,
    required this.gl,
    required this.calories,
    required this.serving,
    this.carbs,
    this.custom = false,
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

  Map<String, dynamic> toJson() => {
        'name': name,
        'gi': gi,
        'gl': gl,
        'calories': calories,
        'serving': serving,
        if (carbs != null) 'carbs': carbs,
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        name: json['name'] as String,
        gi: (json['gi'] as num).toInt(),
        gl: (json['gl'] as num).toDouble(),
        calories: (json['calories'] as num).toInt(),
        serving: json['serving'] as String,
        carbs: (json['carbs'] as num?)?.toDouble(),
        custom: true,
      );

  GlClass get glClass => glClassFor(gl);
}

/// Per-serving GL bands: ≤ 10 low, 11–19 medium, ≥ 20 high.
GlClass glClassFor(double gl) {
  if (gl <= 10) return GlClass.low;
  if (gl <= 19) return GlClass.medium;
  return GlClass.high;
}
