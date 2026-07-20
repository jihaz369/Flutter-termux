import 'dart:convert';
import 'dart:typed_data';

import '../crypto/aes_gcm.dart';
import 'fec.dart';
import 'frame_builder.dart';

/// Result of the full TX pipeline.
class EncodeResult {
  /// Payload carried inside the frame (after optional AES + FEC).
  final Uint8List framePayload;

  /// Complete framed bit stream (preamble .. crc).
  final List<int> bits;

  final bool encrypted;
  final bool fecApplied;

  /// Length of the original UTF-8 message in bytes.
  final int rawLength;

  const EncodeResult({
    required this.framePayload,
    required this.bits,
    required this.encrypted,
    required this.fecApplied,
    required this.rawLength,
  });
}

/// TX pipeline: `text -> [AES-256-GCM] -> [RS-FEC] -> frame -> bits`.
class PayloadEncoder {
  PayloadEncoder._();

  static EncodeResult encode(
    String text, {
    required bool encrypt,
    required String key,
    required bool fec,
  }) {
    var data = Uint8List.fromList(utf8.encode(text));
    final int rawLength = data.length;

    final bool doEncrypt = encrypt && key.isNotEmpty;
    if (doEncrypt) {
      data = AesGcm.encryptBytes(data, key);
    }

    var fecApplied = false;
    if (fec && data.isNotEmpty) {
      data = ReedSolomon.encodeBlocks(data);
      fecApplied = true;
    }

    final List<int> bits = FrameBuilder.build(
      data,
      encrypted: doEncrypt,
      fec: fecApplied,
    );

    return EncodeResult(
      framePayload: data,
      bits: bits,
      encrypted: doEncrypt,
      fecApplied: fecApplied,
      rawLength: rawLength,
    );
  }
}
