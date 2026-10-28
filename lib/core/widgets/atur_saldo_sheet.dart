import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_labels.dart';
import '../models/duit_type.dart';
import '../providers/app_state_provider.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/formatters.dart';
import '../../data/repositories/providers.dart';

/// Menampilkan Bottom Sheet menu Atur Saldo sesuai Duit aktif
void showAturSaldoBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required DuitSelection duit,
  int? preselectedWalletId,
}) {
  if (duit.isSemua) return;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: duit.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.tune_rounded, color: duit.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Atur Saldo ${duit.label}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),

              if (!duit.isPencapaian) ...[
                // 1. Tambah Saldo
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.income.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.income,
                    ),
                  ),
                  title: Text(
                    'Tambah Saldo',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'Catat uang masuk ke ${duit.label}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showTambahSaldoDialog(context, ref, duit, preselectedWalletId);
                  },
                ),

                // 2. Koreksi Saldo
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  title: Text(
                    'Koreksi Saldo',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'Sesuaikan saldo jika ada selisih dengan saldo nyata',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showKoreksiSaldoDialog(context, ref, duit, preselectedWalletId);
                  },
                ),

                // 3. Reset Saldo
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restart_alt_rounded,
                      color: AppColors.expense,
                    ),
                  ),
                  title: Text(
                    'Reset Saldo',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.expense,
                    ),
                  ),
                  subtitle: Text(
                    'Kembalikan saldo ke Rp 0 atau hapus riwayat',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showResetSaldoDialog(context, ref, duit, preselectedWalletId);
                  },
                ),
              ] else ...[
                // Duit Pencapaian -> Reset Progres
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.expense,
                    ),
                  ),
                  title: Text(
                    'Reset Progres Pencapaian',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.expense,
                    ),
                  ),
                  subtitle: Text(
                    'Kembalikan jumlah terkumpul target ke Rp 0',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showResetGoalProgressDialog(context, ref);
                  },
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

// 1. DIALOG TAMBAH SALDO
Future<void> _showTambahSaldoDialog(
  BuildContext context,
  WidgetRef ref,
  DuitSelection duit,
  int? preselectedWalletId,
) async {
  final ledger = duit.ledgerKey ?? 'daily';
  final wallets = await ref.read(walletRepositoryProvider).getWalletsByLedger(ledger);
  if (wallets.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada akun dompet untuk duit ini.')),
      );
    }
    return;
  }

  int selectedWalletId = preselectedWalletId ?? wallets.first.id!;
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Tambah Saldo ${duit.label}',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallets.length == 1 ? 'Tujuan:' : 'Pilih Tujuan:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (wallets.length == 1)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : const Color(0xFFF2ECE1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Text(
                          wallets.first.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      )
                    else
                      DropdownButtonFormField<int>(
                        value: selectedWalletId,
                        items: wallets.map((w) {
                          return DropdownMenuItem<int>(
                            value: w.id!,
                            child: Text(w.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedWalletId = val);
                        },
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Nominal (Rp):',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'Rp 0',
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      validator: (val) {
                        final parsed = CurrencyInputFormatter.parseRupiah(val ?? '');
                        if (parsed <= 0) return 'Nominal harus lebih dari 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Catatan (opsional):',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Tambah saldo awal / gaji',
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: duit.color),
                onPressed: () async {
                  if (formKey.currentState?.validate() != true) return;
                  final amount = CurrencyInputFormatter.parseRupiah(amountController.text);
                  final note = noteController.text.trim();

                  await ref.read(transactionRepositoryProvider).addBalance(
                        walletId: selectedWalletId,
                        amount: amount,
                        note: note.isNotEmpty ? note : 'Tambah Saldo',
                      );

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Berhasil menambah saldo ${formatRupiah(amount)}'),
                        backgroundColor: AppColors.income,
                      ),
                    );
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      );
    },
  );
}

// 2. DIALOG KOREKSI SALDO
Future<void> _showKoreksiSaldoDialog(
  BuildContext context,
  WidgetRef ref,
  DuitSelection duit,
  int? preselectedWalletId,
) async {
  final ledger = duit.ledgerKey ?? 'daily';
  final wallets = await ref.read(walletRepositoryProvider).getWalletsByLedger(ledger);
  if (wallets.isEmpty) return;

  int selectedWalletId = preselectedWalletId ?? wallets.first.id!;
  int currentBalance = await ref.read(transactionRepositoryProvider).calculateWalletBalance(selectedWalletId);

  final actualController = TextEditingController(text: formatRupiah(currentBalance));
  final formKey = GlobalKey<FormState>();

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final enteredActual = CurrencyInputFormatter.parseRupiah(actualController.text);
          final diff = enteredActual - currentBalance;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Koreksi Saldo ${duit.label}',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallets.length == 1 ? 'Tujuan:' : 'Pilih Tujuan:',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    if (wallets.length == 1)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : const Color(0xFFF2ECE1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Text(
                          wallets.first.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      )
                    else
                      DropdownButtonFormField<int>(
                        value: selectedWalletId,
                        items: wallets.map((w) {
                          return DropdownMenuItem<int>(
                            value: w.id!,
                            child: Text(w.name),
                          );
                        }).toList(),
                        onChanged: (val) async {
                          if (val != null) {
                            final newBal = await ref.read(transactionRepositoryProvider).calculateWalletBalance(val);
                            setState(() {
                              selectedWalletId = val;
                              currentBalance = newBal;
                              actualController.text = formatRupiah(newBal);
                            });
                          }
                        },
                      ),
                    const SizedBox(height: 14),
                    Text(
                      'Saldo Saat Ini: ${formatRupiah(currentBalance)}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Saldo Nyata Sebenarnya (Rp):',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: actualController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    if (diff != 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (diff > 0 ? AppColors.income : AppColors.expense).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          diff > 0
                              ? 'Selisih: +${formatRupiah(diff)} (Pemasukan Penyesuaian)'
                              : 'Selisih: -${formatRupiah(diff.abs())} (Pengeluaran Penyesuaian)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: diff > 0 ? AppColors.income : AppColors.expense,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: duit.color),
                onPressed: () async {
                  final actual = CurrencyInputFormatter.parseRupiah(actualController.text);
                  await ref.read(transactionRepositoryProvider).correctBalance(
                        walletId: selectedWalletId,
                        actualBalance: actual,
                      );

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(AppLabels.saldoDisesuaikan),
                        backgroundColor: AppColors.income,
                      ),
                    );
                  }
                },
                child: const Text('Terapkan Koreksi'),
              ),
            ],
          );
        },
      );
    },
  );
}

// 3. DIALOG RESET SALDO (2 PILIHAN)
Future<void> _showResetSaldoDialog(
  BuildContext context,
  WidgetRef ref,
  DuitSelection duit,
  int? preselectedWalletId,
) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.expense),
            const SizedBox(width: 8),
            Text(
              'Reset Saldo ${duit.label}',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih metode reset untuk ${duit.label}:',
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Opsi A
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                _executeResetWithHistory(context, ref, duit, preselectedWalletId);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'a. Reset ke Rp 0 & Simpan Riwayat',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Membuat transaksi penyesuaian agar saldo menjadi Rp 0. Semua riwayat lama tetap tersimpan.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Opsi B
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                _promptResetAndWipeHistory(context, ref, duit);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.expense.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'b. Reset & Hapus Riwayat Duit Ini',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.expense,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Menghapus bersih seluruh transaksi ${duit.label} dan mengembalikan saldo ke Rp 0.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
        ],
      );
    },
  );
}

Future<void> _executeResetWithHistory(
  BuildContext context,
  WidgetRef ref,
  DuitSelection duit,
  int? preselectedWalletId,
) async {
  final ledger = duit.ledgerKey ?? 'daily';
  final wallets = await ref.read(walletRepositoryProvider).getWalletsByLedger(ledger);
  for (final w in wallets) {
    if (preselectedWalletId == null || w.id == preselectedWalletId) {
      if (w.id != null) {
        await ref.read(transactionRepositoryProvider).resetBalanceWithHistory(walletId: w.id!);
      }
    }
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saldo ${duit.label} berhasil direset ke Rp 0 (riwayat tersimpan).'),
        backgroundColor: AppColors.income,
      ),
    );
  }
}

Future<void> _promptResetAndWipeHistory(
  BuildContext context,
  WidgetRef ref,
  DuitSelection duit,
) async {
  final isPinEnabled = ref.read(isPinEnabledProvider);

  // Jika PIN aktif, minta PIN terlebih dahulu
  if (isPinEnabled) {
    final pinVerified = await _showVerifyPinDialog(context, ref);
    if (!pinVerified) return;
  }

  if (!context.mounted) return;

  // Konfirmasi 2 Langkah: Ketik "RESET"
  final confirmController = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final isMatch = confirmController.text.trim().toUpperCase() == 'RESET';

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Konfirmasi Hapus Riwayat',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppColors.expense,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tindakan ini akan MENGHAPUS SEMUA TRANSAKSI pada ${duit.label} secara permanen. Ketik kata "RESET" di bawah ini untuk melanjutkan:',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.45),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'Ketik RESET',
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
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
                onPressed: isMatch ? () => Navigator.pop(ctx, true) : null,
                child: const Text('Hapus Permanen'),
              ),
            ],
          );
        },
      );
    },
  );

  if (confirmed == true && context.mounted) {
    final ledger = duit.ledgerKey ?? 'daily';
    await ref.read(transactionRepositoryProvider).resetLedgerAndWipeHistory(ledger: ledger);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Riwayat dan saldo ${duit.label} berhasil direset bersih.'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }
}

Future<bool> _showVerifyPinDialog(BuildContext context, WidgetRef ref) async {
  final pinController = TextEditingController();
  String? error;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Verifikasi PIN',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Masukkan 4 digit PIN Anda sebelum menghapus riwayat.'),
                const SizedBox(height: 12),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  autofocus: true,
                  decoration: InputDecoration(
                    errorText: error,
                    counterText: '',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final pin = pinController.text.trim();
                  final valid = await ref.read(securityServiceProvider).verifyPin(pin);
                  if (valid) {
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } else {
                    setState(() => error = 'PIN salah!');
                  }
                },
                child: const Text('Verifikasi'),
              ),
            ],
          );
        },
      );
    },
  );

  return result == true;
}

// 4. RESET PROGRES PENCAPAIAN
Future<void> _showResetGoalProgressDialog(BuildContext context, WidgetRef ref) async {
  final goals = await ref.read(savingGoalRepositoryProvider).getAllSavingGoals();
  if (goals.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buat pencapaian dulu sebelum menyetor'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return;
  }

  int selectedGoalId = goals.first.id!;

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Reset Progres Pencapaian',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goals.length == 1 ? 'Target:' : 'Pilih Target:',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                if (goals.length == 1)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : const Color(0xFFF2ECE1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Text(
                      '${goals.first.name} (${formatRupiah(goals.first.currentAmount)})',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  )
                else
                  DropdownButtonFormField<int>(
                    value: selectedGoalId,
                    items: goals.map((g) {
                      return DropdownMenuItem<int>(
                        value: g.id!,
                        child: Text('${g.name} (${formatRupiah(g.currentAmount)})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedGoalId = val);
                    },
                  ),
                const SizedBox(height: 12),
                Text(
                  'Target tidak akan dihapus, hanya nominal yang terkumpul akan kembali menjadi Rp 0.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.4),
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
                  backgroundColor: AppColors.expense,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await ref.read(savingGoalRepositoryProvider).resetProgress(selectedGoalId);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(AppLabels.progresDireset),
                        backgroundColor: AppColors.expense,
                      ),
                    );
                  }
                },
                child: const Text('Reset Progres'),
              ),
            ],
          );
        },
      );
    },
  );
}
