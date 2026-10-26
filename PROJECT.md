# MyDuitGweh - Konteks Proyek

Aplikasi pencatat keuangan pribadi untuk Android yang berjalan secara offline.

---

## TUJUAN
Mencatat pemasukan dan pengeluaran harian, mengelola dompet (Uang Harian, Saldo, Tabungan), serta melihat statistik dengan grafik interaktif.

---

## TECH STACK
- **Framework**: Flutter + Dart
- **State Management**: flutter_riverpod
- **Routing & Navigasi**: go_router
- **Database Lokal**: drift (SQLite)
- **Visualisasi & Grafik**: fl_chart
- **Formatting**: intl (format rupiah & tanggal)
- **Tipografi**: google_fonts (Plus Jakarta Sans)

---

## STRUKTUR FOLDER (Berbasis Fitur)
```text
lib/
  main.dart
  app.dart
  core/
    theme/
    constants/
    utils/
    widgets/
  data/
    database/
    models/
    repositories/
  features/
    home/
      presentation/
      providers/
    transactions/
      presentation/
      providers/
    wallets/
      presentation/
      providers/
    savings/
      presentation/
      providers/
    statistics/
      presentation/
      providers/
    settings/
      presentation/
      providers/
assets/
  images/
  icons/
  mockups/
test/
```

---

## GAYA VISUAL
Terinspirasi dari nuansa platform donasi kreator Indonesia yang hangat, ramah, dan santai (tanpa meniru logo/nama/aset pihak mana pun):
- **Warna Utama**: Kuning-oranye hangat (`#F9A826`)
- **Aksen Gelap**: Gelap pekat (`#2B2B2B`)
- **Latar Terang**: Krem terang (`#FFF8EC`)
- **Kartu**: Putih bersih (`#FFFFFF`) dengan sudut membulat 16–20px dan bayangan sangat tipis (subtle soft shadow)
- **Tombol Utama**: Besar, berbentuk pill (`BorderRadius.circular(999)` / capsule), teks tebal
- **Font**: Plus Jakarta Sans (`google_fonts`), judul tebal, bersahabat dan santai
- **Format Mata Uang**: Selalu format rupiah standar Indonesia: `Rp 1.500.000`
- **Indikator Keuangan**: Pemasukan berwarna hijau, pengeluaran berwarna merah lembut
- **Mode Tema**: Mendukung tema terang (Light) dan gelap (Dark)

---

## ATURAN KERJA
1. Kerjakan **HANYA** yang diminta pada tiap tahap. Jangan menambah fitur lain di luar cakupan permintaan.
2. Seluruh teks antarmuka berbahasa Indonesia.
3. Kode rapi, nama jelas, tanpa kode mati (*dead code*).
4. Setiap tahap selesai: jalankan `flutter analyze` dan perbaiki semua masalah.
5. Di akhir tahap, tulis ringkasan singkat: file yang dibuat/diubah dan cara mencobanya.
6. Jika ada keputusan yang meragukan, pilih opsi paling sederhana dan catat secara transparan.
7. Gunakan istilah duit, bukan dompet atau catatan, pada teks antarmuka.
8. Label di bawah sapaan Beranda memakai format MyDuitGweh (NamaDuit).
