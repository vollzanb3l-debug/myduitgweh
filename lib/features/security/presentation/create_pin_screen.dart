import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/widgets/numeric_keypad.dart';

class CreatePinScreen extends ConsumerStatefulWidget {
  final bool isChangingPin;

  const CreatePinScreen({super.key, this.isChangingPin = false});

  @override
  ConsumerState<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends ConsumerState<CreatePinScreen> {
  bool _isConfirming = false;
  String _firstPin = '';
  String _confirmPin = '';
  String? _errorMessage;

  void _onDigitPressed(String digit) {
    if (!_isConfirming) {
      if (_firstPin.length < 4) {
        setState(() {
          _firstPin += digit;
          _errorMessage = null;
        });

        if (_firstPin.length == 4) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              setState(() {
                _isConfirming = true;
              });
            }
          });
        }
      }
    } else {
      if (_confirmPin.length < 4) {
        setState(() {
          _confirmPin += digit;
          _errorMessage = null;
        });

        if (_confirmPin.length == 4) {
          _verifyAndSave();
        }
      }
    }
  }

  void _onBackspacePressed() {
    setState(() {
      _errorMessage = null;
      if (!_isConfirming) {
        if (_firstPin.isNotEmpty) {
          _firstPin = _firstPin.substring(0, _firstPin.length - 1);
        }
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          // Kembali ke input PIN pertama
          _isConfirming = false;
        }
      }
    });
  }

  Future<void> _verifyAndSave() async {
    if (_confirmPin == _firstPin) {
      final security = ref.read(securityServiceProvider);
      await security.savePin(_firstPin);

      final prefs = ref.read(preferencesServiceProvider);
      await prefs.setHasSeenOnboarding(true);
      await ref.read(isPinEnabledProvider.notifier).setEnabled(true);
      ref.read(isAppLockedProvider.notifier).state = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isChangingPin
                  ? 'PIN berhasil diubah!'
                  : 'PIN keamanan berhasil dibuat!',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.income,
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (widget.isChangingPin) {
          context.pop();
        } else {
          context.go('/beranda');
        }
      }
    } else {
      setState(() {
        _errorMessage = 'PIN tidak cocok. Silakan ulangi konfirmasi.';
        _confirmPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentCode = _isConfirming ? _confirmPin : _firstPin;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isChangingPin ? 'Ubah PIN' : 'Buat PIN',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_isConfirming) {
              setState(() {
                _isConfirming = false;
                _confirmPin = '';
                _errorMessage = null;
              });
            } else {
              context.pop();
            }
          },
        ),
      ),
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
                      const SizedBox(height: 20),

                      // Judul & Petunjuk
                      Text(
                        _isConfirming ? 'Konfirmasi PIN Anda' : 'Masukkan 4 Digit PIN',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isConfirming
                            ? 'Ketik ulang PIN yang sama untuk memastikan'
                            : 'Gunakan kombinasi angka yang mudah Anda ingat',
                        textAlign: TextAlign.center,
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
                          final isFilled = index < currentCode.length;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFilled
                                  ? AppColors.primary
                                  : Colors.transparent,
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

                      // Keypad Angka Kustom
                      NumericKeypad(
                        onDigitPressed: _onDigitPressed,
                        onBackspacePressed: _onBackspacePressed,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
