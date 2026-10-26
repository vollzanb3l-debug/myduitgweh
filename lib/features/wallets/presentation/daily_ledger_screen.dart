import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_labels.dart';
import '../../../core/models/duit_type.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../core/widgets/atur_saldo_sheet.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/providers.dart';

class DailyLedgerScreen extends ConsumerWidget {
  const DailyLedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final balanceAsync = ref.watch(ledgerBalanceStreamProvider('daily'));
    final transactionsAsync =
        ref.watch(transactionsByLedgerStreamProvider('daily'));
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final txRepo = ref.watch(transactionRepositoryProvider);

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
                              color: AppColors.duitHarian.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.today_rounded,
                              color: AppColors.duitHarian,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Saldo Duit Harian',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                balanceAsync.when(
                                  data: (bal) => AnimatedRupiahCounter(
                                    amount: bal,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.darkAccent,
                                    ),
                                  ),
                                  loading: () => const Text('Memuat...'),
                                  error: (e, _) => const Text('Rp 0'),
                                ),
                              ],
                            ),
                          ),
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
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      FutureBuilder<List<int>>(
                        future: Future.wait([
                          txRepo.getTotalIncomeByDateRange(
                            startOfMonth,
                            endOfMonth,
                            ledger: 'daily',
                          ),
                          txRepo.getTotalExpenseByDateRange(
                            startOfMonth,
                            endOfMonth,
                            ledger: 'daily',
                          ),
                        ]),
                        builder: (context, snapshot) {
                          final inc = snapshot.data?[0] ?? 0;
                          final exp = snapshot.data?[1] ?? 0;
                          return Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.income
                                            .withValues(alpha: 0.15),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Masuk Bulan Ini',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                          Text(
                                            formatRupiah(inc),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.income,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
                                        color: AppColors.expense
                                            .withValues(alpha: 0.15),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Keluar Bulan Ini',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                          Text(
                                            formatRupiah(exp),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.expense,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Duit Harian',
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
                  message: 'Gagal memuat duit harian: $err',
                  onRetry: () =>
                      ref.invalidate(transactionsByLedgerStreamProvider('daily')),
                ),
              ),
              data: (txList) {
                if (txList.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: 'Belum Ada Transaksi Duit Harian',
                      message:
                          'Catat transaksi duit harian Anda agar keuangan lebih terkontrol.',
                      buttonText: 'Tambah Transaksi Pertama',
                      onButtonPressed: () =>
                          context.push('/tambah-transaksi', extra: 'daily'),
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
                                : Icons.arrow_downward_rounded);
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
                                              : 'Transaksi Harian'),
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
                              Text(
                                '${isExpense ? "-" : (isIncome ? "+" : "")}${formatRupiah(tx.amount)}',
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
            text: '+ Catat Transaksi Harian',
            onPressed: () => context.push('/tambah-transaksi', extra: 'daily'),
          ),
        ),
      ),
    );
  }
}
