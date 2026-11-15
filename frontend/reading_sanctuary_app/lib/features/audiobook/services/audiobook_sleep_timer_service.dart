import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum SleepTimerMode {
  duration,
  chapterEnd,
  trackEnd,
}

class AudiobookSleepTimerService {
  Timer? _ticker;
  DateTime? _deadline;
  SleepTimerMode? _activeMode;
  bool _fadeoutEnabled = true;
  double _initialVolume = 1.0;
  bool _isFadingOut = false;
  bool _isExpired = false;

  // Shake detection
  StreamSubscription<UserAccelerometerEvent>? _sensorSubscription;
  DateTime _lastShakeTime = DateTime.now();
  static const double _shakeThreshold = 14.0;
  static const Duration _shakeCooldown = Duration(seconds: 3);

  final _remainingController = StreamController<Duration?>.broadcast();
  final _stateController = StreamController<bool>.broadcast();
  final _nightModeController = StreamController<bool>.broadcast();

  Stream<Duration?> get remainingStream => _remainingController.stream;
  Stream<bool> get isActiveStream => _stateController.stream;
  Stream<bool> get nightModeStream => _nightModeController.stream;

  bool get isActive => _deadline != null && DateTime.now().isBefore(_deadline!);
  bool get isExpiredWaitingForExtend => _isExpired;
  Duration? get remaining => _deadline?.difference(DateTime.now());
  SleepTimerMode? get mode => _activeMode;

  // Callbacks for player actions
  VoidCallback? onTimerExpired;
  void Function(double volume)? onVolumeChanged;
  VoidCallback? onExtendRequested;

  void startDurationTimer(
    Duration duration, {
    bool fadeOut = true,
    double currentVolume = 1.0,
    bool enableShake = true,
    bool enableNightAppearance = true,
  }) {
    cancel();
    _activeMode = SleepTimerMode.duration;
    _fadeoutEnabled = fadeOut;
    _initialVolume = currentVolume;
    _isFadingOut = false;
    _isExpired = false;
    _deadline = DateTime.now().add(duration);

    _stateController.add(true);
    if (enableNightAppearance) {
      _nightModeController.add(true);
    }

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tick();
    });
    _tick();

    if (enableShake) {
      _listenForShake();
    }
  }

  void startChapterEndTimer({
    bool enableNightAppearance = true,
  }) {
    cancel();
    _activeMode = SleepTimerMode.chapterEnd;
    _stateController.add(true);
    if (enableNightAppearance) {
      _nightModeController.add(true);
    }
    _listenForShake();
  }

  void startTrackEndTimer({
    bool enableNightAppearance = true,
  }) {
    cancel();
    _activeMode = SleepTimerMode.trackEnd;
    _stateController.add(true);
    if (enableNightAppearance) {
      _nightModeController.add(true);
    }
    _listenForShake();
  }

  void _tick() {
    if (_deadline == null) return;
    final now = DateTime.now();
    final rem = _deadline!.difference(now);

    if (rem <= Duration.zero) {
      _handleExpiration();
      return;
    }

    _remainingController.add(rem);

    // Fade-out in final 20 seconds
    if (_fadeoutEnabled && rem.inSeconds <= 20) {
      _isFadingOut = true;
      final factor = (rem.inMilliseconds / 20000.0).clamp(0.0, 1.0);
      onVolumeChanged?.call(_initialVolume * factor);
    }
  }

  void _handleExpiration() {
    _ticker?.cancel();
    _remainingController.add(Duration.zero);
    _isExpired = true;

    // Zero volume and pause
    if (_fadeoutEnabled) {
      onVolumeChanged?.call(0.0);
    }
    onTimerExpired?.call();

    // Give a 15-second window for shake-to-extend or button extend
    Timer(const Duration(seconds: 15), () {
      if (_isExpired) {
        cancel();
      }
    });
  }

  void extend({Duration amount = const Duration(minutes: 5)}) {
    _isExpired = false;
    _deadline = DateTime.now().add(amount);
    _isFadingOut = false;

    // Restore volume
    onVolumeChanged?.call(_initialVolume);

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _tick();

    _stateController.add(true);
    onExtendRequested?.call();
  }

  void _listenForShake() {
    _sensorSubscription?.cancel();
    try {
      _sensorSubscription = userAccelerometerEventStream().listen((event) {
        final gX = event.x;
        final gY = event.y;
        final gZ = event.z;
        final magnitude = sqrt(gX * gX + gY * gY + gZ * gZ);

        if (magnitude > _shakeThreshold) {
          final now = DateTime.now();
          if (now.difference(_lastShakeTime) > _shakeCooldown) {
            _lastShakeTime = now;
            debugPrint('Shake detected for sleep timer extension');
            extend();
          }
        }
      });
    } catch (e) {
      debugPrint('Sensor not supported on this platform: $e');
    }
  }

  void cancel() {
    _ticker?.cancel();
    _sensorSubscription?.cancel();
    _ticker = null;
    _sensorSubscription = null;
    _deadline = null;
    _activeMode = null;
    _isExpired = false;

    // Restore volume
    if (_isFadingOut) {
      onVolumeChanged?.call(_initialVolume);
      _isFadingOut = false;
    }

    _remainingController.add(null);
    _stateController.add(false);
    _nightModeController.add(false);
  }

  void dispose() {
    cancel();
    _remainingController.close();
    _stateController.close();
    _nightModeController.close();
  }
}
