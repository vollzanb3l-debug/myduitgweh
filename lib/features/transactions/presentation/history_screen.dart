import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _offset = 0;
  DateTime _currentAnchor = DateTime.now();
  int _pagingLimit = 50;

  @override
  void initState() {
    super.initState();
    _currentAnchor = DateTime.now();
  }

  void _resetToCurrent() {
    setState(() {
      _offset = 0;
      _currentAnchor = DateTime.now();
      _pagingLimit = 50;
    });
  }

  void _stepPeriod(int delta, HistoryFilter filter) {
    if (filter == HistoryFilter.all) return;
    final newOffset = _offset + delta;
    if (newOffset > 0) return; // Tidak bisa ke masa depan

    final now = DateTime.now();
    DateTime newDate;
    if (filter == HistoryFilter.daily) {
      newDate = now.add(Duration(days: newOffset));
    } else if (filter == HistoryFilter.weekly) {
      newDate = now.add(Duration(days: newOffset * 7));
    } else {
      // monthly
      newDate = DateTime(now.year, now.month + newOffset, 1);
    }

    setState(() {
      _offset = newOffset;
      _currentAnchor = newDate;
      _pagingLimit = 50;
    });
  }

  Future<void> _pickDirectDate(HistoryFilter filter) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentAnchor.isAfter(now) ? now : _currentAnchor,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: filter == HistoryFilter.monthly
          ? 'Pilih Bulan/Tanggal'
          : (filter == HistoryFilter.weekly
              ? 'Pilih Minggu'
              : 'Pilih Tanggal'),
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (picked != null) {
      final today = DateTime(now.year, now.month, now.day);
      final pickedDay = DateTime(picked.year, picked.month, picked.day);

      int computedOffset = 0;
      if (filter == HistoryFilter.daily) {
        computedOffset = pickedDay.difference(today).inDays;
      } else if (filter == HistoryFilter.weekly) {
        final nowMonday = today.subtract(Duration(days: today.weekday - 1));
        final pickedMonday = pickedDay.subtract(Duration(days: pickedDay.weekday - 1));
        computedOffset = (pickedMonday.difference(nowMonday).inDays / 7).round();
      } else if (filter == HistoryFilter.monthly) {
        computedOffset = (picked.year - now.year) * 12 + (picked.month - now.month);
      }

      if (computedOffset > 0) computedOffset = 0;

      setState(() {
        _offset = computedOffset;
        _currentAnchor = picked;
        _pagingLimit = 50;
      });
    }
  }

  bool _isWithinFilter(DateTime date, HistoryFilter filter) {
    if (filter == HistoryFilter.all) return true;

    final target = _currentAnchor;
    switch (filter) {
      case HistoryFilter.daily:
        return date.year == target.year &&
            date.month == target.month &&
            date.day == target.day;
      case HistoryFilter.weekly:
        final monday = target.subtract(Duration(days: target.weekday - 1));
        final start = DateTime(monday.year, monday.month, monday.day);
        final end = DateTime(monday.year, monday.month, monday.day + 6, 23, 59, 59, 999);
        return !date.isBefore(start) && !date.isAfter(end);
      case HistoryFilter.monthly:
        return date.year == target.year && date.month == target.month;
      case HistoryFilter.all:
        return true;
    }
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return 'Hari ini - ${formatTanggal(date)}';
    } else if (itemDate == yesterday) {
      return 'Kemarin - ${formatTanggal(date)}';
    } else {
      return formatTanggal(date);
    }
  }

  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    TransactionItem item,
  ) async {
    final isTransfer = item.transferPartnerId != null ||
        (item.note != null &&
            (item.note!.startsWith('Transfer') ||
                item.note!.contains('Transfer') ||
                item.note!.startsWith('Dari ') ||
                item.note!.startsWith('Ke ')));

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Transaksi?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hapus transaksi ini? Saldo akan dihitung ulang.',
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
            ),
            if (isTransfer) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.expense.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.expense,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pasangan transaksi transfer ini juga akan otomatis dihapus.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.expense,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: AppColors.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Hapus',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    // Siapkan map categoryId -> CategoryItem
    final categoryMap = <int, CategoryItem>{};
    categoriesAsync.whenData((categories) {
      for (final cat in categories) {
        if (cat.id != null) {
          categoryMap[cat.id!] = cat;
        }
      }
    });

    final activeDuit = ref.watch(activeDuitProvider);
    final filterStr = ref.watch(historyFilterProvider);
    final filter = switch (filterStr) {
      'weekly' => HistoryFilter.weekly,
      'monthly' => HistoryFilter.monthly,
      'all' => HistoryFilter.all,
      _ => HistoryFilter.daily,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          activeDuit.isSemua
              ? 'Riwayat Semua Duit'
              : 'Riwayat ${activeDuit.label}',
        ),
      ),
      body: Column(
        children: [
          // 1. Filter Harian / Mingguan / Bulanan / Semua
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : const Color(0xFFF2ECE1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  _buildFilterTab('Harian', HistoryFilter.daily, filter),
                  _buildFilterTab('Mingguan', HistoryFilter.weekly, filter),
                  _buildFilterTab('Bulanan', HistoryFilter.monthly, filter),
                  _buildFilterTab('Semua', HistoryFilter.all, filter),
                ],
              ),
            ),
          ),

          // 2. Bar Navigasi Periode
          PeriodNavigator(
            filter: filter,
            selectedDate: _currentAnchor,
            offset: _offset,
            onPrevious: () => _stepPeriod(-1, filter),
            onNext: _offset < 0 ? () => _stepPeriod(1, filter) : null,
            onResetToCurrent: _resetToCurrent,
            onTapPeriod: filter != HistoryFilter.all ? () => _pickDirectDate(filter) : null,
          ),

          const SizedBox(height: 4),

          // 3. Daftar Transaksi Dikelompokkan Per Tanggal
          Expanded(
            child: transactionsAsync.when(
              data: (allTransactions) {
                // Filter transaksi sesuai rentang yang dipilih dan duit aktif
                final filteredList = allTransactions.where((t) {
                  if (!activeDuit.isSemua && t.ledger != activeDuit.ledgerKey) {
                    return false;
                  }
                  return _isWithinFilter(t.date, filter);
                }).toList();

                if (filteredList.isEmpty) {
                  // Cari apakah ada transaksi terakhir di luar periode ini untuk rekomendasi lompat
                  final duitTransactions = allTransactions.where((t) {
                    if (!activeDuit.isSemua && t.ledger != activeDuit.ledgerKey) {
                      return false;
                    }
                    return true;
                  }).toList();

                  DateTime? latestAvailableDate;
                  if (duitTransactions.isNotEmpty) {
                    duitTransactions.sort((a, b) => b.date.compareTo(a.date));
                    latestAvailableDate = duitTransactions.first.date;
                  }

                  return EmptyState(
                    title: 'Belum Ada Transaksi di Periode Ini',
                    message: _offset < 0
                        ? 'Tidak ada catatan transaksi pada periode yang sedang Anda lihat.'
                        : 'Mulai catat transaksi ${activeDuit.isSemua ? '' : 'untuk ${activeDuit.label} '}agar keuangan terpantau rapi.',
                    icon: Icons.receipt_long_outlined,
                    action: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_offset < 0) ...[
                          PrimaryButton(
                            text: 'Kembali ke Periode Berjalan',
                            width: 240,
                            onPressed: _resetToCurrent,
                          ),
                          if (latestAvailableDate != null) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                final now = DateTime.now();
                                final today = DateTime(now.year, now.month, now.day);
                                final targetDay = DateTime(latestAvailableDate!.year, latestAvailableDate.month, latestAvailableDate.day);
                                int computedOffset = 0;
                                if (filter == HistoryFilter.daily) {
                                  computedOffset = targetDay.difference(today).inDays;
                                } else if (filter == HistoryFilter.weekly) {
                                  final nowMonday = today.subtract(Duration(days: today.weekday - 1));
                                  final tMonday = targetDay.subtract(Duration(days: targetDay.weekday - 1));
                                  computedOffset = (tMonday.difference(nowMonday).inDays / 7).round();
                                } else if (filter == HistoryFilter.monthly) {
                                  computedOffset = (latestAvailableDate.year - now.year) * 12 + (latestAvailableDate.month - now.month);
                                }
                                if (computedOffset > 0) computedOffset = 0;
                                setState(() {
                                  _offset = computedOffset;
                                  _currentAnchor = latestAvailableDate!;
                                });
                              },
                              icon: const Icon(Icons.history_rounded, size: 16),
                              label: const Text('Lihat Periode Berisi Data'),
                            ),
                          ],
                        ] else ...[
                          PrimaryButton(
                            text: 'Tambah Transaksi',
                            width: 220,
                            onPressed: () => context.push(
                              '/tambah-transaksi',
                              extra: activeDuit.ledgerKey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                // Hitung total ringkasan periode
                int periodIncome = 0;
                int periodExpense = 0;
                for (final item in filteredList) {
                  if (item.type == 'income') {
                    periodIncome += item.amount;
                  } else {
                    periodExpense += item.amount;
                  }
                }

                // Kelompokkan per tanggal: Key = "yyyy-MM-dd"
                final grouped = <String, List<TransactionItem>>{};
                for (final item in filteredList) {
                  final key =
                      '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}';
                  grouped.putIfAbsent(key, () => []).add(item);
                }

                final sortedKeys = grouped.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                // Lazy load / Paging limit untuk daftar jika 'all' atau data banyak
                final displayKeys = sortedKeys.take(_pagingLimit).toList();
                final hasMore = sortedKeys.length > displayKeys.length;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  itemCount: displayKeys.length + (hasMore ? 2 : 1),
                  itemBuilder: (context, index) {
                    // Header Ringkasan Periode di posisi teratas
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pemasukan Periode',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  MoneyText(
                                    amount: periodIncome,
                                    duit: activeDuit.storageKey,
                                    prefix: '+ ',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.income,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pengeluaran Periode',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  MoneyText(
                                    amount: periodExpense,
                                    duit: activeDuit.storageKey,
                                    prefix: '- ',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.expense,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Tombol Muat Lebih Banyak jika paging aktif
                    if (hasMore && index == displayKeys.length + 1) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _pagingLimit += 50;
                              });
                            },
                            icon: const Icon(Icons.expand_more_rounded, size: 18),
                            label: Text(
                              'Muat Lebih Banyak (${sortedKeys.length - displayKeys.length} tersisa)',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    final groupIndex = index - 1;
                    final key = displayKeys[groupIndex];
                    final groupItems = grouped[key]!;
                    final groupDate = groupItems.first.date;

                    // Hitung subtotal untuk tanggal tersebut
                    int dayIncome = 0;
                    int dayExpense = 0;
                    for (final item in groupItems) {
                      if (item.type == 'income') {
                        dayIncome += item.amount;
                      } else {
                        dayExpense += item.amount;
                      }
                    }
                    final netSubtotal = dayIncome - dayExpense;

                    return AnimatedListItem(
                      index: groupIndex,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        // Header Tanggal & Subtotal
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 10.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDateHeader(groupDate),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              MoneyText(
                                amount: netSubtotal.abs(),
                                duit: activeDuit.storageKey,
                                prefix: netSubtotal >= 0 ? '+ ' : '- ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: netSubtotal >= 0
                                      ? AppColors.income
                                      : AppColors.expense,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Item-item Transaksi di Tanggal Tersebut
                        ...groupItems.map((item) {
                          final category = categoryMap[item.categoryId];
                          final catName = category?.name ?? 'Umum';
                          final catIcon = category != null
                              ? IconHelper.getIconData(category.icon)
                              : Icons.receipt_rounded;
                          final catColor = category != null
                              ? IconHelper.parseColor(category.colorHex)
                              : AppColors.primary;
                          final isIncome = item.type == 'income';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Dismissible(
                              key: ValueKey('tx_${item.id}'),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) =>
                                  _showDeleteConfirmation(context, item),
                              onDismissed: (direction) async {
                                final repo = ref.read(
                                  transactionRepositoryProvider,
                                );
                                await repo.deleteTransaction(item.id!);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Transaksi dihapus',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      backgroundColor: AppColors.darkAccent,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.expense,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Hapus',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              child: AppCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                onTap: () {
                                  // Ketuk untuk edit transaksi
                                  context.push(
                                    '/tambah-transaksi',
                                    extra: item,
                                  );
                                },
                                child: Row(
                                  children: [
                                    // Ikon Kategori
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: catColor.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        catIcon,
                                        color: catColor,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Nama Kategori & Catatan
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            catName,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                          if (item.note != null &&
                                              item.note!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              item.note!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: isDark
                                                    ? AppColors
                                                          .darkTextSecondary
                                                    : AppColors
                                                          .lightTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // Nominal Transaksi
                                    MoneyText(
                                      amount: item.amount,
                                      duit: activeDuit.storageKey,
                                      prefix: isIncome ? '+ ' : '- ',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isIncome
                                            ? AppColors.income
                                            : AppColors.expense,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => ErrorState(
              title: 'Gagal Memuat Riwayat',
              message: 'Terjadi kendala saat mengambil riwayat transaksi. Silakan coba lagi.',
              onRetry: () => ref.invalidate(transactionsStreamProvider),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildFilterTab(
    String label,
    HistoryFilter filterOption,
    HistoryFilter currentFilter,
  ) {
    final isSelected = currentFilter == filterOption;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref
              .read(historyFilterProvider.notifier)
              .setFilter(filterOption.name);
          setState(() {
            _offset = 0;
            _currentAnchor = DateTime.now();
            _pagingLimit = 50;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? AppColors.darkAccent
                    : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
