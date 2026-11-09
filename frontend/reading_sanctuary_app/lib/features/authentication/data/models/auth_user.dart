class AuthUser {
  final String id;
  final String email;
  final String? token;
  final String? displayName;

  const AuthUser({
    required this.id,
    required this.email,
    this.token,
    this.displayName,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      token: json['accessToken']?.toString() ?? json['token']?.toString(),
      displayName: json['displayName']?.toString() ?? json['email']?.toString().split('@').first,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'token': token,
      'displayName': displayName,
    };
  }
}
