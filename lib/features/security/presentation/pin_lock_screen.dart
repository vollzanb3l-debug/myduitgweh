import '../../../core/services/total_reset_service.dart';
import '../../../core/widgets/widgets.dart';
import 'create_pin_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/widgets/numeric_keypad.dart';

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

  // Dialog Lupa PIN: Pertanyaan Pemulihan & Reset Total
  Future<void> _handleForgotPin() async {
    final security = ref.read(securityServiceProvider);
    final questions = await security.getRecoveryQuestions();

    if (questions != null && questions.length >= 2) {
      if (!mounted) return;
      await _showAnswerRecoveryDialog(questions);
    } else {
      if (!mounted) return;
      await _showResetConfirmationFlow();
    }
  }

  Future<void> _showAnswerRecoveryDialog(List<String> questions) async {
    final q1 = questions[0];
    final q2 = questions[1];
    final ans1Ctrl = TextEditingController();
    final ans2Ctrl = TextEditingController();
    String? errorText;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pertanyaan Pemulihan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Jawab kedua pertanyaan untuk membuat PIN baru tanpa kehilangan data keuangan Anda.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pertanyaan 1:',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      q1,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: ans1Ctrl,
                      decoration: const InputDecoration(hintText: 'Jawaban Anda...'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pertanyaan 2:',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      q2,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: ans2Ctrl,
                      decoration: const InputDecoration(hintText: 'Jawaban Anda...'),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText!,
                        style: const TextStyle(
                          color: AppColors.expense,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    PrimaryButton(
                      text: 'Verifikasi Jawaban',
                      onPressed: () async {
                        final ans1 = ans1Ctrl.text.trim();
                        final ans2 = ans2Ctrl.text.trim();

                        if (ans1.isEmpty || ans2.isEmpty) {
                          setModalState(() => errorText = 'Harap isi kedua jawaban');
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(context);
                        final security = ref.read(securityServiceProvider);
                        final isValid = await security.verifyRecoveryAnswers(a1: ans1, a2: ans2);

                        if (isValid) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Jawaban benar! Silakan buat PIN baru.',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: AppColors.income,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            nav.push(
                              MaterialPageRoute(
                                builder: (_) => const CreatePinScreen(isChangingPin: true),
                              ),
                            );
                          }
                        } else {
                          if (security.isRecoveryLockedOut) {
                            if (ctx.mounted) Navigator.pop(ctx);
                            _startLockoutCountdown(30);
                            await _showHardForgotDialog();
                          } else {
                            final attemptsLeft = 5 - security.failedRecoveryAttempts;
                            setModalState(() {
                              errorText = 'Jawaban salah! Sisa percobaan: $attemptsLeft kali.';
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showResetConfirmationFlow();
                        },
                        child: Text(
                          'Saya benar-benar lupa -> Hapus Semua Data',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.expense,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showHardForgotDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Batas Percobaan Habis'),
        content: const Text(
          'Anda telah salah menjawab pemulihan 5 kali. Silakan tunggu 30 detik atau lakukan Reset Total.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tunggu'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showResetConfirmationFlow();
            },
            child: const Text('Hapus Semua Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _showResetConfirmationFlow() async {
    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.expense),
            const SizedBox(width: 8),
            Text(
              'Hapus Semua Data?',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'SEMUA DATA AKAN HILANG PERMANEN DAN TIDAK BISA DIKEMBALIKAN:\n\n'
          '• Semua transaksi dan riwayat\n'
          '• Akun saldo, tabungan, dan target impian\n'
          '• Seluruh pengaturan dan PIN keamanan\n\n'
          'Aplikasi akan dikembalikan ke kondisi awal seperti baru diinstal.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5),
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
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );

    if (step1 != true || !mounted) return;

    final step2 = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        String input = '';
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final isMatch = input.trim() == 'HAPUS';
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Ketik "HAPUS" untuk Konfirmasi',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: AppColors.expense,
                  fontSize: 16,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Untuk memastikan Anda benar-benar yakin, ketik kata HAPUS di bawah ini:',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Ketik HAPUS',
                    ),
                    onChanged: (val) {
                      setDialogState(() {
                        input = val;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.expense,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isMatch ? () => Navigator.of(dialogCtx).pop(true) : null,
                  child: const Text('HAPUS SEMUA DATA'),
                ),
              ],
            );
          },
        );
      },
    );

    if (step2 == true && mounted) {
      await TotalResetService.performTotalReset(ref);
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
