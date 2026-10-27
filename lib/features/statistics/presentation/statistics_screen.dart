import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/duit_type.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/icon_helper.dart';
import '../../../core/widgets/widgets.dart';
import '../providers/statistics_provider.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(statsFilterProvider);
    final statsAsync = ref.watch(statisticsDataProvider);
    final activeDuit = ref.watch(activeDuitProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          activeDuit.isSemua
              ? 'Statistik Semua Duit'
              : 'Statistik ${activeDuit.label}',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Jenis Catatan (Semua / Harian / Saldo / Tabungan / Pencapaian)
              _buildLedgerFilter(context, ref, filter),

              const SizedBox(height: 12),

              // 1. Pemilih Periode & Panah Navigasi
              _buildPeriodSelector(context, ref, filter),

              const SizedBox(height: 12),

              statsAsync.when(
                data: (data) {
                  final isEmpty = data.totalIncome == 0 && data.totalExpense == 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Panah Geser Periode & Label
                      _buildPeriodNavigation(context, ref, filter, data.periodLabel),

                      const SizedBox(height: 20),

                      if (isEmpty) ...[
                        const SizedBox(height: 20),
                        EmptyState(
                          title:
                              'Belum Ada Transaksi ${activeDuit.isSemua ? '' : activeDuit.label}',
                          message:
                              'Belum ada data ${activeDuit.isSemua ? '' : 'untuk ${activeDuit.label} '}pada periode ${data.periodLabel.toLowerCase()}.',
                          icon: Icons.bar_chart_rounded,
                        ),
                        const SizedBox(height: 40),
                      ] else ...[
                        // 2. Ringkasan: Pemasukan, Pengeluaran, dan Selisih
                        _buildSummaryCard(context, data),

                        const SizedBox(height: 24),

                        // 3. Donut Chart Pengeluaran per Kategori
                        _buildCategoryPieChartSection(context, ref, data),

                        const SizedBox(height: 24),

                        // 4. Bar Chart Perbandingan Pemasukan vs Pengeluaran
                        _buildComparisonBarChartSection(context, data),

                        const SizedBox(height: 24),

                        // 5. Daftar Pengeluaran Terbesar (Top 3)
                        _buildTopCategoriesSection(context, data),

                        const SizedBox(height: 32),
                      ],
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: ErrorState(
                    title: 'Gagal Memuat Statistik',
                    message: 'Tidak dapat menampilkan data statistik keuangan. Silakan coba lagi.',
                    onRetry: () => ref.invalidate(statisticsDataProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Filter Jenis Catatan (Semua / Harian / Saldo / Tabungan / Pencapaian)
  Widget _buildLedgerFilter(
    BuildContext context,
    WidgetRef ref,
    StatsFilter filter,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = [
      {'id': 'all', 'label': 'Semua', 'icon': Icons.all_inclusive_rounded},
      {'id': 'daily', 'label': 'Harian', 'icon': Icons.today_rounded},
      {
        'id': 'balance',
        'label': 'Saldo',
        'icon': Icons.account_balance_rounded
      },
      {'id': 'saving', 'label': 'Tabungan', 'icon': Icons.savings_rounded},
      {
        'id': 'goal',
        'label': 'Pencapaian',
        'icon': Icons.emoji_events_rounded
      },
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final opt = options[index];
          final isSelected = filter.ledger == opt['id'];
          return FilterChip(
            selected: isSelected,
            avatar: Icon(
              opt['icon'] as IconData,
              size: 16,
              color: isSelected
                  ? AppColors.darkAccent
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
            label: Text(
              opt['label'] as String,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.darkAccent
                    : (isDark ? Colors.white : AppColors.darkAccent),
              ),
            ),
            selectedColor: AppColors.primary,
            checkmarkColor: AppColors.darkAccent,
            onSelected: (val) {
              if (val) {
                final ledgerId = opt['id'] as String;
                ref.read(statsFilterProvider.notifier).state =
                    filter.copyWith(ledger: ledgerId);
                ref
                    .read(activeDuitProvider.notifier)
                    .select(DuitSelection.fromLedger(ledgerId));
              }
            },
          );
        },
      ),
    );
  }

  // 1. Pemilih Periode: Minggu ini / Bulan ini / Tahun ini
  Widget _buildPeriodSelector(BuildContext context, WidgetRef ref, StatsFilter filter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF2ECE1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _buildPeriodTab(context, ref, 'Minggu', StatsPeriod.weekly, filter),
          _buildPeriodTab(context, ref, 'Bulan', StatsPeriod.monthly, filter),
          _buildPeriodTab(context, ref, 'Tahun', StatsPeriod.yearly, filter),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(
    BuildContext context,
    WidgetRef ref,
    String title,
    StatsPeriod period,
    StatsFilter currentFilter,
  ) {
    final isSelected = currentFilter.period == period;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(statsFilterProvider.notifier).state = StatsFilter(
            period: period,
            offset: 0, // Reset ke periode terkini saat tab berganti
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? AppColors.darkAccent
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Panah Geser Periode
  Widget _buildPeriodNavigation(
    BuildContext context,
    WidgetRef ref,
    StatsFilter filter,
    String periodLabel,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canGoForward = filter.offset < 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () {
            ref.read(statsFilterProvider.notifier).state = filter.copyWith(
              offset: filter.offset - 1,
            );
          },
        ),
        Expanded(
          child: Text(
            periodLabel,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.chevron_right_rounded,
            size: 28,
            color: canGoForward
                ? (isDark ? Colors.white : AppColors.darkAccent)
                : (isDark ? Colors.white24 : Colors.black12),
          ),
          onPressed: canGoForward
              ? () {
                  ref.read(statsFilterProvider.notifier).state = filter.copyWith(
                    offset: filter.offset + 1,
                  );
                }
              : null,
        ),
      ],
    );
  }

  // 2. Ringkasan: Total Pemasukan, Pengeluaran, Selisih
  Widget _buildSummaryCard(BuildContext context, StatisticsData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = data.netDifference >= 0;
    final diffColor = isPositive ? AppColors.income : AppColors.expense;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              // Pemasukan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pemasukan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedRupiahCounter(
                      amount: data.totalIncome,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.income,
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 36, width: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              const SizedBox(width: 16),
              // Pengeluaran
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengeluaran',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedRupiahCounter(
                      amount: data.totalExpense,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          // Selisih
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selisih Bersih',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              AnimatedRupiahCounter(
                amount: data.netDifference.abs(),
                prefix: isPositive ? '+ ' : '- ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: diffColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Donut Chart Pengeluaran per Kategori
  Widget _buildCategoryPieChartSection(BuildContext context, WidgetRef ref, StatisticsData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Proporsi Pengeluaran Kategori',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          if (data.categoryExpenses.isEmpty || data.totalExpense <= 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 48,
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada pengeluaran pada periode ini',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2.5,
                  centerSpaceRadius: 42,
                  sections: data.categoryExpenses.map((item) {
                    final color = IconHelper.parseColor(item.category.colorHex);
                    final pct = (item.percentage * 100).toStringAsFixed(0);
                    return PieChartSectionData(
                      color: color,
                      value: item.totalAmount.toDouble(),
                      title: '$pct%',
                      radius: 46,
                      titleStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Legenda Kategori
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.categoryExpenses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = data.categoryExpenses[index];
                final color = IconHelper.parseColor(item.category.colorHex);
                final pct = (item.percentage * 100).toStringAsFixed(1);

                return Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.category.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      ref.watch(hideBalanceProvider) ? '$pct% (Rp ••••••)' : '$pct% (${formatRupiah(item.totalAmount)})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // 4. Bar Chart Perbandingan Pemasukan vs Pengeluaran
  Widget _buildComparisonBarChartSection(BuildContext context, StatisticsData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final points = data.comparisonPoints;
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    // Cari nilai maksimum untuk scaling
    int maxVal = 0;
    for (final p in points) {
      if (p.income > maxVal) maxVal = p.income;
      if (p.expense > maxVal) maxVal = p.expense;
    }
    final double maxY = maxVal > 0 ? (maxVal * 1.25) : 100000;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Arus Kas Masuk vs Keluar',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              // Indikator Warna
              Row(
                children: [
                  _buildLegendIndicator('Masuk', AppColors.income),
                  const SizedBox(width: 12),
                  _buildLegendIndicator('Keluar', AppColors.expense),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < points.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              points[idx].label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
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
                barGroups: List.generate(points.length, (i) {
                  final p = points[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: p.income.toDouble(),
                        color: AppColors.income,
                        width: points.length > 7 ? 6 : 9,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: p.expense.toDouble(),
                        color: AppColors.expense,
                        width: points.length > 7 ? 6 : 9,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // 5. Daftar Pengeluaran Terbesar (Top 3 Kategori)
  Widget _buildTopCategoriesSection(BuildContext context, StatisticsData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pengeluaran Terbesar',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (data.top3Categories.isEmpty)
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Belum ada data pengeluaran',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.top3Categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = data.top3Categories[index];
              final color = IconHelper.parseColor(item.category.colorHex);
              final iconData = IconHelper.getIconData(item.category.icon);
              final pct = (item.percentage * 100).toStringAsFixed(1);

              return AnimatedListItem(
                index: index,
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(iconData, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.category.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '$pct% dari total pengeluaran',
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
                        MoneyText(
                          amount: item.totalAmount,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.expense,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: item.percentage,
                        minHeight: 6,
                        backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
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
