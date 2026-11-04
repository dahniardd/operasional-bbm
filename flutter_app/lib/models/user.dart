class User {
  final int id;
  final String username;
  final String role;
  final String? photoUrl;

  User({
    required this.id,
    required this.username,
    required this.role,
    this.photoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String? ?? '-',
      role: json['role'] as String? ?? 'petugas',
      photoUrl: json['photo_url'] as String?,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isPetugas => role == 'petugas';
  bool get canManageHarga => isAdmin || isPetugas;
}
