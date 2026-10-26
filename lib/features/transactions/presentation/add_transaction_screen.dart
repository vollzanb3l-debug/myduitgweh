import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/duit_type.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/saving_goal_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/wallet_model.dart';
import '../../../data/repositories/providers.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionItem? transactionToEdit;
  final String? initialType;

  const AddTransactionScreen({
    super.key,
    this.transactionToEdit,
    this.initialType,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  late String _ledger; // 'daily', 'balance', 'saving', 'goal'
  late String _type; // 'expense' atau 'income'
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  int? _selectedCategoryId;
  int? _selectedWalletId;
  int? _selectedGoalId;
  bool _deductFromWallet = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final edit = widget.transactionToEdit;

    if (edit != null) {
      _ledger = edit.ledger;
      _type = edit.type;
      _selectedDate = edit.date;
      _selectedCategoryId = edit.categoryId;
      _selectedWalletId = edit.walletId;
      _selectedGoalId = edit.goalId;
    } else {
      final initial = widget.initialType;
      if (initial != null &&
          ['daily', 'balance', 'saving', 'goal'].contains(initial)) {
        _ledger = initial;
      } else {
        final currentDuit = ref.read(activeDuitProvider);
        _ledger = currentDuit.ledgerKey ?? 'daily';
      }

      if (initial == 'income' || initial == 'expense') {
        _type = initial!;
      } else {
        _type = _ledger == 'saving' ? 'income' : 'expense';
      }

      _selectedDate = DateTime.now();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(activeDuitProvider.notifier)
            .select(DuitSelection.fromLedger(_ledger));
      });
    }

    final initialAmountText = edit != null
        ? CurrencyInputFormatter()
            .formatEditUpdate(
              TextEditingValue.empty,
              TextEditingValue(text: edit.amount.toString()),
            )
            .text
        : '';
    _amountController = TextEditingController(text: initialAmountText);
    _noteController = TextEditingController(text: edit?.note ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    final amount = CurrencyInputFormatter.parseRupiah(_amountController.text);

    // Validasi
    if (amount <= 0) {
      setState(() {
        _errorMessage = 'Nominal harus diisi dan lebih dari Rp 0';
      });
      return;
    }

    if (_ledger == 'goal') {
      if (_selectedGoalId == null) {
        setState(() {
          _errorMessage = 'Pilih target pencapaian terlebih dahulu';
        });
        return;
      }

      if (_deductFromWallet && _selectedWalletId == null) {
        setState(() {
          _errorMessage = 'Pilih dompet yang akan dipotong saldonya';
        });
        return;
      }
    } else {
      if (_selectedCategoryId == null) {
        setState(() {
          _errorMessage = 'Pilih kategori transaksi terlebih dahulu';
        });
        return;
      }

      if (_selectedWalletId == null) {
        setState(() {
          _errorMessage = 'Pilih dompet/akun transaksi terlebih dahulu';
        });
        return;
      }
    }

    setState(() {
      _errorMessage = null;
    });

    final txRepo = ref.read(transactionRepositoryProvider);
    final isEdit = widget.transactionToEdit != null;

    if (_ledger == 'goal') {
      final note = _noteController.text.trim().isEmpty
          ? 'Setoran ke target'
          : _noteController.text.trim();

      await txRepo.depositToGoal(
        goalId: _selectedGoalId!,
        amount: amount,
        sourceWalletId: _deductFromWallet ? _selectedWalletId : null,
        note: note,
      );
    } else {
      final tx = TransactionItem(
        id: widget.transactionToEdit?.id,
        type: _type,
        ledger: _ledger,
        amount: amount,
        categoryId: _selectedCategoryId!,
        walletId: _selectedWalletId!,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        createdAt: widget.transactionToEdit?.createdAt ?? DateTime.now(),
      );

      if (isEdit) {
        await txRepo.updateTransaction(tx);
      } else {
        await txRepo.insertTransaction(tx);
      }
    }

    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'Transaksi diperbarui' : 'Transaksi berhasil dicatat',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.darkAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpense = _type == 'expense';
    final activeTypeColor = isExpense ? AppColors.expense : AppColors.income;

    // Streams
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final walletsAsync = ref.watch(walletsStreamProvider);
    final goalsAsync = ref.watch(savingGoalsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transactionToEdit == null
              ? 'Tambah Transaksi'
              : 'Edit Transaksi',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Pemilih Jenis Duit (Chip/Segmented di bagian paling atas)
              Text(
                'Pilih Duit',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              _buildLedgerSelector(isDark),

              const SizedBox(height: 20),

              // 2. Segmented Tipe: Pengeluaran / Pemasukan (hanya untuk daily, balance, saving)
              if (_ledger != 'goal') ...[
                _buildTypeSelector(isDark, isExpense),
                const SizedBox(height: 20),
              ],

              // 3. Input Nominal Besar
              Text(
                'Nominal Transaksi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Rp ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _ledger == 'goal'
                            ? const Color(0xFFF59E0B)
                            : activeTypeColor,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary)
                                .withOpacity(0.4),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.expense,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 4. Kategori ATAU Pilihan Target Impian
              if (_ledger == 'goal') ...[
                // Pencapaian: tidak memakai kategori; memakai target
                _buildGoalSelector(goalsAsync, isDark),
              ] else ...[
                // Harian / Saldo / Tabungan: Menampilkan kategori relevan
                _buildCategorySelector(categoriesAsync, isDark),
              ],

              const SizedBox(height: 24),

              // 5. Pilihan Dompet / Akun Penyimpanan
              _buildWalletSelector(walletsAsync, isDark),

              const SizedBox(height: 20),

              // 6. Pemilih Tanggal
              Text(
                'Tanggal',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatTanggal(_selectedDate),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 7. Kolom Catatan
              Text(
                'Catatan (Opsional)',
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
                controller: _noteController,
                maxLines: 2,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tulis keterangan transaksi...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 8. Tombol Simpan
              PrimaryButton(
                text: widget.transactionToEdit == null
                    ? (_ledger == 'goal'
                        ? 'Setor ke Pencapaian'
                        : 'Simpan Transaksi')
                    : 'Perbarui Transaksi',
                onPressed: _saveTransaction,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Pemilih Jenis Catatan (Chip/Segmented)
  Widget _buildLedgerSelector(bool isDark) {
    final ledgers = [
      {'id': 'daily', 'label': 'Harian', 'icon': Icons.today_rounded},
      {'id': 'balance', 'label': 'Saldo', 'icon': Icons.account_balance_rounded},
      {'id': 'saving', 'label': 'Tabungan', 'icon': Icons.savings_rounded},
      {
        'id': 'goal',
        'label': 'Pencapaian',
        'icon': Icons.emoji_events_rounded
      },
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF2ECE1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: ledgers.map((l) {
          final isSelected = _ledger == l['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_ledger != l['id']) {
                  setState(() {
                    _ledger = l['id'] as String;
                    _selectedCategoryId = null;
                    _selectedWalletId = null;
                    _selectedGoalId = null;
                    _errorMessage = null;

                    if (_ledger == 'saving') {
                      _type = 'income'; // default setoran
                    } else if (_ledger == 'goal') {
                      _type = 'income';
                    } else {
                      _type = 'expense';
                    }
                  });
                  ref
                      .read(activeDuitProvider.notifier)
                      .select(DuitSelection.fromLedger(l['id'] as String));
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      l['icon'] as IconData,
                      size: 16,
                      color: isSelected
                          ? AppColors.darkAccent
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? AppColors.darkAccent
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Pemilih Tipe Pengeluaran / Pemasukan
  Widget _buildTypeSelector(bool isDark, bool isExpense) {
    final expenseLabel = _ledger == 'saving' ? 'Penarikan' : 'Pengeluaran';
    final incomeLabel = _ledger == 'saving' ? 'Setoran' : 'Pemasukan';

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF2ECE1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_type != 'expense') {
                  setState(() {
                    _type = 'expense';
                    _selectedCategoryId = null;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      isExpense ? AppColors.expense : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  child: Text(
                    expenseLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isExpense
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_type != 'income') {
                  setState(() {
                    _type = 'income';
                    _selectedCategoryId = null;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      !isExpense ? AppColors.income : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  child: Text(
                    incomeLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: !isExpense
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Pemilih Kategori (Grid Ikon Bulat)
  Widget _buildCategorySelector(
    AsyncValue<List<CategoryItem>> categoriesAsync,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Kategori',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        categoriesAsync.when(
          data: (categories) {
            // Filter kategori yang sesuai dengan ledger dan type
            final filtered = categories
                .where((c) => c.ledger == _ledger && c.type == _type)
                .toList();

            if (filtered.isEmpty) {
              return const EmptyState(
                title: 'Kategori Belum Ada',
                message: 'Belum ada kategori untuk jenis transaksi ini.',
                icon: Icons.category_outlined,
              );
            }

            // Default pilih kategori pertama jika belum ada yang terpilih
            if (_selectedCategoryId == null && filtered.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _selectedCategoryId == null) {
                  setState(() {
                    _selectedCategoryId = filtered.first.id;
                  });
                }
              });
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final cat = filtered[index];
                final isSelected = cat.id == _selectedCategoryId;
                final catColor = IconHelper.parseColor(cat.colorHex);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = cat.id;
                      _errorMessage = null;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? catColor
                              : (isDark
                                  ? AppColors.darkCard
                                  : catColor.withOpacity(0.12)),
                          border: Border.all(
                            color: isSelected
                                ? (isDark
                                    ? Colors.white
                                    : AppColors.darkAccent)
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: catColor.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          IconHelper.getIconData(cat.icon),
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : catColor),
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => ErrorState(
            isCompact: true,
            title: 'Gagal Memuat Kategori',
            message: 'Tidak dapat memuat kategori transaksi.',
            onRetry: () => ref.invalidate(categoriesStreamProvider),
          ),
        ),
      ],
    );
  }

  // Pemilih Target Impian (Pencapaian)
  Widget _buildGoalSelector(
    AsyncValue<List<SavingGoalItem>> goalsAsync,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Target Impian',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        goalsAsync.when(
          data: (goals) {
            if (goals.isEmpty) {
              return const EmptyState(
                title: 'Belum Ada Target Pencapaian',
                message:
                    'Buat target impian terlebih dahulu di Duit Pencapaian.',
                icon: Icons.emoji_events_outlined,
              );
            }

            // Default pilih target pertama jika belum ada yang terpilih
            if (_selectedGoalId == null && goals.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _selectedGoalId == null) {
                  setState(() {
                    _selectedGoalId = goals.first.id;
                  });
                }
              });
            }

            return Column(
              children: goals.map((g) {
                final isSelected = g.id == _selectedGoalId;
                final iconData = IconHelper.getIconData(g.icon);

                return AppCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  border: isSelected
                      ? Border.all(color: const Color(0xFFF59E0B), width: 2)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedGoalId = g.id;
                      _errorMessage = null;
                    });
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          iconData,
                          color: const Color(0xFFF59E0B),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${formatRupiah(g.currentAmount)} / ${formatRupiah(g.targetAmount)}',
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
                      Radio<int>(
                        value: g.id!,
                        groupValue: _selectedGoalId,
                        onChanged: (val) {
                          setState(() {
                            _selectedGoalId = val;
                            _errorMessage = null;
                          });
                        },
                        activeColor: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Text('Gagal memuat target: $err'),
        ),
      ],
    );
  }

  // Pemilih Dompet / Akun Penyimpanan
  Widget _buildWalletSelector(
    AsyncValue<List<WalletItem>> walletsAsync,
    bool isDark,
  ) {
    if (_ledger == 'goal') {
      // Untuk catatan pencapaian: opsi mandiri atau potong dompet
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Potong dari catatan lain',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                _deductFromWallet
                    ? 'Saldo akun yang dipilih akan dikurangi sesuai setoran'
                    : 'Setoran mandiri (tanpa mengurangi saldo catatan lain)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              value: _deductFromWallet,
              onChanged: (val) {
                setState(() => _deductFromWallet = val);
              },
            ),
            if (_deductFromWallet) ...[
              const SizedBox(height: 10),
              Text(
                'Pilih Akun Sumber:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              walletsAsync.when(
                data: (wallets) {
                  if (_selectedWalletId == null && wallets.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _selectedWalletId == null) {
                        setState(() {
                          _selectedWalletId = wallets.first.id;
                        });
                      }
                    });
                  }

                  return DropdownButtonFormField<int>(
                    value: _selectedWalletId,
                    decoration: const InputDecoration(isDense: true),
                    items: wallets.map((w) {
                      final label = w.ledger == 'daily'
                          ? 'Harian'
                          : (w.ledger == 'balance' ? 'Saldo' : 'Tabungan');
                      return DropdownMenuItem<int>(
                        value: w.id,
                        child: Text('${w.name} ($label)'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedWalletId = val);
                    },
                  );
                },
                loading: () => const Text('Memuat dompet...'),
                error: (e, _) => const Text('Gagal memuat dompet'),
              ),
            ],
          ],
        ),
      );
    }

    // Untuk daily, balance, saving: pilih dompet yang relevan
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _ledger == 'balance' ? 'Pilih Akun Saldo' : 'Pilih Akun Penyimpanan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        walletsAsync.when(
          data: (wallets) {
            // Filter dompet sesuai dengan ledger aktif
            final filtered =
                wallets.where((w) => w.ledger == _ledger).toList();

            if (filtered.isEmpty) {
              return const EmptyState(
                title: 'Akun Belum Ada',
                message:
                    'Silakan buat akun untuk duit ini di tab Duit.',
                icon: Icons.account_balance_wallet_outlined,
              );
            }

            // Default pilih dompet pertama jika belum dipilih
            if (_selectedWalletId == null && filtered.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _selectedWalletId == null) {
                  setState(() {
                    _selectedWalletId = filtered.first.id;
                  });
                }
              });
            }

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filtered.map((w) {
                final isSelected = w.id == _selectedWalletId;
                return ChoiceChip(
                  label: Text(w.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedWalletId = w.id;
                        _errorMessage = null;
                      });
                    }
                  },
                  selectedColor: AppColors.primary,
                  backgroundColor:
                      isDark ? AppColors.darkCard : Colors.white,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? AppColors.darkAccent
                        : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => ErrorState(
            isCompact: true,
            title: 'Gagal Memuat Akun',
            message: 'Tidak dapat memuat daftar akun.',
            onRetry: () => ref.invalidate(walletsStreamProvider),
          ),
        ),
      ],
    );
  }
}
