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

    // Batasi maksimum angka agar tidak overflow integer (maks 13 digit rupiah)
    final truncatedDigits = cleanDigits.length > 13
        ? cleanDigits.substring(0, 13)
        : cleanDigits;

    final parsed = int.tryParse(truncatedDigits) ?? 0;
    final formatted = _formatter.format(parsed).trim();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Ekstrak integer murni dari teks yang telah diformat
  static int parseRupiah(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }
}
