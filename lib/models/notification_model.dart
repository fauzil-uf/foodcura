import '../constants/app_date_formatter.dart';

/// Model notifikasi aplikasi (peringatan kedaluwarsa, nutrisi, tips, sistem)
class NotificationModel {
  final int? id;
  final int? userId;
  final String? firestoreId;
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
    this.firestoreId,
    required this.title,
    required this.message,
    required this.type,
    required this.iconType,
    this.isRead = false,
    this.relatedPantryId,
    required this.createdAt,
  });

  /// Format waktu relatif (misal: '5 menit lalu', 'Kemarin')
  String get timeAgo => AppDateFormatter.formatRelativeTime(createdAt);

  /// Cek apakah notifikasi masuk hari ini
  bool get isToday {
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }

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

  NotificationModel copyWith({
    int? id,
    int? userId,
    String? firestoreId,
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
      firestoreId: firestoreId ?? this.firestoreId,
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
