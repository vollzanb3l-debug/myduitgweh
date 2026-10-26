import 'package:flutter_test/flutter_test.dart';
import 'package:myduitgweh/data/models/category_model.dart';
import 'package:myduitgweh/data/models/transaction_model.dart';
import 'package:myduitgweh/data/models/wallet_model.dart';
import 'package:myduitgweh/data/repositories/transaction_repository.dart';
import 'package:myduitgweh/data/repositories/wallet_repository.dart';
import 'package:myduitgweh/features/statistics/providers/statistics_provider.dart';

void main() {
  group('StatsFilter Unit Tests', () {
    test('Default StatsFilter bernilai bulanan dengan offset 0', () {
      const filter = StatsFilter();
      expect(filter.period, equals(StatsPeriod.monthly));
      expect(filter.offset, equals(0));
    });

    test('StatsFilter copyWith dapat mengubah periode dan offset dengan benar', () {
      const filter = StatsFilter();
      final updated = filter.copyWith(period: StatsPeriod.weekly, offset: -1);
      expect(updated.period, equals(StatsPeriod.weekly));
      expect(updated.offset, equals(-1));
    });
  });

  group('Statistics Aggregation Unit Tests', () {
    late InMemoryWalletRepository walletRepo;
    late InMemoryTransactionRepository transactionRepo;

    setUp(() async {
      walletRepo = InMemoryWalletRepository(seedInitialData: false);
      await walletRepo.insertWallet(
        WalletItem(
          id: 1,
          name: 'Dompet Utama',
          type: 'balance',
          initialBalance: 1000000,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      transactionRepo = InMemoryTransactionRepository(walletRepository: walletRepo);
    });

    tearDown(() {
      walletRepo.dispose();
      transactionRepo.dispose();
    });

    test('Menghitung selisih dan aggregasi kategori dengan benar', () async {
      final now = DateTime(2026, 10, 15);

      // Tambah pemasukan: 500.000
      await transactionRepo.insertTransaction(
        TransactionItem(
          type: 'income',
          amount: 500000,
          categoryId: 10, // Gaji
          walletId: 1,
          date: now,
          note: 'Gaji sampingan',
          createdAt: now,
        ),
      );

      // Tambah pengeluaran: 150.000 (Makan) & 50.000 (Transport)
      await transactionRepo.insertTransaction(
        TransactionItem(
          type: 'expense',
          amount: 150000,
          categoryId: 1, // Makan
          walletId: 1,
          date: now,
          note: 'Makan malam',
          createdAt: now,
        ),
      );
      await transactionRepo.insertTransaction(
        TransactionItem(
          type: 'expense',
          amount: 50000,
          categoryId: 2, // Transport
          walletId: 1,
          date: now,
          note: 'Bensin',
          createdAt: now,
        ),
      );

      final start = DateTime(2026, 10, 1);
      final end = DateTime(2026, 10, 31, 23, 59, 59);

      final totalIncome = await transactionRepo.getTotalIncomeByDateRange(start, end);
      final totalExpense = await transactionRepo.getTotalExpenseByDateRange(start, end);
      final netDiff = totalIncome - totalExpense;

      expect(totalIncome, equals(500000));
      expect(totalExpense, equals(200000));
      expect(netDiff, equals(300000));

      final categoryTotals = await transactionRepo.getTotalByCategory(start, end, type: 'expense');
      expect(categoryTotals[1], equals(150000));
      expect(categoryTotals[2], equals(50000));

      const dummyCategory = CategoryItem(
        id: 1,
        name: 'Makan',
        icon: 'restaurant_rounded',
        colorHex: '#EB5757',
        type: 'expense',
      );

      final summary = CategoryExpenseSummary(
        category: dummyCategory,
        totalAmount: 150000,
        percentage: 150000 / totalExpense,
      );

      expect(summary.percentage, equals(0.75));
    });
  });
}
