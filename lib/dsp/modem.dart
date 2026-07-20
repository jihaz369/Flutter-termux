import 'dart:math' as math;

import 'afsk.dart';
import 'fsk.dart';
import 'msk.dart';
import 'psk.dart';
import 'qpsk.dart';

/// Supported modulation schemes.
enum Modulation { fsk, afsk, psk, qpsk, msk }

extension ModulationInfo on Modulation {
  String get label => switch (this) {
    Modulation.fsk => 'FSK',
    Modulation.afsk => 'AFSK',
    Modulation.psk => 'BPSK',
    Modulation.qpsk => 'QPSK',
    Modulation.msk => 'MSK',
  };

  String get description => switch (this) {
    Modulation.fsk => 'Binary frequency-shift keying (two tones)',
    Modulation.afsk => 'Audio FSK, continuous phase (Bell-202 style)',
    Modulation.psk => 'Differential binary phase-shift keying',
    Modulation.qpsk => 'Differential quadrature PSK (2 bits/symbol)',
    Modulation.msk => 'Minimum-shift keying, continuous phase',
  };

  int get bitsPerSymbol => this == Modulation.qpsk ? 2 : 1;
}

/// Everything a modem needs to know about the channel.
class ModemConfig {
  final int sampleRate;

  /// Symbols per second.
  final double baud;

  /// FSK tone for bit 1 (Hz).
  final double markFreq;

  /// FSK tone for bit 0 (Hz).
  final double spaceFreq;

  /// Carrier / center frequency for PSK, QPSK and MSK (Hz).
  final double carrierFreq;

  /// Output amplitude 0..1.
  final double amplitude;

  const ModemConfig({
    this.sampleRate = 44100,
    this.baud = 150,
    this.markFreq = 1300,
    this.spaceFreq = 2100,
    this.carrierFreq = 1800,
    this.amplitude = 0.7,
  });

  int get samplesPerSymbol => math.max(8, (sampleRate / baud).round());

  ModemConfig copyWith({
    int? sampleRate,
    double? baud,
    double? markFreq,
    double? spaceFreq,
    double? carrierFreq,
    double? amplitude,
  }) => ModemConfig(
    sampleRate: sampleRate ?? this.sampleRate,
    baud: baud ?? this.baud,
    markFreq: markFreq ?? this.markFreq,
    spaceFreq: spaceFreq ?? this.spaceFreq,
    carrierFreq: carrierFreq ?? this.carrierFreq,
    amplitude: amplitude ?? this.amplitude,
  );

  @override
  String toString() =>
      'sr=$sampleRate baud=$baud mark=$markFreq space=$spaceFreq '
      'carrier=$carrierFreq amp=$amplitude';
}

/// One complex baseband sample (I/Q pair) for the constellation view.
class IqPoint {
  final double i;
  final double q;
  const IqPoint(this.i, this.q);
}

/// Wraps an angle to (-pi, pi].
double wrapAngle(double a) {
  var d = a;
  while (d > math.pi) d -= 2 * math.pi;
  while (d <= -math.pi) d += 2 * math.pi;
  return d;
}

/// Base class for all modems.
abstract class Modem {
  const Modem();

  /// Bits (0/1) -> audio samples in [-amplitude, amplitude].
  List<double> modulate(List<int> bits, ModemConfig cfg);

  /// Audio samples -> bits (0/1).
  List<int> demodulate(List<double> samples, ModemConfig cfg);

  /// Per-symbol complex points for the constellation viewer.
  /// Modems without a native I/Q representation may return energy pairs.
  List<IqPoint> iqSamples(List<double> samples, ModemConfig cfg) =>
      const <IqPoint>[];
}

/// Factory for the currently selected modulation.
Modem modemFor(Modulation m) => switch (m) {
  Modulation.fsk => const FskModem(),
  Modulation.afsk => const AfskModem(),
  Modulation.psk => const PskModem(),
  Modulation.qpsk => const QpskModem(),
  Modulation.msk => const MskModem(),
};
