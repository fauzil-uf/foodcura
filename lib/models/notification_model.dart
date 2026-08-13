import '../constants/app_date_formatter.dart';

class NotificationModel {
  final int? id;
  final String title;
  final String message;
  final String type; // expiry_warning, nutrition_excess, tips, system
  final String iconType; // warning, restaurant, lightbulb, eco, system_update
  final bool isRead;
  final int? relatedPantryId;
  final DateTime createdAt;

  const NotificationModel({
    this.id,
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

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
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
      title: map['title'] as String,
      message: map['message'] as String,
      type: map['type'] as String,
      iconType: map['icon_type'] as String,
      isRead: (map['is_read'] as int?) == 1,
      relatedPantryId: map['related_pantry_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
