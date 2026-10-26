import 'package:flutter_test/flutter_test.dart';
import 'package:myduitgweh/data/models/transaction_model.dart';
import 'package:myduitgweh/data/models/wallet_model.dart';
import 'package:myduitgweh/data/repositories/transaction_repository.dart';
import 'package:myduitgweh/data/repositories/wallet_repository.dart';

void main() {
  late InMemoryWalletRepository walletRepo;
  late InMemoryTransactionRepository transactionRepo;

  setUp(() async {
    walletRepo = InMemoryWalletRepository(seedInitialData: false);
    // Buat dompet uji dengan initialBalance = 500.000
    await walletRepo.insertWallet(
      WalletItem(
        id: 1,
        name: 'Uang Harian',
        type: 'daily',
        initialBalance: 500000,
        createdAt: DateTime(2026, 1, 1),
      ),
    );

    transactionRepo = InMemoryTransactionRepository(
      walletRepository: walletRepo,
    );
  });

  tearDown(() {
    walletRepo.dispose();
    transactionRepo.dispose();
  });

  group('TransactionRepository Unit Tests', () {
    test('Dapat menambah transaksi baru dan mengambilnya kembali', () async {
      final tx = TransactionItem(
        type: 'expense',
        amount: 25000,
        categoryId: 1, // Makan
        walletId: 1,
        date: DateTime(2026, 10, 26),
        note: 'Beli nasi goreng',
        createdAt: DateTime.now(),
      );

      final id = await transactionRepo.insertTransaction(tx);
      expect(id, isPositive);

      final retrieved = await transactionRepo.getTransactionById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.amount, equals(25000));
      expect(retrieved.note, equals('Beli nasi goreng'));
    });

    test(
      'Dapat menghitung total pemasukan dan pengeluaran per rentang tanggal',
      () async {
        final startDate = DateTime(2026, 10, 1);
        final endDate = DateTime(2026, 10, 31);

        // Pemasukan 1 (dalam rentang): 1.000.000
        await transactionRepo.insertTransaction(
          TransactionItem(
            type: 'income',
            amount: 1000000,
            categoryId: 8, // Gaji
            walletId: 1,
            date: DateTime(2026, 10, 5),
            createdAt: DateTime.now(),
          ),
        );

        // Pemasukan 2 (dalam rentang): 200.000
        await transactionRepo.insertTransaction(
          TransactionItem(
            type: 'income',
            amount: 200000,
            categoryId: 9, // Uang saku
            walletId: 1,
            date: DateTime(2026, 10, 15),
            createdAt: DateTime.now(),
          ),
        );

        // Pengeluaran 1 (dalam rentang): 50.000
        await transactionRepo.insertTransaction(
          TransactionItem(
            type: 'expense',
            amount: 50000,
            categoryId: 1, // Makan
            walletId: 1,
            date: DateTime(2026, 10, 10),
            createdAt: DateTime.now(),
          ),
        );

        // Pengeluaran 2 (di luar rentang, bulan November): 100.000
        await transactionRepo.insertTransaction(
          TransactionItem(
            type: 'expense',
            amount: 100000,
            categoryId: 1,
            walletId: 1,
            date: DateTime(2026, 11, 2),
            createdAt: DateTime.now(),
          ),
        );

        final totalIncome = await transactionRepo.getTotalIncomeByDateRange(
          startDate,
          endDate,
        );
        final totalExpense = await transactionRepo.getTotalExpenseByDateRange(
          startDate,
          endDate,
        );

        expect(totalIncome, equals(1200000));
        expect(totalExpense, equals(50000));
      },
    );

    test('Dapat menghitung total pengeluaran per kategori', () async {
      final start = DateTime(2026, 10, 1);
      final end = DateTime(2026, 10, 31);

      // Kategori 1 (Makan): 25.000 + 35.000 = 60.000
      await transactionRepo.insertTransaction(
        TransactionItem(
          type: 'expense',
          amount: 25000,
          categoryId: 1,
          walletId: 1,
          date: DateTime(2026, 10, 10),
          createdAt: DateTime.now(),
        ),
      );
      await transactionRepo.insertTransaction(
        TransactionItem(
          type: 'expense',
          amount: 35000,
          categoryId: 1,
          walletId: 1,
          date: DateTime(2026, 10, 12),
          createdAt: DateTime.now(),
        ),
      );

      // Kategori 2 (Transport): 20.000
      await transactionRepo.insertTransaction(
        TransactionItem(
          type: 'expense',
          amount: 20000,
          categoryId: 2,
          walletId: 1,
          date: DateTime(2026, 10, 14),
          createdAt: DateTime.now(),
        ),
      );

      final categoryTotals = await transactionRepo.getTotalByCategory(
        start,
        end,
        type: 'expense',
      );

      expect(categoryTotals[1], equals(60000));
      expect(categoryTotals[2], equals(20000));
      expect(categoryTotals[3], isNull);
    });

    test('Dapat menghitung saldo dompet (initialBalance + pemasukan - pengeluaran)', () async {
      // initialBalance dompet ID 1 = 500.000
      // Pemasukan = 1.000.000
      await transactionRepo.insertTransaction(
        TransactionItem(
          type: 'income',
          amount: 1000000,
          categoryId: 8,
          walletId: 1,
          date: DateTime(2026, 10, 1),
          createdAt: DateTime.now(),
        ),
      );

      // Pengeluaran = 350.000
      await transactionRepo.insertTransaction(
        TransactionItem(
          type: 'expense',
          amount: 350000,
          categoryId: 1,
          walletId: 1,
          date: DateTime(2026, 10, 2),
          createdAt: DateTime.now(),
        ),
      );

      // Saldo = 500.000 + 1.000.000 - 350.000 = 1.150.000
      final balance = await transactionRepo.calculateWalletBalance(1);
      expect(balance, equals(1150000));
    });

    test('Dapat melakukan transfer antar dompet dan memperbarui saldo kedua dompet', () async {
      // Buat dompet kedua: Dompet B (ID 2, initialBalance = 100.000)
      await walletRepo.insertWallet(
        WalletItem(
          id: 2,
          name: 'Saldo Tabungan',
          type: 'saving',
          initialBalance: 100000,
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      // Saldo awal: Dompet 1 = 500.000, Dompet 2 = 100.000
      final initialBalance1 = await transactionRepo.calculateWalletBalance(1);
      final initialBalance2 = await transactionRepo.calculateWalletBalance(2);
      expect(initialBalance1, equals(500000));
      expect(initialBalance2, equals(100000));

      // Lakukan transfer 200.000 dari Dompet 1 ke Dompet 2
      await transactionRepo.transferBetweenWallets(
        sourceWalletId: 1,
        targetWalletId: 2,
        amount: 200000,
        note: 'Pindah ke tabungan',
      );

      // Saldo akhir: Dompet 1 berkurang 200.000 -> 300.000
      //              Dompet 2 bertambah 200.000 -> 300.000
      final finalBalance1 = await transactionRepo.calculateWalletBalance(1);
      final finalBalance2 = await transactionRepo.calculateWalletBalance(2);
      expect(finalBalance1, equals(300000));
      expect(finalBalance2, equals(300000));

      // Verifikasi hasTransactionsForWallet bernilai true
      expect(await transactionRepo.hasTransactionsForWallet(1), isTrue);
      expect(await transactionRepo.hasTransactionsForWallet(2), isTrue);

      // Verifikasi dompet tanpa transaksi bernilai false
      expect(await transactionRepo.hasTransactionsForWallet(99), isFalse);
    });
  });
}
