# HoloRadio — Cyberpunk Audio Data Modem (Flutter)

HoloRadio is a native Flutter rewrite of the HoloRadio web app: a neon
cyberpunk **audio modem** that turns text into sound and back.

```
TEXT ──► [AES-256-GCM] ──► [RS-FEC] ──► [FRAME + CRC16] ──► MODULATOR ──► WAV / SPEAKER
TEXT ◄── [AES-256-GCM] ◄── [RS-FEC] ◄── [FRAME + CRC16] ◄── DEMODULATOR ◄── MIC / WAV
```

## Features

- **5 modulations**: FSK, AFSK (Bell-202 style continuous phase), DBPSK, DQPSK, MSK
- **AES-256-GCM** encryption (key derived from passphrase via SHA-256)
- **Reed-Solomon FEC** — corrects up to 16 corrupted bytes per 255-byte block
- **CRC-16/CCITT** framed packets with preamble + sync word
- **Generate / play / save WAV**, load and decode WAV files
- **Microphone recording** and live decoding
- **Export** BIN (packed bits), ENC (encoded payload container), TXT
- **Analyzer**: real-time spectrum (FFT), constellation view, oscilloscope
- Cyberpunk UI: neon glow, matrix grid, terminal fonts, animated packet monitor
- Material You (dynamic color) support, offline operation

## Project structure

```
lib/
├── main.dart               app entry, navigation shell, dynamic theming
├── theme/                  colors.dart · fonts.dart · cyber_theme.dart
├── state/                  app_state.dart (Provider / ChangeNotifier)
├── screens/                sender · receiver · analyzer · settings
├── widgets/                neon_button · neon_card · terminal_box · toggle_switch
│                           waveform · constellation · spectrum · cyber_background
├── dsp/                    modem.dart (base+config) · fsk · afsk · psk · qpsk · msk
│                           goertzel.dart · fft.dart
├── codec/                  encoder · decoder · frame_builder · crc16 · fec (Reed-Solomon)
├── crypto/                 aes_gcm.dart
├── audio/                  wav_generator · wav_parser · player · recorder
├── storage/                file_manager.dart
└── utils/                  format.dart
```

## Build the APK

The `lib/`, `assets/`, `pubspec.yaml` and the Android manifest are included.
Generate the remaining platform scaffolding with Flutter (3.19 or newer):

```bash
cd holoradio_flutter

# 1. Generate the android/ gradle project (keeps your lib/ and pubspec)
flutter create --org com.holoradio --project-name holoradio --platforms=android .

# 2. Restore the permissions manifest (flutter create may reset it)
cp docs/AndroidManifest.xml android/app/src/main/AndroidManifest.xml

# 3. Dependencies
flutter pub get

# 4. Run on a device/emulator, or build release artifacts
flutter run
flutter build apk --release        # build/app/outputs/flutter-apk/app-release.apk
flutter build apk --debug          # app-debug.apk
flutter build appbundle --release  # app-release.aab (Google Play)
```

### Notes

- If the build complains about `minSdkVersion`, set `minSdkVersion 23` in
  `android/app/build.gradle(.kts)` (required by the audio recording plugin).
- Microphone permission is requested at runtime before recording.
- Google Fonts are fetched once and cached; offline the UI falls back to the
  system monospace font.
- The FFT and the Reed-Solomon codec are implemented natively in Dart
  (`lib/dsp/fft.dart`, `lib/codec/fec.dart`), so no native FFT/RS packages
  are needed. The `record` + `audioplayers` plugins handle audio I/O
  (`flutter_sound` from the original spec is not required).

## Signal chain details

| Stage      | Format |
|------------|--------|
| Frame      | preamble (16 alternating bits) · sync `0xD391` · flags · length(16) · payload · CRC-16 |
| flags      | bit0 = AES-256-GCM encrypted, bit1 = RS-FEC applied |
| FEC        | RS over GF(2⁸), 32 parity bytes per block, 223 data bytes per full block |
| Encryption | AES-256-GCM, 12-byte random nonce prepended to ciphertext |
| Modulation | symbol rate = baud, differential phase for PSK/QPSK (leading reference symbol) |
| WAV        | 16-bit PCM mono, configurable sample rate (default 44.1 kHz) |
