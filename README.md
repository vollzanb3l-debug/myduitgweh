# MyDuitGweh 💰

Aplikasi pencatat keuangan pribadi modern untuk Android yang beroperasi 100% secara offline. Dirancang dengan antarmuka yang ramah, hangat, dan menyenangkan—terinspirasi oleh nuansa platform donasi kreator Indonesia dengan dominasi warna kuning-oranye hangat (`#F9A826`) dan aksen gelap pekat (`#2B2B2B`).

---

## 🌟 Fitur Utama

### 1. 🏠 Layar Beranda (Home)
- **Kartu Ringkasan Saldo**: Total saldo keseluruhan dengan animasi angka menghitung naik (*counting-up animation*), serta perbandingan pemasukan & pengeluaran bulan ini.
- **Pintasan Aksi Cepat**: Tombol bulat praktis untuk *Tambah Pemasukan*, *Tambah Pengeluaran*, *Riwayat*, dan *Statistik*.
- **Dompet Saya**: Kartu geser horizontal menampilkan rincian saldo masing-masing dompet (*Uang Harian*, *Saldo Utama*, *Tabungan*).
- **Mini Grafik Tren Pengeluaran**: Visualisasi garis interaktif pengeluaran 7 hari terakhir.
- **Transaksi Terakhir**: Daftar 5 transaksi terkini dengan status kategori dan tanggal.

### 2. 📝 Tambah & Ubah Transaksi
- Pilihan jenis transaksi (*Pengeluaran* / *Pemasukan*) dengan pewarnaan intuitif.
- Input nominal rupiah otomatis dengan format instan (*currency input formatter*).
- Grid kategori visual dengan ikon membulat dan warna tematik.
- Pilihan dompet sumber dana, kalender pemilih tanggal, serta kolom catatan opsional.
- Validasi input lengkap sebelum data tersimpan.

### 3. 📜 Riwayat Transaksi (History)
- Filter rentang waktu: **Harian**, **Mingguan**, dan **Bulanan**.
- Pengelompokan transaksi per tanggal lengkap dengan subtotal harian.
- Geser ke kiri (*Swipe-to-delete*) untuk menghapus transaksi dengan konfirmasi dialog.
- Ketuk transaksi untuk membuka form edit dan memperbarui data.

### 4. 💳 Manajemen Dompet & Transfer
- Pengelolaan dompet fleksibel: tambah dompet baru, edit informasi, serta hapus dompet aman (hanya dapat dihapus jika belum memiliki riwayat transaksi).
- **Transfer Antar-Dompet**: Fitur pemindahan dana antar-dompet yang otomatis tercatat sebagai sepasang transaksi terkait (pengeluaran pada dompet asal dan pemasukan pada dompet tujuan) agar saldo tetap akurat.

### 5. 🎯 Target Tabungan (Saving Goals)
- Manajemen target impian finansial dengan progress bar persentase membulat berwarna kuning-oranye.
- Estimasi sisa setoran yang perlu ditabung per bulan jika target memiliki tenggat waktu.
- Fitur **Setor Tabungan** langsung ke target impian.
- Efek perayaan sederhana (centang & status selesai) saat target tabungan berhasil tercapai.

### 6. 📊 Statistik & Grafik Finansial
- Pemilih periode fleksibel: **Minggu Ini**, **Bulan Ini**, dan **Tahun Ini** dilengkapi tombol panah geser periode sebelumnya/berikutnya.
- Ringkasan pemasukan, pengeluaran, dan selisih bersih (*surplus* berwarna hijau, *defisit* berwarna merah).
- **Donut/Pie Chart**: Proporsi pengeluaran per kategori dilengkapi persentase dan nominal.
- **Bar Chart**: Perbandingan arus kas pemasukan vs pengeluaran per hari (mingguan), per minggu (bulanan), atau per bulan (tahunan).
- Daftar **Pengeluaran Terbesar** (Top 3 Kategori).

### 7. ✨ Polesan Visual & Aksesibilitas
- Animasi transisi halus antar-layar dan animasi staggered list item.
- Dukungan penuh **Tema Terang (Light)** dan **Tema Gelap (Dark)**.
- Desain responsif, aman dari layout overflow pada layar kecil (lebar 320dp).
- Ikon aplikasi bertema *MyDuitGweh* yang dikonfigurasi melalui `flutter_launcher_icons`.

---

## 🛠️ Tech Stack & Arsitektur

- **Framework**: Flutter (Dart 3)
- **State Management**: `flutter_riverpod`
- **Navigasi & Routing**: `go_router`
- **Penyimpanan Lokal (Offline Database)**: `drift` (SQLite) dengan `sqlite3_flutter_libs` & `path_provider`
- **Visualisasi Grafik**: `fl_chart`
- **Tipografi**: `google_fonts` (Plus Jakarta Sans)
- **Format Tanggal & Rupiah**: `intl`
- **Ikon Aplikasi**: `flutter_launcher_icons`

---

## 📁 Struktur Folder Proyek

```text
lib/
├── main.dart                          # Titik masuk aplikasi
├── app.dart                           # Inisialisasi konfigurasi tema, router, & Riverpod
├── core/                              # Pondasi & utilitas global
│   ├── constants/                     # Warna (AppColors) & konstanta (AppConstants)
│   ├── routes/                        # Konfigurasi rute navigasi (AppRouter)
│   ├── theme/                         # Pengaturan tema terang & gelap (AppTheme)
│   ├── utils/                         # Formatter rupiah, tanggal, currency input, helper ikon
│   └── widgets/                       # Widget umum (AppCard, PrimaryButton, EmptyState, dll)
├── data/                              # Lapisan data & database lokal
│   ├── database/                      # Drift database, skema tabel, seeding data awal
│   ├── models/                        # Domain model (Wallet, Category, Transaction, SavingGoal)
│   └── repositories/                  # Repository CRUD & Riverpod Stream providers
└── features/                          # Modul berbasis fitur
    ├── splash/                        # Layar pembuka (Splash screen)
    ├── home/                          # Layar Beranda & overview provider
    ├── transactions/                  # Layar Tambah Transaksi & Riwayat
    ├── wallets/                       # Layar Dompet & Target Tabungan
    └── statistics/                    # Layar Statistik & agregasi grafik
```

---

## 🚀 Cara Menjalankan Proyek

### 1. Prasyarat
- Flutter SDK (>= 3.16.0)
- Android Studio / Android SDK / Emulator atau perangkat fisik Android yang terhubung.

### 2. Pemasangan Dependensi
Jalankan perintah berikut di root repositori:
```bash
flutter pub get
```

### 3. Menjalankan Kode Generator (Drift Database)
Jika skema database diubah:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Menjalankan Aplikasi
```bash
flutter run
```

### 5. Menjalankan Analisis & Unit Testing
```bash
flutter analyze
flutter test
```

---

## 📦 Pembuatan APK Release (Build APK)

Untuk membuat file paket instalasi Android siap rilis (Release APK):

```bash
flutter build apk --release
```

### 📍 Lokasi File Hasil:
Setelah proses build selesai, file APK siap instal berada di:
```text
build/app/outputs/flutter-apk/app-release.apk
```
File APK tersebut dapat langsung disalin dan dipasang ke perangkat Android.
