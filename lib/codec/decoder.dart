import 'dart:convert';
import 'dart:typed_data';

import '../crypto/aes_gcm.dart';
import 'fec.dart';
import 'frame_builder.dart';

/// Result of the full RX pipeline.
class DecodeResult {
  /// Decoded plain text (null when nothing decodable was found).
  final String? text;

  /// Every frame found in the bit stream (packet monitor).
  final List<FrameInfo> frames;

  /// The frame that was actually decoded.
  final FrameInfo? frame;

  /// Final payload after FEC + decryption (null on failure).
  final Uint8List? payload;

  /// Bytes corrected by Reed-Solomon.
  final int correctedErrors;

  /// Step-by-step log for the terminal view.
  final List<String> log;

  const DecodeResult({
    required this.text,
    required this.frames,
    required this.frame,
    required this.payload,
    required this.correctedErrors,
    required this.log,
  });

  bool get ok => text != null;
}

/// RX pipeline: `bits -> frames -> [RS-FEC] -> [AES-256-GCM] -> text`.
class PayloadDecoder {
  PayloadDecoder._();

  static DecodeResult decode(List<int> bits, {String key = ''}) {
    final List<String> log = <String>[];
    final List<FrameInfo> frames = FrameBuilder.parse(bits);
    log.add('scanned ${bits.length} bits -> ${frames.length} frame(s)');

    FrameInfo? chosen;
    for (final FrameInfo f in frames) {
      if (f.crcOk) {
        chosen = f;
        break;
      }
    }
    chosen ??= frames.isNotEmpty ? frames.first : null;

    if (chosen == null) {
      log.add('ERR: no frame sync (0xD391) found in bit stream');
      return DecodeResult(
        text: null,
        frames: frames,
        frame: null,
        payload: null,
        correctedErrors: 0,
        log: log,
      );
    }

    log.add(
      'frame @bit ${chosen.bitOffset}: ${chosen.length} B '
      '[${chosen.flagsLabel.isEmpty ? 'RAW' : chosen.flagsLabel}] '
      'crc=${chosen.crcOk ? 'OK' : 'FAIL'}',
    );

    var data = chosen.payload;
    var corrected = 0;

    if (chosen.fec) {
      try {
        final RsResult r = ReedSolomon.decodeBlocks(data);
        data = r.data;
        corrected = r.corrected;
        log.add('RS-FEC: $corrected byte error(s) corrected');
      } on RsException catch (e) {
        log.add('ERR: RS-FEC failed (${e.message}) — using raw payload');
      }
    }

    if (chosen.encrypted) {
      if (key.isEmpty) {
        log.add('ERR: frame is AES-256-GCM encrypted, no key set');
        return DecodeResult(
          text: null,
          frames: frames,
          frame: chosen,
          payload: null,
          correctedErrors: corrected,
          log: log,
        );
      }
      try {
        data = AesGcm.decryptBytes(data, key);
        log.add('AES-256-GCM: decrypted ${data.length} B');
      } catch (_) {
        log.add('ERR: decryption failed (wrong key or corrupted data)');
        return DecodeResult(
          text: null,
          frames: frames,
          frame: chosen,
          payload: null,
          correctedErrors: corrected,
          log: log,
        );
      }
    }

    final String text = utf8.decode(data, allowMalformed: true);
    log.add('decoded ${data.length} B -> ${text.length} chars');

    return DecodeResult(
      text: text,
      frames: frames,
      frame: chosen,
      payload: data,
      correctedErrors: corrected,
      log: log,
    );
  }
}
