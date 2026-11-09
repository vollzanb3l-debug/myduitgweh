import 'package:intl/intl.dart';

const List<String> _namaBulanId = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember'
];

const List<String> _namaBulanSingkatId = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des'
];

/// Memformat angka nominal menjadi format Rupiah standar Indonesia,
/// contoh: 1500000 -> "Rp 1.500.000"
String formatRupiah(int amount) {
  try {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount).trim();
  } catch (_) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return 'Rp $formatted';
  }
}

/// Memformat tanggal menjadi format deskriptif bahasa Indonesia,
/// contoh: DateTime(2026, 10, 26) -> "26 Oktober 2026"
String formatTanggal(DateTime date) {
  try {
    return DateFormat('d MMMM yyyy', 'id_ID').format(date);
  } catch (_) {
    final bulan = (date.month >= 1 && date.month <= 12)
        ? _namaBulanId[date.month - 1]
        : date.month.toString();
    return '${date.day} $bulan ${date.year}';
  }
}

/// Memformat tanggal dalam bentuk ringkas,
/// contoh: DateTime(2026, 10, 26) -> "26 Okt 2026"
String formatTanggalSingkat(DateTime date) {
  try {
    return DateFormat('d MMM yyyy', 'id_ID').format(date);
  } catch (_) {
    final bulan = (date.month >= 1 && date.month <= 12)
        ? _namaBulanSingkatId[date.month - 1]
        : date.month.toString();
    return '${date.day} $bulan ${date.year}';
  }
}
