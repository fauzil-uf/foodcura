/// Model representasi bahan baku mentah (ingredients) khusus untuk inventaris dapur (Pantry).
class PantryIngredientModel {
  final String name;
  final String category;
  final String defaultStorage;
  final int defaultShelfLifeDays;
  final String defaultUnit;
  final String? imageUrl;

  const PantryIngredientModel({
    required this.name,
    required this.category,
    required this.defaultStorage,
    required this.defaultShelfLifeDays,
    required this.defaultUnit,
    this.imageUrl,
  });
}
