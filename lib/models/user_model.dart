/// Model entitas pengguna akun FoodCura di database SQLite lokal.
class UserModelSQL {
  final int? id;
  final String name;
  final String email;
  final String password;
  final String? createdAt;

  const UserModelSQL({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.createdAt,
  });

  /// Menandakan apakah pengguna terdaftar dan masuk melalui Google OAuth
  bool get isGoogleAccount => password == 'google_oauth_user';

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
    );
  }

  UserModelSQL copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? createdAt,
  }) {
    return UserModelSQL(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
