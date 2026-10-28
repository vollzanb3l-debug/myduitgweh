import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/widgets/widgets.dart';

class WelcomeNameScreen extends ConsumerStatefulWidget {
  const WelcomeNameScreen({super.key});

  @override
  ConsumerState<WelcomeNameScreen> createState() => _WelcomeNameScreenState();
}

class _WelcomeNameScreenState extends ConsumerState<WelcomeNameScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitName() async {
    final name = _nameController.text.trim();
    if (name.length < 2) {
      setState(() {
        _errorText = 'Nama wajib diisi minimal 2 karakter ya';
      });
      return;
    }

    // Simpan nama
    await ref.read(userNameProvider.notifier).updateName(name);

    if (mounted) {
      context.go('/pilihan-pin');
    }
  }

  Future<void> _handleRestoreOldData() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Pulihkan Data Lama',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Data cadangan (.json) Anda akan dipulihkan. Nama pengguna dan semua catatan akan dikembalikan.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pilih File'),
          ),
        ],
      ),
    );

    if (proceed != true || !mounted) return;

    final backup = BackupService.fromRef(ref);
    final jsonContent = await backup.pickBackupFile();
    if (jsonContent == null) return;

    final prelimError = backup.validateBackupPrelim(jsonContent);
    if (prelimError != null) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Berkas Tidak Sesuai'),
            content: Text(
              prelimError,
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Mengerti'),
              ),
            ],
          ),
        );
      }
      return;
    }

    final result = await backup.restoreBackup(jsonContent);
    if (!mounted) return;

    if (result.success) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.income),
              const SizedBox(width: 8),
              Text(
                'Pemulihan Berhasil',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data berhasil dipulihkan dari berkas cadangan:',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text('• ${result.restoredTransactions} Transaksi'),
              Text('• ${result.restoredWallets} Akun Dompet'),
              Text('• ${result.restoredGoals} Target Impian'),
              Text('• ${result.restoredCategories} Kategori'),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Selesai'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (result.userName != null && result.userName!.trim().isNotEmpty) {
        final name = result.userName!.trim();
        await ref.read(userNameProvider.notifier).updateName(name);
        if (mounted) {
          context.go('/pilihan-pin');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data berhasil dipulihkan. Silakan isi nama panggilan Anda untuk melanjutkan.',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.darkAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.isNotEmpty
                ? result.message
                : 'Gagal memulihkan cadangan. Pastikan berkas cadangan valid.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Ikon Maskot / Profil
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.waving_hand_rounded,
                  size: 38,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 28),

              // Judul & Deskripsi
              Text(
                'Selamat Datang di MyDuitGweh!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Biar makin akrab dan catatan keuangan terasa personal, siapa nama panggilan Anda?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 36),

              // Kolom Input Nama
              Text(
                'Nama Panggilan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Contoh: Budi, Sarah, Rizky',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  errorText: _errorText,
                ),
                onChanged: (val) {
                  if (_errorText != null && val.trim().length >= 2) {
                    setState(() {
                      _errorText = null;
                    });
                  }
                },
                onSubmitted: (_) => _submitName(),
              ),

              const SizedBox(height: 48),

              // Tombol Lanjut
              PrimaryButton(
                text: 'Lanjut',
                onPressed: _submitName,
              ),

              const SizedBox(height: 16),

              Center(
                child: TextButton.icon(
                  onPressed: _handleRestoreOldData,
                  icon: const Icon(Icons.restore_rounded, size: 18),
                  label: Text(
                    'Pernah memakai MyDuitGweh? Pulihkan data lama',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
