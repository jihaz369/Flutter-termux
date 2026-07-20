import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/player.dart';
import '../audio/wav_generator.dart';
import '../codec/encoder.dart';
import '../codec/frame_builder.dart';
import '../dsp/modem.dart';
import '../state/app_state.dart';
import '../storage/file_manager.dart';
import '../theme/colors.dart';
import '../theme/fonts.dart';
import '../utils/format.dart';
import '../widgets/neon_button.dart';
import '../widgets/neon_card.dart';
import '../widgets/terminal_box.dart';
import '../widgets/toggle_switch.dart';
import '../widgets/waveform.dart';

/// TX screen: compose a message, run the encode pipeline, modulate it,
/// play / save / export the result.
class SenderScreen extends StatefulWidget {
  const SenderScreen({super.key});

  @override
  State<SenderScreen> createState() => _SenderScreenState();
}

class _SenderScreenState extends State<SenderScreen> {
  final TextEditingController _msgCtrl = TextEditingController(
    text: 'HELLO HOLORADIO',
  );
  final AudioPlayerService _player = AudioPlayerService();
  final List<String> _log = <String>[];
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player.onStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _playing = state.name == 'playing');
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  void _logLine(String msg) {
    setState(() => _log.add('[${logTimestamp()}] $msg'));
  }

  // ------------------------------------------------------------ actions
  void _generate() {
    final AppState app = context.read<AppState>();
    final String text = _msgCtrl.text;
    if (text.trim().isEmpty) {
      _logLine('ERR: message is empty');
      return;
    }
    if (app.encryption && app.cryptoKey.isEmpty) {
      _logLine('WARN: encryption on but key empty — sending unencrypted');
    }

    final EncodeResult enc = PayloadEncoder.encode(
      text,
      encrypt: app.encryption,
      key: app.cryptoKey,
      fec: app.fec,
    );
    final List<double> samples = app.modem.modulate(enc.bits, app.config);
    final Uint8List wav = WavGenerator.fromSamples(samples, app.sampleRate);
    app.setTx(samples, wav, enc.bits, enc);

    _logLine(
      '${app.modulation.label} | ${enc.rawLength} B text -> '
      '${enc.framePayload.length} B payload '
      '(${[if (enc.encrypted) 'AES-256-GCM', if (enc.fecApplied) 'RS-FEC', 'CRC16'].join(' + ')})',
    );
    _logLine(
      '${enc.bits.length} bits -> ${samples.length} samples '
      '(${formatDuration(samples.length, app.sampleRate)} @ '
      '${app.config.baud.toStringAsFixed(0)} baud)',
    );
    _logLine('WAV ready: ${formatBytes(wav.length)}');
  }

  Future<void> _play() async {
    final Uint8List? wav = context.read<AppState>().txWav;
    if (wav == null) return;
    await _player.playBytes(wav);
    _logLine('playing transmission...');
  }

  Future<void> _save(Uint8List bytes, String name) async {
    final String? path = await FileManager.saveBytes(name, bytes);
    _logLine(path == null ? 'save cancelled' : 'saved -> $path');
  }

  // --------------------------------------------------------------- view
  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final Color accent = app.accent;
    final bool hasTx = app.txWav != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        // Modulation selector.
        NeonCard(
          title: 'Modulation',
          color: accent,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              for (final Modulation m in Modulation.values) _modChip(m, app),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Message.
        NeonCard(
          title: 'Message',
          color: accent,
          child: Column(
            children: <Widget>[
              TextField(
                controller: _msgCtrl,
                maxLines: 3,
                style: CyberFonts.terminal(
                  size: 15,
                  color: CyberColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: '// type message to transmit',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              NeonToggle(
                label: 'AES-256 Encryption',
                subtitle: 'GCM mode, key = SHA-256(passphrase)',
                value: app.encryption,
                color: accent,
                onChanged: app.setEncryption,
              ),
              if (app.encryption)
                TextField(
                  onChanged: app.setCryptoKey,
                  obscureText: true,
                  style: CyberFonts.terminal(
                    size: 14,
                    color: CyberColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'encryption passphrase',
                    prefixIcon: Icon(Icons.key, size: 18),
                    border: OutlineInputBorder(),
                  ),
                ),
              NeonToggle(
                label: 'Reed-Solomon FEC',
                subtitle: '+32 parity bytes / 223 B block, fixes 16 B',
                value: app.fec,
                color: accent,
                onChanged: app.setFec,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Actions.
        NeonCard(
          title: 'Transmit',
          color: accent,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              NeonButton(
                label: 'Generate',
                icon: Icons.bolt,
                color: accent,
                filled: true,
                onPressed: _generate,
              ),
              NeonButton(
                label: _playing ? 'Playing' : 'Play',
                icon: _playing ? Icons.volume_up : Icons.play_arrow,
                color: CyberColors.neonGreen,
                onPressed: hasTx && !_playing ? _play : null,
              ),
              NeonButton(
                label: 'Save WAV',
                icon: Icons.save_alt,
                color: accent,
                onPressed: hasTx
                    ? () =>
                          _save(app.txWav!, 'holoradio_${fileTimestamp()}.wav')
                    : null,
              ),
              NeonButton(
                label: 'Export BIN',
                icon: Icons.binary,
                color: CyberColors.neonAmber,
                compact: true,
                onPressed: hasTx
                    ? () => _save(
                        FrameBuilder.packBits(app.txBits!),
                        'holoradio_${fileTimestamp()}.bin',
                      )
                    : null,
              ),
              NeonButton(
                label: 'Export ENC',
                icon: Icons.enhanced_encryption,
                color: CyberColors.neonMagenta,
                compact: true,
                onPressed: hasTx
                    ? () => _save(
                        app.lastEncode!.framePayload,
                        'holoradio_${fileTimestamp()}.enc',
                      )
                    : null,
              ),
              NeonButton(
                label: 'Save TXT',
                icon: Icons.text_snippet,
                color: CyberColors.neonViolet,
                compact: true,
                onPressed: () => _save(
                  Uint8List.fromList(_msgCtrl.text.codeUnits),
                  'holoradio_${fileTimestamp()}.txt',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Waveform preview.
        NeonCard(
          title: 'TX Waveform',
          color: accent,
          child: Oscilloscope(samples: app.txSamples, color: accent),
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

  Widget _modChip(Modulation m, AppState app) {
    final bool selected = app.modulation == m;
    final Color accent = app.accent;
    return GestureDetector(
      onTap: () => app.setModulation(m),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.16) : CyberColors.surfaceAlt,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? accent : CyberColors.gridLine,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected ? CyberColors.glow(accent, blur: 8) : null,
        ),
        child: Text(
          m.label,
          style: CyberFonts.terminal(
            size: 13,
            letterSpacing: 2,
            color: selected ? accent : CyberColors.textDim,
            weight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
