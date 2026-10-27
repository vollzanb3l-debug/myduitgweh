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

  static const String _keyRecoveryQ1 = 'secure_recovery_q1';
  static const String _keyRecoveryQ2 = 'secure_recovery_q2';
  static const String _keyRecoveryA1Hash = 'secure_recovery_a1_hash';
  static const String _keyRecoveryA1Salt = 'secure_recovery_a1_salt';
  static const String _keyRecoveryA2Hash = 'secure_recovery_a2_hash';
  static const String _keyRecoveryA2Salt = 'secure_recovery_a2_salt';

  int _failedRecoveryAttempts = 0;
  DateTime? _recoveryLockoutUntil;

  int get failedRecoveryAttempts => _failedRecoveryAttempts;

  bool get isRecoveryLockedOut {
    if (_recoveryLockoutUntil == null) return false;
    if (DateTime.now().isAfter(_recoveryLockoutUntil!)) {
      _recoveryLockoutUntil = null;
      _failedRecoveryAttempts = 0;
      return false;
    }
    return true;
  }

  int get recoveryLockoutSecondsRemaining {
    if (_recoveryLockoutUntil == null) return 0;
    final diff = _recoveryLockoutUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// Normalisasi jawaban: huruf kecil dan spasi di tepi dihapus
  static String normalizeAnswer(String answer) {
    return answer.trim().toLowerCase();
  }

  /// Simpan 2 pertanyaan pemulihan dan hash + salt jawabannya
  Future<void> saveRecoveryQuestions({
    required String q1,
    required String a1,
    required String q2,
    required String a2,
  }) async {
    final salt1 = _generateSalt();
    final hash1 = _hashPin(normalizeAnswer(a1), salt1);

    final salt2 = _generateSalt();
    final hash2 = _hashPin(normalizeAnswer(a2), salt2);

    await _storage.write(key: _keyRecoveryQ1, value: q1.trim());
    await _storage.write(key: _keyRecoveryQ2, value: q2.trim());
    await _storage.write(key: _keyRecoveryA1Hash, value: hash1);
    await _storage.write(key: _keyRecoveryA1Salt, value: salt1);
    await _storage.write(key: _keyRecoveryA2Hash, value: hash2);
    await _storage.write(key: _keyRecoveryA2Salt, value: salt2);

    _failedRecoveryAttempts = 0;
    _recoveryLockoutUntil = null;
  }

  /// Mengambil daftar 2 pertanyaan pemulihan yang tersimpan (atau null jika belum dibuat)
  Future<List<String>?> getRecoveryQuestions() async {
    final q1 = await _storage.read(key: _keyRecoveryQ1);
    final q2 = await _storage.read(key: _keyRecoveryQ2);
    if (q1 == null || q2 == null || q1.isEmpty || q2.isEmpty) {
      return null;
    }
    return [q1, q2];
  }

  /// Verifikasi kedua jawaban pemulihan terhadap hash + salt
  Future<bool> verifyRecoveryAnswers({
    required String a1,
    required String a2,
  }) async {
    if (isRecoveryLockedOut) return false;

    final storedHash1 = await _storage.read(key: _keyRecoveryA1Hash);
    final storedSalt1 = await _storage.read(key: _keyRecoveryA1Salt);
    final storedHash2 = await _storage.read(key: _keyRecoveryA2Hash);
    final storedSalt2 = await _storage.read(key: _keyRecoveryA2Salt);

    if (storedHash1 == null ||
        storedSalt1 == null ||
        storedHash2 == null ||
        storedSalt2 == null) {
      return false;
    }

    final computed1 = _hashPin(normalizeAnswer(a1), storedSalt1);
    final computed2 = _hashPin(normalizeAnswer(a2), storedSalt2);

    final isCorrect = (computed1 == storedHash1) && (computed2 == storedHash2);

    if (isCorrect) {
      _failedRecoveryAttempts = 0;
      _recoveryLockoutUntil = null;
      return true;
    } else {
      _failedRecoveryAttempts++;
      if (_failedRecoveryAttempts >= 5) {
        _recoveryLockoutUntil =
            DateTime.now().add(const Duration(seconds: 30));
      }
      return false;
    }
  }

  /// Hapus semua data keamanan (PIN dan Pertanyaan Pemulihan)
  Future<void> wipeAllSecurityData() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
    await _storage.delete(key: _keyPinHash);
    await _storage.delete(key: _keyPinSalt);
    await _storage.delete(key: _keyRecoveryQ1);
    await _storage.delete(key: _keyRecoveryQ2);
    await _storage.delete(key: _keyRecoveryA1Hash);
    await _storage.delete(key: _keyRecoveryA1Salt);
    await _storage.delete(key: _keyRecoveryA2Hash);
    await _storage.delete(key: _keyRecoveryA2Salt);
    _failedAttempts = 0;
    _lockoutUntil = null;
    _failedRecoveryAttempts = 0;
    _recoveryLockoutUntil = null;
  }

  void resetFailedAttempts() {
    _failedAttempts = 0;
    _lockoutUntil = null;
    _failedRecoveryAttempts = 0;
    _recoveryLockoutUntil = null;
  }
}
