import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dsp/modem.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../theme/fonts.dart';
import '../widgets/neon_card.dart';
import '../widgets/toggle_switch.dart';

/// Modem parameters, security, display and about.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<int> _sampleRates = <int>[
    8000,
    11025,
    16000,
    22050,
    44100,
    48000,
  ];

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final Color accent = app.accent;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        // ------------------------------------------------ modem
        NeonCard(
          title: 'Modem',
          color: accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final Modulation m in Modulation.values) _modRow(m, app),
              const Divider(height: 24),
              _dropdownRow(
                'SAMPLE RATE',
                '${app.sampleRate} Hz',
                _sampleRates
                    .map(
                      (int r) =>
                          DropdownMenuItem<int>(value: r, child: Text('$r Hz')),
                    )
                    .toList(),
                (int? v) {
                  if (v != null) app.setSampleRate(v);
                },
                app.sampleRate,
              ),
              _sliderRow(
                'BAUD',
                app.baud,
                50,
                600,
                accent,
                (double v) => app.setBaud(v),
                '${app.baud.round()} sym/s',
              ),
              _sliderRow(
                'MARK',
                app.markFreq,
                600,
                3000,
                accent,
                (double v) => app.setMarkFreq(v),
                '${app.markFreq.round()} Hz',
              ),
              _sliderRow(
                'SPACE',
                app.spaceFreq,
                600,
                4000,
                accent,
                (double v) => app.setSpaceFreq(v),
                '${app.spaceFreq.round()} Hz',
              ),
              _sliderRow(
                'CARRIER',
                app.carrierFreq,
                600,
                4000,
                accent,
                (double v) => app.setCarrierFreq(v),
                '${app.carrierFreq.round()} Hz',
              ),
              _sliderRow(
                'AMPLITUDE',
                app.amplitude,
                0.1,
                1.0,
                accent,
                (double v) => app.setAmplitude(v),
                app.amplitude.toStringAsFixed(2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ------------------------------------------------ security
        NeonCard(
          title: 'Security',
          color: accent,
          child: Column(
            children: <Widget>[
              NeonToggle(
                label: 'AES-256 Encryption',
                subtitle: 'GCM authenticated encryption',
                value: app.encryption,
                color: accent,
                onChanged: app.setEncryption,
              ),
              TextField(
                onChanged: app.setCryptoKey,
                obscureText: true,
                style: CyberFonts.terminal(
                  size: 14,
                  color: CyberColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'shared passphrase (TX and RX must match)',
                  prefixIcon: Icon(Icons.key, size: 18),
                  border: OutlineInputBorder(),
                ),
              ),
              NeonToggle(
                label: 'Reed-Solomon FEC',
                subtitle: 'corrects up to 16 byte errors per block',
                value: app.fec,
                color: accent,
                onChanged: app.setFec,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ------------------------------------------------ display
        NeonCard(
          title: 'Display',
          color: accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'ACCENT COLOR',
                style: CyberFonts.terminal(
                  size: 12,
                  color: CyberColors.textDim,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  for (var i = 0; i < CyberColors.accents.length; i++)
                    _accentDot(i, app),
                ],
              ),
              const SizedBox(height: 8),
              NeonToggle(
                label: 'Matrix grid background',
                value: app.grid,
                color: accent,
                onChanged: app.setGrid,
              ),
              NeonToggle(
                label: 'Material You',
                subtitle: 'use system dynamic colors when available',
                value: app.materialYou,
                color: accent,
                onChanged: app.setMaterialYou,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ------------------------------------------------ about
        NeonCard(
          title: 'About',
          color: CyberColors.neonViolet,
          child: Text(
            'HOLORADIO v1.0 — cyberpunk audio data modem\n\n'
            'TEXT -> [AES-256-GCM] -> [RS-FEC] -> [FRAME+CRC16]\n'
            '      -> FSK/AFSK/BPSK/QPSK/MSK -> SOUND\n\n'
            'Reed-Solomon, FFT, Goertzel and all modems are implemented '
            'natively in Dart. Offline capable.',
            style: CyberFonts.terminal(
              size: 12,
              color: CyberColors.textDim,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _modRow(Modulation m, AppState app) {
    final bool selected = app.modulation == m;
    final Color accent = app.accent;
    return InkWell(
      onTap: () => app.setModulation(m),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: selected ? accent : CyberColors.textDim,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    m.label,
                    style: CyberFonts.terminal(
                      size: 14,
                      color: selected ? accent : CyberColors.textPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    m.description,
                    style: CyberFonts.terminal(
                      size: 11,
                      color: CyberColors.textDim.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sliderRow(
    String label,
    double value,
    double min,
    double max,
    Color accent,
    ValueChanged<double> onChanged,
    String valueLabel,
  ) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: CyberFonts.terminal(
              size: 12,
              color: CyberColors.textDim,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 86,
          child: Text(
            valueLabel,
            textAlign: TextAlign.right,
            style: CyberFonts.terminal(size: 12, color: accent),
          ),
        ),
      ],
    );
  }

  Widget _dropdownRow<T>(
    String label,
    String display,
    List<DropdownMenuItem<T>> items,
    ValueChanged<T?> onChanged,
    T value,
  ) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: CyberFonts.terminal(
              size: 12,
              color: CyberColors.textDim,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            dropdownColor: CyberColors.surfaceAlt,
            underline: Container(height: 1, color: CyberColors.gridLine),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _accentDot(int index, AppState app) {
    final Color c = CyberColors.accents[index];
    final bool selected = app.accentIndex == index;
    return GestureDetector(
      onTap: () => app.setAccentIndex(index),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.withOpacity(selected ? 0.9 : 0.25),
          border: Border.all(
            color: selected ? c : c.withOpacity(0.4),
            width: selected ? 2.2 : 1,
          ),
          boxShadow: selected ? CyberColors.glow(c, blur: 10) : null,
        ),
        child: selected
            ? const Icon(Icons.check, size: 16, color: Colors.black)
            : null,
      ),
    );
  }
}
