class AudioSettings {
  final double playbackSpeed;
  final Duration? sleepTimerDuration;
  final bool silenceSkipping;
  final bool volumeBoost;
  final int autoRewindSeconds;
  final bool shakeToExtend;
  final bool nightAppearance;
  final bool stopAtChapterEnd;
  final int? customAccentColor;

  const AudioSettings({
    this.playbackSpeed = 1.0,
    this.sleepTimerDuration,
    this.silenceSkipping = false,
    this.volumeBoost = false,
    this.autoRewindSeconds = 3,
    this.shakeToExtend = true,
    this.nightAppearance = false,
    this.stopAtChapterEnd = false,
    this.customAccentColor,
  });

  static const List<double> availableSpeeds = [
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
    2.5,
    3.0,
  ];

  AudioSettings copyWith({
    double? playbackSpeed,
    Duration? sleepTimerDuration,
    bool clearSleepTimer = false,
    bool? silenceSkipping,
    bool? volumeBoost,
    int? autoRewindSeconds,
    bool? shakeToExtend,
    bool? nightAppearance,
    bool? stopAtChapterEnd,
    int? customAccentColor,
    bool clearCustomAccentColor = false,
  }) {
    return AudioSettings(
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      sleepTimerDuration:
          clearSleepTimer ? null : (sleepTimerDuration ?? this.sleepTimerDuration),
      silenceSkipping: silenceSkipping ?? this.silenceSkipping,
      volumeBoost: volumeBoost ?? this.volumeBoost,
      autoRewindSeconds: autoRewindSeconds ?? this.autoRewindSeconds,
      shakeToExtend: shakeToExtend ?? this.shakeToExtend,
      nightAppearance: nightAppearance ?? this.nightAppearance,
      stopAtChapterEnd: stopAtChapterEnd ?? this.stopAtChapterEnd,
      customAccentColor: clearCustomAccentColor
          ? null
          : (customAccentColor ?? this.customAccentColor),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playbackSpeed': playbackSpeed,
      if (sleepTimerDuration != null)
        'sleepTimerMinutes': sleepTimerDuration!.inMinutes,
      'silenceSkipping': silenceSkipping,
      'volumeBoost': volumeBoost,
      'autoRewindSeconds': autoRewindSeconds,
      'shakeToExtend': shakeToExtend,
      'nightAppearance': nightAppearance,
      'stopAtChapterEnd': stopAtChapterEnd,
      if (customAccentColor != null) 'customAccentColor': customAccentColor,
    };
  }

  factory AudioSettings.fromJson(Map<String, dynamic> json) {
    return AudioSettings(
      playbackSpeed: (json['playbackSpeed'] as num?)?.toDouble() ?? 1.0,
      sleepTimerDuration: json['sleepTimerMinutes'] != null
          ? Duration(minutes: (json['sleepTimerMinutes'] as num).toInt())
          : null,
      silenceSkipping: json['silenceSkipping'] as bool? ?? false,
      volumeBoost: json['volumeBoost'] as bool? ?? false,
      autoRewindSeconds: (json['autoRewindSeconds'] as num?)?.toInt() ?? 3,
      shakeToExtend: json['shakeToExtend'] as bool? ?? true,
      nightAppearance: json['nightAppearance'] as bool? ?? false,
      stopAtChapterEnd: json['stopAtChapterEnd'] as bool? ?? false,
      customAccentColor: (json['customAccentColor'] as num?)?.toInt(),
    );
  }
}
