import 'dart:math' as math;

import 'goertzel.dart';
import 'modem.dart';

/// Minimum-shift keying: continuous-phase FSK with the minimum tone
/// separation that keeps the two tones orthogonal over one symbol
/// (`delta f = baud / 2`, i.e. carrier +/- baud/4).
class MskModem extends Modem {
  const MskModem();

  double _highFreq(ModemConfig cfg) => cfg.carrierFreq + cfg.baud / 4;
  double _lowFreq(ModemConfig cfg) => cfg.carrierFreq - cfg.baud / 4;

  @override
  List<double> modulate(List<int> bits, ModemConfig cfg) {
    final int sps = cfg.samplesPerSymbol;
    final List<double> out = List<double>.filled(bits.length * sps, 0);
    var idx = 0;
    double phase = 0;
    for (final int bit in bits) {
      final double f = bit == 1 ? _highFreq(cfg) : _lowFreq(cfg);
      final double step = 2 * math.pi * f / cfg.sampleRate;
      for (var n = 0; n < sps; n++) {
        phase += step;
        out[idx++] = cfg.amplitude * math.sin(phase);
      }
    }
    return out;
  }

  @override
  List<int> demodulate(List<double> samples, ModemConfig cfg) {
    final int sps = cfg.samplesPerSymbol;
    final int count = samples.length ~/ sps;
    final double fh = _highFreq(cfg);
    final double fl = _lowFreq(cfg);
    final List<int> bits = <int>[];
    for (var s = 0; s < count; s++) {
      final int start = s * sps;
      final double hi = Goertzel.magnitude(
        samples,
        start,
        sps,
        fh,
        cfg.sampleRate,
      );
      final double lo = Goertzel.magnitude(
        samples,
        start,
        sps,
        fl,
        cfg.sampleRate,
      );
      bits.add(hi >= lo ? 1 : 0);
    }
    return bits;
  }

  @override
  List<IqPoint> iqSamples(List<double> samples, ModemConfig cfg) {
    final int sps = cfg.samplesPerSymbol;
    final int count = samples.length ~/ sps;
    final double fh = _highFreq(cfg);
    final double fl = _lowFreq(cfg);
    final List<IqPoint> pts = <IqPoint>[];
    for (var s = 0; s < count; s++) {
      final int start = s * sps;
      final double hi = Goertzel.magnitude(
        samples,
        start,
        sps,
        fh,
        cfg.sampleRate,
      );
      final double lo = Goertzel.magnitude(
        samples,
        start,
        sps,
        fl,
        cfg.sampleRate,
      );
      pts.add(IqPoint(hi, lo));
    }
    return pts;
  }
}
