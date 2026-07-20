import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/recorder.dart';
import '../audio/wav_parser.dart';
import '../codec/decoder.dart';
import '../codec/frame_builder.dart';
import '../state/app_state.dart';
import '../storage/file_manager.dart';
import '../theme/colors.dart';
import '../theme/fonts.dart';
import '../utils/format.dart';
import '../widgets/neon_button.dart';
import '../widgets/neon_card.dart';
import '../widgets/terminal_box.dart';
import '../widgets/waveform.dart';

/// RX screen: record the microphone or load a WAV file, demodulate,
/// deframe and decode. Includes the animated packet monitor.
class ReceiverScreen extends StatefulWidget {
  const ReceiverScreen({super.key});

  @override
  State<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  final MicRecorder _mic = MicRecorder();
  final List<String> _log = <String>[];
  final List<double> _captured = <double>[];

  StreamSubscription<Uint8List>? _sub;
  bool _recording = false;
  DecodeResult? _result;

  @override
  void dispose() {
    _sub?.cancel();
    _mic.dispose();
    super.dispose();
  }

  void _logLine(String msg) {
    setState(() => _log.add('[${logTimestamp()}] $msg'));
  }

  // ------------------------------------------------------------ actions
  Future<void> _loadWav() async {
    final AppState app = context.read<AppState>();
    try {
      final Uint8List? bytes = await FileManager.pickWavBytes();
      if (bytes == null) {
        _logLine('load cancelled');
        return;
      }
      final WavData wav = WavParser.parse(bytes);
      app.setRx(wav.samples);
      _result = null;
      _logLine(
        'loaded ${formatBytes(bytes.length)}: ${wav.samples.length} '
        'samples @ ${wav.sampleRate} Hz '
        '(${formatDuration(wav.samples.length, wav.sampleRate)})',
      );
      if (wav.sampleRate != app.sampleRate) {
        _logLine(
          'WARN: file rate ${wav.sampleRate} != modem rate '
          '${app.sampleRate} — decode may fail',
        );
      }
    } on FormatException catch (e) {
      _logLine('ERR: ${e.message}');
    } catch (e) {
      _logLine('ERR: failed to load WAV ($e)');
    }
  }

  Future<void> _toggleRecord() async {
    final AppState app = context.read<AppState>();
    if (_recording) {
      await _sub?.cancel();
      _sub = null;
      await _mic.stop();
      setState(() => _recording = false);
      app.setRx(List<double>.from(_captured));
      _logLine(
        'recorded ${_captured.length} samples '
        '(${formatDuration(_captured.length, app.sampleRate)})',
      );
      return;
    }
    if (!await _mic.requestPermission()) {
      _logLine('ERR: microphone permission denied');
      return;
    }
    _captured.clear();
    _result = null;
    final Stream<Uint8List> stream = await _mic.start(
      sampleRate: app.sampleRate,
    );
    _sub = stream.listen((Uint8List chunk) {
      _captured.addAll(MicRecorder.pcm16ToSamples(chunk));
      if (_captured.length % (app.sampleRate ~/ 2) < 2048 && mounted) {
        setState(() {}); // refresh level meter about twice a second
      }
    });
    setState(() => _recording = true);
    _logLine('recording @ ${app.sampleRate} Hz — press STOP when done');
  }

  void _decode() {
    final AppState app = context.read<AppState>();
    final List<double>? rx = app.rxSamples;
    if (rx == null || rx.isEmpty) {
      _logLine('ERR: no signal — record or load a WAV first');
      return;
    }
    _logLine(
      'demodulating ${rx.length} samples '
      '(${app.modulation.label}, ${app.config.samplesPerSymbol} sp/sym)...',
    );

    final List<int> bits = app.modem.demodulate(rx, app.config);
    final DecodeResult result = PayloadDecoder.decode(bits, key: app.cryptoKey);
    setState(() => _result = result);
    for (final String line in result.log) {
      _logLine(line);
    }
  }

  // --------------------------------------------------------------- view
  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final Color accent = app.accent;
    final List<double>? rx = app.rxSamples;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        // Signal source.
        NeonCard(
          title: 'Signal Source',
          color: accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  NeonButton(
                    label: 'Load WAV',
                    icon: Icons.folder_open,
                    color: accent,
                    onPressed: _recording ? null : _loadWav,
                  ),
                  NeonButton(
                    label: _recording ? 'Stop' : 'Record',
                    icon: _recording ? Icons.stop : Icons.mic,
                    color: _recording
                        ? CyberColors.neonRed
                        : CyberColors.neonGreen,
                    filled: _recording,
                    onPressed: _toggleRecord,
                  ),
                  NeonButton(
                    label: 'Decode',
                    icon: Icons.downloading,
                    color: CyberColors.neonMagenta,
                    filled: true,
                    onPressed: !_recording && rx != null ? _decode : null,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _recording
                    ? 'REC ${_captured.length} samples '
                          '(${formatDuration(_captured.length, app.sampleRate)})'
                    : rx == null
                    ? 'no signal loaded'
                    : 'signal: ${rx.length} samples '
                          '(${formatDuration(rx.length, app.sampleRate)})',
                style: CyberFonts.terminal(
                  size: 12,
                  color: _recording ? CyberColors.neonRed : CyberColors.textDim,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Packet monitor.
        NeonCard(
          title: 'Packet Monitor',
          color: CyberColors.neonAmber,
          child: _buildPacketMonitor(),
        ),
        const SizedBox(height: 16),

        // Decoded output.
        NeonCard(
          title: 'Decoded Output',
          color: CyberColors.neonGreen,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 70),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: CyberColors.neonGreen.withOpacity(0.35),
              ),
            ),
            child: SelectableText(
              _result?.text ?? '// nothing decoded yet',
              style: CyberFonts.terminal(
                size: 15,
                color: _result?.text != null
                    ? CyberColors.neonGreen
                    : CyberColors.textDim.withOpacity(0.6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // RX waveform.
        NeonCard(
          title: 'RX Waveform',
          color: accent,
          child: Oscilloscope(
            samples: _recording ? _captured : rx,
            color: _recording ? CyberColors.neonRed : accent,
          ),
        ),
        const SizedBox(height: 16),

        // Terminal.
        NeonCard(
          title: 'Terminal',
          color: CyberColors.neonGreen,
          child: TerminalBox(lines: _log),
        ),
      ],
    );
  }

  Widget _buildPacketMonitor() {
    final DecodeResult? result = _result;
    if (result == null || result.frames.isEmpty) {
      return Text(
        '// no packets decoded',
        style: CyberFonts.terminal(
          size: 12,
          color: CyberColors.textDim.withOpacity(0.6),
        ),
      );
    }
    return Column(
      children: <Widget>[
        for (var i = 0; i < result.frames.length; i++)
          _packetRow(i, result.frames[i]),
      ],
    );
  }

  Widget _packetRow(int index, FrameInfo f) {
    final Color statusColor = f.crcOk
        ? CyberColors.neonGreen
        : CyberColors.neonRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CyberColors.surfaceAlt.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.inventory_2, size: 16, color: statusColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '#$index  @bit ${f.bitOffset}  ${f.length} B  '
              '[${f.flagsLabel.isEmpty ? 'RAW' : f.flagsLabel}]',
              style: CyberFonts.terminal(
                size: 12,
                color: CyberColors.textPrimary,
              ),
            ),
          ),
          Text(
            f.crcOk ? 'CRC OK' : 'CRC FAIL',
            style: CyberFonts.terminal(
              size: 12,
              color: statusColor,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
