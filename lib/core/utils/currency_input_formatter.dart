import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Ambil hanya karakter angka
    final cleanDigits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanDigits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Batasi maksimum angka agar tidak overflow integer (maksimal 15 digit)
    final truncatedDigits = cleanDigits.length > 15
        ? cleanDigits.substring(0, 15)
        : cleanDigits;

    final parsed = int.tryParse(truncatedDigits) ?? 0;
    final formatted = _formatter.format(parsed).trim();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Ekstrak integer murni dari teks yang telah diformat (maksimal 15 digit)
  static int parseRupiah(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return 0;
    final truncated = clean.length > 15 ? clean.substring(0, 15) : clean;
    return int.tryParse(truncated) ?? 0;
  }
}
