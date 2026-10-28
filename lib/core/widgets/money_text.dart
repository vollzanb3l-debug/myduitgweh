import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state_provider.dart';
import '../utils/formatters.dart';

/// Widget bersama untuk menampilkan nominal mata uang rupiah dengan:
/// 1. Otomatis menyembunyikan nominal menjadi "Rp ••••••" jika fitur privasi saldo aktif
/// 2. Menghindari pembungkusan per-huruf (bug teks turun ke bawah) dengan FittedBox dan maxLines: 1
/// 3. Aman untuk nominal besar tanpa overflow
class MoneyText extends ConsumerWidget {
  final int amount;
  final TextStyle? style;
  final String prefix;
  final bool forceShow;
  final Alignment alignment;
  final dynamic duit;

  const MoneyText({
    super.key,
    required this.amount,
    this.style,
    this.prefix = '',
    this.forceShow = false,
    this.alignment = Alignment.centerLeft,
    this.duit,
  });

  /// Teks sensor default saat saldo disembunyikan
  static const String hiddenText = 'Rp ••••••';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isHidden;
    if (duit != null) {
      final key = normalizeDuitKey(duit);
      isHidden = ref.watch(isDuitHiddenProvider(key));
    } else {
      isHidden = ref.watch(hideBalanceProvider);
    }

    if (isHidden && !forceShow) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Text(
          prefix.isNotEmpty && !prefix.startsWith('+') && !prefix.startsWith('-')
              ? '$prefix$hiddenText'
              : hiddenText,
          style: style,
          maxLines: 1,
        ),
      );
    }

    final formatted = formatRupiah(amount);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(
        '$prefix$formatted',
        style: style,
        maxLines: 1,
      ),
    );
  }
}

/// Helper function untuk format rupiah yang otomatis sensor jika saldo disembunyikan
String formatRupiahOrHidden(int amount, {required bool isHidden, String prefix = ''}) {
  if (isHidden) {
    return MoneyText.hiddenText;
  }
  return '$prefix${formatRupiah(amount)}';
}
