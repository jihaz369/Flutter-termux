import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

/// File pick / save helpers built on file_picker + path_provider.
class FileManager {
  FileManager._();

  /// Opens the system save dialog (SAF on Android). Returns the chosen
  /// location or null when cancelled.
  static Future<String?> saveBytes(String fileName, Uint8List bytes) =>
      FilePicker.platform.saveFile(
        dialogTitle: 'Save $fileName',
        fileName: fileName,
        bytes: bytes,
      );

  /// Picks a file and returns its bytes (falls back to reading the path
  /// when the picker does not provide data directly).
  static Future<Uint8List?> pickFileBytes(List<String> extensions) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: true,
    );
    final PlatformFile? file = result?.files.first;
    if (file == null) return null;
    if (file.bytes != null) return file.bytes;
    if (file.path != null) {
      try {
        return await File(file.path!).readAsBytes();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Picks a WAV file and returns its bytes.
  static Future<Uint8List?> pickWavBytes() => pickFileBytes(<String>['wav']);

  /// A temporary file path the app may write to (used for sharing and
  /// plugin-based playback).
  static Future<String> tempPath(String fileName) async {
    final Directory dir = await getTemporaryDirectory();
    return '${dir.path}/$fileName';
  }

  /// An app-private documents directory path for long-lived exports.
  static Future<String> docsPath(String fileName) async {
    final Directory dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$fileName';
  }
}
