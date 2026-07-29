class PeyapayAuthToken {
  const PeyapayAuthToken({
    required this.token,
    this.refreshToken,
    this.userId,
    this.username,
    this.roles = const [],
  });

  final String token;
  final String? refreshToken;
  final String? userId;
  final String? username;
  final List<String> roles;

  factory PeyapayAuthToken.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'];
    return PeyapayAuthToken(
      token: json['token']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString(),
      userId: json['userId']?.toString(),
      username: json['username']?.toString(),
      roles: rolesRaw is List ? rolesRaw.map((e) => e.toString()).toList(growable: false) : const [],
    );
  }
}
