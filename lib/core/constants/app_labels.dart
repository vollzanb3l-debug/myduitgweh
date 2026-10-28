/// Label dan teks antarmuka terpusat untuk aplikasi MyDuitGweh.
/// Sesuai aturan Tahap 12: gunakan istilah 'duit', bukan 'dompet' atau 'catatan' pada teks antarmuka.
class AppLabels {
  AppLabels._();

  // Istilah Utama
  static const String appName = 'MyDuitGweh';
  static const String duit = 'Duit';
  static const String semuaDuit = 'Semua Duit';
  static const String duitSaya = 'Duit Saya';

  // 4 Jenis Duit
  static const String duitUtama = 'Duit Utama';
  static const String duitHarian = 'Duit Utama'; // Alias kompatibilitas
  static const String duitSaldo = 'Duit Saldo';
  static const String duitTabungan = 'Duit Tabungan';
  static const String duitPencapaian = 'Duit Pencapaian';

  // Penjelasan Singkat
  static const String descDuitUtama = 'Uang saku, makan, belanja, dan operasional sehari-hari';
  static const String descDuitHarian = descDuitUtama; // Alias kompatibilitas
  static const String descDuitSaldo = 'Kas tunai, rekening bank, dan dompet digital (e-wallet)';
  static const String descDuitTabungan = 'Simpanan masa depan, dana darurat, dan cadangan';
  static const String descDuitPencapaian = 'Target impian dan barang idaman yang ingin dicapai';

  // Navigasi & Tab
  static const String tabBeranda = 'Beranda';
  static const String tabDuit = 'Duit';
  static const String tabRiwayat = 'Riwayat';
  static const String tabStatistik = 'Statistik';
  static const String tabPengaturan = 'Pengaturan';

  // Aksi Duit & Saldo
  static const String aturSaldo = 'Atur Saldo';
  static const String tambahSaldo = 'Tambah Saldo';
  static const String koreksiSaldo = 'Koreksi Saldo';
  static const String resetSaldo = 'Reset Saldo';
  static const String resetProgres = 'Reset Progres';

  // Aksi Cepat
  static const String aksiPemasukan = 'Pemasukan';
  static const String aksiPengeluaran = 'Pengeluaran';
  static const String aksiSetor = 'Setor';
  static const String aksiTambahTarget = 'Tambah Target';
  static const String aksiRiwayat = 'Riwayat';
  static const String aksiStatistik = 'Statistik';

  // Pesan & Dialog
  static const String fiturBelumTersedia = 'Belum tersedia';
  static const String fiturSedangDisiapkan = 'Fitur ini sedang disiapkan';
  static const String saldoDisesuaikan = 'Saldo berhasil disesuaikan';
  static const String saldoDireset = 'Saldo berhasil direset';
  static const String progresDireset = 'Progres pencapaian berhasil direset';

  /// Mengembalikan nama pendek jenis duit (Utama, Saldo, Tabungan, Pencapaian, Semua)
  static String duitShortName(dynamic duit) => getDuitShortName(duit);

  /// Mengembalikan label merek: MyDuitGweh (NamaDuit)
  static String brandLabel(dynamic duit) => getBrandLabel(duit);
}

/// Fungsi pembantu untuk mendapatkan nama pendek duit (Utama, Saldo, Tabungan, Pencapaian, Semua)
String duitShortName(dynamic duit) => getDuitShortName(duit);

/// Fungsi pembantu untuk mendapatkan label merek: MyDuitGweh (NamaDuit)
String brandLabel(dynamic duit) => getBrandLabel(duit);

/// Implementasi ekstraksi nama pendek jenis duit
String getDuitShortName(dynamic duit) {
  if (duit == null) return 'Semua';
  final str = duit.toString().toLowerCase();
  if (str.contains('utama') || str.contains('harian') || str.contains('daily')) return 'Utama';
  if (str.contains('saldo') || str.contains('balance')) return 'Saldo';
  if (str.contains('tabungan') || str.contains('saving')) return 'Tabungan';
  if (str.contains('pencapaian') || str.contains('goal')) return 'Pencapaian';
  if (str.contains('semua')) return 'Semua';
  return 'Semua';
}

/// Implementasi label merek MyDuitGweh (NamaDuit)
String getBrandLabel(dynamic duit) {
  return '${AppLabels.appName} (${getDuitShortName(duit)})';
}

