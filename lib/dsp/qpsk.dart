import 'dart:math' as math;

import 'goertzel.dart';
import 'modem.dart';

/// Differential QPSK (2 bits per symbol), Gray-coded:
///
/// | dibit | phase delta |
/// |-------|-------------|
/// |  00   |   +pi/4     |
/// |  01   |  +3pi/4     |
/// |  11   |  -3pi/4     |
/// |  10   |   -pi/4     |
///
/// A leading reference symbol is emitted, so decoding only depends on
/// phase *differences* between consecutive symbols.
class QpskModem extends Modem {
  const QpskModem();

  static final List<double> _deltas = <double>[
    math.pi / 4,
    3 * math.pi / 4,
    -3 * math.pi / 4,
    -math.pi / 4,
  ];

  static const List<List<int>> _codes = <List<int>>[
    <int>[0, 0],
    <int>[0, 1],
    <int>[1, 1],
    <int>[1, 0],
  ];

  static int _codeIndex(int b0, int b1) {
    for (var i = 0; i < _codes.length; i++) {
      if (_codes[i][0] == b0 && _codes[i][1] == b1) return i;
    }
    return 0;
  }

  @override
  List<double> modulate(List<int> bits, ModemConfig cfg) {
    final List<int> padded = List<int>.from(bits);
    if (padded.length.isOdd) padded.add(0);
    final int sps = cfg.samplesPerSymbol;
    final double w = 2 * math.pi * cfg.carrierFreq / cfg.sampleRate;
    final int symbols = padded.length ~/ 2;
    final List<double> out = List<double>.filled((symbols + 1) * sps, 0);
    var idx = 0;
    double phase = 0;

    // Reference symbol.
    for (var n = 0; n < sps; n++) {
      out[idx++] = cfg.amplitude * math.sin(w * n + phase);
    }
    for (var s = 0; s < symbols; s++) {
      phase += _deltas[_codeIndex(padded[2 * s], padded[2 * s + 1])];
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
      var best = 0;
      var bestDist = double.infinity;
      for (var k = 0; k < 4; k++) {
        final double dist = wrapAngle(d - _deltas[k]).abs();
        if (dist < bestDist) {
          bestDist = dist;
          best = k;
        }
      }
      bits.add(_codes[best][0]);
      bits.add(_codes[best][1]);
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
