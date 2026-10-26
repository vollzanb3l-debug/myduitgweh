import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/widgets/numeric_keypad.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/providers.dart';
import '../../security/presentation/create_pin_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Dialog Ubah Nama
  Future<void> _showChangeNameDialog(String currentName) async {
    final nameCtrl = TextEditingController(text: currentName);
    String? errorText;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Ubah Nama Panggilan',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nama ini akan ditampilkan pada sapaan Beranda dan judul tabungan Anda.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Nama panggilan',
                    errorText: errorText,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.darkAccent,
                ),
                onPressed: () async {
                  final newName = nameCtrl.text.trim();
                  if (newName.length < 2) {
                    setModalState(() {
                      errorText = 'Nama minimal 2 karakter ya';
                    });
                    return;
                  }

                  await ref.read(userNameProvider.notifier).updateName(newName);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Nama berhasil diubah menjadi "$newName"'),
                        backgroundColor: AppColors.darkAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Dialog Minta PIN Saat Ini (untuk konfirmasi matikan PIN atau ubah PIN)
  Future<bool> _promptCurrentPin({required String title}) async {
    String pinInput = '';
    String? errorText;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.only(top: 24, bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx, false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ketik 4 digit PIN Anda saat ini',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4 Bulatan Indikator PIN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < pinInput.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
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
                            width: 2,
                          ),
                        ),
                      );
                    }),
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

                  const SizedBox(height: 24),

                  NumericKeypad(
                    onDigitPressed: (digit) async {
                      if (pinInput.length < 4) {
                        setModalState(() {
                          pinInput += digit;
                          errorText = null;
                        });

                        if (pinInput.length == 4) {
                          final security = ref.read(securityServiceProvider);
                          final isValid = await security.verifyPin(pinInput);
                          if (isValid) {
                            if (ctx.mounted) Navigator.pop(ctx, true);
                          } else {
                            setModalState(() {
                              errorText = 'PIN salah. Silakan coba lagi.';
                              pinInput = '';
                            });
                          }
                        }
                      }
                    },
                    onBackspacePressed: () {
                      if (pinInput.isNotEmpty) {
                        setModalState(() {
                          pinInput = pinInput.substring(0, pinInput.length - 1);
                          errorText = null;
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return result ?? false;
  }

  // Dialog Reset Semua Data (2 Langkah)
  Future<void> _handleResetAllData() async {
    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.expense),
            const SizedBox(width: 8),
            Text(
              'Reset Semua Data?',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Tindakan ini akan menghapus seluruh catatan keuangan, dompet kustom, target impian, dan PIN keamanan Anda.',
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
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );

    if (step1 != true || !mounted) return;

    final step2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Konfirmasi Akhir',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: AppColors.expense,
          ),
        ),
        content: Text(
          'Semua data akan terhapus secara permanen dari perangkat ini. Apakah Anda yakin?',
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
            child: const Text('Hapus & Mulai Ulang'),
          ),
        ],
      ),
    );

    if (step2 == true && mounted) {
      final security = ref.read(securityServiceProvider);
      await security.wipeAllSecurityData();

      final prefs = ref.read(preferencesServiceProvider);
      await prefs.clearAll();

      ref.read(userNameProvider.notifier).updateName('');
      await ref.read(isPinEnabledProvider.notifier).setEnabled(false);
      ref.read(isAppLockedProvider.notifier).state = false;

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
    final isPinEnabled = ref.watch(isPinEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pengaturan',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        children: [
          // Section 1: Profil
          _buildSectionHeader('Profil Pengguna'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName.isNotEmpty ? userName : 'Belum diatur',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nama Panggilan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () => _showChangeNameDialog(userName),
                  child: const Text('Ubah'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 2: Keamanan & PIN
          _buildSectionHeader('Keamanan & PIN'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Toggle Status PIN
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isPinEnabled
                              ? AppColors.primary
                              : AppColors.lightTextSecondary)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isPinEnabled
                          ? Icons.lock_rounded
                          : Icons.lock_open_rounded,
                      color: isPinEnabled
                          ? AppColors.primary
                          : AppColors.lightTextSecondary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Kunci Aplikasi dengan PIN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    isPinEnabled ? 'PIN Aktif (4 digit)' : 'Tidak aktif',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  value: isPinEnabled,
                  onChanged: (val) async {
                    if (!val) {
                      // Matikan PIN: Minta PIN saat ini dulu
                      final confirmed = await _promptCurrentPin(
                        title: 'Matikan PIN Keamanan',
                      );
                      if (confirmed) {
                        final security = ref.read(securityServiceProvider);
                        await security.disablePin();
                        await ref
                            .read(isPinEnabledProvider.notifier)
                            .setEnabled(false);
                        ref.read(isAppLockedProvider.notifier).state = false;

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PIN keamanan dinonaktifkan'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    } else {
                      // Aktifkan PIN: Buka CreatePinScreen
                      if (context.mounted) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreatePinScreen(),
                          ),
                        );
                      }
                    }
                  },
                ),

                if (isPinEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E7490).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.password_rounded,
                        color: Color(0xFF0E7490),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Ubah PIN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final confirmed = await _promptCurrentPin(
                        title: 'Verifikasi PIN Lama',
                      );
                      if (confirmed && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const CreatePinScreen(isChangingPin: true),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Tampilan & Tema
          _buildSectionHeader('Tampilan & Tema'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _buildThemeTile(
                  context,
                  title: 'Ikuti Sistem',
                  subtitle: 'Menyesuaikan tampilan sistem perangkat Anda',
                  icon: Icons.brightness_auto_rounded,
                  modeValue: 'system',
                  currentMode: ref.watch(themeModeProvider),
                ),
                const Divider(height: 1),
                _buildThemeTile(
                  context,
                  title: 'Mode Terang',
                  subtitle: 'Tampilan cerah dan bersih',
                  icon: Icons.light_mode_rounded,
                  modeValue: 'light',
                  currentMode: ref.watch(themeModeProvider),
                ),
                const Divider(height: 1),
                _buildThemeTile(
                  context,
                  title: 'Mode Gelap',
                  subtitle: 'Tampilan nyaman di mata saat gelap',
                  icon: Icons.dark_mode_rounded,
                  modeValue: 'dark',
                  currentMode: ref.watch(themeModeProvider),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Cadangkan & Pulihkan
          _buildSectionHeader('Cadangkan & Pulihkan'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.cloud_upload_rounded,
                      color: Color(0xFF0284C7),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Cadangkan Data (Backup)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Simpan salinan data ke berkas lokal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Belum tersedia: Fitur cadangkan data sedang disiapkan'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.cloud_download_rounded,
                      color: Color(0xFF0D9488),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Pulihkan Data (Impor)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Pulihkan data dari berkas cadangan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Belum tersedia: Fitur pulihkan data sedang disiapkan'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 3: Data Aplikasi
          _buildSectionHeader('Data & Reset'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.expense.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppColors.expense,
                  size: 20,
                ),
              ),
              title: Text(
                'Hapus Semua Data Aplikasi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.expense,
                ),
              ),
              subtitle: Text(
                'Mengembalikan aplikasi ke pengaturan awal',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              onTap: _handleResetAllData,
            ),
          ),

          const SizedBox(height: 32),

          // Section 4: Informasi Versi
          Center(
            child: Column(
              children: [
                Text(
                  'MyDuitGweh v1.0.0',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aplikasi Pencatat Keuangan Pribadi Offline',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary.withValues(alpha: 0.7)
                        : AppColors.lightTextSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String modeValue,
    required String currentMode,
  }) {
    final isSelected = currentMode == modeValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isSelected ? AppColors.primary : AppColors.lightTextSecondary)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.lightTextSecondary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
      onTap: () {
        ref.read(themeModeProvider.notifier).setThemeMode(modeValue);
      },
    );
  }
}
