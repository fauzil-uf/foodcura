/// Model untuk memudahkan mapping key & value ke/dari SQLite (sesuai
/// contoh "UserModelSQL" pada Local Storage II - SQFlite.pdf).
class UserModelSQL {
  final int? id;
  final String name;
  final String email;
  final String password;

  UserModelSQL({
    this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
    };
  }

  factory UserModelSQL.fromMap(Map<String, dynamic> map) {
    return UserModelSQL(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }
}
