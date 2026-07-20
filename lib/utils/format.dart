/// Small formatting helpers shared by the screens.
library;

/// `20260717_153042` style timestamp for export file names.
String fileTimestamp([DateTime? t]) {
  final DateTime d = t ?? DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year}${two(d.month)}${two(d.day)}_'
      '${two(d.hour)}${two(d.minute)}${two(d.second)}';
}

/// `HH:MM:SS.mmm` timestamp for terminal log lines.
String logTimestamp([DateTime? t]) {
  final DateTime d = t ?? DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.hour)}:${two(d.minute)}:${two(d.second)}.'
      '${d.millisecond.toString().padLeft(3, '0')}';
}

/// Human readable byte count (`128 B`, `1.4 KB`, `2.1 MB`).
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Human readable duration for sample counts.
String formatDuration(int samples, int sampleRate) {
  final double seconds = samples / sampleRate;
  if (seconds < 1) return '${(seconds * 1000).toStringAsFixed(0)} ms';
  return '${seconds.toStringAsFixed(2)} s';
}
