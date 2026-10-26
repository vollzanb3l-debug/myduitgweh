import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/providers.dart';

enum StatsPeriod { weekly, monthly, yearly }

class StatsFilter {
  final StatsPeriod period;
  final int offset;

  const StatsFilter({
    this.period = StatsPeriod.monthly,
    this.offset = 0,
  });

  StatsFilter copyWith({
    StatsPeriod? period,
    int? offset,
  }) {
    return StatsFilter(
      period: period ?? this.period,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatsFilter &&
          runtimeType == other.runtimeType &&
          period == other.period &&
          offset == other.offset;

  @override
  int get hashCode => period.hashCode ^ offset.hashCode;
}

class CategoryExpenseSummary {
  final CategoryItem category;
  final int totalAmount;
  final double percentage; // 0.0 - 1.0

  const CategoryExpenseSummary({
    required this.category,
    required this.totalAmount,
    required this.percentage,
  });
}

class BarChartComparisonPoint {
  final String label;
  final int income;
  final int expense;

  const BarChartComparisonPoint({
    required this.label,
    required this.income,
    required this.expense,
  });
}

class StatisticsData {
  final DateTime startDate;
  final DateTime endDate;
  final String periodLabel;
  final int totalIncome;
  final int totalExpense;
  final int netDifference;
  final List<CategoryExpenseSummary> categoryExpenses;
  final List<CategoryExpenseSummary> top3Categories;
  final List<BarChartComparisonPoint> comparisonPoints;

  const StatisticsData({
    required this.startDate,
    required this.endDate,
    required this.periodLabel,
    required this.totalIncome,
    required this.totalExpense,
    required this.netDifference,
    required this.categoryExpenses,
    required this.top3Categories,
    required this.comparisonPoints,
  });
}

final statsFilterProvider = StateProvider<StatsFilter>((ref) {
  return const StatsFilter(period: StatsPeriod.monthly, offset: 0);
});

final statisticsDataProvider = FutureProvider<StatisticsData>((ref) async {
  // Re-run whenever filter or transactions change
  final filter = ref.watch(statsFilterProvider);
  ref.watch(transactionsStreamProvider); // watch stream for reactive updates
  final txRepo = ref.watch(transactionRepositoryProvider);
  final categories = ref.watch(categoriesStreamProvider).value ?? [];

  final now = DateTime.now();
  late DateTime start;
  late DateTime end;
  late String periodLabel;

  final monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  switch (filter.period) {
    case StatsPeriod.weekly:
      // Hitung awal minggu (Senin) dengan offset
      final currentMonday = now.subtract(Duration(days: now.weekday - 1));
      final targetMonday = currentMonday.add(Duration(days: filter.offset * 7));
      start = DateTime(targetMonday.year, targetMonday.month, targetMonday.day);
      end = DateTime(start.year, start.month, start.day + 6, 23, 59, 59, 999);

      if (filter.offset == 0) {
        periodLabel = 'Minggu Ini (${start.day} - ${end.day} ${monthNames[end.month - 1]})';
      } else if (filter.offset == -1) {
        periodLabel = 'Minggu Lalu (${start.day} - ${end.day} ${monthNames[end.month - 1]})';
      } else {
        periodLabel = '${start.day} ${monthNames[start.month - 1]} - ${end.day} ${monthNames[end.month - 1]}';
      }
      break;

    case StatsPeriod.monthly:
      // Hitung bulan target dengan offset
      final targetMonthDate = DateTime(now.year, now.month + filter.offset, 1);
      start = DateTime(targetMonthDate.year, targetMonthDate.month, 1);
      final lastDay = DateTime(start.year, start.month + 1, 0).day;
      end = DateTime(start.year, start.month, lastDay, 23, 59, 59, 999);

      if (filter.offset == 0) {
        periodLabel = 'Bulan Ini (${monthNames[start.month - 1]} ${start.year})';
      } else {
        periodLabel = '${monthNames[start.month - 1]} ${start.year}';
      }
      break;

    case StatsPeriod.yearly:
      final targetYear = now.year + filter.offset;
      start = DateTime(targetYear, 1, 1);
      end = DateTime(targetYear, 12, 31, 23, 59, 59, 999);

      if (filter.offset == 0) {
        periodLabel = 'Tahun Ini ($targetYear)';
      } else {
        periodLabel = 'Tahun $targetYear';
      }
      break;
  }

  // 1. Total Pemasukan, Pengeluaran & Selisih
  final totalIncome = await txRepo.getTotalIncomeByDateRange(start, end);
  final totalExpense = await txRepo.getTotalExpenseByDateRange(start, end);
  final netDifference = totalIncome - totalExpense;

  // 2. Pengeluaran per kategori
  final categoryTotalsMap = await txRepo.getTotalByCategory(start, end, type: 'expense');
  final categoryMap = {for (final c in categories) c.id: c};

  final categoryExpenses = <CategoryExpenseSummary>[];
  categoryTotalsMap.forEach((catId, amount) {
    if (amount > 0) {
      final cat = categoryMap[catId] ??
          CategoryItem(
            id: catId,
            name: 'Kategori #$catId',
            icon: 'category_rounded',
            colorHex: '#F9A826',
            type: 'expense',
          );
      final pct = totalExpense > 0 ? (amount / totalExpense) : 0.0;
      categoryExpenses.add(
        CategoryExpenseSummary(
          category: cat,
          totalAmount: amount,
          percentage: pct,
        ),
      );
    }
  });

  // Urutkan pengeluaran terbesar
  categoryExpenses.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
  final top3Categories = categoryExpenses.take(3).toList();

  // 3. Titik perbandingan Bar Chart
  final comparisonPoints = <BarChartComparisonPoint>[];

  if (filter.period == StatsPeriod.weekly) {
    const dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    for (int i = 0; i < 7; i++) {
      final dayDate = start.add(Duration(days: i));
      final s = DateTime(dayDate.year, dayDate.month, dayDate.day);
      final e = DateTime(dayDate.year, dayDate.month, dayDate.day, 23, 59, 59);

      final inc = await txRepo.getTotalIncomeByDateRange(s, e);
      final exp = await txRepo.getTotalExpenseByDateRange(s, e);

      comparisonPoints.add(
        BarChartComparisonPoint(
          label: dayLabels[i],
          income: inc,
          expense: exp,
        ),
      );
    }
  } else if (filter.period == StatsPeriod.monthly) {
    // 4 Interval per minggu dalam sebulan
    final totalDays = end.day;
    final chunkSize = (totalDays / 4).ceil();

    for (int i = 0; i < 4; i++) {
      final startDay = (i * chunkSize) + 1;
      var endDay = (i + 1) * chunkSize;
      if (endDay > totalDays) endDay = totalDays;

      final s = DateTime(start.year, start.month, startDay);
      final e = DateTime(start.year, start.month, endDay, 23, 59, 59);

      final inc = await txRepo.getTotalIncomeByDateRange(s, e);
      final exp = await txRepo.getTotalExpenseByDateRange(s, e);

      comparisonPoints.add(
        BarChartComparisonPoint(
          label: 'M${i + 1} ($startDay-$endDay)',
          income: inc,
          expense: exp,
        ),
      );
    }
  } else {
    // 12 Bulan dalam setahun
    const shortMonths = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    for (int m = 1; m <= 12; m++) {
      final s = DateTime(start.year, m, 1);
      final lastDay = DateTime(start.year, m + 1, 0).day;
      final e = DateTime(start.year, m, lastDay, 23, 59, 59);

      final inc = await txRepo.getTotalIncomeByDateRange(s, e);
      final exp = await txRepo.getTotalExpenseByDateRange(s, e);

      comparisonPoints.add(
        BarChartComparisonPoint(
          label: shortMonths[m - 1],
          income: inc,
          expense: exp,
        ),
      );
    }
  }

  return StatisticsData(
    startDate: start,
    endDate: end,
    periodLabel: periodLabel,
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    netDifference: netDifference,
    categoryExpenses: categoryExpenses,
    top3Categories: top3Categories,
    comparisonPoints: comparisonPoints,
  );
});
