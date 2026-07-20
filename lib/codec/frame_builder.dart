import 'dart:typed_data';

import 'crc16.dart';

/// One parsed frame from the bit stream.
class FrameInfo {
  final int bitOffset;
  final bool encrypted;
  final bool fec;
  final Uint8List payload;
  final int crcExpected;
  final int crcReceived;

  const FrameInfo({
    required this.bitOffset,
    required this.encrypted,
    required this.fec,
    required this.payload,
    required this.crcExpected,
    required this.crcReceived,
  });

  bool get crcOk => crcExpected == crcReceived;
  int get length => payload.length;

  String get flagsLabel =>
      '${encrypted ? 'ENC ' : ''}${fec ? 'FEC' : ''}'.trim();
}

/// Frame wire format (MSB first):
///
/// ```
///  preamble : 16 alternating bits 1010...
///  sync     : 0xD3 0x91
///  flags    : 1 byte   (bit0 = AES encrypted, bit1 = RS-FEC applied)
///  length   : 2 bytes  (payload length, big endian)
///  payload  : length bytes
///  crc      : 2 bytes  CRC-16/CCITT over flags+length+payload
/// ```
class FrameBuilder {
  FrameBuilder._();

  static const int syncWord = 0xD391;
  static const int syncHi = 0xD3;
  static const int syncLo = 0x91;
  static const int preambleLength = 16;
  static const int maxPayload = 4096;

  static List<int> bytesToBits(List<int> bytes) => <int>[
    for (final int b in bytes)
      for (var k = 7; k >= 0; k--) (b >> k) & 1,
  ];

  static int _readBits(List<int> bits, int start, int count) {
    var v = 0;
    for (var k = 0; k < count; k++) {
      v = (v << 1) | (bits[start + k] & 1);
    }
    return v;
  }

  /// Packs a bit list into bytes (MSB first, zero padded) for BIN export.
  static Uint8List packBits(List<int> bits) {
    final int n = (bits.length + 7) ~/ 8;
    final Uint8List out = Uint8List(n);
    for (var i = 0; i < bits.length; i++) {
      if (bits[i] != 0) out[i >> 3] |= 0x80 >> (i & 7);
    }
    return out;
  }

  static List<int> build(
    Uint8List payload, {
    required bool encrypted,
    required bool fec,
  }) {
    final int flags = (encrypted ? 1 : 0) | (fec ? 2 : 0);
    final List<int> header = <int>[
      flags,
      (payload.length >> 8) & 0xFF,
      payload.length & 0xFF,
    ];
    final int crc = Crc16.compute(<int>[...header, ...payload]);

    final List<int> bits = <int>[];
    for (var i = 0; i < preambleLength; i++) {
      bits.add(i.isEven ? 1 : 0);
    }
    bits.addAll(bytesToBits(<int>[syncHi, syncLo]));
    bits.addAll(bytesToBits(header));
    bits.addAll(bytesToBits(payload));
    bits.addAll(bytesToBits(<int>[(crc >> 8) & 0xFF, crc & 0xFF]));
    return bits;
  }

  /// Scans the bit stream for frames at *any* bit offset. Stops after a
  /// successfully framed (not necessarily CRC-valid) packet and resumes
  /// scanning right behind it.
  static List<FrameInfo> parse(List<int> bits) {
    final List<FrameInfo> frames = <FrameInfo>[];
    var i = 0;
    while (i + 40 <= bits.length) {
      if (_readBits(bits, i, 16) == syncWord) {
        final int flags = _readBits(bits, i + 16, 8);
        final int len = _readBits(bits, i + 24, 16);
        final int total = 40 + len * 8 + 16;
        if (len > 0 && len <= maxPayload && i + total <= bits.length) {
          final Uint8List payload = Uint8List.fromList(<int>[
            for (var b = 0; b < len; b++) _readBits(bits, i + 40 + b * 8, 8),
          ]);
          final int crcRx = _readBits(bits, i + 40 + len * 8, 16);
          final int crcCalc = Crc16.compute(<int>[
            flags,
            (len >> 8) & 0xFF,
            len & 0xFF,
            ...payload,
          ]);
          frames.add(
            FrameInfo(
              bitOffset: i,
              encrypted: flags & 1 != 0,
              fec: flags & 2 != 0,
              payload: payload,
              crcExpected: crcCalc,
              crcReceived: crcRx,
            ),
          );
          i += total;
          continue;
        }
      }
      i++;
    }
    return frames;
  }
}
