# Checklist QA Manual Rilis MyDuitGweh

Dokumen ini berisi panduan 12 langkah uji cepat (smoke test ~5 menit) sebelum rilis APK/pembaruan ke pengguna. Lakukan pengujian langsung pada perangkat Android fisik atau emulator.

---

### 1. Tambah Transaksi Duit Utama
- [ ] Buka tab **Beranda** -> pilih **MyDuitGweh (Utama)** -> tekan tombol **+**.
- [ ] Pastikan hanya kategori Duit Utama yang muncul (Makan & Minum, Transport, Jajan, dll). Tidak ada kategori Bank, Tagihan, atau Penarikan.
- [ ] Pastikan seluruh ikon kategori berwarna cerah sesuai jenisnya (baik pada tema Terang maupun Gelap).
- [ ] Simpan transaksi pengeluaran (misal Rp 25.000). Saldo Duit Utama langsung berkurang secara reaktif.

### 2. Tambah Transaksi Duit Saldo
- [ ] Buka tab **Duit** -> pilih **Duit Saldo** -> tekan tombol **+ Tambah Transaksi**.
- [ ] Pastikan hanya kategori Duit Saldo yang tampil (Tunai, Bank, E-Wallet, Tagihan, Transfer, Biaya Admin).
- [ ] Tidak ada pilihan akun berputar atau permintaan membuat akun.
- [ ] Simpan transaksi pemasukan (misal Isi Saldo Rp 100.000). Saldo Duit Saldo bertambah.

### 3. Tambah Transaksi Duit Tabungan
- [ ] Buka tab **Duit** -> pilih **Duit Tabungan** -> tekan tombol **+ Tambah Transaksi**.
- [ ] Pastikan hanya kategori Tabungan yang tampil (Setoran, Bunga/Bonus, Penarikan).
- [ ] Masukkan nominal setoran tabungan (misal Rp 50.000). Saldo Tabungan bertambah.

### 4. Tambah Kategori Kustom (+ Lainnya)
- [ ] Pada formulir transaksi, tekan tombol **+ Lainnya**.
- [ ] Buat kategori baru (misal "Kopi Santai").
- [ ] Pastikan kategori tersimpan, langsung terpilih, dan memiliki warna cerah dari palet warna aplikasi (bukan abu-abu mati).

### 5. Buat Target Duit Pencapaian
- [ ] Buka tab **Duit** -> pilih **Duit Pencapaian**.
- [ ] Jika belum ada target, tekan tombol **Buat Pencapaian Pertama**.
- [ ] Masukkan Nama Target (misal "Beli Laptop") dan Nominal Target (misal Rp 10.000.000). Simpan.
- [ ] Kartu target tampil dengan progres 0% dan nominal terkumpul Rp 0.

### 6. Setor ke Target (Mandiri)
- [ ] Pada kartu target, tekan tombol **Setor**.
- [ ] Pastikan form setor HANYA meminta: nama target (terkunci), nominal setoran, tanggal setoran, dan catatan. TIDAK ADA isian nominal target.
- [ ] Masukkan setoran Rp 500.000 (tanpa centang potong duit lain). Simpan.
- [ ] Progres target langsung bertambah (misal 5% Rp 500.000) dan transaksi muncul di riwayat bawah tanpa restart aplikasi.

### 7. Setor ke Target (Potong dari Duit Lain)
- [ ] Tekan tombol **+** di AppBar Duit Pencapaian -> pilih **Setor ke Target**.
- [ ] Masukkan nominal Rp 200.000.
- [ ] Aktifkan tombol geser **Potong dari catatan lain** -> pilih Duit Utama.
- [ ] Simpan. Pastikan saldo target bertambah Rp 200.000 DAN saldo Duit Utama berkurang Rp 200.000.

### 8. Riwayat Transaksi & Filter Periode
- [ ] Buka tab **Riwayat**.
- [ ] Uji filter periode: **Harian**, **Mingguan**, **Bulanan**, dan **Semua**.
- [ ] Tekan tombol panah navigasi **<** dan **>** untuk berpindah ke periode lalu/berikutnya.
- [ ] Pastikan transaksi lama tampil sesuai periodenya dan muncul tombol pintas **Kembali ke Periode Ini**.

### 9. Hapus Transaksi Terpadu (Swipe / Tempat Sampah)
- [ ] Di layar Riwayat atau daftar transaksi tiap Duit, geser transaksi ke kiri atau tekan ikon tempat sampah.
- [ ] Dialog konfirmasi tampil dengan rincian kategori, nominal, tanggal, serta dampak ke saldo.
- [ ] Hapus transaksi biasa: saldo duit tersebut langsung kembali seperti semula.
- [ ] Hapus transaksi setoran pencapaian (yang potong duit lain): kedua catatan terhapus sekaligus dan saldo asal serta target kembali sinkron.

### 10. Sembunyikan Saldo (Privasi)
- [ ] Tekan ikon mata di kartu saldo beranda atau tiap Duit.
- [ ] Seluruh nominal saldo berubah menjadi masking `Rp ••••••`.
- [ ] Tekan kembali untuk menampilkan angka saldo.

### 11. Mode Terang & Gelap
- [ ] Buka tab **Pengaturan** -> ganti tema dari **Terang** ke **Gelap** dan sebaliknya.
- [ ] Pastikan kontras teks nyaman dibaca, kartu putih/abu gelap bersih, dan ikon kategori tetap cerah berwarna.

### 12. Cadangkan & Pulihkan Data (Backup & Restore)
- [ ] Di tab **Pengaturan**, pilih **Cadangkan Data** -> simpan berkas JSON cadangan.
- [ ] Tambahkan transaksi baru sembarang, lalu lakukan **Pulihkan Data** dari berkas cadangan tadi.
- [ ] Pastikan data kembali persis ke kondisi saat dicadangkan tanpa ada kategori yang tertukar atau data yang hilang.
