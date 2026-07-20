import 'dart:math' as math;

import 'goertzel.dart';
import 'modem.dart';

/// Binary FSK: bit 1 -> [ModemConfig.markFreq], bit 0 ->
/// [ModemConfig.spaceFreq]. Phase restarts at zero on every symbol.
class FskModem extends Modem {
  const FskModem();

  @override
  List<double> modulate(List<int> bits, ModemConfig cfg) {
    final int sps = cfg.samplesPerSymbol;
    final List<double> out = List<double>.filled(bits.length * sps, 0);
    var idx = 0;
    for (final int bit in bits) {
      final double f = bit == 1 ? cfg.markFreq : cfg.spaceFreq;
      final double w = 2 * math.pi * f / cfg.sampleRate;
      for (var n = 0; n < sps; n++) {
        out[idx++] = cfg.amplitude * math.sin(w * n);
      }
    }
    return out;
  }

  @override
  List<int> demodulate(List<double> samples, ModemConfig cfg) {
    final int sps = cfg.samplesPerSymbol;
    final int count = samples.length ~/ sps;
    final List<int> bits = <int>[];
    for (var s = 0; s < count; s++) {
      final int start = s * sps;
      final double mark = Goertzel.magnitude(
        samples,
        start,
        sps,
        cfg.markFreq,
        cfg.sampleRate,
      );
      final double space = Goertzel.magnitude(
        samples,
        start,
        sps,
        cfg.spaceFreq,
        cfg.sampleRate,
      );
      bits.add(mark >= space ? 1 : 0);
    }
    return bits;
  }

  /// For the constellation view: (mark energy, space energy) per symbol —
  /// produces two well separated clusters.
  @override
  List<IqPoint> iqSamples(List<double> samples, ModemConfig cfg) {
    final int sps = cfg.samplesPerSymbol;
    final int count = samples.length ~/ sps;
    final List<IqPoint> pts = <IqPoint>[];
    for (var s = 0; s < count; s++) {
      final int start = s * sps;
      final double mark = Goertzel.magnitude(
        samples,
        start,
        sps,
        cfg.markFreq,
        cfg.sampleRate,
      );
      final double space = Goertzel.magnitude(
        samples,
        start,
        sps,
        cfg.spaceFreq,
        cfg.sampleRate,
      );
      pts.add(IqPoint(mark, space));
    }
    return pts;
  }
}
