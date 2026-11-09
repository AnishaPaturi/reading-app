class AudioSettings {
  final double playbackSpeed;
  final Duration? sleepTimerDuration;

  const AudioSettings({
    this.playbackSpeed = 1.0,
    this.sleepTimerDuration,
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
  }) {
    return AudioSettings(
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      sleepTimerDuration:
          clearSleepTimer ? null : (sleepTimerDuration ?? this.sleepTimerDuration),
    );
  }
}
