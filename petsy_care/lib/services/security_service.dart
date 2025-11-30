import 'package:encrypt/encrypt.dart' as encrypt;

class SecurityService {
  // --- CONFIGURATION ---
  // These MUST match exactly what is on your ESP32 Hardware.
  // AES-128 requires a 16-character key.
  static const String _keyString = 'petsycare_secret'; // 16 chars
  static const String _ivString  = 'petsycare_init_v'; // 16 chars

  late final encrypt.Encrypter _encrypter;
  late final encrypt.IV _iv;

  SecurityService() {
    final key = encrypt.Key.fromUtf8(_keyString);
    _iv = encrypt.IV.fromUtf8(_ivString);
    // We use AES Mode CBC (Cipher Block Chaining) - standard for IoT
    _encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  }

  // --- Decrypt (Read from Hardware) ---
  // Takes the encrypted garbage text from Firebase and returns the real value
  String decrypt(String encryptedBase64) {
    try {
      if (encryptedBase64.isEmpty) return '0';
      return _encrypter.decrypt64(encryptedBase64, iv: _iv);
    } catch (e) {
      print('Decryption Error: $e');
      return 'Err'; // Return error if keys don't match
    }
  }

  // --- Encrypt (Send to Hardware) ---
  // Takes a command (like "true" for Heater ON) and encrypts it
  String encryptData(String plainText) {
    return _encrypter.encrypt(plainText, iv: _iv).base64;
  }
}