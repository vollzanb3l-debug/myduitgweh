import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/widgets/widgets.dart';

class PinChoiceScreen extends ConsumerWidget {
  const PinChoiceScreen({super.key});

  Future<void> _skipPin(BuildContext context, WidgetRef ref) async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setHasSeenOnboarding(true);
    await ref.read(isPinEnabledProvider.notifier).setEnabled(false);
    ref.read(isAppLockedProvider.notifier).state = false;

    if (context.mounted) {
      context.go('/beranda');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              const Spacer(),

              // Ikon Gembok / Keamanan
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 54,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Judul & Teks Penjelasan
              Text(
                'Pakai PIN?',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Gunakan PIN 4 digit agar catatan keuangan Anda tetap privat dan aman saat ponsel dipinjam orang lain.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              // Tombol Buat PIN
              PrimaryButton(
                text: 'Buat PIN',
                onPressed: () => context.push('/buat-pin'),
              ),
              const SizedBox(height: 14),

              // Tombol Lewati Dulu
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _skipPin(context, ref),
                  child: Text(
                    'Lewati dulu',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
