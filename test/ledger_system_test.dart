import 'package:flutter_test/flutter_test.dart';
import 'package:myduitgweh/data/models/saving_goal_model.dart';
import 'package:myduitgweh/data/models/transaction_model.dart';
import 'package:myduitgweh/data/models/wallet_model.dart';
import 'package:myduitgweh/data/repositories/category_repository.dart';
import 'package:myduitgweh/data/repositories/saving_goal_repository.dart';
import 'package:myduitgweh/data/repositories/transaction_repository.dart';
import 'package:myduitgweh/data/repositories/wallet_repository.dart';
import 'package:myduitgweh/features/statistics/providers/statistics_provider.dart';

void main() {
  group('Tahap 10: Sistem 4 Jenis Catatan Terpisah Unit Tests', () {
    late InMemoryWalletRepository walletRepo;
    late InMemoryCategoryRepository categoryRepo;
    late InMemorySavingGoalRepository goalRepo;
    late InMemoryTransactionRepository txRepo;

    setUp(() {
      walletRepo = InMemoryWalletRepository(seedInitialData: true);
      categoryRepo = InMemoryCategoryRepository(seedInitialData: true);
      goalRepo = InMemorySavingGoalRepository(seedInitialData: true);
      txRepo = InMemoryTransactionRepository(
        walletRepository: walletRepo,
        savingGoalRepository: goalRepo,
      );
    });

    tearDown(() {
      walletRepo.dispose();
      categoryRepo.dispose();
      goalRepo.dispose();
      txRepo.dispose();
    });

    test('1. Kategori dan dompet awal terisi sesuai dengan jenis catatan', () async {
      final dailyWallets = await walletRepo.getWalletsByLedger('daily');
      expect(dailyWallets.length, 1);
      expect(dailyWallets.first.name, 'Uang Utama');

      final balanceWallets = await walletRepo.getWalletsByLedger('balance');
      expect(balanceWallets.length, 1);
      expect(balanceWallets.first.name, 'Duit Saldo');

      final savingWallets = await walletRepo.getWalletsByLedger('saving');
      expect(savingWallets.length, 1);
      expect(savingWallets.first.name, 'Duit Tabungan');

      final dailyExpenseCategories = await categoryRepo.getCategoriesByLedger('daily', type: 'expense');
      expect(dailyExpenseCategories.length, 9);
      expect(dailyExpenseCategories.map((c) => c.name), containsAll([
        'Makan & Minum',
        'Transport',
        'Jajan',
        'Pulsa & Paket Data',
        'Belanja',
        'Hiburan',
        'Pendidikan',
        'Kesehatan',
        'Lainnya',
      ]));

      final dailyIncomeCategories = await categoryRepo.getCategoriesByLedger('daily', type: 'income');
      expect(dailyIncomeCategories.length, 5);
      expect(dailyIncomeCategories.map((c) => c.name), containsAll([
        'Uang Saku',
        'Gaji',
        'Bonus',
        'Hadiah',
        'Lainnya',
      ]));

      final balanceIncomeCategories = await categoryRepo.getCategoriesByLedger('balance', type: 'income');
      expect(balanceIncomeCategories.length, 7);
      expect(balanceIncomeCategories.map((c) => c.name), containsAll([
        'Isi Saldo',
        'Transfer Masuk',
        'Gaji',
        'Tunai',
        'Bank',
        'E-Wallet',
        'Lainnya',
      ]));

      final balanceExpenseCategories = await categoryRepo.getCategoriesByLedger('balance', type: 'expense');
      expect(balanceExpenseCategories.length, 7);
      expect(balanceExpenseCategories.map((c) => c.name), containsAll([
        'Tagihan',
        'Transfer Keluar',
        'Biaya Admin',
        'Tunai',
        'Bank',
        'E-Wallet',
        'Lainnya',
      ]));

      final savingCategories = await categoryRepo.getCategoriesByLedger('saving');
      expect(savingCategories.length, 5);
      expect(savingCategories.map((c) => c.name), containsAll([
        'Setoran',
        'Penarikan',
        'Bunga/Bonus',
        'Lainnya',
      ]));
    });

    test('2. Catatan Harian: transaksi pengeluaran dan pemasukan mempengaruhi saldo harian', () async {
      final now = DateTime.now();

      // Tambah pemasukan harian Rp 100.000 ke dompet Uang Harian (id: 1)
      await txRepo.insertTransaction(
        TransactionItem(
          type: 'income',
          ledger: 'daily',
          amount: 100000,
          categoryId: 10, // Uang Saku
          walletId: 1, // Uang Harian
          date: now,
          createdAt: now,
        ),
      );

      // Tambah pengeluaran harian Rp 25.000
      await txRepo.insertTransaction(
        TransactionItem(
          type: 'expense',
          ledger: 'daily',
          amount: 25000,
          categoryId: 1, // Makan & Minum
          walletId: 1,
          date: now,
          createdAt: now,
        ),
      );

      final dailyBalance = await txRepo.calculateLedgerBalance('daily');
      expect(dailyBalance, 75000);

      final dailyTxs = await txRepo.getTransactionsByLedger('daily');
      expect(dailyTxs.length, 2);
    });

    test('3. Catatan Saldo: penambahan akun baru dan transfer antar akun', () async {
      // Tambah akun saldo baru
      final newAccountId = await walletRepo.insertWallet(
        WalletItem(
          name: 'Bank Jago',
          type: 'balance',
          ledger: 'balance',
          initialBalance: 500000,
          createdAt: DateTime.now(),
        ),
      );

      final balanceAccounts = await walletRepo.getWalletsByLedger('balance');
      expect(balanceAccounts.any((w) => w.id == newAccountId), isTrue);

      final jagoBalance = await txRepo.calculateWalletBalance(newAccountId);
      expect(jagoBalance, 500000);

      // Transfer dari Bank Jago ke Tunai (id: 2) sebesar Rp 100.000
      await txRepo.transferBetweenWallets(
        sourceWalletId: newAccountId,
        targetWalletId: 2,
        amount: 100000,
        note: 'Tarik tunai',
      );

      final updatedJagoBalance = await txRepo.calculateWalletBalance(newAccountId);
      expect(updatedJagoBalance, 400000);

      final tunaiBalance = await txRepo.calculateWalletBalance(2);
      expect(tunaiBalance, 100000);
    });

    test('4. Catatan Tabungan: setoran dan penarikan tabungan', () async {
      final now = DateTime.now();

      // Setor tabungan Rp 300.000 (dompet tabungan: id 5)
      await txRepo.insertTransaction(
        TransactionItem(
          type: 'income',
          ledger: 'saving',
          amount: 300000,
          categoryId: 19, // Setoran
          walletId: 5,
          date: now,
          createdAt: now,
        ),
      );

      // Tarik tabungan Rp 50.000
      await txRepo.insertTransaction(
        TransactionItem(
          type: 'expense',
          ledger: 'saving',
          amount: 50000,
          categoryId: 20, // Penarikan
          walletId: 5,
          date: now,
          createdAt: now,
        ),
      );

      final savingBalance = await txRepo.calculateLedgerBalance('saving');
      expect(savingBalance, 250000);

      final savingTxs = await txRepo.getTransactionsByLedger('saving');
      expect(savingTxs.length, 2);
    });

    test('5. Catatan Pencapaian: setoran mandiri vs setoran potong dompet', () async {
      // Buat target baru
      final goalId = await goalRepo.insertSavingGoal(
        const SavingGoalItem(
          name: 'Beli handphone',
          targetAmount: 3000000,
          walletId: 1,
          icon: 'phone_android_rounded',
        ),
      );

      // 5a. Setoran mandiri (tanpa memotong dompet)
      await txRepo.depositToGoal(
        goalId: goalId,
        amount: 500000,
        sourceWalletId: null, // mandiri
        note: 'Tabungan sisa',
      );

      var goal = await goalRepo.getSavingGoalById(goalId);
      expect(goal?.currentAmount, 500000);
      expect(goal?.progress, closeTo(0.166, 0.01));

      // 5b. Setoran memotong dompet (misal dompet Tunai: id 2 punya saldo Rp 500.000)
      await walletRepo.updateWallet(
        (await walletRepo.getWalletById(2))!.copyWith(initialBalance: 500000),
      );
      final tunaiBefore = await txRepo.calculateWalletBalance(2);
      expect(tunaiBefore, 500000);

      await txRepo.depositToGoal(
        goalId: goalId,
        amount: 200000,
        sourceWalletId: 2, // potong dari Tunai
        note: 'Alokasi dari tunai',
      );

      goal = await goalRepo.getSavingGoalById(goalId);
      expect(goal?.currentAmount, 700000);

      final tunaiAfter = await txRepo.calculateWalletBalance(2);
      expect(tunaiAfter, 300000); // berkurang Rp 200.000

      final goalTxs = await txRepo.getTransactionsByLedger('goal');
      expect(goalTxs.length, 2);
    });

    test('6. Filter ledger pada StatsFilter', () {
      const defaultFilter = StatsFilter();
      expect(defaultFilter.ledger, 'all');

      final harianFilter = defaultFilter.copyWith(ledger: 'daily');
      expect(harianFilter.ledger, 'daily');
      expect(harianFilter == defaultFilter, isFalse);
    });
  });
}
