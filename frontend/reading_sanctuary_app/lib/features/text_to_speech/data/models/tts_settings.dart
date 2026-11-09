class TtsSettings {
  final String? voiceName;
  final String? voiceLocale;
  final double speechRate;
  final double pitch;

  const TtsSettings({
    this.voiceName,
    this.voiceLocale,
    this.speechRate = 1.0,
    this.pitch = 1.0,
  });

  static const List<double> availableRates = [
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
  ];

  static const List<double> availablePitches = [
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
  ];

  TtsSettings copyWith({
    String? voiceName,
    String? voiceLocale,
    double? speechRate,
    double? pitch,
  }) {
    return TtsSettings(
      voiceName: voiceName ?? this.voiceName,
      voiceLocale: voiceLocale ?? this.voiceLocale,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voiceName': voiceName,
      'voiceLocale': voiceLocale,
      'speechRate': speechRate,
      'pitch': pitch,
    };
  }

  factory TtsSettings.fromJson(Map<String, dynamic> json) {
    return TtsSettings(
      voiceName: json['voiceName'] as String?,
      voiceLocale: json['voiceLocale'] as String?,
      speechRate: (json['speechRate'] as num?)?.toDouble() ?? 1.0,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
