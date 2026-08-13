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

  static List<String> _parseCsvFields(String line) {
    final fields = <String>[];
    final sb = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(sb.toString().trim());
        sb.clear();
      } else {
        sb.write(char);
      }
    }
    fields.add(sb.toString().trim());
    return fields;
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

  factory FoodItemModel.fromCsvLine(String line) {
    final parts = _parseCsvFields(line);
    if (parts.length >= 7) {
      // Check if schema is id,calories,proteins,fat,carbohydrate,name,image
      final secondPartVal = double.tryParse(parts[1]);
      if (secondPartVal != null) {
        final rawId = int.tryParse(parts[0]);
        final cals = (double.tryParse(parts[1]) ?? 0).toInt();
        final prot = double.tryParse(parts[2]) ?? 0.0;
        final ft = double.tryParse(parts[3]) ?? 0.0;
        final crbs = double.tryParse(parts[4]) ?? 0.0;
        final nm = parts[5].replaceAll('"', '').trim();
        final img = parts[6].replaceAll('"', '').trim();
        final cat = _inferCategory(nm);

        return FoodItemModel(
          id: rawId,
          name: nm,
          calories: cals,
          protein: prot,
          carbs: crbs,
          fat: ft,
          category: cat,
          imagePath: img,
        );
      }
    }

    // Older schema fallback: id,name,calories,protein,carbs,fat,category,image_path
    final rawId = int.tryParse(parts[0]);
    final nm = parts.length > 1 ? parts[1] : 'Makanan';
    final cals = parts.length > 2 ? (double.tryParse(parts[2]) ?? 0).toInt() : 0;
    final prot = parts.length > 3 ? (double.tryParse(parts[3]) ?? 0) : 0.0;
    final crbs = parts.length > 4 ? (double.tryParse(parts[4]) ?? 0) : 0.0;
    final ft = parts.length > 5 ? (double.tryParse(parts[5]) ?? 0) : 0.0;
    final cat = parts.length > 6 ? parts[6] : 'Makan Siang';
    final img = parts.length > 7 ? parts[7] : 'assets/images/food/nasi.png';

    return FoodItemModel(
      id: rawId,
      name: nm,
      calories: cals,
      protein: prot,
      carbs: crbs,
      fat: ft,
      category: cat,
      imagePath: img,
    );
  }
}
