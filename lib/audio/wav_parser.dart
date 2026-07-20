import 'dart:typed_data';

class WavData {
  final int sampleRate;
  final int channels;
  final int bitsPerSample;

  /// Mono samples normalised to roughly [-1, 1]
  /// (multi-channel input is down-mixed by averaging).
  final List<double> samples;

  const WavData({
    required this.sampleRate,
    required this.channels,
    required this.bitsPerSample,
    required this.samples,
  });
}

/// Parses RIFF/WAVE files: PCM 8/16/24/32-bit and IEEE float 32-bit.
class WavParser {
  WavParser._();

  static WavData parse(Uint8List bytes) {
    if (bytes.length < 44) {
      throw const FormatException('file too small to be a WAV');
    }
    String tag(int offset) => String.fromCharCodes(bytes, offset, offset + 4);
    final ByteData bd = ByteData.sublistView(bytes);

    if (tag(0) != 'RIFF' || tag(8) != 'WAVE') {
      throw const FormatException('not a RIFF/WAVE file');
    }

    int audioFormat = 1;
    int channels = 1;
    int sampleRate = 44100;
    int bitsPerSample = 16;
    Uint8List? dataChunk;

    var offset = 12;
    while (offset + 8 <= bytes.length) {
      final String id = tag(offset);
      final int size = bd.getUint32(offset + 4, Endian.little);
      final int body = offset + 8;
      if (body + size > bytes.length) break;
      if (id == 'fmt ') {
        audioFormat = bd.getUint16(body, Endian.little);
        channels = bd.getUint16(body + 2, Endian.little);
        sampleRate = bd.getUint32(body + 4, Endian.little);
        bitsPerSample = bd.getUint16(body + 14, Endian.little);
      } else if (id == 'data') {
        dataChunk = Uint8List.sublistView(bytes, body, body + size);
      }
      offset = body + size + (size.isOdd ? 1 : 0); // chunks are 2-aligned
    }

    if (dataChunk == null) {
      throw const FormatException('WAVE data chunk not found');
    }
    if (channels < 1) {
      throw const FormatException('invalid channel count');
    }

    final ByteData dd = ByteData.sublistView(dataChunk);
    final int bytesPerSample = (bitsPerSample + 7) ~/ 8;
    final int frameSize = bytesPerSample * channels;
    if (frameSize == 0) {
      throw const FormatException('invalid sample format');
    }
    final int frames = dataChunk.length ~/ frameSize;
    final List<double> samples = List<double>.filled(frames, 0);

    double readSample(int frame, int ch) {
      final int o = frame * frameSize + ch * bytesPerSample;
      switch (audioFormat) {
        case 1: // PCM integer
          switch (bitsPerSample) {
            case 8:
              return (dd.getUint8(o) - 128) / 128.0;
            case 16:
              return dd.getInt16(o, Endian.little) / 32768.0;
            case 24:
              var v =
                  dd.getUint8(o) |
                  (dd.getUint8(o + 1) << 8) |
                  (dd.getUint8(o + 2) << 16);
              if (v & 0x800000 != 0) v -= 0x1000000;
              return v / 8388608.0;
            case 32:
              return dd.getInt32(o, Endian.little) / 2147483648.0;
          }
          break;
        case 3: // IEEE float
          if (bitsPerSample == 32) {
            return dd.getFloat32(o, Endian.little);
          }
          break;
      }
      throw FormatException(
        'unsupported WAV format (format=$audioFormat bits=$bitsPerSample)',
      );
    }

    for (var f = 0; f < frames; f++) {
      var acc = 0.0;
      for (var ch = 0; ch < channels; ch++) {
        acc += readSample(f, ch);
      }
      samples[f] = acc / channels;
    }

    return WavData(
      sampleRate: sampleRate,
      channels: channels,
      bitsPerSample: bitsPerSample,
      samples: samples,
    );
  }
}
