import 'dart:math' as math;

/// Iterative radix-2 FFT (native Dart, no external packages).
class Fft {
  Fft._();

  static int nextPow2(int n) {
    var p = 1;
    while (p < n) p <<= 1;
    return p;
  }

  /// In-place Cooley-Tukey FFT. `re` / `im` must have equal power-of-two
  /// lengths.
  static void transform(List<double> re, List<double> im) {
    final int n = re.length;

    // Bit-reversal permutation.
    var j = 0;
    for (var i = 1; i < n; i++) {
      var bit = n >> 1;
      while (j & bit != 0) {
        j ^= bit;
        bit >>= 1;
      }
      j ^= bit;
      if (i < j) {
        final double tr = re[i];
        re[i] = re[j];
        re[j] = tr;
        final double ti = im[i];
        im[i] = im[j];
        im[j] = ti;
      }
    }

    // Butterflies.
    for (var len = 2; len <= n; len <<= 1) {
      final double ang = -2 * math.pi / len;
      final double wRe = math.cos(ang);
      final double wIm = math.sin(ang);
      final int half = len >> 1;
      for (var i = 0; i < n; i += len) {
        var curRe = 1.0, curIm = 0.0;
        for (var k = 0; k < half; k++) {
          final int a = i + k;
          final int b = i + k + half;
          final double uRe = re[a], uIm = im[a];
          final double vRe = re[b] * curRe - im[b] * curIm;
          final double vIm = re[b] * curIm + im[b] * curRe;
          re[a] = uRe + vRe;
          im[a] = uIm + vIm;
          re[b] = uRe - vRe;
          im[b] = uIm - vIm;
          final double nRe = curRe * wRe - curIm * wIm;
          curIm = curRe * wIm + curIm * wRe;
          curRe = nRe;
        }
      }
    }
  }

  /// One-sided magnitude spectrum of [samples] (Hann windowed by default).
  ///
  /// The transform size is `min(nextPow2(samples.length), maxN)`; when the
  /// input is longer than [maxN] the *first* [maxN] samples are used.
  /// Returns `N/2` normalised magnitudes (a full-scale sine peaks near 1).
  static List<double> magnitudes(
    List<double> samples, {
    bool window = true,
    int maxN = 4096,
  }) {
    var n = nextPow2(math.max(2, samples.length));
    if (n > maxN) n = maxN;
    final List<double> re = List<double>.filled(n, 0);
    final List<double> im = List<double>.filled(n, 0);
    final int count = math.min(samples.length, n);
    for (var i = 0; i < count; i++) {
      final double w = window
          ? 0.5 * (1 - math.cos(2 * math.pi * i / (count - 1)))
          : 1.0;
      re[i] = samples[i] * w;
    }
    transform(re, im);
    final int half = n >> 1;
    final List<double> mags = List<double>.filled(half, 0);
    for (var i = 0; i < half; i++) {
      mags[i] = math.sqrt(re[i] * re[i] + im[i] * im[i]) * 2.0 / n;
    }
    return mags;
  }
}
