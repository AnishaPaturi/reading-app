class AuthUser {
  final String id;
  final String email;
  final String? token;
  final String? displayName;
  final String? profilePictureUrl;

  const AuthUser({required this.id, required this.email, this.token,
    this.displayName, this.profilePictureUrl});

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['userId']?.toString() ?? json['id']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    token: json['accessToken']?.toString() ?? json['token']?.toString(),
    displayName: json['displayName']?.toString()
        ?? json['email']?.toString().split('@').first,
    profilePictureUrl: json['profilePictureUrl']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'email': email, 'token': token,
    'displayName': displayName, 'profilePictureUrl': profilePictureUrl,
  };
}
