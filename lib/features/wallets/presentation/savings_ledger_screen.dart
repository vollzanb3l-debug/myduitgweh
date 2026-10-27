import '../../../core/providers/app_state_provider.dart';
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

class SavingsLedgerScreen extends ConsumerWidget {
  const SavingsLedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final balanceAsync = ref.watch(ledgerBalanceStreamProvider('saving'));
    final transactionsAsync =
        ref.watch(transactionsByLedgerStreamProvider('saving'));
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final txRepo = ref.watch(transactionRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLabels.duitTabungan,
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
              duit: DuitSelection.tabungan,
            ),
          ),
          IconButton(
            tooltip: 'Tambah Transaksi',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => context.push('/tambah-transaksi', extra: 'saving'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ledgerBalanceStreamProvider('saving'));
          ref.invalidate(transactionsByLedgerStreamProvider('saving'));
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
                              color: AppColors.duitTabungan
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.savings_rounded,
                              color: AppColors.duitTabungan,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Total Duit Tabungan',
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
                              ref.watch(hideBalanceProvider)
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 18,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            tooltip: ref.watch(hideBalanceProvider)
                                ? 'Tampilkan Saldo'
                                : 'Sembunyikan Saldo',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () =>
                                ref.read(hideBalanceProvider.notifier).toggle(),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.duitTabungan,
                              side: const BorderSide(color: AppColors.duitTabungan),
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
                              duit: DuitSelection.tabungan,
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
                              color: isDark
                                  ? Colors.white
                                  : AppColors.darkAccent,
                            ),
                          ),
                          loading: () => const Text('Memuat...'),
                          error: (e, _) => const Text('Rp 0'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      FutureBuilder<List<int>>(
                        future: Future.wait([
                          txRepo.getTotalIncomeByDateRange(
                            startOfMonth,
                            endOfMonth,
                            ledger: 'saving',
                          ),
                          txRepo.getTotalExpenseByDateRange(
                            startOfMonth,
                            endOfMonth,
                            ledger: 'saving',
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
                                        Icons.add_circle_outline_rounded,
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
                                            'Setoran Bulan Ini',
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
                                        Icons.remove_circle_outline_rounded,
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
                                            'Penarikan Bulan Ini',
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

            // Header Riwayat Tabungan
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Duit Tabungan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          context.push('/tambah-transaksi', extra: 'saving'),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Tambah Transaksi'),
                    ),
                  ],
                ),
              ),
            ),

            // Daftar Transaksi Tabungan
            transactionsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                child: ErrorState(
                  message: 'Gagal memuat duit tabungan: $err',
                  onRetry: () => ref.invalidate(
                    transactionsByLedgerStreamProvider('saving'),
                  ),
                ),
              ),
              data: (txList) {
                if (txList.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.savings_outlined,
                      title: 'Belum Ada Transaksi Duit Tabungan',
                      message:
                          'Mulai catat transaksi duit tabungan Anda untuk masa depan yang lebih aman.',
                      buttonText: 'Tambah Transaksi Pertama',
                      onButtonPressed: () =>
                          context.push('/tambah-transaksi', extra: 'saving'),
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
                                      cat?.name ??
                                          (tx.note?.isNotEmpty == true
                                              ? tx.note!
                                              : 'Setoran Tabungan'),
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
            text: '+ Catat Setoran Tabungan',
            onPressed: () => context.push('/tambah-transaksi', extra: 'saving'),
          ),
        ),
      ),
    );
  }
}
