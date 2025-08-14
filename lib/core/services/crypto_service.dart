import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class CryptoService {
  static const String _masterPassphrase = 'classes_app_master_passphrase_v1';
  static const List<int> _masterSalt = <int>[
    0x43, 0x6c, 0x61, 0x73, 0x73, 0x65, 0x73, 0x5f, 0x41, 0x70, 0x70, 0x5f, 0x53, 0x61, 0x6c, 0x74
  ];

  final Cipher _cipher = AesGcm.with128bits();

  SecretKey? _cachedMasterKey;

  Future<SecretKey> _deriveMasterKey() async {
    if (_cachedMasterKey != null) return _cachedMasterKey!;
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 128,
    );
    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(_masterPassphrase)),
      nonce: _masterSalt,
    );
    _cachedMasterKey = secretKey;
    return secretKey;
  }

  List<int> generateRandomBytes(int length) {
    final secureRandom = Random.secure();
    return List<int>.generate(length, (_) => secureRandom.nextInt(256));
  }

  String generateSaltBase64({int length = 16}) {
    final salt = generateRandomBytes(length);
    return base64Encode(salt);
  }

  Future<String> hashPassword(String password, String saltBase64) async {
    final salt = base64Decode(saltBase64);
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 150000,
      bits: 256,
    );
    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    final hashBytes = await secretKey.extractBytes();
    return base64Encode(hashBytes);
  }

  Future<Map<String, String>> encryptField(String plaintext) async {
    final key = await _deriveMasterKey();
    final nonce = generateRandomBytes(12);
    final secretBox = await _cipher.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );
    final ciphertextB64 = base64Encode(secretBox.cipherText);
    final nonceB64 = base64Encode(secretBox.nonce);
    final macB64 = base64Encode(secretBox.mac.bytes);
    return <String, String>{
      'ciphertext': ciphertextB64,
      'nonce': nonceB64,
      'mac': macB64,
    };
  }

  Future<String> decryptField({
    required String ciphertextBase64,
    required String nonceBase64,
    required String macBase64,
  }) async {
    final key = await _deriveMasterKey();
    final secretBox = SecretBox(
      base64Decode(ciphertextBase64),
      nonce: base64Decode(nonceBase64),
      mac: Mac(base64Decode(macBase64)),
    );
    final clearBytes = await _cipher.decrypt(
      secretBox,
      secretKey: key,
    );
    return utf8.decode(clearBytes);
  }
}


