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

enum HistoryFilter { daily, weekly, monthly }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {

  bool _isWithinFilter(DateTime date, HistoryFilter filter) {
    final now = DateTime.now();
    switch (filter) {
      case HistoryFilter.daily:
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case HistoryFilter.weekly:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return !date.isBefore(start) && !date.isAfter(end);
      case HistoryFilter.monthly:
        return date.year == now.year && date.month == now.month;
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
              const SizedBox(height: 8),
              Text(
                'Transaksi ini terhubung dengan transfer. Kedua transaksi akan dihapus.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.expense,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
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
              backgroundColor: const Color(0xFFE57373),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Hapus',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteTransaction(
    BuildContext context,
    TransactionItem item,
  ) async {
    final confirmed = await _showDeleteConfirmation(context, item);
    if (confirmed == true && context.mounted) {
      final repo = ref.read(transactionRepositoryProvider);
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
    }
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
          // 1. Filter Harian / Mingguan / Bulanan
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
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
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 2. Daftar Transaksi Dikelompokkan Per Tanggal
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
                  return EmptyState(
                    title:
                        'Belum Ada Transaksi ${activeDuit.isSemua ? '' : activeDuit.label}',
                    message: filter == HistoryFilter.daily
                        ? 'Belum ada transaksi ${activeDuit.isSemua ? '' : 'untuk ${activeDuit.label} '}hari ini.'
                        : 'Mulai catat transaksi ${activeDuit.isSemua ? '' : 'untuk ${activeDuit.label} '}agar keuangan terpantau rapi.',
                    icon: Icons.receipt_long_outlined,
                    action: PrimaryButton(
                      text: 'Tambah Transaksi',
                      width: 220,
                      onPressed: () => context.push(
                        '/tambah-transaksi',
                        extra: activeDuit.ledgerKey,
                      ),
                    ),
                  );
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

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, groupIndex) {
                    final key = sortedKeys[groupIndex];
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

                                    // Nominal Transaksi
                                    MoneyText(
                                      amount: item.amount,
                                      duit: item.ledger,
                                      prefix: isIncome ? '+ ' : '- ',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isIncome
                                            ? AppColors.income
                                            : AppColors.expense,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 19,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                      tooltip: 'Hapus Transaksi',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                        minHeight: 28,
                                      ),
                                      onPressed: () =>
                                          _handleDeleteTransaction(context, item),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
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
                fontSize: 13,
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
