import '../constants/app_date_formatter.dart';

//// Model notifikasi aplikasi (peringatan kedaluwarsa, nutrisi, tips, sistem)
class NotificationModel {
  /// Tipe-tipe notifikasi
  static const String typeExpiryWarning = 'expiry_warning';
  static const String typeNutritionExcess = 'nutrition_excess';
  static const String typeMealReminder = 'meal_reminder';
  static const String typeTips = 'tips';
  static const String typeSystem = 'system';

  /// Tipe-tipe icon notifikasi
  static const String iconWarning = 'warning';
  static const String iconRestaurant = 'restaurant';
  static const String iconLightbulb = 'lightbulb';
  static const String iconEco = 'eco';
  static const String iconSystemUpdate = 'system_update';
  static const String iconInfo = 'info';

  /// Kategori filter notifikasi
  static const String filterAll = 'all';
  static const String filterUnread = 'unread';
  static const String filterExpiry = 'expiry';
  static const String filterMealReminder = 'meal_reminder';
  static const String filterNutritionExcess = 'nutrition_excess';
  static const String filterInfoTips = 'foodcura';

  final int? id;
  final int? userId;
  final String? firestoreId;
  final String title;
  final String message;
  final String type;
  final String iconType;
  final bool isRead;
  final bool isDeleted;
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
    this.isDeleted = false,
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

  /// Serialisasi ke Map untuk database lokal SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (firestoreId != null) 'firestore_id': firestoreId,
      'title': title,
      'message': message,
      'type': type,
      'icon_type': iconType,
      'is_read': isRead ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'related_pantry_id': relatedPantryId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Serialisasi ke Map untuk Cloud Firestore
  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'message': message,
      'type': type,
      'icon_type': iconType,
      'is_read': isRead,
      'is_deleted': isDeleted,
      'related_pantry_id': relatedPantryId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Factory deserialisasi dari Map SQLite atau JSON dengan parsing tanggal & boolean yang aman
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    final rawCreatedAt = map['created_at'];
    if (rawCreatedAt is DateTime) {
      parsedDate = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      parsedDate = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final rawIsRead = map['is_read'];
    final isReadBool = rawIsRead == 1 || rawIsRead == true;

    final rawIsDeleted = map['is_deleted'];
    final isDeletedBool = rawIsDeleted == 1 || rawIsDeleted == true;

    return NotificationModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      firestoreId: map['firestore_id'] as String?,
      title: (map['title'] ?? '') as String,
      message: (map['message'] ?? '') as String,
      type: (map['type'] ?? typeSystem) as String,
      iconType: (map['icon_type'] ?? iconInfo) as String,
      isRead: isReadBool,
      isDeleted: isDeletedBool,
      relatedPantryId: map['related_pantry_id'] as int?,
      createdAt: parsedDate,
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
    bool? isDeleted,
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
      isDeleted: isDeleted ?? this.isDeleted,
      relatedPantryId: relatedPantryId ?? this.relatedPantryId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
