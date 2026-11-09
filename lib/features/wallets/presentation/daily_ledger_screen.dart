import '../../../core/providers/app_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_labels.dart';
import '../../../core/models/duit_type.dart';
import '../../../core/widgets/atur_saldo_sheet.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/providers.dart';

class DailyLedgerScreen extends ConsumerStatefulWidget {
  const DailyLedgerScreen({super.key});

  @override
  ConsumerState<DailyLedgerScreen> createState() => _DailyLedgerScreenState();
}

class _DailyLedgerScreenState extends ConsumerState<DailyLedgerScreen> {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final balanceAsync = ref.watch(ledgerBalanceStreamProvider('daily'));
    final transactionsAsync =
        ref.watch(transactionsByLedgerStreamProvider('daily'));
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
          AppLabels.duitHarian,
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
              duit: DuitSelection.harian,
            ),
          ),
          IconButton(
            tooltip: 'Tambah Transaksi',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => context.push('/tambah-transaksi', extra: 'daily'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ledgerBalanceStreamProvider('daily'));
          ref.invalidate(transactionsByLedgerStreamProvider('daily'));
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

            // Kartu Ringkasan Saldo & Total Periode
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
                              'Saldo Duit Utama',
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
                              ref.watch(isDuitHiddenProvider('utama'))
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 18,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            tooltip: ref.watch(isDuitHiddenProvider('utama'))
                                ? 'Tampilkan Saldo'
                                : 'Sembunyikan Saldo',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () =>
                                ref.read(duitHideBalanceProvider.notifier).toggle('utama'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.duitHarian,
                              side: const BorderSide(color: AppColors.duitHarian),
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
                              duit: DuitSelection.harian,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AnimatedCurrency(
                        amount: balanceAsync.value ?? 0,
                        duit: 'utama',
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
                                        Icons.arrow_downward_rounded,
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
                                            'Masuk Periode',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                          MoneyText(
                                            amount: inc,
                                            duit: 'utama',
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
                                        Icons.arrow_upward_rounded,
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
                                            'Keluar Periode',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                          MoneyText(
                                            amount: exp,
                                            duit: 'utama',
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
                      'Riwayat Duit Utama',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          context.push('/tambah-transaksi', extra: 'daily'),
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
                  message: 'Gagal memuat duit utama: $err',
                  onRetry: () =>
                      ref.invalidate(transactionsByLedgerStreamProvider('daily')),
                ),
              ),
              data: (txList) {
                final filtered = txList.where((t) => _isWithinFilter(t.date, filter)).toList();

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: 'Belum Ada Transaksi di Periode Ini',
                      message: _offset < 0
                          ? 'Tidak ada catatan transaksi Duit Utama pada periode ini.'
                          : 'Catat transaksi duit utama Anda agar keuangan lebih terkontrol.',
                      buttonText: _offset < 0 ? 'Kembali ke Periode Berjalan' : 'Tambah Transaksi Pertama',
                      onButtonPressed: _offset < 0
                          ? _resetToCurrent
                          : () => context.push('/tambah-transaksi', extra: 'daily'),
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

                        return TransactionListItem(
                          transaction: tx,
                          category: cat,
                          onTap: () =>
                              context.push('/tambah-transaksi', extra: tx),
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
            text: '+ Catat Transaksi Utama',
            onPressed: () => context.push('/tambah-transaksi', extra: 'daily'),
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
