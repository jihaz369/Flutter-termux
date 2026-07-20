import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Thin wrapper around audioplayers for playing generated WAV data.
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  Stream<PlayerState> get onStateChanged => _player.onPlayerStateChanged;

  bool get isPlaying => _player.state == PlayerState.playing;

  Future<void> playBytes(Uint8List wavBytes) =>
      _player.play(BytesSource(wavBytes));

  Future<void> playFile(String path) => _player.play(DeviceFileSource(path));

  Future<void> stop() => _player.stop();

  void dispose() => _player.dispose();
}
