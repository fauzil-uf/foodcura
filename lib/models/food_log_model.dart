/// Model representasi catatan konsumsi makanan harian pengguna.
///
/// Menyimpan data makanan yang dicatat (nama, waktu, tanggal, tipe makan,
/// kalori, makronutrisi, kolesterol riil, serta catatan tambahan opsional).
class FoodLogModel {
  final int? id;
  final int? userId;
  final String foodName;
  final String mealType; // 'Sarapan', 'Makan Siang', 'Makan Malam', 'Camilan'
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double cholesterol;
  final String imagePath;
  final String time;
  final String date;
  final String? note;

  const FoodLogModel({
    this.id,
    this.userId,
    required this.foodName,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.cholesterol = 0.0,
    required this.imagePath,
    required this.time,
    required this.date,
    this.note,
  });

  /// Mengonversi objek [FoodLogModel] menjadi format [Map] untuk SQLite.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'food_name': foodName,
      'meal_type': mealType,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'cholesterol': cholesterol,
      'image_path': imagePath,
      'time': time,
      'date': date,
      'note': note ?? '',
    };
  }

  /// Membuat instance [FoodLogModel] dari hasil pembacaan baris [Map] SQLite.
  factory FoodLogModel.fromMap(Map<String, dynamic> map) {
    return FoodLogModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      foodName: map['food_name'] as String,
      mealType: map['meal_type'] as String,
      calories: (map['calories'] as num).toInt(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      cholesterol: (map['cholesterol'] as num?)?.toDouble() ?? 0.0,
      imagePath: map['image_path'] as String,
      time: map['time'] as String,
      date: map['date'] as String,
      note: map['note'] as String?,
    );
  }

  /// Membuat salinan objek dengan opsi pembaruan field tertentu.
  FoodLogModel copyWith({
    int? id,
    int? userId,
    String? foodName,
    String? mealType,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? cholesterol,
    String? imagePath,
    String? time,
    String? date,
    String? note,
  }) {
    return FoodLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      foodName: foodName ?? this.foodName,
      mealType: mealType ?? this.mealType,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      cholesterol: cholesterol ?? this.cholesterol,
      imagePath: imagePath ?? this.imagePath,
      time: time ?? this.time,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}
