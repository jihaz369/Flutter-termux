import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/recorder.dart';
import '../dsp/fft.dart';
import '../dsp/modem.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../theme/fonts.dart';
import '../utils/format.dart';
import '../widgets/constellation.dart';
import '../widgets/neon_card.dart';
import '../widgets/spectrum.dart';
import '../widgets/toggle_switch.dart';
import '../widgets/waveform.dart';

/// Signal analyzer: spectrum (FFT), constellation and oscilloscope over
/// the last TX/RX signal — or a live microphone feed.
class AnalyzerScreen extends StatefulWidget {
  const AnalyzerScreen({super.key});

  @override
  State<AnalyzerScreen> createState() => _AnalyzerScreenState();
}

class _AnalyzerScreenState extends State<AnalyzerScreen> {
  static const int _fftSize = 2048;
  static const int _liveWindow = 8192;

  final MicRecorder _mic = MicRecorder();
  final List<double> _live = <double>[];

  StreamSubscription<Uint8List>? _sub;
  Timer? _ticker;
  bool _liveMode = false;
  int _tab = 0; // 0 spectrum, 1 constellation, 2 scope

  @override
  void dispose() {
    _ticker?.cancel();
    _sub?.cancel();
    _mic.dispose();
    super.dispose();
  }

  Future<void> _toggleLive(bool on) async {
    final AppState app = context.read<AppState>();
    if (on) {
      if (!await _mic.requestPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('microphone permission denied')),
          );
        }
        return;
      }
      _live.clear();
      final Stream<Uint8List> stream = await _mic.start(
        sampleRate: app.sampleRate,
      );
      _sub = stream.listen((Uint8List chunk) {
        _live.addAll(MicRecorder.pcm16ToSamples(chunk));
        if (_live.length > _liveWindow) {
          _live.removeRange(0, _live.length - _liveWindow);
        }
      });
      _ticker = Timer.periodic(const Duration(milliseconds: 90), (_) {
        if (mounted) setState(() {});
      });
      setState(() => _liveMode = true);
    } else {
      _ticker?.cancel();
      _ticker = null;
      await _sub?.cancel();
      _sub = null;
      await _mic.stop();
      setState(() => _liveMode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final Color accent = app.accent;

    final List<double>? stored = app.lastSignal;
    final List<double>? source = _liveMode ? _live : stored;
    final String sourceLabel = _liveMode
        ? 'LIVE MIC'
        : app.rxSamples != null
        ? 'RX SIGNAL'
        : app.txSamples != null
        ? 'TX SIGNAL'
        : 'NO SIGNAL';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        NeonCard(
          title: 'Analyzer',
          color: accent,
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  _tabButton(0, 'SPECTRUM', accent),
                  const SizedBox(width: 8),
                  _tabButton(1, 'IQ CONST', accent),
                  const SizedBox(width: 8),
                  _tabButton(2, 'SCOPE', accent),
                ],
              ),
              const SizedBox(height: 8),
              NeonToggle(
                label: 'Live microphone',
                subtitle: _liveMode
                    ? '${_live.length} samples in window'
                    : 'analyse last TX / RX signal instead',
                value: _liveMode,
                color: accent,
                onChanged: _toggleLive,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SRC: $sourceLabel · ${source?.length ?? 0} samples · '
                  '${app.sampleRate} Hz · ${app.modulation.label}',
                  style: CyberFonts.terminal(
                    size: 11,
                    color: CyberColors.textDim,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        NeonCard(
          title: switch (_tab) {
            0 => 'Spectrum Analyzer',
            1 => 'Constellation',
            _ => 'Oscilloscope',
          },
          color: accent,
          child: _buildView(source, app),
        ),
        const SizedBox(height: 16),
        NeonCard(
          title: 'Signal Info',
          color: CyberColors.neonAmber,
          child: _buildInfo(source, app),
        ),
      ],
    );
  }

  Widget _tabButton(int index, String label, Color accent) {
    final bool selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? accent.withOpacity(0.16) : CyberColors.surfaceAlt,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? accent : CyberColors.gridLine,
              width: selected ? 1.3 : 1,
            ),
            boxShadow: selected ? CyberColors.glow(accent, blur: 8) : null,
          ),
          child: Center(
            child: Text(
              label,
              style: CyberFonts.terminal(
                size: 11,
                letterSpacing: 1.5,
                color: selected ? accent : CyberColors.textDim,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildView(List<double>? source, AppState app) {
    if (source == null || source.length < 16) {
      return Text(
        '// no signal — generate, receive or enable live mic',
        style: CyberFonts.terminal(
          size: 12,
          color: CyberColors.textDim.withOpacity(0.6),
        ),
      );
    }
    switch (_tab) {
      case 0:
        final List<double> mags = Fft.magnitudes(source, maxN: _fftSize);
        return SpectrumView(magnitudes: mags, color: app.accent);
      case 1:
        // Limit to ~300 symbols so the painter stays light.
        final int maxSamples = 300 * app.config.samplesPerSymbol;
        final List<double> slice = source.length > maxSamples
            ? source.sublist(0, maxSamples)
            : source;
        final List<IqPoint> pts = app.modem.iqSamples(slice, app.config);
        return ConstellationView(points: pts, color: CyberColors.neonMagenta);
      default:
        return Oscilloscope(
          samples: source.length > 4096 ? source.sublist(0, 4096) : source,
          color: app.accent,
          height: 160,
        );
    }
  }

  Widget _buildInfo(List<double>? source, AppState app) {
    final int n = source?.length ?? 0;
    final double freqRes = app.sampleRate / _fftSize;
    final rows = <List<String>>[
      <String>['samples', '$n'],
      <String>['duration', formatDuration(n, app.sampleRate)],
      <String>['fft size', '$_fftSize (${freqRes.toStringAsFixed(1)} Hz/bin)'],
      <String>[
        'symbol rate',
        '${app.config.baud.toStringAsFixed(0)} baud '
            '(${app.config.samplesPerSymbol} samples/symbol)',
      ],
      <String>[
        'tones',
        app.modulation == Modulation.psk || app.modulation == Modulation.qpsk
            ? 'carrier ${app.config.carrierFreq.toStringAsFixed(0)} Hz'
            : app.modulation == Modulation.msk
            ? '${(app.config.carrierFreq - app.config.baud / 4).toStringAsFixed(1)} / '
                  '${(app.config.carrierFreq + app.config.baud / 4).toStringAsFixed(1)} Hz'
            : 'mark ${app.config.markFreq.toStringAsFixed(0)} / '
                  'space ${app.config.spaceFreq.toStringAsFixed(0)} Hz',
      ],
    ];
    return Column(
      children: <Widget>[
        for (final List<String> row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 110,
                  child: Text(
                    row[0].toUpperCase(),
                    style: CyberFonts.terminal(
                      size: 12,
                      color: CyberColors.textDim,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    row[1],
                    style: CyberFonts.terminal(
                      size: 12,
                      color: CyberColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
