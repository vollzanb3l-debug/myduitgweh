import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class NumericKeypad extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final Widget? leftActionButton;
  final bool enabled;

  const NumericKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    this.leftActionButton,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(context, ['1', '2', '3'], isDark),
        const SizedBox(height: 14),
        _buildRow(context, ['4', '5', '6'], isDark),
        const SizedBox(height: 14),
        _buildRow(context, ['7', '8', '9'], isDark),
        const SizedBox(height: 14),
        _buildBottomRow(context, isDark),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<String> digits, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((digit) {
        return _buildKey(
          context: context,
          child: Text(
            digit,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.darkAccent,
            ),
          ),
          onTap: enabled ? () => onDigitPressed(digit) : null,
          isDark: isDark,
        );
      }).toList(),
    );
  }

  Widget _buildBottomRow(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Tombol kiri bawah (bisa kosong atau aksi khusus)
        SizedBox(
          width: 72,
          height: 72,
          child: Center(child: leftActionButton ?? const SizedBox.shrink()),
        ),

        // Angka 0
        _buildKey(
          context: context,
          child: Text(
            '0',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.darkAccent,
            ),
          ),
          onTap: enabled ? () => onDigitPressed('0') : null,
          isDark: isDark,
        ),

        // Tombol Hapus (Backspace)
        _buildKey(
          context: context,
          child: Icon(
            Icons.backspace_outlined,
            size: 26,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          onTap: enabled ? onBackspacePressed : null,
          isDark: isDark,
          isActionButton: true,
        ),
      ],
    );
  }

  Widget _buildKey({
    required BuildContext context,
    required Widget child,
    required VoidCallback? onTap,
    required bool isDark,
    bool isActionButton = false,
  }) {
    final bgColor = isDark ? AppColors.darkCard : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(36),
        splashColor: AppColors.primary.withValues(alpha: 0.3),
        highlightColor: AppColors.primary.withValues(alpha: 0.15),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActionButton ? Colors.transparent : bgColor,
            boxShadow: isActionButton
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
