import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/widgets/numeric_keypad.dart';
import '../../../data/repositories/providers.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  String _enteredPin = '';
  String? _errorMessage;
  Timer? _countdownTimer;
  int _lockoutSeconds = 0;

  @override
  void initState() {
    super.initState();
    _checkLockoutStatus();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _checkLockoutStatus() {
    final security = ref.read(securityServiceProvider);
    if (security.isLockedOut) {
      _startLockoutCountdown(security.lockoutSecondsRemaining);
    }
  }

  void _startLockoutCountdown(int seconds) {
    setState(() {
      _lockoutSeconds = seconds > 0 ? seconds : 30;
      _enteredPin = '';
      _errorMessage =
          'Terlalu banyak percobaan salah. Coba lagi dalam $_lockoutSeconds detik.';
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_lockoutSeconds > 1) {
          _lockoutSeconds--;
          _errorMessage =
              'Terlalu banyak percobaan salah. Coba lagi dalam $_lockoutSeconds detik.';
        } else {
          _lockoutSeconds = 0;
          _errorMessage = null;
          timer.cancel();
          final security = ref.read(securityServiceProvider);
          security.resetFailedAttempts();
        }
      });
    });
  }

  void _onDigitPressed(String digit) {
    if (_lockoutSeconds > 0) return;

    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = null;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspacePressed() {
    if (_lockoutSeconds > 0) return;

    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _verifyPin() async {
    final security = ref.read(securityServiceProvider);
    final isValid = await security.verifyPin(_enteredPin);

    if (isValid) {
      ref.read(isAppLockedProvider.notifier).state = false;
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/beranda');
        }
      }
    } else {
      if (security.isLockedOut) {
        _startLockoutCountdown(security.lockoutSecondsRemaining);
      } else {
        setState(() {
          final attemptsLeft = 5 - security.failedAttempts;
          _errorMessage =
              'PIN salah! Sisa percobaan: $attemptsLeft kali.';
          _enteredPin = '';
        });
      }
    }
  }

  // Dialog Lupa PIN (2 Langkah)
  Future<void> _handleForgotPin() async {
    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.expense),
            const SizedBox(width: 8),
            Text(
              'Lupa PIN?',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'PIN dienkripsi secara aman demi privasi Anda dan tidak dapat dipulihkan. '
          'Satu-satunya cara untuk masuk kembali adalah dengan MENGHAPUS SEMUA DATA aplikasi.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lanjut ke Hapus Data'),
          ),
        ],
      ),
    );

    if (step1 != true || !mounted) return;

    // Langkah 2: Konfirmasi Final
    final step2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Konfirmasi Hapus Permanen',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: AppColors.expense,
          ),
        ),
        content: Text(
          'Apakah Anda benar-benar yakin? Semua catatan harian, saldo, tabungan, dan target impian akan terhapus bersih dan tidak dapat dikembalikan.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Hapus Semua'),
          ),
        ],
      ),
    );

    if (step2 == true && mounted) {
      // Hapus data keamanan & shared preferences
      final security = ref.read(securityServiceProvider);
      await security.wipeAllSecurityData();

      final prefs = ref.read(preferencesServiceProvider);
      await prefs.clearAll();

      // Reset state provider
      ref.read(userNameProvider.notifier).updateName('');
      await ref.read(isPinEnabledProvider.notifier).setEnabled(false);
      ref.read(isAppLockedProvider.notifier).state = false;

      // Reset repositories jika memungkinkan
      ref.invalidate(walletRepositoryProvider);
      ref.invalidate(categoryRepositoryProvider);
      ref.invalidate(transactionRepositoryProvider);
      ref.invalidate(savingGoalRepositoryProvider);

      if (mounted) {
        context.go('/panduan');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userName = ref.watch(userNameProvider);

    return PopScope(
      canPop: false, // Jangan biarkan tombol back menutup layar kunci
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),

                        // Ikon Gembok Kunci
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 34,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Teks Sapaan & Instruksi
                        Text(
                          userName.isNotEmpty ? 'Halo, $userName!' : 'MyDuitGweh Terkunci',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Masukkan 4 digit PIN untuk membuka aplikasi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 4 Indikator Bulatan PIN
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            final isFilled = index < _enteredPin.length;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isFilled ? AppColors.primary : Colors.transparent,
                                border: Border.all(
                                  color: isFilled
                                      ? AppColors.primary
                                      : (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder),
                                  width: 2.5,
                                ),
                              ),
                            );
                          }),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.expense,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],

                        const Spacer(),

                        // Keypad Angka
                        NumericKeypad(
                          enabled: _lockoutSeconds == 0,
                          onDigitPressed: _onDigitPressed,
                          onBackspacePressed: _onBackspacePressed,
                        ),

                        const SizedBox(height: 12),

                        // Tombol Lupa PIN
                        TextButton(
                          onPressed: _handleForgotPin,
                          child: Text(
                            'Lupa PIN?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.expense,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
