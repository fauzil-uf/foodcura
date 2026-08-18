/// Model representasi data pengguna pada database SQLite.
///
/// Digunakan untuk proses autentikasi (Registrasi, Login) dan sinkronisasi
/// data profil (nama, email, avatar dinamis).
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

  /// Mengonversi objek [UserModelSQL] menjadi format [Map] untuk disimpan ke SQLite.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'password': password,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  /// Membuat instance [UserModelSQL] dari hasil pembacaan baris [Map] SQLite.
  factory UserModelSQL.fromMap(Map<String, dynamic> map) {
    return UserModelSQL(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      createdAt: map['created_at'] as String?,
    );
  }

  /// Membuat salinan objek dengan opsi pembaruan field tertentu.
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
