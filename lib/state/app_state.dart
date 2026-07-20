import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../codec/encoder.dart';
import '../dsp/modem.dart';
import '../theme/colors.dart';

/// Central application state (Provider).
///
/// Holds the modem / crypto / UI settings and the most recent TX/RX
/// signals so the Analyzer can visualise them.
class AppState extends ChangeNotifier {
  // ---------------------------------------------------------- settings
  Modulation _modulation = Modulation.fsk;
  int _sampleRate = 44100;
  double _baud = 150;
  double _markFreq = 1300;
  double _spaceFreq = 2100;
  double _carrierFreq = 1800;
  double _amplitude = 0.7;
  bool _encryption = false;
  String _cryptoKey = '';
  bool _fec = true;
  int _accentIndex = 0;
  bool _grid = true;
  bool _materialYou = false;

  Modulation get modulation => _modulation;
  int get sampleRate => _sampleRate;
  double get baud => _baud;
  double get markFreq => _markFreq;
  double get spaceFreq => _spaceFreq;
  double get carrierFreq => _carrierFreq;
  double get amplitude => _amplitude;
  bool get encryption => _encryption;
  String get cryptoKey => _cryptoKey;
  bool get fec => _fec;
  int get accentIndex => _accentIndex;
  bool get grid => _grid;
  bool get materialYou => _materialYou;

  Color get accent => CyberColors.accents[_accentIndex];

  ModemConfig get config => ModemConfig(
    sampleRate: _sampleRate,
    baud: _baud,
    markFreq: _markFreq,
    spaceFreq: _spaceFreq,
    carrierFreq: _carrierFreq,
    amplitude: _amplitude,
  );

  Modem get modem => modemFor(_modulation);

  void setModulation(Modulation v) {
    _modulation = v;
    notifyListeners();
  }

  void setSampleRate(int v) {
    _sampleRate = v;
    notifyListeners();
  }

  void setBaud(double v) {
    _baud = v;
    notifyListeners();
  }

  void setMarkFreq(double v) {
    _markFreq = v;
    notifyListeners();
  }

  void setSpaceFreq(double v) {
    _spaceFreq = v;
    notifyListeners();
  }

  void setCarrierFreq(double v) {
    _carrierFreq = v;
    notifyListeners();
  }

  void setAmplitude(double v) {
    _amplitude = v;
    notifyListeners();
  }

  void setEncryption(bool v) {
    _encryption = v;
    notifyListeners();
  }

  void setCryptoKey(String v) {
    _cryptoKey = v;
    notifyListeners();
  }

  void setFec(bool v) {
    _fec = v;
    notifyListeners();
  }

  void setAccentIndex(int v) {
    _accentIndex = v % CyberColors.accents.length;
    notifyListeners();
  }

  void setGrid(bool v) {
    _grid = v;
    notifyListeners();
  }

  void setMaterialYou(bool v) {
    _materialYou = v;
    notifyListeners();
  }

  // -------------------------------------------------------- last signals
  List<double>? txSamples;
  Uint8List? txWav;
  List<int>? txBits;
  EncodeResult? lastEncode;
  List<double>? rxSamples;

  void setTx(
    List<double> samples,
    Uint8List wav,
    List<int> bits,
    EncodeResult encode,
  ) {
    txSamples = samples;
    txWav = wav;
    txBits = bits;
    lastEncode = encode;
    notifyListeners();
  }

  void setRx(List<double> samples) {
    rxSamples = samples;
    notifyListeners();
  }

  /// What the Analyzer falls back to when nothing was received yet.
  List<double>? get lastSignal => rxSamples ?? txSamples;
}
