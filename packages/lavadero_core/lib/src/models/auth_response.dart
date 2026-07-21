import 'user_profile.dart';

/// Respuesta de `POST /api/v1/auth/login` y `POST /api/v1/auth/register`.
class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresIn: json['expiresIn'] as int,
        user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
      );

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserProfile user;

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresIn': expiresIn,
        'user': user.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthResponse &&
          other.accessToken == accessToken &&
          other.refreshToken == refreshToken &&
          other.expiresIn == expiresIn &&
          other.user == user;

  @override
  int get hashCode => Object.hash(accessToken, refreshToken, expiresIn, user);

  @override
  String toString() => 'AuthResponse(user: $user)';
}
