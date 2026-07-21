/// Respuesta de `POST /api/v1/auth/refresh`: solo el par de tokens, sin datos
/// de usuario (a diferencia de [AuthResponse]).
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresIn: json['expiresIn'] as int,
      );

  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresIn': expiresIn,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthTokens &&
          other.accessToken == accessToken &&
          other.refreshToken == refreshToken &&
          other.expiresIn == expiresIn;

  @override
  int get hashCode => Object.hash(accessToken, refreshToken, expiresIn);

  @override
  String toString() => 'AuthTokens(expiresIn: $expiresIn)';
}
