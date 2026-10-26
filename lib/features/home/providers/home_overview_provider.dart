import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/transaction_model.dart';
import '../../../data/models/wallet_model.dart';
import '../../../data/repositories/providers.dart';

class HomeOverviewData {
  final int totalBalance;
  final int monthlyIncome;
  final int monthlyExpense;
  final List<WalletWithBalance> walletsWithBalance;
  final List<DailyExpensePoint> last7DaysExpenses;
  final List<TransactionItem> recentTransactions;

  const HomeOverviewData({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.walletsWithBalance,
    required this.last7DaysExpenses,
    required this.recentTransactions,
  });
}

class WalletWithBalance {
  final WalletItem wallet;
  final int balance;

  const WalletWithBalance({required this.wallet, required this.balance});
}

class DailyExpensePoint {
  final DateTime date;
  final String dayName;
  final int expenseAmount;

  const DailyExpensePoint({
    required this.date,
    required this.dayName,
    required this.expenseAmount,
  });
}

final homeOverviewProvider = FutureProvider<HomeOverviewData>((ref) async {
  // Re-trigger when transactions or wallets stream updates
  final allTransactions = ref.watch(transactionsStreamProvider).value ?? [];
  final wallets = ref.watch(walletsStreamProvider).value ?? [];
  final txRepo = ref.watch(transactionRepositoryProvider);

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  // 1. Hitung saldo per dompet & total saldo
  final walletsWithBalance = <WalletWithBalance>[];
  int totalBalance = 0;

  for (final w in wallets) {
    if (w.id != null) {
      final balance = await txRepo.calculateWalletBalance(w.id!);
      walletsWithBalance.add(WalletWithBalance(wallet: w, balance: balance));
      totalBalance += balance;
    }
  }

  // 2. Pemasukan & Pengeluaran bulan ini
  final monthlyIncome = await txRepo.getTotalIncomeByDateRange(
    startOfMonth,
    endOfMonth,
  );
  final monthlyExpense = await txRepo.getTotalExpenseByDateRange(
    startOfMonth,
    endOfMonth,
  );

  // 3. Mini grafik 7 hari terakhir
  final last7Days = <DailyExpensePoint>[];
  const dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

  for (int i = 6; i >= 0; i--) {
    final d = now.subtract(Duration(days: i));
    final startOfDay = DateTime(d.year, d.month, d.day);
    final endOfDay = DateTime(d.year, d.month, d.day, 23, 59, 59);

    final dayExpense = await txRepo.getTotalExpenseByDateRange(
      startOfDay,
      endOfDay,
    );
    final dayLabel = dayNames[d.weekday % 7];

    last7Days.add(
      DailyExpensePoint(
        date: startOfDay,
        dayName: dayLabel,
        expenseAmount: dayExpense,
      ),
    );
  }

  // 4. 5 transaksi terakhir
  final sortedTx = allTransactions.toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  final recentTransactions = sortedTx.take(5).toList();

  return HomeOverviewData(
    totalBalance: totalBalance,
    monthlyIncome: monthlyIncome,
    monthlyExpense: monthlyExpense,
    walletsWithBalance: walletsWithBalance,
    last7DaysExpenses: last7Days,
    recentTransactions: recentTransactions,
  );
});
