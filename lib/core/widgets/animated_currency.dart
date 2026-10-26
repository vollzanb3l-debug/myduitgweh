import 'package:flutter/material.dart';
import '../utils/formatters.dart';

/// Widget untuk menampilkan angka saldo/rupiah dengan animasi menghitung naik (counting up).
class AnimatedRupiahCounter extends StatelessWidget {
  final int amount;
  final TextStyle? style;
  final Duration duration;
  final String prefix;

  const AnimatedRupiahCounter({
    super.key,
    required this.amount,
    this.style,
    this.duration = const Duration(milliseconds: 700),
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(amount),
      tween: Tween<double>(begin: 0, end: amount.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final currentInt = value.round();
        return Text(
          '$prefix${formatRupiah(currentInt)}',
          style: style,
        );
      },
    );
  }
}
