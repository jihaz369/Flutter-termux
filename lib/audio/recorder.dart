import 'dart:typed_data';

import 'package:record/record.dart';

/// Microphone capture as raw PCM16 streams via the `record` plugin.
class MicRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;

  bool get isRecording => _recording;

  /// Requests microphone permission; true when granted.
  Future<bool> requestPermission() => _recorder.hasPermission();

  /// Starts a mono PCM16 stream at [sampleRate].
  Future<Stream<Uint8List>> start({required int sampleRate}) async {
    final Stream<Uint8List> stream = await _recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
      ),
    );
    _recording = true;
    return stream;
  }

  Future<void> stop() async {
    await _recorder.stop();
    _recording = false;
  }

  void dispose() => _recorder.dispose();

  /// Converts a PCM16 little-endian chunk into normalised samples.
  static List<double> pcm16ToSamples(Uint8List chunk) {
    final ByteData bd = ByteData.sublistView(chunk);
    final int n = chunk.length ~/ 2;
    return List<double>.generate(
      n,
      (i) => bd.getInt16(i * 2, Endian.little) / 32768.0,
      growable: false,
    );
  }
}
