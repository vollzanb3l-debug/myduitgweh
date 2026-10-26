import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/transaction_model.dart';
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
  late String _type; // 'expense' atau 'income'
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  int? _selectedCategoryId;
  int? _selectedWalletId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final edit = widget.transactionToEdit;
    _type = edit?.type ?? widget.initialType ?? 'expense';
    _selectedDate = edit?.date ?? DateTime.now();
    _selectedCategoryId = edit?.categoryId;
    _selectedWalletId = edit?.walletId;

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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: AppColors.darkAccent,
            ),
          ),
          child: child!,
        );
      },
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

    if (_selectedCategoryId == null) {
      setState(() {
        _errorMessage = 'Pilih kategori transaksi terlebih dahulu';
      });
      return;
    }

    if (_selectedWalletId == null) {
      setState(() {
        _errorMessage = 'Pilih dompet transaksi terlebih dahulu';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    final txRepo = ref.read(transactionRepositoryProvider);
    final isEdit = widget.transactionToEdit != null;

    final tx = TransactionItem(
      id: widget.transactionToEdit?.id,
      type: _type,
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

    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'Transaksi diperbarui' : 'Transaksi tersimpan',
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

    // Stream kategori & dompet
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final walletsAsync = ref.watch(walletsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transactionToEdit == null
              ? 'Tambah Transaksi'
              : 'Edit Transaksi',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Segmented Tipe: Pengeluaran / Pemasukan
              Container(
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
                              _selectedCategoryId = null; // Reset pilihan kategori jika tipe berubah
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isExpense
                                ? AppColors.expense
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Center(
                            child: Text(
                              'Pengeluaran',
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
                            color: !isExpense
                                ? AppColors.income
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Center(
                            child: Text(
                              'Pemasukan',
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
              ),

              const SizedBox(height: 24),

              // 2. Input Nominal Besar di Atas
              Text(
                'Nominal',
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
                        color: activeTypeColor,
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
                            color:
                                (isDark
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

              // 3. Pilihan Kategori (Grid Ikon Bulat)
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
                  final filtered = categories
                      .where((c) => c.type == _type)
                      .toList();
                  if (filtered.isEmpty) {
                    return const Text('Tidak ada kategori tersedia');
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Gagal memuat kategori'),
              ),

              const SizedBox(height: 20),

              // 4. Pilihan Dompet
              Text(
                'Pilih Dompet',
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
                  if (wallets.isEmpty) {
                    return const Text('Tidak ada dompet');
                  }

                  // Default pilih dompet pertama jika belum dipilih
                  if (_selectedWalletId == null && wallets.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _selectedWalletId == null) {
                        setState(() {
                          _selectedWalletId = wallets.first.id;
                        });
                      }
                    });
                  }

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: wallets.map((w) {
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
                        backgroundColor: isDark
                            ? AppColors.darkCard
                            : Colors.white,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
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
                loading: () => const SizedBox(),
                error: (_, __) => const Text('Gagal memuat dompet'),
              ),

              const SizedBox(height: 20),

              // 5. Pemilih Tanggal
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

              // 6. Kolom Catatan
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

              // 7. Tombol Simpan Besar Bentuk Pill
              PrimaryButton(
                text: widget.transactionToEdit == null
                    ? 'Simpan Transaksi'
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
}
