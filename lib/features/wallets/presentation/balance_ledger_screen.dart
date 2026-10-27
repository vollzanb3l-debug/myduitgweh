import '../../../core/providers/app_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_labels.dart';
import '../../../core/models/duit_type.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../core/widgets/atur_saldo_sheet.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/wallet_model.dart';
import '../../../data/repositories/providers.dart';

class BalanceLedgerScreen extends ConsumerStatefulWidget {
  const BalanceLedgerScreen({super.key});

  @override
  ConsumerState<BalanceLedgerScreen> createState() => _BalanceLedgerScreenState();
}

class _BalanceLedgerScreenState extends ConsumerState<BalanceLedgerScreen> {
  // Dialog Tambah / Edit Akun Saldo
  Future<void> _showAccountDialog({WalletItem? accountToEdit}) async {
    final isEdit = accountToEdit != null;
    final nameCtrl = TextEditingController(text: accountToEdit?.name ?? '');
    final balanceCtrl = TextEditingController();
    String? errorText;

    await showModalBottomSheet(
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Edit Akun Saldo' : 'Tambah Akun Saldo Baru',
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
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: ['Tunai', 'Bank', 'E-Wallet', 'Lainnya'].map((opt) {
                      return ActionChip(
                        label: Text(opt),
                        onPressed: () {
                          if (opt != 'Lainnya') {
                            setModalState(() {
                              nameCtrl.text = opt;
                            });
                          } else {
                            setModalState(() {
                              nameCtrl.clear();
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nama Akun Penyimpanan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Tunai, Bank, E-Wallet, atau nama sendiri',
                    ),
                  ),
                  if (!isEdit) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Saldo Awal (Opsional)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: balanceCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      decoration: const InputDecoration(
                        prefixText: 'Rp ',
                        hintText: '0',
                      ),
                    ),
                  ],
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      style: const TextStyle(
                        color: AppColors.expense,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: isEdit ? 'Simpan Perubahan' : 'Buat Akun Saldo',
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.length < 2) {
                        setModalState(() {
                          errorText = 'Nama akun wajib diisi minimal 2 karakter';
                        });
                        return;
                      }

                      final walletRepo = ref.read(walletRepositoryProvider);
                      final initialBal =
                          CurrencyInputFormatter.parseRupiah(balanceCtrl.text);

                      if (isEdit) {
                        await walletRepo.updateWallet(
                          accountToEdit.copyWith(name: name),
                        );
                      } else {
                        await walletRepo.insertWallet(
                          WalletItem(
                            name: name,
                            type: 'balance',
                            ledger: 'balance',
                            initialBalance: initialBal,
                            createdAt: DateTime.now(),
                          ),
                        );
                      }

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEdit
                                  ? 'Akun saldo diperbarui'
                                  : 'Akun saldo baru berhasil ditambahkan',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.darkAccent,
                          ),
                        );
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
  }

  // Dialog Transfer Antar Akun Saldo
  Future<void> _showTransferDialog(List<WalletItem> accounts) async {
    if (accounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Dibutuhkan minimal 2 akun saldo untuk melakukan transfer'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    int sourceWalletId = accounts.first.id!;
    int targetWalletId = accounts[1].id!;
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String? errorText;

    await showModalBottomSheet(
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transfer Antar Akun Saldo',
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
                  const SizedBox(height: 16),
                  Text(
                    'Sumber:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: sourceWalletId,
                    decoration: const InputDecoration(),
                    items: accounts.map((w) {
                      return DropdownMenuItem<int>(
                        value: w.id,
                        child: Text(w.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          sourceWalletId = val;
                          if (targetWalletId == val) {
                            final other =
                                accounts.firstWhere((w) => w.id != val);
                            targetWalletId = other.id!;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pilih Tujuan:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: targetWalletId,
                    decoration: const InputDecoration(),
                    items: accounts.map((w) {
                      return DropdownMenuItem<int>(
                        value: w.id,
                        enabled: w.id != sourceWalletId,
                        child: Text(w.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => targetWalletId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nominal Transfer',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    decoration: const InputDecoration(
                      prefixText: 'Rp ',
                      hintText: '0',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Catatan (Opsional)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Tarik tunai dari ATM',
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      style: const TextStyle(
                        color: AppColors.expense,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Kirim Transfer',
                    onPressed: () async {
                      final amount =
                          CurrencyInputFormatter.parseRupiah(amountCtrl.text);
                      if (amount <= 0) {
                        setModalState(() {
                          errorText = 'Nominal transfer harus lebih dari Rp 0';
                        });
                        return;
                      }

                      if (sourceWalletId == targetWalletId) {
                        setModalState(() {
                          errorText = 'Akun asal dan tujuan harus berbeda';
                        });
                        return;
                      }

                      final txRepo = ref.read(transactionRepositoryProvider);
                      await txRepo.transferBetweenWallets(
                        sourceWalletId: sourceWalletId,
                        targetWalletId: targetWalletId,
                        amount: amount,
                        note: noteCtrl.text.trim().isEmpty
                            ? null
                            : noteCtrl.text.trim(),
                      );

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Transfer sebesar ${formatRupiah(amount)} berhasil diproses',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.darkAccent,
                          ),
                        );
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
  }

  // Dialog Konfirmasi Hapus Akun Saldo
  Future<void> _handleDeleteAccount(WalletItem account) async {
    final txRepo = ref.read(transactionRepositoryProvider);
    final hasTx = await txRepo.hasTransactionsForWallet(account.id!);

    if (!mounted) return;

    if (hasTx) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Tidak Dapat Dihapus',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Akun "${account.name}" tidak dapat dihapus karena sudah memiliki riwayat mutasi tercatat.',
            style: GoogleFonts.plusJakartaSans(fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Akun Saldo?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus akun "${account.name}"?',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
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
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final walletRepo = ref.read(walletRepositoryProvider);
      await walletRepo.deleteWallet(account.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun saldo berhasil dihapus'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.darkAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final balanceAsync = ref.watch(ledgerBalanceStreamProvider('balance'));
    final accountsAsync = ref.watch(walletsByLedgerStreamProvider('balance'));
    final transactionsAsync =
        ref.watch(transactionsByLedgerStreamProvider('balance'));
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLabels.duitSaldo,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Atur Saldo',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => showAturSaldoBottomSheet(
              context: context,
              ref: ref,
              duit: DuitSelection.saldo,
            ),
          ),
          IconButton(
            tooltip: 'Tambah Akun',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _showAccountDialog(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ledgerBalanceStreamProvider('balance'));
          ref.invalidate(walletsByLedgerStreamProvider('balance'));
          ref.invalidate(transactionsByLedgerStreamProvider('balance'));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Ringkasan Atas
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.duitSaldo.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.account_balance_rounded,
                              color: AppColors.duitSaldo,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Total Duit Saldo',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    final current = ref.read(hideBalanceProvider);
                                    ref.read(hideBalanceProvider.notifier).setHidden(!current);
                                  },
                                  child: Icon(
                                    ref.watch(hideBalanceProvider)
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    size: 18,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.duitSaldo,
                              side: const BorderSide(color: AppColors.duitSaldo),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.tune_rounded, size: 14),
                            label: Text(
                              'Atur Saldo',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: () => showAturSaldoBottomSheet(
                              context: context,
                              ref: ref,
                              duit: DuitSelection.saldo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: balanceAsync.when(
                          data: (bal) => AnimatedRupiahCounter(
                            amount: bal,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.darkAccent,
                            ),
                          ),
                          loading: () => const Text('Memuat...'),
                          error: (e, _) => const Text('Rp 0'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _showAccountDialog(),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('+ Akun Baru'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.darkAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                final accs = accountsAsync.value ?? [];
                                _showTransferDialog(accs);
                              },
                              icon: const Icon(Icons.swap_horiz_rounded,
                                  size: 18),
                              label: const Text('Transfer'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Section 1: Daftar Akun Saldo
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: Text(
                  'Tempat Penyimpanan (Akun Saldo)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            accountsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Gagal memuat akun: $err'),
                ),
              ),
              data: (accounts) {
                if (accounts.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: EmptyState(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Belum Ada Akun Saldo',
                        message:
                            'Tambahkan akun seperti Tunai, Rekening Bank, atau E-Wallet.',
                        buttonText: 'Tambah Akun Saldo',
                        onButtonPressed: () => _showAccountDialog(),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final acc = accounts[index];
                        final balAsync = ref
                            .watch(walletBalanceStreamProvider(acc.id ?? 0));

                        return AppCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0E7490)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Color(0xFF0E7490),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      acc.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    balAsync.when(
                                      data: (bal) => MoneyText(
                                        amount: bal,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: isDark
                                              ? AppColors.primary
                                              : AppColors.darkAccent,
                                        ),
                                      ),
                                      loading: () =>
                                          const Text('Menghitung...'),
                                      error: (e, _) => const Text('Rp 0'),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () =>
                                    _showAccountDialog(accountToEdit: acc),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: AppColors.expense,
                                ),
                                onPressed: () => _handleDeleteAccount(acc),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: accounts.length,
                    ),
                  ),
                );
              },
            ),

            // Section 2: Riwayat Mutasi Saldo
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Mutasi Saldo',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          context.push('/tambah-transaksi', extra: 'balance'),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Catat'),
                    ),
                  ],
                ),
              ),
            ),

            transactionsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ErrorState(
                    message: 'Gagal memuat mutasi: $err',
                    onRetry: () => ref.invalidate(
                      transactionsByLedgerStreamProvider('balance'),
                    ),
                  ),
                ),
              ),
              data: (txList) {
                if (txList.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 24.0,
                      ),
                      child: Center(
                        child: Text(
                          'Belum ada transaksi mutasi saldo tercatat.',
                          style: TextStyle(
                            color: AppColors.lightTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final categories = categoriesAsync.value ?? [];
                final categoryMap = {for (final c in categories) c.id: c};

                final sorted = txList.toList()
                  ..sort((a, b) => b.date.compareTo(a.date));

                return SliverPadding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 80,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tx = sorted[index];
                        final cat = categoryMap[tx.categoryId];
                        final isExpense = tx.type == 'expense';
                        final isIncome = tx.type == 'income';

                        final iconData = cat != null
                            ? IconHelper.getIconData(cat.icon)
                            : (isExpense
                                ? Icons.arrow_upward_rounded
                                : (isIncome
                                    ? Icons.arrow_downward_rounded
                                    : Icons.swap_horiz_rounded));
                        final color = isExpense
                            ? AppColors.expense
                            : (isIncome ? AppColors.income : AppColors.secondary);

                        return AppCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          onTap: () =>
                              context.push('/tambah-transaksi', extra: tx),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(iconData, color: color, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat?.name ??
                                          (tx.note?.isNotEmpty == true
                                              ? tx.note!
                                              : (tx.type == 'transfer'
                                                  ? 'Transfer Antar Akun'
                                                  : 'Mutasi Saldo')),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      formatTanggal(tx.date),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                    if (tx.note != null &&
                                        tx.note!.isNotEmpty &&
                                        cat?.name != tx.note) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        tx.note!,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              MoneyText(
                                amount: tx.amount,
                                prefix: isExpense ? '- ' : (isIncome ? '+ ' : ''),
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: sorted.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: PrimaryButton(
            text: '+ Catat Mutasi Saldo',
            onPressed: () =>
                context.push('/tambah-transaksi', extra: 'balance'),
          ),
        ),
      ),
    );
  }
}
