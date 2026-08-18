/// Model representasi bahan makanan yang disimpan di dalam Pantry/Inventaris.
///
/// Menyediakan kalkulasi dinamis untuk:
/// - [daysUntilExpiry]: Sisa hari menuju tanggal kedaluwarsa.
/// - [expiryStatus]: Kategori status ('expired', 'urgent', 'segera', 'aman').
/// - [expiryProgress]: Nilai persentase (0.0 - 1.0) untuk progress bar visual.
/// - [quantityDisplay]: Format display jumlah, unit, dan lokasi penyimpanan.
class PantryItemModel {
  final int? id;
  final String name;
  final double quantity;
  final String unit;
  final String storage;
  final DateTime expiryDate;
  final String? imageUrl;
  final bool isUsed;
  final DateTime createdAt;

  const PantryItemModel({
    this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.storage,
    required this.expiryDate,
    this.imageUrl,
    this.isUsed = false,
    required this.createdAt,
  });

  /// Hitung sisa hari sampai kadaluwarsa dari sekarang
  int get daysUntilExpiry {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  /// Status kadaluwarsa: 'expired', 'urgent', 'segera', 'aman'
  String get expiryStatus {
    final days = daysUntilExpiry;
    if (days < 0) return 'expired';
    if (days <= 2) return 'urgent';
    if (days <= 5) return 'segera';
    return 'aman';
  }

  /// Persentase progress bar (0.0 - 1.0), semakin dekat expired semakin penuh
  double get expiryProgress {
    final days = daysUntilExpiry;
    if (days <= 0) return 1.0;
    if (days >= 10) return 0.1;
    return 1.0 - (days / 10.0);
  }

  /// Format display jumlah + unit + storage
  String get quantityDisplay {
    final qty = quantity % 1 == 0
        ? quantity.toInt().toString()
        : quantity.toString();
    return '$qty $unit · $storage';
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'storage': storage,
      'expiry_date': expiryDate.toIso8601String(),
      'image_url': imageUrl ?? '',
      'is_used': isUsed ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PantryItemModel.fromMap(Map<String, dynamic> map) {
    return PantryItemModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      storage: map['storage'] as String,
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      imageUrl: (map['image_url'] as String?)?.isEmpty == true
          ? null
          : map['image_url'] as String?,
      isUsed: (map['is_used'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  PantryItemModel copyWith({
    int? id,
    String? name,
    double? quantity,
    String? unit,
    String? storage,
    DateTime? expiryDate,
    String? imageUrl,
    bool? isUsed,
    DateTime? createdAt,
  }) {
    return PantryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      storage: storage ?? this.storage,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrl: imageUrl ?? this.imageUrl,
      isUsed: isUsed ?? this.isUsed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
