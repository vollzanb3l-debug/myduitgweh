import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/widgets/primary_button.dart';

class RecoveryQuestionsScreen extends ConsumerStatefulWidget {
  final bool isEditing;

  const RecoveryQuestionsScreen({
    super.key,
    this.isEditing = false,
  });

  @override
  ConsumerState<RecoveryQuestionsScreen> createState() =>
      _RecoveryQuestionsScreenState();
}

class _RecoveryQuestionsScreenState
    extends ConsumerState<RecoveryQuestionsScreen> {
  final _q1Ctrl = TextEditingController();
  final _a1Ctrl = TextEditingController();
  final _q2Ctrl = TextEditingController();
  final _a2Ctrl = TextEditingController();

  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadExistingQuestions();
    }
  }

  Future<void> _loadExistingQuestions() async {
    final security = ref.read(securityServiceProvider);
    final questions = await security.getRecoveryQuestions();
    if (questions != null && questions.length >= 2) {
      _q1Ctrl.text = questions[0];
      _q2Ctrl.text = questions[1];
    }
  }

  @override
  void dispose() {
    _q1Ctrl.dispose();
    _a1Ctrl.dispose();
    _q2Ctrl.dispose();
    _a2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final q1 = _q1Ctrl.text.trim();
    final a1 = _a1Ctrl.text.trim();
    final q2 = _q2Ctrl.text.trim();
    final a2 = _a2Ctrl.text.trim();

    if (q1.length < 5) {
      setState(() => _errorMessage = 'Pertanyaan 1 minimal 5 karakter');
      return;
    }
    if (a1.length < 2) {
      setState(() => _errorMessage = 'Jawaban 1 minimal 2 karakter');
      return;
    }
    if (q2.length < 5) {
      setState(() => _errorMessage = 'Pertanyaan 2 minimal 5 karakter');
      return;
    }
    if (a2.length < 2) {
      setState(() => _errorMessage = 'Jawaban 2 minimal 2 karakter');
      return;
    }
    if (q1.toLowerCase() == q2.toLowerCase()) {
      setState(() => _errorMessage = 'Pertanyaan 1 dan 2 harus berbeda');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final security = ref.read(securityServiceProvider);
    await security.saveRecoveryQuestions(q1: q1, a1: a1, q2: q2, a2: a2);

    if (!mounted) return;

    if (widget.isEditing) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pertanyaan pemulihan berhasil diperbarui'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Ubah Pertanyaan Pemulihan'
              : 'Pertanyaan Pemulihan',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: widget.isEditing,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      color: AppColors.primaryDark,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pertanyaan ini digunakan jika Anda lupa PIN. Jawaban Anda disimpan aman dan dienkripsi.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: isDark ? Colors.white : AppColors.darkAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Pertanyaan 1
              Text(
                'Pertanyaan 1 (Wajib)',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _q1Ctrl,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Apa nama hewan peliharaan pertamamu?',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Jawaban 1 (Wajib)',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _a1Ctrl,
                decoration: const InputDecoration(
                  hintText: 'Tulis jawaban pertanyaan 1...',
                ),
              ),

              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),

              // Pertanyaan 2
              Text(
                'Pertanyaan 2 (Wajib)',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _q2Ctrl,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Di kota mana orang tuamu pertama kali bertemu?',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Jawaban 2 (Wajib)',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _a2Ctrl,
                decoration: const InputDecoration(
                  hintText: 'Tulis jawaban pertanyaan 2...',
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.expense.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.expense, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.expense,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              PrimaryButton(
                text: _isLoading ? 'Menyimpan...' : 'Simpan & Lanjutkan',
                onPressed: _isLoading ? null : _handleSave,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
