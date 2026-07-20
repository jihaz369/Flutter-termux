import 'dart:math' as math;

/// Goertzel single-frequency detection and complex correlation.
///
/// Convention used everywhere in HoloRadio:
///   I =  (2/N) * sum( x[n] * cos(w n) )
///   Q = -(2/N) * sum( x[n] * sin(w n) )
/// so for a signal `sin(w n + phi)` the recovered phase is
/// `atan2(Q, I) == phi - pi/2`, and *differences* of that phase between
/// consecutive symbols equal the true phase differences.
class Goertzel {
  Goertzel._();

  /// Magnitude of the [freq] component inside `samples[start .. start+length]`,
  /// normalised by window length.
  static double magnitude(
    List<double> samples,
    int start,
    int length,
    double freq,
    int sampleRate,
  ) {
    final double w = 2 * math.pi * freq / sampleRate;
    final double coeff = 2 * math.cos(w);
    final int end = math.min(start + length, samples.length);
    double s1 = 0, s2 = 0;
    for (int i = start; i < end; i++) {
      final double s0 = samples[i] + coeff * s1 - s2;
      s2 = s1;
      s1 = s0;
    }
    final int n = math.max(1, end - start);
    return math.sqrt(math.max(0.0, s1 * s1 + s2 * s2 - coeff * s1 * s2)) / n;
  }

  /// Complex correlation of the window with the complex exponential at
  /// [freq]; returns `[I, Q]`, normalised so a full-scale matching tone
  /// yields a magnitude near its amplitude.
  static List<double> correlate(
    List<double> samples,
    int start,
    int length,
    double freq,
    int sampleRate,
  ) {
    final double w = 2 * math.pi * freq / sampleRate;
    final int end = math.min(start + length, samples.length);
    double iAcc = 0, qAcc = 0;
    for (int n = start; n < end; n++) {
      final double t = w * (n - start);
      iAcc += samples[n] * math.cos(t);
      qAcc -= samples[n] * math.sin(t);
    }
    final double scale = 2.0 / math.max(1, end - start);
    return <double>[iAcc * scale, qAcc * scale];
  }

  /// Phase of the [freq] component (see class doc for the convention).
  static double phase(
    List<double> samples,
    int start,
    int length,
    double freq,
    int sampleRate,
  ) {
    final List<double> iq = correlate(samples, start, length, freq, sampleRate);
    return math.atan2(iq[1], iq[0]);
  }
}
