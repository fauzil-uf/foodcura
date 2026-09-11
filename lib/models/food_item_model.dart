import 'dart:convert';

//// Model katalog makanan dan informasi kandungan nutrisi (TKPI Kemenkes RI).
class FoodItemModel {
  final int? id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double cholesterol;
  final String category;
  final String imagePath;

  final String? firestoreId;

  const FoodItemModel({
    this.id,
    this.firestoreId,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.cholesterol = 0.0,
    required this.category,
    required this.imagePath,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'cholesterol': cholesterol,
      'category': category,
      'image_path': imagePath,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'cholesterol': cholesterol,
      'category': category,
      'image_path': imagePath,
    };
  }

  factory FoodItemModel.fromMap(Map<String, dynamic> map) {
    return FoodItemModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      calories: (map['calories'] as num).toInt(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      cholesterol: (map['cholesterol'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String,
      imagePath: map['image_path'] as String,
    );
  }

  /// Inferensi kategori waktu makan otomatis dari nama hidangan
  static String _inferCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('rujak cingur')) {
      return 'Makan Siang';
    } else if (lower.contains('goreng') ||
        lower.contains('soto') ||
        lower.contains('nasi') ||
        lower.contains('ayam') ||
        lower.contains('ikan') ||
        lower.contains('daging') ||
        lower.contains('gulai') ||
        lower.contains('sop') ||
        lower.contains('rendang') ||
        lower.contains('mie') ||
        lower.contains('sate') ||
        lower.contains('bakso') ||
        lower.contains('babat') ||
        lower.contains('bebek') ||
        lower.contains('masakan')) {
      return 'Makan Siang';
    } else if (lower.contains('roti') ||
        lower.contains('telur') ||
        lower.contains('bubur') ||
        lower.contains('lontong') ||
        lower.contains('kopi') ||
        lower.contains('teh') ||
        lower.contains('oatmeal') ||
        lower.contains('sandwich') ||
        lower.contains('pancake') ||
        lower.contains('sarapan')) {
      return 'Sarapan';
    } else if (lower.contains('kangkung') ||
        lower.contains('tumis') ||
        lower.contains('tahu') ||
        lower.contains('tempe') ||
        lower.contains('capcay') ||
        lower.contains('karedok') ||
        lower.contains('buncis') ||
        lower.contains('bayam') ||
        lower.contains('sayur')) {
      return 'Makan Malam';
    } else if (lower.contains('apel') ||
        lower.contains('pisang') ||
        lower.contains('es') ||
        lower.contains('jus') ||
        lower.contains('kue') ||
        lower.contains('keripik') ||
        lower.contains('biskuit') ||
        lower.contains('donat') ||
        lower.contains('martabak') ||
        lower.contains('yoghurt') ||
        lower.contains('semangka') ||
        lower.contains('jagung') ||
        lower.contains('biji') ||
        lower.contains('coklat') ||
        lower.contains('dodol') ||
        lower.contains('getuk') ||
        lower.contains('camilan') ||
        lower.contains('rujak') ||
        lower.contains('buah')) {
      return 'Camilan';
    }
    return 'Makan Siang';
  }

  factory FoodItemModel.fromJson(Map<String, dynamic> json) {
    final nm = (json['name'] as String? ?? '').trim();
    final cal = json['calories'] ?? json['energy'] ?? json['cal'] ?? 0;
    final prot = json['proteins'] ?? json['protein'] ?? 0;
    final carb =
        json['carbohydrate'] ?? json['carbs'] ?? json['carbohydrates'] ?? 0;
    final ft = json['fat'] ?? 0;
    final chol = json['cholesterol'] ?? json['chol'] ?? 0;
    final img = json['image'] ?? json['image_path'] ?? json['imageUrl'] ?? '';
    final cat = (json['category'] as String?)?.trim();

    return FoodItemModel(
      id: (json['id'] as num?)?.toInt(),
      name: nm,
      calories: (cal as num).toInt(),
      protein: (prot as num).toDouble(),
      carbs: (carb as num).toDouble(),
      fat: (ft as num).toDouble(),
      cholesterol: (chol as num).toDouble(),
      category: (cat != null && cat.isNotEmpty) ? cat : _inferCategory(nm),
      imagePath: (img as String).trim(),
    );
  }

  static List<FoodItemModel> listFromJsonString(String jsonString) {
    final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
    return list
        .map((e) => FoodItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
