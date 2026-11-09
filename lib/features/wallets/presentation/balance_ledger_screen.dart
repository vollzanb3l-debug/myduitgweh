import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_labels.dart';
import '../../../core/models/duit_type.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../core/widgets/atur_saldo_sheet.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/providers.dart';

class BalanceLedgerScreen extends ConsumerStatefulWidget {
  const BalanceLedgerScreen({super.key});

  @override
  ConsumerState<BalanceLedgerScreen> createState() => _BalanceLedgerScreenState();
}

class _BalanceLedgerScreenState extends ConsumerState<BalanceLedgerScreen> {
  int _offset = 0;
  DateTime _currentAnchor = DateTime.now();
  int _pagingLimit = 50;

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
    if (newOffset > 0) return;

    final now = DateTime.now();
    DateTime newDate;
    if (filter == HistoryFilter.daily) {
      newDate = now.add(Duration(days: newOffset));
    } else if (filter == HistoryFilter.weekly) {
      newDate = now.add(Duration(days: newOffset * 7));
    } else {
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

  Future<bool?> _showDeleteTxConfirmation(
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
                'Transaksi transfer ini memiliki pasangan yang juga akan otomatis dihapus.',
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

  Future<void> _handleDeleteTransaction(
    BuildContext context,
    WidgetRef ref,
    TransactionItem tx,
  ) async {
    final confirm = await _showDeleteTxConfirmation(context, tx);
    if (confirm == true && tx.id != null) {
      final txRepo = ref.read(transactionRepositoryProvider);
      await txRepo.deleteTransaction(tx.id!);
      ref.invalidate(ledgerBalanceStreamProvider('balance'));
      ref.invalidate(transactionsByLedgerStreamProvider('balance'));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Transaksi berhasil dihapus',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
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
    final balanceAsync = ref.watch(ledgerBalanceStreamProvider('balance'));
    final transactionsAsync =
        ref.watch(transactionsByLedgerStreamProvider('balance'));
    final categoriesAsync = ref.watch(categoriesStreamProvider);

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
            tooltip: 'Tambah Transaksi',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => context.push('/tambah-transaksi', extra: 'balance'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ledgerBalanceStreamProvider('balance'));
          ref.invalidate(transactionsByLedgerStreamProvider('balance'));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Filter Selector Tab
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
            ),

            // Bar Navigasi Periode
            SliverToBoxAdapter(
              child: PeriodNavigator(
                filter: filter,
                selectedDate: _currentAnchor,
                offset: _offset,
                onPrevious: () => _stepPeriod(-1, filter),
                onNext: _offset < 0 ? () => _stepPeriod(1, filter) : null,
                onResetToCurrent: _resetToCurrent,
                onTapPeriod: filter != HistoryFilter.all ? () => _pickDirectDate(filter) : null,
              ),
            ),

            // Kartu Ringkasan Saldo
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
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
                          IconButton(
                            icon: Icon(
                              ref.watch(isDuitHiddenProvider('saldo'))
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 18,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            tooltip: ref.watch(isDuitHiddenProvider('saldo'))
                                ? 'Tampilkan Saldo'
                                : 'Sembunyikan Saldo',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () =>
                                ref.read(duitHideBalanceProvider.notifier).toggle('saldo'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.duitSaldo,
                              side: const BorderSide(color: AppColors.duitSaldo),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.tune_rounded, size: 16),
                            label: Text(
                              'Atur Saldo',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
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
                      AnimatedCurrency(
                        amount: balanceAsync.value ?? 0,
                        duit: 'saldo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : AppColors.darkAccent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 14),

                      // Ringkasan Masuk & Keluar mengikuti periode yang dilihat
                      Builder(
                        builder: (context) {
                          final allTxs = transactionsAsync.value ?? [];
                          final filtered = allTxs.where((t) => _isWithinFilter(t.date, filter)).toList();
                          int inc = 0;
                          int exp = 0;
                          for (final t in filtered) {
                            if (t.type == 'income') inc += t.amount;
                            if (t.type == 'expense') exp += t.amount;
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.income.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add_circle_outline_rounded,
                                        color: AppColors.income,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Pemasukan Periode',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                          MoneyText(
                                            amount: inc,
                                            duit: 'saldo',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.income,
                                            ),
                                            alignment: Alignment.centerLeft,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.expense.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.remove_circle_outline_rounded,
                                        color: AppColors.expense,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Pengeluaran Periode',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                          MoneyText(
                                            amount: exp,
                                            duit: 'saldo',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.expense,
                                            ),
                                            alignment: Alignment.centerLeft,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Header Daftar Transaksi
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Duit Saldo',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          context.push('/tambah-transaksi', extra: 'balance'),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Tambah Transaksi'),
                    ),
                  ],
                ),
              ),
            ),

            // Daftar Transaksi
            transactionsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                child: ErrorState(
                  message: 'Gagal memuat transaksi: $err',
                  onRetry: () => ref.invalidate(
                    transactionsByLedgerStreamProvider('balance'),
                  ),
                ),
              ),
              data: (txList) {
                final filtered = txList.where((t) => _isWithinFilter(t.date, filter)).toList();

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Belum Ada Transaksi di Periode Ini',
                      message: _offset < 0
                          ? 'Tidak ada catatan transaksi Duit Saldo pada periode ini.'
                          : 'Mulai catat transaksi uang tunai, bank, atau dompet digital Anda.',
                      buttonText: _offset < 0 ? 'Kembali ke Periode Berjalan' : 'Tambah Transaksi Pertama',
                      onButtonPressed: _offset < 0
                          ? _resetToCurrent
                          : () => context.push('/tambah-transaksi', extra: 'balance'),
                    ),
                  );
                }

                final categories = categoriesAsync.value ?? [];
                final categoryMap = {for (final c in categories) c.id: c};

                final sorted = filtered.toList()
                  ..sort((a, b) => b.date.compareTo(a.date));

                final displayList = sorted.take(_pagingLimit).toList();
                final hasMore = sorted.length > displayList.length;

                return SliverPadding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 80,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (hasMore && index == displayList.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Center(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() => _pagingLimit += 50);
                                },
                                icon: const Icon(Icons.expand_more_rounded, size: 16),
                                label: Text(
                                  'Muat Lebih Banyak (${sorted.length - displayList.length} tersisa)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        final tx = displayList[index];
                        final cat = categoryMap[tx.categoryId];
                        final isExpense = tx.type == 'expense';
                        final isIncome = tx.type == 'income';

                        final iconData = cat != null
                            ? IconHelper.getIconData(cat.icon)
                            : (isExpense
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded);
                        final color = isExpense
                            ? AppColors.expense
                            : (isIncome ? AppColors.income : const Color(0xFF6366F1));

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
                                      cat?.name ?? 'Kategori #${tx.categoryId}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tx.note != null && tx.note!.isNotEmpty
                                          ? '${tx.note} • ${formatTanggal(tx.date)}'
                                          : formatTanggal(tx.date),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  MoneyText(
                                    amount: tx.amount,
                                    duit: 'saldo',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: color,
                                    ),
                                    prefix: isExpense ? '- ' : '+ ',
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () => _handleDeleteTransaction(
                                      context,
                                      ref,
                                      tx,
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(2.0),
                                      child: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 16,
                                        color: Color(0xFFE57373),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: displayList.length + (hasMore ? 1 : 0),
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
            text: '+ Catat Transaksi Saldo',
            onPressed: () => context.push('/tambah-transaksi', extra: 'balance'),
          ),
        ),
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
          ref.read(historyFilterProvider.notifier).setFilter(filterOption.name);
          setState(() {
            _offset = 0;
            _currentAnchor = DateTime.now();
            _pagingLimit = 50;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
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
