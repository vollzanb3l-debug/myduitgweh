/// Konstanta versi dan konfigurasi format cadangan (backup) MyDuitGweh.
///
/// ATURAN PEMELIHARAAN (PROJECT.md):
/// Setiap kali struktur data berubah (menambah, menghapus, atau mengganti kolom),
/// [currentBackupVersion] wajib dinaikkan (+1) dan fungsi migrasi bertahap
/// ditambahkan di [BackupService._migrateBackup] agar berkas cadangan versi lama
/// tetap selalu dapat dipulihkan dengan aman.
class BackupConstants {
  BackupConstants._();

  /// Versi format berkas cadangan saat ini (angka bulat positif, mulai 1)
  static const int currentBackupVersion = 1;

  /// Versi aplikasi saat ini
  static const String currentAppVersion = '1.0.0';

  /// Identitas nama aplikasi yang wajib ada di setiap berkas cadangan
  static const String appIdentifier = 'MyDuitGweh';

  /// Pesan kesalahan standar
  static const String errInvalidBackup =
      'Berkas bukan cadangan MyDuitGweh yang valid.';

  static const String errNewerVersion =
      'Cadangan ini dibuat dengan versi aplikasi yang lebih baru. Perbarui aplikasi dulu.';
}
