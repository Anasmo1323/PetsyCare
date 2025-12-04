import 'package:encrypt/encrypt.dart' as encrypt;

class SecurityService {
  // These MUST match exactly what is on your ESP32 Hardware.
  static const String _keyString = 'petsycare_secret'; // 16 chars
  static const String _ivString  = 'petsycare_init_v'; // 16 chars

  late final encrypt.Encrypter _encrypter;
  late final encrypt.IV _iv;

  SecurityService() {
    // FIXED: Changed .utf8 to .fromUtf8
    final key = encrypt.Key.fromUtf8(_keyString);
    _iv = encrypt.IV.fromUtf8(_ivString);
    
    // We set 'padding: null' to stop the app from crashing if padding is weird.
    _encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: null)
    );
  }

  String decrypt(String encryptedBase64) {
    try {
      if (encryptedBase64.isEmpty) return '0';
      
      // 1. Decrypt without checking padding
      String decrypted = _encrypter.decrypt64(encryptedBase64, iv: _iv);
      
      // 2. Clean up the result (Remove null bytes/garbage)
      String cleanResult = decrypted.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
      
      return cleanResult;
    } catch (e) {
      print('Decryption Error: $e');
      return 'Err'; 
    }
  }

  String encryptData(String plainText) {
    // FIXED: Changed .utf8 to .fromUtf8
    final key = encrypt.Key.fromUtf8(_keyString);
    
    // For sending commands, we stick to standard padding
    final standardEncrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    return standardEncrypter.encrypt(plainText, iv: _iv).base64;
  }
}