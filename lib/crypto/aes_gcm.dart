import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// AES-256-GCM with a key derived from a passphrase via SHA-256.
///
/// Wire format: `[12-byte random nonce][ciphertext][16-byte GCM tag]`
/// (the encrypt package appends the tag to the ciphertext).
class AesGcm {
  AesGcm._();

  static enc.Key _deriveKey(String passphrase) {
    final Digest digest = sha256.convert(utf8.encode(passphrase));
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  static Uint8List encryptBytes(Uint8List data, String passphrase) {
    final enc.Key key = _deriveKey(passphrase);
    final enc.IV iv = enc.IV.fromSecureRandom(12);
    final enc.Encrypter encrypter = enc.Encrypter(
      enc.AES(key, mode: enc.AESMode.gcm),
    );
    final enc.Encrypted encrypted = encrypter.encryptBytes(data, iv: iv);
    return Uint8List.fromList(<int>[...iv.bytes, ...encrypted.bytes]);
  }

  static Uint8List decryptBytes(Uint8List data, String passphrase) {
    if (data.length < 12 + 16) {
      throw ArgumentError('ciphertext too short');
    }
    final enc.Key key = _deriveKey(passphrase);
    final enc.IV iv = enc.IV(Uint8List.fromList(data.sublist(0, 12)));
    final enc.Encrypter encrypter = enc.Encrypter(
      enc.AES(key, mode: enc.AESMode.gcm),
    );
    final List<int> plain = encrypter.decryptBytes(
      enc.Encrypted(Uint8List.fromList(data.sublist(12))),
      iv: iv,
    );
    return Uint8List.fromList(plain);
  }
}
