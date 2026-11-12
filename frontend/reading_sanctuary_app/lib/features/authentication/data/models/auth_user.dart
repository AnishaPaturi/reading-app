class AuthUser {
  final String id;
  final String email;
  final String? token;
  final String? displayName;
  final String? profilePictureUrl;
  final String? gender;

  const AuthUser({
    required this.id,
    required this.email,
    this.token,
    this.displayName,
    this.profilePictureUrl,
    this.gender,
  });

  AuthUser copyWith({
    String? id,
    String? email,
    String? token,
    String? displayName,
    String? profilePictureUrl,
    String? gender,
  }) => AuthUser(
    id: id ?? this.id,
    email: email ?? this.email,
    token: token ?? this.token,
    displayName: displayName ?? this.displayName,
    profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    gender: gender ?? this.gender,
  );

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final rawName = json['displayName']?.toString().trim();
    final email = json['email']?.toString().trim() ?? '';
    final emailPrefix = email.contains('@') ? email.split('@').first : email;
    final formattedFallback = emailPrefix.isNotEmpty
        ? (emailPrefix[0].toUpperCase() + (emailPrefix.length > 1 ? emailPrefix.substring(1) : ''))
        : 'Reader';
    final name = (rawName != null && rawName.isNotEmpty) ? rawName : formattedFallback;

    return AuthUser(
      id: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      email: email,
      token: json['accessToken']?.toString() ?? json['token']?.toString(),
      displayName: name,
      profilePictureUrl: json['profilePictureUrl']?.toString(),
      gender: json['gender']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'token': token,
    'displayName': displayName,
    'profilePictureUrl': profilePictureUrl,
    'gender': gender,
  };
}
