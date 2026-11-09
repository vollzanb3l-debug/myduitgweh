# Changelog MyDuitGweh

Semua perubahan penting pada aplikasi MyDuitGweh dicatat dalam dokumen ini.

## [1.0.2] - 2026-11-09 (Tahap 18)

### Perbaikan Regresi & Peningkatan Kualitas
- **Pemisahan Kategori & Pemulihan Warna Terpusat (Poin 1)**:
  - Mengembalikan isolasi kategori per Duit: membuka form transaksi dari Duit Utama hanya menampilkan kategori Utama; Duit Saldo hanya kategori Saldo; Duit Tabungan hanya kategori Tabungan.
  - Memusatkan tabel konstanta kategori bawaan, palet warna cerah, dan pemetaan ikon ke `lib/core/constants/category_constants.dart`.
  - Mengembalikan tampilan warna-warni pada ikon kategori di seluruh tema (Terang maupun Gelap) tanpa tampilan abu-abu mati.
  - Memberikan warna fallback cerah deterministik dari palet aplikasi untuk kategori kustom buatan pengguna.
  - Migrasi database schemaVersion 7 non-destruktif: memperbaiki label ledger bawaan yang sempat salah tanpa menghapus, mengubah, atau merusak kategori kustom dan transaksi lama pengguna.
- **Pemisahan Alur Duit Pencapaian (Poin 2)**:
  - Memisahkan secara tegas dua tindakan berbeda: **"Buat / Ubah Target"** (nama, nominal target, deadline, ikon, catatan) vs **"Setor ke Target"** (target terpilih, nominal setor, tanggal setor, catatan opsional). Formulir setor TIDAK LAGI meminta nominal target.
  - Tombol "+" di Duit Pencapaian memberikan pilihan dialog jelas antara "Setor ke Target" atau "Buat Target Baru" jika target sudah ada (langsung "Buat Target Baru" jika belum ada target).
  - Tombol "Setor" pada kartu target langsung membuka form setoran dengan target tersebut sudah terpilih otomatis tanpa perlu dropdown.
  - Setor mandiri langsung menambah progres target dan nominal terkumpul secara reaktif tanpa syarat potong duit lain; opsi potong catatan lain tetap berfungsi dengan pemotongan saldo sumber yang sinkron.
- **Komponen Item Riwayat Terpadu & Alur Hapus Transaksi (Poin 3)**:
  - Menstandarkan komponen riwayat transaksi di seluruh aplikasi (`TransactionListItem`) pada Riwayat Utama, Duit Utama, Duit Saldo, Duit Tabungan, Duit Pencapaian, dan Beranda.
  - Menampilkan ikon kategori dengan warna asli, judul kategori/target, catatan, tanggal, format nominal tegas (+ hijau / - merah), tombol tempat sampah, dan gestur geser (swipe-to-delete).
  - Dialog konfirmasi hapus transaksi yang transparan: menjelaskan kategori, nominal, tanggal, serta dampak ke saldo masing-masing Duit.
  - Penghapusan transaksi atomik: menghapus setoran pencapaian otomatis mengurangi progres target; menghapus transaksi transfer/potong antar-duit otomatis menghapus kedua pasangan transaksi dan mengembalikan saldo kedua duit secara bersih di level transaksi database.
- **Pengaman Kualitas & QA (Poin 4)**:
  - Menambahkan rangkaian automated regression tests (`test/tahap_18_regression_safeguards_test.dart`) untuk isolasi kategori, validitas warna, setoran target mandiri & potong duit, penghapusan transaksi atomik, dan konsistensi saldo.
  - Menyusun dokumen panduan pengujian manual 12 langkah cepat sebelum rilis (`docs/QA_CHECKLIST.md`).
  - Memperbarui aturan kerja proyek pada `PROJECT.md`.

---

## [1.0.1] - 2026-11-09 (Tahap 17)

### Fitur & Peningkatan
- **Navigasi Periode Riwayat Transaksi**:
  - Menambahkan bar navigasi periode dengan tombol panah kiri/kanan pada filter Harian, Mingguan, dan Bulanan di Riwayat dan layar tiap Duit.
  - Panah kanan otomatis nonaktif saat berada di periode berjalan (mencegah geser ke masa depan).
  - Ketuk judul periode untuk langsung memilih tanggal/minggu/bulan via date picker.
  - Tombol cepat "Kembali ke Hari Ini / Minggu Ini / Bulan Ini" saat sedang meninjau periode masa lalu.
  - Menambahkan opsi filter **"Semua"** untuk menampilkan seluruh riwayat transaksi tanpa batas waktu dengan sistem paging bertahap (lazy loading) yang ringan.
  - Ringkasan pemasukan, pengeluaran, dan subtotal per tanggal mengikuti periode yang sedang dilihat.
  - Rekomendasi lompat ke periode berisi data saat periode yang dipilih masih kosong.
- **Setor Duit Pencapaian**:
  - Menjamin setoran ke target impian langsung dapat digunakan tanpa mewajibkan mencatat transaksi di duit lain terlebih dahulu.
  - Setoran mandiri langsung menambah saldo impian secara mandiri, sementara opsi potong dompet tetap tersedia sebagai pilihan opsional.
  - Validasi nominal lebih dari Rp 0 dan maksimal 15 digit.
- **Sinkronisasi Versi Terpusat**:
  - Versi aplikasi terpusat pada `AboutText.appVersion` (`1.0.1+2`), tersinkron otomatis pada berkas cadangan dan halaman Pengaturan/Tentang.

### Pemeliharaan & Resiliensi
- Menjaga data lama, kompatibilitas mundur impor backup (v1, v2, v3), dan integritas saldo di seluruh periode waktu.

---

## [1.0.0] - 2026-10-28 (Tahap 16)
- Rilis perdana dengan arsitektur 4 jenis Duit (Utama, Saldo, Tabungan, Pencapaian).
- Penghilangan konsep akun/dompet perbankan yang rumit menjadi satu dompet internal otomatis per Duit.
- Penyimpanan lokal SQLite (Drift) persisten dan cadangan JSON v3.

