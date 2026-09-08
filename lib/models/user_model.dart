/// Model entitas pengguna akun FoodCura di database SQLite lokal.
class UserModelSQL {
  final int? id;
  final String name;
  final String email;
  final String password;
  final String? createdAt;
  final String? firebaseUid;
  final int? ecoPoints;
  final int? streakCount;

  const UserModelSQL({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.createdAt,
    this.firebaseUid,
    this.ecoPoints,
    this.streakCount,
  });

  /// Menandakan apakah pengguna terdaftar dan masuk melalui Google OAuth
  bool get isGoogleAccount =>
      password == 'google_oauth_user' ||
      password.startsWith('GOOGLE_OAUTH_') ||
      password.startsWith('GOOGLE_AUTH_');

  Map<String, dynamic> toFirestore() {
    return {
      if (firebaseUid != null) 'uid': firebaseUid,
      'name': name,
      'email': email,
      if (ecoPoints != null) 'eco_points': ecoPoints,
      if (streakCount != null) 'streak_count': streakCount,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'password': password,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  factory UserModelSQL.fromMap(Map<String, dynamic> map) {
    return UserModelSQL(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      createdAt: map['created_at'] as String?,
      firebaseUid: map['firebase_uid'] as String? ?? map['uid'] as String?,
      ecoPoints: (map['eco_points'] as num?)?.toInt(),
      streakCount: (map['streak_count'] as num?)?.toInt(),
    );
  }

  UserModelSQL copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? createdAt,
    String? firebaseUid,
    int? ecoPoints,
    int? streakCount,
  }) {
    return UserModelSQL(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      ecoPoints: ecoPoints ?? this.ecoPoints,
      streakCount: streakCount ?? this.streakCount,
    );
  }
}
