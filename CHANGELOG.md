# Changelog MyDuitGweh

Semua perubahan penting pada aplikasi MyDuitGweh dicatat dalam dokumen ini.

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

