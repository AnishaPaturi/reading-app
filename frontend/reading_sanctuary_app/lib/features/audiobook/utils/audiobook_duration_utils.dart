import '../data/models/audiobook.dart';

class AudiobookDurationUtils {
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String formatDurationHuman(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  /// Formats byte size into human-readable string (e.g. "14.5 MB", "1.20 GB")
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static AudiobookStatus calculateStatus({
    required int positionMs,
    required int totalDurationMs,
    required bool explicitlyCompleted,
  }) {
    if (explicitlyCompleted) {
      return AudiobookStatus.completed;
    }

    // Small threshold (e.g. within 10 seconds of end or >= 98%)
    if (totalDurationMs > 0) {
      if (positionMs >= totalDurationMs - 10000 || (positionMs / totalDurationMs) >= 0.98) {
        return AudiobookStatus.completed;
      }
    }

    if (positionMs > 5000) {
      return AudiobookStatus.current;
    }

    return AudiobookStatus.notStarted;
  }
}
