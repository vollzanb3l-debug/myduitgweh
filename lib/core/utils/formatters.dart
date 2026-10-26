import 'package:intl/intl.dart';

/// Memformat angka nominal menjadi format Rupiah standar Indonesia,
/// contoh: 1500000 -> "Rp 1.500.000"
String formatRupiah(int amount) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return formatter.format(amount).trim();
}

/// Memformat tanggal menjadi format deskriptif bahasa Indonesia,
/// contoh: DateTime(2026, 10, 26) -> "26 Oktober 2026"
String formatTanggal(DateTime date) {
  return DateFormat('d MMMM yyyy', 'id_ID').format(date);
}

/// Memformat tanggal dalam bentuk ringkas,
/// contoh: DateTime(2026, 10, 26) -> "26 Okt 2026"
String formatTanggalSingkat(DateTime date) {
  return DateFormat('d MMM yyyy', 'id_ID').format(date);
}
