import 'dart:math' as math;

import 'goertzel.dart';
import 'modem.dart';

/// Differential BPSK: a **reference symbol** is emitted first, then
/// bit 0 = phase flip of pi, bit 1 = no phase change. Differential
/// encoding makes decoding immune to the unknown absolute phase of the
/// recording path (microphone, speakers, file).
class PskModem extends Modem {
  const PskModem();

  @override
  List<double> modulate(List<int> bits, ModemConfig cfg) {
    final int sps = cfg.samplesPerSymbol;
    final double w = 2 * math.pi * cfg.carrierFreq / cfg.sampleRate;
    final List<double> out = List<double>.filled((bits.length + 1) * sps, 0);
    var idx = 0;
    double phase = 0;

    // Reference symbol.
    for (var n = 0; n < sps; n++) {
      out[idx++] = cfg.amplitude * math.sin(w * n + phase);
    }
    for (final int bit in bits) {
      if (bit == 0) phase += math.pi;
      for (var n = 0; n < sps; n++) {
        out[idx++] = cfg.amplitude * math.sin(w * n + phase);
      }
    }
    return out;
  }

  @override
  List<int> demodulate(List<double> samples, ModemConfig cfg) {
    final int sps = cfg.samplesPerSymbol;
    final int count = samples.length ~/ sps;
    if (count < 2) return const <int>[];
    final List<int> bits = <int>[];
    double prev = Goertzel.phase(
      samples,
      0,
      sps,
      cfg.carrierFreq,
      cfg.sampleRate,
    );
    for (var s = 1; s < count; s++) {
      final double ph = Goertzel.phase(
        samples,
        s * sps,
        sps,
        cfg.carrierFreq,
        cfg.sampleRate,
      );
      final double d = wrapAngle(ph - prev);
      bits.add(d.abs() > math.pi / 2 ? 0 : 1);
      prev = ph;
    }
    return bits;
  }

  @override
  List<IqPoint> iqSamples(List<double> samples, ModemConfig cfg) {
    final int sps = cfg.samplesPerSymbol;
    final int count = samples.length ~/ sps;
    final List<IqPoint> pts = <IqPoint>[];
    for (var s = 0; s < count; s++) {
      final List<double> iq = Goertzel.correlate(
        samples,
        s * sps,
        sps,
        cfg.carrierFreq,
        cfg.sampleRate,
      );
      pts.add(IqPoint(iq[0], iq[1]));
    }
    return pts;
  }
}
