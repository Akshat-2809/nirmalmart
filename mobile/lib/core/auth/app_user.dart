/// The signed-in customer (backend UserResponse)
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.username,
    this.phone,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        email: j['email'] as String,
        fullName: j['full_name'] as String,
        role: j['role'] as String? ?? 'customer',
        username: j['username'] as String?,
        phone: j['phone'] as String?,
      );

  final int id;
  final String email;
  final String fullName;
  final String role;
  final String? username;
  final String? phone;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;
  bool get isAdmin => role == 'admin';
}
