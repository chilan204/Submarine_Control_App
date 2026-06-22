class PasswordLoginData {
  final String token;
  final String? role;
  final String? username;
  final String? name;
  final int? userId;
  final int? expiresIn;

  const PasswordLoginData({
    required this.token,
    this.role,
    this.username,
    this.name,
    this.userId,
    this.expiresIn,
  });

  factory PasswordLoginData.fromJson(Map<String, dynamic> json) {
    return PasswordLoginData(
      token: json['token'] as String,
      role: json['roleCode'] as String?,
      username: json['username'] as String?,
      name: json['name'] as String?,
      userId: (json['userId'] as num?)?.toInt(),
      expiresIn: (json['expiresIn'] as num?)?.toInt(),
    );
  }
}

class PasswordLoginResult {
  final bool success;
  final PasswordLoginData? data;
  final String? message;

  const PasswordLoginResult({
    required this.success,
    this.data,
    this.message,
  });
}

class VoiceLoginData {
  final bool authenticated;
  final String? token;
  final int? userId;
  final String? username;
  final String? name;
  final String? role;
  final String? speaker;
  final double? verificationScore;
  final String? text;

  const VoiceLoginData({
    required this.authenticated,
    this.token,
    this.userId,
    this.username,
    this.name,
    this.role,
    this.speaker,
    this.verificationScore,
    this.text,
  });

  factory VoiceLoginData.fromJson(Map<String, dynamic> json) {
    return VoiceLoginData(
      authenticated: json['authenticated'] as bool? ?? false,
      token: json['token'] as String?,
      userId: (json['userId'] as num?)?.toInt(),
      username: json['username'] as String?,
      name: json['name'] as String?,
      role: (json['roleCode'] ?? json['role']) as String?,
      speaker: json['speaker'] as String?,
      verificationScore: (json['verificationScore'] as num?)?.toDouble(),
      text: json['text'] as String?,
    );
  }
}

class VoiceLoginResult {
  final bool success;
  final VoiceLoginData? data;
  final String? message;

  const VoiceLoginResult({
    required this.success,
    this.data,
    this.message,
  });
}

/// Retains the alias for backward compatibility with existing imports.
typedef LoginData = PasswordLoginData;
typedef LoginResult = PasswordLoginResult;
