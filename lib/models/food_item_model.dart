import 'dart:convert';

/// Model representasi data katalog makanan dan kandungan nutrisinya.
///
/// Menyimpan informasi kalori, makronutrisi (protein, karbohidrat, lemak),
/// kategori waktu makan, dan path gambar lokal/network.
class FoodItemModel {
  final int? id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String category;
  final String imagePath;

  const FoodItemModel({
    this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.category,
    required this.imagePath,
  });

  /// Estimasi kolesterol (mg) berdasarkan profil makronutrisi lemak & protein
  double get cholesterol => fat * 4.5 + protein * 3.5;

  /// Mengonversi objek [FoodItemModel] menjadi format [Map] untuk SQLite.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
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
      category: map['category'] as String,
      imagePath: map['image_path'] as String,
    );
  }

  static String _inferCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('goreng') ||
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
        lower.contains('buah')) {
      return 'Camilan';
    }
    return 'Makan Siang';
  }

  /// Parse dari satu entry JSON object (Map)
  factory FoodItemModel.fromJson(Map<String, dynamic> json) {
    final nm = (json['name'] as String? ?? '').trim();
    return FoodItemModel(
      id: (json['id'] as num?)?.toInt(),
      name: nm,
      calories: (json['calories'] as num? ?? 0).toInt(),
      protein: (json['proteins'] as num? ?? 0).toDouble(),
      carbs: (json['carbohydrate'] as num? ?? 0).toDouble(),
      fat: (json['fat'] as num? ?? 0).toDouble(),
      category: _inferCategory(nm),
      imagePath: (json['image'] as String? ?? '').trim(),
    );
  }

  /// Parse seluruh file JSON asset menjadi list FoodItemModel
  static List<FoodItemModel> listFromJsonString(String jsonString) {
    final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
    return list
        .map((e) => FoodItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
