import '../constants/app_date_formatter.dart';

/// Model representasi notifikasi dalam aplikasi FoodCura.
///
/// Mendukung berbagai tipe notifikasi:
/// - `expiry_warning`: Pengingat masa kadaluwarsa bahan makanan di Pantry.
/// - `nutrition_excess`: Peringatan kelebihan batas asupan nutrisi harian.
/// - `tips`: Edukasi & tips pencegahan food waste.
/// - `system`: Informasi pembaruan sistem dan pencapaian.
class NotificationModel {
  final int? id;
  final int? userId;
  final String title;
  final String message;
  final String type; // expiry_warning, nutrition_excess, tips, system
  final String iconType; // warning, restaurant, lightbulb, eco, system_update
  final bool isRead;
  final int? relatedPantryId;
  final DateTime createdAt;

  const NotificationModel({
    this.id,
    this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.iconType,
    this.isRead = false,
    this.relatedPantryId,
    required this.createdAt,
  });

  /// Tampilkan waktu relatif presisi sampai menit
  String get timeAgo => AppDateFormatter.formatRelativeTime(createdAt);

  /// Apakah notifikasi dibuat hari ini
  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }

  /// Mengonversi objek [NotificationModel] menjadi format [Map] untuk SQLite.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'icon_type': iconType,
      'is_read': isRead ? 1 : 0,
      'related_pantry_id': relatedPantryId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Membuat instance [NotificationModel] dari hasil pembacaan baris [Map] SQLite.
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      title: map['title'] as String,
      message: map['message'] as String,
      type: map['type'] as String,
      iconType: map['icon_type'] as String,
      isRead: (map['is_read'] as int?) == 1,
      relatedPantryId: map['related_pantry_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Membuat salinan objek dengan opsi pembaruan field tertentu.
  NotificationModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? message,
    String? type,
    String? iconType,
    bool? isRead,
    int? relatedPantryId,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      iconType: iconType ?? this.iconType,
      isRead: isRead ?? this.isRead,
      relatedPantryId: relatedPantryId ?? this.relatedPantryId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
