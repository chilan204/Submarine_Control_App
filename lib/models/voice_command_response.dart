class VoiceCommandDetail {
  final String? action;
  final String? direction;
  final int? value;

  const VoiceCommandDetail({this.action, this.direction, this.value});

  factory VoiceCommandDetail.fromJson(Map<String, dynamic> json) {
    return VoiceCommandDetail(
      action: json['action'] as String?,
      direction: json['direction'] as String?,
      value: json['value'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'action': action,
        'direction': direction,
        'value': value,
      };

  String toCommandText() {
    final sb = StringBuffer();
    if (action != null) sb.write(action);
    if (direction != null) sb.write('_$direction');
    if (value != null) sb.write('_$value');
    return sb.toString();
  }
}

class VoiceCommandResponse {
  final String? status;
  final String? speaker;
  final double? speakerScore;
  final double? verificationScore;
  final String? text;
  final VoiceCommandDetail? command;
  final String? role;

  const VoiceCommandResponse({
    this.status,
    this.speaker,
    this.speakerScore,
    this.verificationScore,
    this.text,
    this.command,
    this.role,
  });

  factory VoiceCommandResponse.fromJson(Map<String, dynamic> json) {
    return VoiceCommandResponse(
      status: json['status'] as String?,
      speaker: (json['speaker_id'] ?? json['speaker']) as String?,
      speakerScore: (json['speaker_score'] as num?)?.toDouble(),
      verificationScore: (json['verification_score'] as num?)?.toDouble(),
      text: json['text'] as String?,
      command: json['command'] != null
          ? VoiceCommandDetail.fromJson(json['command'] as Map<String, dynamic>)
          : null,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'speaker_id': speaker,
        'speaker_score': speakerScore,
        'verification_score': verificationScore,
        'text': text,
        'command': command?.toJson(),
        'role': role,
      };
}

class VoiceCommandResult {
  final bool success;
  final bool unauthorized;
  final VoiceCommandResponse? data;
  final String? message;

  const VoiceCommandResult({
    required this.success,
    this.unauthorized = false,
    this.data,
    this.message,
  });
}
