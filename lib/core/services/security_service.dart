import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityService {
  static const String _keyPinHash = 'secure_pin_hash';
  static const String _keyPinSalt = 'secure_pin_salt';

  final FlutterSecureStorage _storage;

  // Pelacakan percobaan gagal dan lockout
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  SecurityService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  int get failedAttempts => _failedAttempts;

  bool get isLockedOut {
    if (_lockoutUntil == null) return false;
    if (DateTime.now().isAfter(_lockoutUntil!)) {
      _lockoutUntil = null;
      _failedAttempts = 0;
      return false;
    }
    return true;
  }

  int get lockoutSecondsRemaining {
    if (_lockoutUntil == null) return 0;
    final diff = _lockoutUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  String _generateSalt([int length = 16]) {
    final rand = Random.secure();
    final values = List<int>.generate(length, (_) => rand.nextInt(256));
    return base64Url.encode(values);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    return sha256.convert(bytes).toString();
  }

  /// Menyimpan PIN baru dalam bentuk SHA-256(PIN + salt). PIN asli tidak pernah disimpan.
  Future<void> savePin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _storage.write(key: _keyPinHash, value: hash);
    await _storage.write(key: _keyPinSalt, value: salt);
    _failedAttempts = 0;
    _lockoutUntil = null;
  }

  /// Memverifikasi PIN input terhadap hash + salt yang tersimpan
  Future<bool> verifyPin(String pin) async {
    if (isLockedOut) return false;

    final storedHash = await _storage.read(key: _keyPinHash);
    final storedSalt = await _storage.read(key: _keyPinSalt);

    if (storedHash == null || storedSalt == null) {
      return false;
    }

    final computedHash = _hashPin(pin, storedSalt);
    final isValid = computedHash == storedHash;

    if (isValid) {
      _failedAttempts = 0;
      _lockoutUntil = null;
      return true;
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
      }
      return false;
    }
  }

  /// Menghapus PIN dari secure storage
  Future<void> disablePin() async {
    await _storage.delete(key: _keyPinHash);
    await _storage.delete(key: _keyPinSalt);
    _failedAttempts = 0;
    _lockoutUntil = null;
  }

  /// Memeriksa apakah PIN sudah tersimpan
  Future<bool> isPinConfigured() async {
    final hash = await _storage.read(key: _keyPinHash);
    final salt = await _storage.read(key: _keyPinSalt);
    return hash != null && salt != null;
  }

  /// Hapus semua data keamanan
  Future<void> wipeAllSecurityData() async {
    await _storage.deleteAll();
    _failedAttempts = 0;
    _lockoutUntil = null;
  }

  void resetFailedAttempts() {
    _failedAttempts = 0;
    _lockoutUntil = null;
  }
}
