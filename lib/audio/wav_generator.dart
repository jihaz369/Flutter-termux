import 'dart:typed_data';

/// Builds 16-bit PCM mono WAV files from floating point samples.
class WavGenerator {
  WavGenerator._();

  static Uint8List fromSamples(List<double> samples, int sampleRate) {
    final int dataLen = samples.length * 2;
    final ByteData buffer = ByteData(44 + dataLen);

    void ascii(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        buffer.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    // RIFF header.
    ascii(0, 'RIFF');
    buffer.setUint32(4, 36 + dataLen, Endian.little);
    ascii(8, 'WAVE');
    // fmt chunk.
    ascii(12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little); // chunk size
    buffer.setUint16(20, 1, Endian.little); // PCM
    buffer.setUint16(22, 1, Endian.little); // mono
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    buffer.setUint16(32, 2, Endian.little); // block align
    buffer.setUint16(34, 16, Endian.little); // bits per sample
    // data chunk.
    ascii(36, 'data');
    buffer.setUint32(40, dataLen, Endian.little);

    for (var i = 0; i < samples.length; i++) {
      final double v = samples[i].clamp(-1.0, 1.0).toDouble();
      buffer.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    }
    return buffer.buffer.asUint8List();
  }
}
