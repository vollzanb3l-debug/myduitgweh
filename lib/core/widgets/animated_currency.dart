import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state_provider.dart';
import '../utils/formatters.dart';
import 'money_text.dart';

/// Widget untuk menampilkan angka saldo/rupiah dengan animasi menghitung naik (counting up).
/// Mendukung fitur privasi saldo (hideBalanceProvider) dan FittedBox agar tidak overflow/turun per huruf.
class AnimatedRupiahCounter extends ConsumerWidget {
  final int amount;
  final TextStyle? style;
  final Duration duration;
  final String prefix;
  final bool forceShow;
  final Alignment alignment;

  const AnimatedRupiahCounter({
    super.key,
    required this.amount,
    this.style,
    this.duration = const Duration(milliseconds: 700),
    this.prefix = '',
    this.forceShow = false,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHidden = ref.watch(hideBalanceProvider);

    if (isHidden && !forceShow) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Text(
          prefix.isNotEmpty && !prefix.startsWith('+') && !prefix.startsWith('-')
              ? '$prefix${MoneyText.hiddenText}'
              : MoneyText.hiddenText,
          style: style,
          maxLines: 1,
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey(amount),
      tween: Tween<double>(begin: 0, end: amount.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final currentInt = value.round();
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment,
          child: Text(
            '$prefix${formatRupiah(currentInt)}',
            style: style,
            maxLines: 1,
          ),
        );
      },
    );
  }
}

/// Alias untuk AnimatedRupiahCounter
typedef AnimatedCurrency = AnimatedRupiahCounter;
