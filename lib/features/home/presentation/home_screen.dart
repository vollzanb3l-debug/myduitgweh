import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/providers.dart';
import '../providers/home_overview_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(homeOverviewProvider);
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

    return Scaffold(
      body: SafeArea(
        child: overviewAsync.when(
          data: (data) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(homeOverviewProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Ramah
                    _buildHeader(context),

                    const SizedBox(height: 20),

                    // 2. Kartu Besar Berwarna Kuning-Oranye
                    _buildTotalBalanceCard(context, data),

                    const SizedBox(height: 24),

                    // 3. Baris Tombol Aksi Cepat
                    _buildQuickActionButtons(context),

                    const SizedBox(height: 28),

                    // 4. Bagian Dompet Saya
                    _buildWalletsSection(context, data),

                    const SizedBox(height: 28),

                    // 5. Mini Grafik Garis Pengeluaran 7 Hari Terakhir
                    _buildExpenseChartSection(context, data),

                    const SizedBox(height: 28),

                    // 6. Bagian Transaksi Terakhir (5 Terbaru)
                    _buildRecentTransactionsSection(context, data, categoryMap),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) =>
              Center(child: Text('Gagal memuat data beranda: $err')),
        ),
      ),
    );
  }

  // 1. Header Ramah
  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatTanggal(DateTime.now()),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: AppColors.primary,
            size: 26,
          ),
        ),
      ],
    );
  }

  // 2. Kartu Besar Berwarna Kuning-Oranye
  Widget _buildTotalBalanceCard(BuildContext context, HomeOverviewData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Saldo Keseluruhan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.darkAccent.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedRupiahCounter(
              amount: data.totalBalance,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.darkAccent,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Pemasukan Bulan Ini
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.income.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_downward_rounded,
                          size: 16,
                          color: AppColors.income,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pemasukan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.lightTextSecondary,
                              ),
                            ),
                            AnimatedRupiahCounter(
                              amount: data.monthlyIncome,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.income,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: Colors.black12,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                // Pengeluaran Bulan Ini
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.expense.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          size: 16,
                          color: AppColors.expense,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pengeluaran',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.lightTextSecondary,
                              ),
                            ),
                            AnimatedRupiahCounter(
                              amount: data.monthlyExpense,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.expense,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Baris Tombol Aksi Cepat
  Widget _buildQuickActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          context: context,
          icon: Icons.add_rounded,
          label: 'Pemasukan',
          iconColor: AppColors.income,
          bgColor: AppColors.income.withOpacity(0.12),
          onTap: () => context.push('/tambah-transaksi', extra: 'income'),
        ),
        _buildActionButton(
          context: context,
          icon: Icons.remove_rounded,
          label: 'Pengeluaran',
          iconColor: AppColors.expense,
          bgColor: AppColors.expense.withOpacity(0.12),
          onTap: () => context.push('/tambah-transaksi', extra: 'expense'),
        ),
        _buildActionButton(
          context: context,
          icon: Icons.receipt_long_rounded,
          label: 'Riwayat',
          iconColor: const Color(0xFF2F80ED),
          bgColor: const Color(0xFF2F80ED).withOpacity(0.12),
          onTap: () => context.go('/riwayat'),
        ),
        _buildActionButton(
          context: context,
          icon: Icons.bar_chart_rounded,
          label: 'Statistik',
          iconColor: const Color(0xFF9B51E0),
          bgColor: const Color(0xFF9B51E0).withOpacity(0.12),
          onTap: () => context.go('/statistik'),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Bagian Dompet Saya
  Widget _buildWalletsSection(BuildContext context, HomeOverviewData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dompet Saya',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: data.walletsWithBalance.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = data.walletsWithBalance[index];
              final w = item.wallet;
              final balance = item.balance;

              IconData walletIcon = Icons.account_balance_wallet_rounded;
              Color iconColor = AppColors.primary;
              if (w.type == 'daily') {
                walletIcon = Icons.shopping_basket_rounded;
                iconColor = const Color(0xFFE17055);
              } else if (w.type == 'saving') {
                walletIcon = Icons.savings_rounded;
                iconColor = AppColors.income;
              } else {
                walletIcon = Icons.credit_card_rounded;
                iconColor = const Color(0xFF2F80ED);
              }

              return AppCard(
                width: 170,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(walletIcon, size: 16, color: iconColor),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            w.name,
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
                      ],
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: AnimatedRupiahCounter(
                        amount: balance,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 5. Mini Grafik Garis Pengeluaran 7 Hari Terakhir
  Widget _buildExpenseChartSection(
    BuildContext context,
    HomeOverviewData data,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final points = data.last7DaysExpenses;

    // Cari nilai maksimum pengeluaran untuk scaling grafik
    int maxExpense = 0;
    int totalWeekExpense = 0;
    for (final p in points) {
      totalWeekExpense += p.expenseAmount;
      if (p.expenseAmount > maxExpense) {
        maxExpense = p.expenseAmount;
      }
    }
    final double maxY = maxExpense > 0 ? (maxExpense * 1.25) : 100000;

    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].expenseAmount.toDouble()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pengeluaran 7 Hari Terakhir',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            Text(
              formatRupiah(totalWeekExpense),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.expense,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.only(
            top: 20,
            right: 16,
            left: 16,
            bottom: 12,
          ),
          child: SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < points.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              points[idx].dayName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.expense,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.expense.withOpacity(0.25),
                          AppColors.expense.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 6. Bagian Transaksi Terakhir (5 Terbaru)
  Widget _buildRecentTransactionsSection(
    BuildContext context,
    HomeOverviewData data,
    Map<int, CategoryItem> categoryMap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactions = data.recentTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transaksi Terakhir',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            if (transactions.isNotEmpty)
              TextButton(
                onPressed: () => context.go('/riwayat'),
                child: Text(
                  'Lihat semua',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (transactions.isEmpty)
          EmptyState(
            title: 'Belum Ada Transaksi',
            message: 'Ayo catat pemasukan atau pengeluaran pertamamu!',
            icon: Icons.receipt_long_outlined,
            action: PrimaryButton(
              text: 'Catat Transaksi Pertama',
              width: 240,
              onPressed: () => context.push('/tambah-transaksi'),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = transactions[index];
              final category = categoryMap[item.categoryId];
              final catName = category?.name ?? 'Umum';
              final catIcon = category != null
                  ? IconHelper.getIconData(category.icon)
                  : Icons.receipt_rounded;
              final catColor = category != null
                  ? IconHelper.parseColor(category.colorHex)
                  : AppColors.primary;
              final isIncome = item.type == 'income';

              return AnimatedListItem(
                index: index,
                child: AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  onTap: () {
                    // Ketuk untuk edit transaksi
                    context.push('/tambah-transaksi', extra: item);
                  },
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(catIcon, color: catColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            catName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.note != null && item.note!.isNotEmpty
                                ? '${formatTanggalSingkat(item.date)} • ${item.note}'
                                : formatTanggalSingkat(item.date),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      isIncome
                          ? '+ ${formatRupiah(item.amount)}'
                          : '- ${formatRupiah(item.amount)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isIncome ? AppColors.income : AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          ),
      ],
    );
  }
}
