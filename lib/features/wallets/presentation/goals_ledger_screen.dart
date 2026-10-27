import '../../../core/providers/app_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_labels.dart';
import '../../../core/models/duit_type.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../core/widgets/atur_saldo_sheet.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/saving_goal_model.dart';
import '../../../data/models/wallet_model.dart';
import '../../../data/repositories/providers.dart';

class GoalsLedgerScreen extends ConsumerStatefulWidget {
  const GoalsLedgerScreen({super.key});

  @override
  ConsumerState<GoalsLedgerScreen> createState() => _GoalsLedgerScreenState();
}

class _GoalsLedgerScreenState extends ConsumerState<GoalsLedgerScreen> {
  // Daftar pilihan ikon target pencapaian
  static const List<Map<String, dynamic>> _iconOptions = [
    {'name': 'phone_android_rounded', 'label': 'Handphone'},
    {'name': 'laptop_rounded', 'label': 'Laptop'},
    {'name': 'two_wheeler_rounded', 'label': 'Motor'},
    {'name': 'flight_rounded', 'label': 'Liburan'},
    {'name': 'school_rounded', 'label': 'Pendidikan'},
    {'name': 'home_rounded', 'label': 'Rumah'},
    {'name': 'directions_car_rounded', 'label': 'Kendaraan'},
    {'name': 'favorite_rounded', 'label': 'Kesehatan'},
    {'name': 'celebration_rounded', 'label': 'Pernikahan'},
    {'name': 'sports_esports_rounded', 'label': 'Hobi'},
    {'name': 'redeem_rounded', 'label': 'Hadiah'},
    {'name': 'star_rounded', 'label': 'Lainnya'},
  ];

  // Dialog Tambah / Edit Target Pencapaian
  Future<void> _showGoalDialog({SavingGoalItem? goalToEdit}) async {
    final isEdit = goalToEdit != null;
    final nameCtrl = TextEditingController(text: goalToEdit?.name ?? '');
    final targetCtrl = TextEditingController(
      text: isEdit ? formatRupiah(goalToEdit.targetAmount) : '',
    );
    final noteCtrl = TextEditingController(text: goalToEdit?.note ?? '');
    DateTime? selectedDeadline = goalToEdit?.deadline;
    String selectedIcon = goalToEdit?.icon ?? 'phone_android_rounded';
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit ? 'Edit Target' : 'Target Pencapaian Baru',
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
                      runSpacing: 6,
                      children: [
                        'Handphone',
                        'Laptop',
                        'Motor',
                        'Liburan',
                        'Pendidikan',
                        'Rumah',
                        'Kendaraan',
                        'Kesehatan',
                        'Pernikahan',
                        'Hobi',
                        'Hadiah',
                        'Lainnya',
                      ].map((preset) {
                        return ActionChip(
                          label: Text(preset),
                          onPressed: () {
                            if (preset != 'Lainnya') {
                              setModalState(() {
                                nameCtrl.text = preset;
                                final match = _iconOptions.firstWhere(
                                  (opt) => opt['label'] == preset,
                                  orElse: () => {'name': 'star_rounded'},
                                );
                                selectedIcon = match['name'] as String;
                              });
                            } else {
                              setModalState(() {
                                nameCtrl.clear();
                                selectedIcon = 'star_rounded';
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nama Barang / Target',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Beli handphone, Laptop Gaming',
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
                      'Pilih Ikon Target',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _iconOptions.map((opt) {
                        final iconKey = opt['name'] as String;
                        final isSelected = selectedIcon == iconKey;
                        final iconData = IconHelper.getIconData(iconKey);
                        return ChoiceChip(
                          avatar: Icon(
                            iconData,
                            size: 18,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                          ),
                          label: Text(opt['label'] as String),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => selectedIcon = iconKey);
                            }
                          },
                        );
                      }).toList(),
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
                          initialDate: selectedDeadline ??
                              DateTime.now().add(const Duration(days: 90)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365 * 10)),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDeadline = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBackground
                              : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              selectedDeadline != null
                                  ? formatTanggal(selectedDeadline!)
                                  : 'Pilih tenggat waktu (opsional)...',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: selectedDeadline != null
                                    ? (isDark
                                        ? Colors.white
                                        : AppColors.darkAccent)
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const Spacer(),
                            if (selectedDeadline != null)
                              GestureDetector(
                                onTap: () => setModalState(
                                    () => selectedDeadline = null),
                                child:
                                    const Icon(Icons.clear_rounded, size: 18),
                              ),
                          ],
                        ),
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
                        hintText: 'Tambah catatan atau rencana impian...',
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
                      text: isEdit ? 'Simpan Perubahan' : 'Buat Target',
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final targetAmount =
                            CurrencyInputFormatter.parseRupiah(targetCtrl.text);

                        if (name.length < 2) {
                          setModalState(
                              () => errorText = 'Nama target wajib diisi minimal 2 karakter');
                          return;
                        }

                        if (targetAmount <= 0) {
                          setModalState(() =>
                              errorText = 'Nominal target harus lebih dari Rp 0');
                          return;
                        }

                        final goalRepo =
                            ref.read(savingGoalRepositoryProvider);

                        final note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();

                        if (isEdit) {
                          await goalRepo.updateSavingGoal(
                            goalToEdit.copyWith(
                              name: name,
                              targetAmount: targetAmount,
                              deadline: selectedDeadline,
                              icon: selectedIcon,
                              note: note,
                            ),
                          );
                        } else {
                          await goalRepo.insertSavingGoal(
                            SavingGoalItem(
                              name: name,
                              targetAmount: targetAmount,
                              deadline: selectedDeadline,
                              walletId: 1,
                              icon: selectedIcon,
                              note: note,
                            ),
                          );
                        }

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEdit
                                    ? 'Target berhasil diperbarui'
                                    : 'Target pencapaian baru berhasil dibuat!',
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
              ),
            );
          },
        );
      },
    );
  }

  // Dialog Setor ke Target (bisa potong dompet atau mandiri)
  Future<void> _showDepositToGoalDialog(
    SavingGoalItem goal,
    List<WalletItem> allWallets,
  ) async {
    final depositCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    bool deductFromWallet = false;
    int? selectedSourceWalletId =
        allWallets.isNotEmpty ? allWallets.first.id : null;
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Setor ke Pencapaian',
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
                      'Target: ${goal.name}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w600,
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
                    const SizedBox(height: 16),
                    // Pilihan Sumber Setoran: Mandiri vs Potong Dompet
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                            : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Potong dari catatan lain',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              deductFromWallet
                                  ? 'Mengurangi saldo catatan yang dipilih'
                                  : 'Berdiri sendiri (tanpa mengurangi catatan lain)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.lightTextSecondary,
                              ),
                            ),
                            value: deductFromWallet,
                            onChanged: (val) {
                              setModalState(() => deductFromWallet = val);
                            },
                          ),
                          if (deductFromWallet && allWallets.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              allWallets.length == 1 ? 'Sumber Dana:' : 'Pilih Sumber Dana:',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (allWallets.length == 1)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  ),
                                ),
                                child: Text(
                                  '${allWallets.first.name} (${allWallets.first.ledger == "daily" ? "Harian" : (allWallets.first.ledger == "balance" ? "Saldo" : "Tabungan")})',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else
                              DropdownButtonFormField<int>(
                                value: selectedSourceWalletId,
                                decoration: const InputDecoration(
                                  isDense: true,
                                ),
                                items: allWallets.map((w) {
                                  final ledgerLabel = w.ledger == 'daily'
                                      ? 'Harian'
                                      : (w.ledger == 'balance'
                                          ? 'Saldo'
                                          : 'Tabungan');
                                  return DropdownMenuItem<int>(
                                    value: w.id,
                                    child: Text('${w.name} ($ledgerLabel)'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(
                                        () => selectedSourceWalletId = val);
                                  }
                                },
                              ),
                          ],
                        ],
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
                        hintText: 'Contoh: Tabungan sisa THR',
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
                      text: 'Konfirmasi Setoran',
                      onPressed: () async {
                        final amount =
                            CurrencyInputFormatter.parseRupiah(depositCtrl.text);
                        if (amount <= 0) {
                          setModalState(() =>
                              errorText = 'Nominal setoran harus lebih dari Rp 0');
                          return;
                        }

                        final txRepo = ref.read(transactionRepositoryProvider);
                        final note = noteCtrl.text.trim().isEmpty
                            ? 'Setoran ke ${goal.name}'
                            : noteCtrl.text.trim();

                        await txRepo.depositToGoal(
                          goalId: goal.id!,
                          amount: amount,
                          sourceWalletId:
                              deductFromWallet ? selectedSourceWalletId : null,
                          note: note,
                        );

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Berhasil menyetor ${formatRupiah(amount)} ke target "${goal.name}"',
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
              ),
            );
          },
        );
      },
    );
  }

  // Dialog Hapus Target
  Future<void> _handleDeleteGoal(SavingGoalItem goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Target?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus target "${goal.name}"?',
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
      final goalRepo = ref.read(savingGoalRepositoryProvider);
      await goalRepo.deleteSavingGoal(goal.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Target pencapaian berhasil dihapus'),
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
    final goalsAsync = ref.watch(savingGoalsStreamProvider);
    final walletsAsync = ref.watch(walletsStreamProvider);
    final transactionsAsync =
        ref.watch(transactionsByLedgerStreamProvider('goal'));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLabels.duitPencapaian,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Reset Progres',
            icon: Icon(
              Icons.restart_alt_rounded,
              color: (goalsAsync.value?.isNotEmpty ?? false)
                  ? null
                  : (isDark ? Colors.white38 : Colors.black26),
            ),
            onPressed: () {
              if (goalsAsync.value?.isEmpty ?? true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Buat pencapaian dulu sebelum menyetor'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              showAturSaldoBottomSheet(
                context: context,
                ref: ref,
                duit: DuitSelection.pencapaian,
              );
            },
          ),
          IconButton(
            tooltip: 'Tambah Target',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _showGoalDialog(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(savingGoalsStreamProvider);
          ref.invalidate(transactionsByLedgerStreamProvider('goal'));
        },
        child: goalsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ErrorState(
                title: 'Gagal Memuat Target',
                message: 'Tidak dapat menampilkan target pencapaian: $err',
                onRetry: () => ref.invalidate(savingGoalsStreamProvider),
              ),
            ),
          ),
          data: (goals) {
            if (goals.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: EmptyState(
                          icon: Icons.stars_rounded,
                          title: 'Belum Ada Pencapaian',
                          message:
                              'Belum ada pencapaian. Tentukan apa yang ingin kamu capai!',
                          buttonText: 'Buat Pencapaian Pertama',
                          onButtonPressed: () => _showGoalDialog(),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            final totalCurrent =
                goals.fold<int>(0, (sum, g) => sum + g.currentAmount);
            final totalTarget =
                goals.fold<int>(0, (sum, g) => sum + g.targetAmount);
            final progress = totalTarget > 0
                ? (totalCurrent / totalTarget).clamp(0.0, 1.0)
                : 0.0;
            final allWallets = walletsAsync.value ?? [];

            return CustomScrollView(
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
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.duitPencapaian
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.emoji_events_rounded,
                                  color: AppColors.duitPencapaian,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'Total Terkumpul Duit Pencapaian',
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
                                    AnimatedRupiahCounter(
                                      amount: totalCurrent,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.darkAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${(progress * 100).toInt()}%',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.duitPencapaian,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.duitPencapaian,
                                      side: const BorderSide(
                                        color: AppColors.duitPencapaian,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.restart_alt_rounded,
                                        size: 14),
                                    label: Text(
                                      'Reset',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    onPressed: () => showAturSaldoBottomSheet(
                                      context: context,
                                      ref: ref,
                                      duit: DuitSelection.pencapaian,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ref.watch(hideBalanceProvider) ? 'Target Total: Rp ••••••' : 'Target Total: ${formatRupiah(totalTarget)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              Text(
                                '${goals.length} Impian Terdaftar',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

            // Header Daftar Impian
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daftar Target Barang / Impian',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showGoalDialog(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Target Baru'),
                    ),
                  ],
                ),
              ),
            ),

            // List Target Pencapaian
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                        final g = goals[index];
                        final progress = g.progress;
                        final isFinished = g.isCompleted;
                        final iconData = IconHelper.getIconData(g.icon);

                        return AppCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      iconData,
                                      color: const Color(0xFFF59E0B),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          g.name,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          g.deadline != null
                                              ? 'Tenggat: ${formatTanggal(g.deadline!)}'
                                              : 'Tanpa tenggat waktu',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    onPressed: () =>
                                        _showGoalDialog(goalToEdit: g),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: AppColors.expense,
                                    ),
                                    onPressed: () => _handleDeleteGoal(g),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isFinished
                                        ? AppColors.income
                                        : const Color(0xFFF59E0B),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ref.watch(hideBalanceProvider) ? 'Rp •••••• / Rp ••••••' : '${formatRupiah(g.currentAmount)} / ${formatRupiah(g.targetAmount)}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: isFinished
                                              ? AppColors.income
                                              : (isDark
                                                  ? Colors.white
                                                  : AppColors.darkAccent),
                                        ),
                                      ),
                                      Text(
                                        isFinished
                                            ? 'Target Tercapai! 🎉'
                                            : '${(progress * 100).toInt()}% tercapai',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: isFinished
                                              ? AppColors.income
                                              : AppColors.lightTextSecondary,
                                          fontWeight: isFinished
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isFinished
                                          ? AppColors.income
                                          : AppColors.primary,
                                      foregroundColor: AppColors.darkAccent,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => _showDepositToGoalDialog(
                                      g,
                                      allWallets,
                                    ),
                                    icon: const Icon(Icons.add_rounded, size: 16),
                                    label: const Text('Setor'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: goals.length,
                    ),
                  ),
                ),

            // Header Riwayat Setoran Pencapaian
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Riwayat Setoran Pencapaian',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
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
                    message: 'Gagal memuat mutasi target: $err',
                    onRetry: () => ref.invalidate(
                      transactionsByLedgerStreamProvider('goal'),
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
                          'Belum ada riwayat setoran pencapaian.',
                          style: TextStyle(
                            color: AppColors.lightTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }

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

                        return AppCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.emoji_events_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.note?.isNotEmpty == true
                                          ? tx.note!
                                          : 'Setoran Target',
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
                                  ],
                                ),
                              ),
                              Text(
                                '+${formatRupiah(tx.amount)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.income,
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
        );
      },
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
            text: '+ Target Baru',
            onPressed: () => _showGoalDialog(),
          ),
        ),
      ),
    );
  }
}
