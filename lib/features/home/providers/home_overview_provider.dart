import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../data/models/saving_goal_model.dart';
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
  final List<SavingGoalItem> savingGoals;

  const HomeOverviewData({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.walletsWithBalance,
    required this.last7DaysExpenses,
    required this.recentTransactions,
    this.savingGoals = const [],
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
  // Re-trigger saat activeDuitProvider berubah atau stream transaksi/wallet update
  final activeDuit = ref.watch(activeDuitProvider);
  final allTransactions = ref.watch(transactionsStreamProvider).value ?? [];
  final wallets = ref.watch(walletsStreamProvider).value ?? [];
  final savingGoals = ref.watch(savingGoalsStreamProvider).value ?? [];
  final txRepo = ref.watch(transactionRepositoryProvider);

  final ledger = activeDuit.ledgerKey;

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  // 1. Hitung saldo per dompet & total saldo
  final relevantWallets = ledger == null
      ? wallets
      : wallets.where((w) => w.ledger == ledger).toList();

  final walletsWithBalance = <WalletWithBalance>[];
  int totalBalance = 0;

  if (ledger != null) {
    totalBalance = await txRepo.calculateLedgerBalance(ledger);
    for (final w in relevantWallets) {
      if (w.id != null) {
        final balance = await txRepo.calculateWalletBalance(w.id!);
        walletsWithBalance.add(WalletWithBalance(wallet: w, balance: balance));
      }
    }
  } else {
    for (final w in wallets) {
      if (w.id != null) {
        final balance = await txRepo.calculateWalletBalance(w.id!);
        walletsWithBalance.add(WalletWithBalance(wallet: w, balance: balance));
        totalBalance += balance;
      }
    }
  }

  // 2. Pemasukan & Pengeluaran bulan ini (relevan terhadap filter)
  final monthlyIncome = await txRepo.getTotalIncomeByDateRange(
    startOfMonth,
    endOfMonth,
    ledger: ledger,
  );
  final monthlyExpense = await txRepo.getTotalExpenseByDateRange(
    startOfMonth,
    endOfMonth,
    ledger: ledger,
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
      ledger: ledger,
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

  // 4. Transaksi terakhir (filter per ledger jika ada)
  final filteredTx = ledger == null
      ? allTransactions
      : allTransactions.where((t) => t.ledger == ledger).toList();

  final sortedTx = filteredTx.toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  final recentTransactions = sortedTx.take(5).toList();

  var finalTotalBalance = totalBalance;
  if (activeDuit.isPencapaian) {
    finalTotalBalance = savingGoals.fold<int>(0, (sum, g) => sum + g.currentAmount);
  }

  return HomeOverviewData(
    totalBalance: finalTotalBalance,
    monthlyIncome: monthlyIncome,
    monthlyExpense: monthlyExpense,
    walletsWithBalance: walletsWithBalance,
    last7DaysExpenses: last7Days,
    recentTransactions: recentTransactions,
    savingGoals: savingGoals,
  );
});
