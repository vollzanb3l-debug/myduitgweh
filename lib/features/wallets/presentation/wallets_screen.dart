import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/saving_goal_model.dart';
import '../../../data/models/wallet_model.dart';
import '../../../data/repositories/providers.dart';

class WalletsScreen extends ConsumerStatefulWidget {
  const WalletsScreen({super.key});

  @override
  ConsumerState<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends ConsumerState<WalletsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Dialog Tambah / Edit Dompet
  Future<void> _showWalletFormDialog({WalletItem? walletToEdit}) async {
    final isEdit = walletToEdit != null;
    final nameCtrl = TextEditingController(text: walletToEdit?.name ?? '');
    final balanceCtrl = TextEditingController(
      text: isEdit
          ? ''
          : '',
    );
    String selectedType = walletToEdit?.type ?? 'daily';
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Edit Dompet' : 'Tambah Dompet Baru',
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
                    'Nama Dompet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Tabungan Liburan',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Jenis Dompet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Uang Harian'),
                        selected: selectedType == 'daily',
                        onSelected: (val) {
                          if (val) setModalState(() => selectedType = 'daily');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Saldo'),
                        selected: selectedType == 'balance',
                        onSelected: (val) {
                          if (val) setModalState(() => selectedType = 'balance');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Tabungan'),
                        selected: selectedType == 'saving',
                        onSelected: (val) {
                          if (val) setModalState(() => selectedType = 'saving');
                        },
                      ),
                    ],
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
                      style: const TextStyle(color: AppColors.expense, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: isEdit ? 'Simpan Perubahan' : 'Buat Dompet',
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        setModalState(() {
                          errorText = 'Nama dompet wajib diisi';
                        });
                        return;
                      }

                      final walletRepo = ref.read(walletRepositoryProvider);
                      final initialBal = CurrencyInputFormatter.parseRupiah(balanceCtrl.text);

                      if (isEdit) {
                        await walletRepo.updateWallet(
                          walletToEdit.copyWith(
                            name: name,
                            type: selectedType,
                          ),
                        );
                      } else {
                        await walletRepo.insertWallet(
                          WalletItem(
                            name: name,
                            type: selectedType,
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
                              isEdit ? 'Dompet diperbarui' : 'Dompet baru berhasil dibuat',
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

  // Dialog Hapus Dompet dengan validasi transaksi
  Future<void> _handleDeleteWallet(WalletItem wallet) async {
    final txRepo = ref.read(transactionRepositoryProvider);
    final hasTx = await txRepo.hasTransactionsForWallet(wallet.id!);

    if (!mounted) return;

    if (hasTx) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Tidak Dapat Dihapus',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Dompet "${wallet.name}" tidak dapat dihapus karena sudah memiliki riwayat transaksi tercatat.',
            style: GoogleFonts.plusJakartaSans(fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Dompet?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus dompet "${wallet.name}"?',
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
      await walletRepo.deleteWallet(wallet.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dompet berhasil dihapus'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.darkAccent,
          ),
        );
      }
    }
  }

  // Dialog Transfer Antar Dompet
  Future<void> _showTransferDialog(List<WalletItem> wallets) async {
    if (wallets.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dibutuhkan minimal 2 dompet untuk melakukan transfer'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    int sourceWalletId = wallets.first.id!;
    int targetWalletId = wallets[1].id!;
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transfer Antar Dompet',
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
                    'Dompet Asal (Pengirim)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: sourceWalletId,
                    decoration: const InputDecoration(),
                    items: wallets.map((w) {
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
                            final other = wallets.firstWhere((w) => w.id != val);
                            targetWalletId = other.id!;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Dompet Tujuan (Penerima)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: targetWalletId,
                    decoration: const InputDecoration(),
                    items: wallets.map((w) {
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
                      hintText: 'Contoh: Alokasi uang saku mingguan',
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      style: const TextStyle(color: AppColors.expense, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Kirim Transfer',
                    onPressed: () async {
                      final amount = CurrencyInputFormatter.parseRupiah(amountCtrl.text);
                      if (amount <= 0) {
                        setModalState(() {
                          errorText = 'Nominal transfer harus lebih dari Rp 0';
                        });
                        return;
                      }

                      if (sourceWalletId == targetWalletId) {
                        setModalState(() {
                          errorText = 'Dompet asal dan tujuan harus berbeda';
                        });
                        return;
                      }

                      final txRepo = ref.read(transactionRepositoryProvider);
                      await txRepo.transferBetweenWallets(
                        sourceWalletId: sourceWalletId,
                        targetWalletId: targetWalletId,
                        amount: amount,
                        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
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

  // Dialog Tambah Target Tabungan Baru
  Future<void> _showAddSavingGoalDialog(List<WalletItem> wallets) async {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    int? selectedWalletId = wallets.isNotEmpty ? wallets.first.id : null;
    DateTime? selectedDeadline;
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target Tabungan Baru',
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
                    'Nama Impian / Target',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Beli Laptop Baru, Liburan Bali',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nominal Target',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: targetCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    decoration: const InputDecoration(
                      prefixText: 'Rp ',
                      hintText: '0',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tenggat Waktu (Opsional)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 90)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDeadline = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            selectedDeadline != null
                                ? formatTanggal(selectedDeadline!)
                                : 'Pilih tanggal tenggat...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: selectedDeadline != null
                                  ? (isDark ? Colors.white : AppColors.darkAccent)
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const Spacer(),
                          if (selectedDeadline != null)
                            GestureDetector(
                              onTap: () => setModalState(() => selectedDeadline = null),
                              child: const Icon(Icons.clear_rounded, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      style: const TextStyle(color: AppColors.expense, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Simpan Target',
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final targetAmount =
                          CurrencyInputFormatter.parseRupiah(targetCtrl.text);

                      if (name.isEmpty) {
                        setModalState(() => errorText = 'Nama target wajib diisi');
                        return;
                      }

                      if (targetAmount <= 0) {
                        setModalState(() => errorText = 'Nominal target harus lebih dari Rp 0');
                        return;
                      }

                      final savingRepo = ref.read(savingGoalRepositoryProvider);
                      await savingRepo.insertSavingGoal(
                        SavingGoalItem(
                          name: name,
                          targetAmount: targetAmount,
                          deadline: selectedDeadline,
                          walletId: selectedWalletId ?? 3,
                        ),
                      );

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Target tabungan berhasil dibuat!'),
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

  // Dialog Setor / Tambah Tabungan
  Future<void> _showDepositDialog(SavingGoalItem item) async {
    final depositCtrl = TextEditingController();
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Setor Tabungan',
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
                  Text(
                    'Target: ${item.name}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nominal Setoran',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: depositCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    autofocus: true,
                    decoration: const InputDecoration(
                      prefixText: 'Rp ',
                      hintText: '0',
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      style: const TextStyle(color: AppColors.expense, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Setor Tabungan',
                    onPressed: () async {
                      final amount = CurrencyInputFormatter.parseRupiah(depositCtrl.text);
                      if (amount <= 0) {
                        setModalState(() => errorText = 'Nominal harus lebih dari Rp 0');
                        return;
                      }

                      final savingRepo = ref.read(savingGoalRepositoryProvider);
                      await savingRepo.addSavings(
                        savingGoalId: item.id!,
                        amount: amount,
                      );

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Berhasil menyetor ${formatRupiah(amount)} ke "${item.name}"'),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletsAsync = ref.watch(walletsStreamProvider);
    final savingGoalsAsync = ref.watch(savingGoalsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dompet & Tabungan'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: isDark ? Colors.white : AppColors.darkAccent,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Daftar Dompet'),
            Tab(text: 'Target Tabungan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: DAFTAR DOMPET
          walletsAsync.when(
            data: (wallets) => _buildWalletsTab(context, wallets),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Gagal memuat dompet: $err')),
          ),

          // TAB 2: TARGET TABUNGAN
          savingGoalsAsync.when(
            data: (goals) => _buildSavingsTab(context, goals, walletsAsync.value ?? []),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Gagal memuat tabungan: $err')),
          ),
        ],
      ),
    );
  }

  // TAB 1 WIDGET
  Widget _buildWalletsTab(BuildContext context, List<WalletItem> wallets) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Tombol Aksi
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showWalletFormDialog(),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Tambah Dompet'),
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showTransferDialog(wallets),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                  label: const Text('Transfer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.darkAccent,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            'Daftar Dompet (${wallets.length})',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          if (wallets.isEmpty)
            EmptyState(
              title: 'Belum Ada Dompet',
              message: 'Buat dompet baru untuk memisahkan alokasi keuanganmu.',
              icon: Icons.account_balance_wallet_outlined,
              action: PrimaryButton(
                text: 'Buat Dompet Pertama',
                width: 220,
                onPressed: () => _showWalletFormDialog(),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: wallets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final wallet = wallets[index];
                final balanceAsync = ref.watch(walletBalanceStreamProvider(wallet.id!));

                IconData iconData = Icons.account_balance_wallet_rounded;
                Color themeColor = AppColors.primary;
                String typeLabel = 'Saldo Utama';

                if (wallet.type == 'daily') {
                  iconData = Icons.shopping_basket_rounded;
                  themeColor = const Color(0xFFE17055);
                  typeLabel = 'Uang Harian';
                } else if (wallet.type == 'saving') {
                  iconData = Icons.savings_rounded;
                  themeColor = AppColors.income;
                  typeLabel = 'Tabungan';
                }

                return AnimatedListItem(
                  index: index,
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconData, color: themeColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  wallet.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: themeColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    typeLabel,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: themeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            balanceAsync.when(
                              data: (balance) => AnimatedRupiahCounter(
                                amount: balance,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              loading: () => const Text('Memuat saldo...'),
                              error: (_, __) => const Text('Gagal hitung'),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded),
                        onSelected: (val) {
                          if (val == 'edit') {
                            _showWalletFormDialog(walletToEdit: wallet);
                          } else if (val == 'delete') {
                            _handleDeleteWallet(wallet);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Edit Dompet'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    color: AppColors.expense, size: 18),
                                SizedBox(width: 8),
                                Text('Hapus Dompet',
                                    style: TextStyle(color: AppColors.expense)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            ),
        ],
      ),
    );
  }

  // TAB 2 WIDGET
  Widget _buildSavingsTab(
    BuildContext context,
    List<SavingGoalItem> goals,
    List<WalletItem> wallets,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Target Tabungan (${goals.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddSavingGoalDialog(wallets),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Target Baru'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.darkAccent,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (goals.isEmpty)
            EmptyState(
              title: 'Belum Ada Target Tabungan',
              message: 'Tentukan impian finansialmu dan mulai menabung sedikit demi sedikit!',
              icon: Icons.savings_outlined,
              action: PrimaryButton(
                text: 'Buat Target Sekarang',
                width: 220,
                onPressed: () => _showAddSavingGoalDialog(wallets),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final item = goals[index];
                final isReached = item.isReached;
                final pct = (item.progressPercentage * 100).toInt();

                // Hitung estimasi sisa tabung per bulan jika ada tenggat
                String? monthlyEstimate;
                if (item.deadline != null && !isReached) {
                  final now = DateTime.now();
                  final diffDays = item.deadline!.difference(now).inDays;
                  final months = (diffDays / 30.4).ceil();
                  final remaining = item.targetAmount - item.currentAmount;

                  if (months > 0 && remaining > 0) {
                    final perMonth = (remaining / months).ceil();
                    monthlyEstimate = 'Perlu ${formatRupiah(perMonth)} / bulan ($months bulan lagi)';
                  } else if (remaining > 0) {
                    monthlyEstimate = 'Tenggat bulan ini! Sisa ${formatRupiah(remaining)}';
                  }
                }

                return AnimatedListItem(
                  index: index,
                  child: AppCard(
                    padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Nama Target & Persentase
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isReached
                                  ? AppColors.income.withOpacity(0.15)
                                  : AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$pct%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isReached ? AppColors.income : AppColors.darkAccent,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Nominal Terkumpul vs Target
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Terkumpul',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                              AnimatedRupiahCounter(
                                amount: item.currentAmount,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.income,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Target',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                              AnimatedRupiahCounter(
                                amount: item.targetAmount,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Progress Bar Membulat Kuning-Oranye
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: item.progressPercentage,
                          minHeight: 10,
                          backgroundColor: const Color(0xFFF0EAE1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isReached ? AppColors.income : AppColors.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Efek Saat Target Tercapai
                      if (isReached)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.income.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.income, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Selamat! Target impianmu telah tercapai 🎉',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.income,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (monthlyEstimate != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded,
                                size: 14, color: AppColors.lightTextSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                monthlyEstimate,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Tombol Tambah Tabungan
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showDepositDialog(item),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                          label: const Text('Tambah Tabungan'),
                          style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            ),
        ],
      ),
    );
  }
}
