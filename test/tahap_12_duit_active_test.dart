import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myduitgweh/core/models/duit_type.dart';
import 'package:myduitgweh/core/providers/app_state_provider.dart';
import 'package:myduitgweh/core/services/preferences_service.dart';
import 'package:myduitgweh/data/models/category_model.dart';
import 'package:myduitgweh/data/models/saving_goal_model.dart';
import 'package:myduitgweh/data/models/transaction_model.dart';
import 'package:myduitgweh/data/models/wallet_model.dart';
import 'package:myduitgweh/data/repositories/category_repository.dart';
import 'package:myduitgweh/data/repositories/saving_goal_repository.dart';
import 'package:myduitgweh/data/repositories/transaction_repository.dart';
import 'package:myduitgweh/data/repositories/wallet_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tahap 12: Duit Aktif & Filter Tests', () {
    test('(1) Pilihan duit tersimpan dan terbaca kembali di SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final prefsService = PreferencesService(prefs);

      // Default awal saat belum ada pilihan tersimpan adalah 'harian'
      expect(prefsService.activeDuitKey, equals('harian'));

      final container = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(prefsService),
        ],
      );
      addTearDown(container.dispose);

      // Baca provider awal: DuitSelection.harian
      var activeDuit = container.read(activeDuitProvider);
      expect(activeDuit.type, equals(DuitType.harian));
      expect(activeDuit.isHarian, isTrue);
      expect(activeDuit.ledgerKey, equals('daily'));

      // Ubah ke Saldo
      container.read(activeDuitProvider.notifier).select(DuitType.saldo);
      activeDuit = container.read(activeDuitProvider);
      expect(activeDuit.type, equals(DuitType.saldo));
      expect(activeDuit.isSaldo, isTrue);
      expect(prefsService.activeDuitKey, equals('saldo'));

      // Ubah ke Tabungan
      container.read(activeDuitProvider.notifier).select(DuitType.tabungan);
      activeDuit = container.read(activeDuitProvider);
      expect(activeDuit.type, equals(DuitType.tabungan));
      expect(prefsService.activeDuitKey, equals('tabungan'));

      // Ubah ke Pencapaian
      container.read(activeDuitProvider.notifier).select(DuitType.pencapaian);
      activeDuit = container.read(activeDuitProvider);
      expect(activeDuit.type, equals(DuitType.pencapaian));
      expect(prefsService.activeDuitKey, equals('pencapaian'));

      // Ubah ke Semua
      container.read(activeDuitProvider.notifier).select('semua');
      activeDuit = container.read(activeDuitProvider);
      expect(activeDuit.isSemua, isTrue);
      expect(prefsService.activeDuitKey, equals('semua'));

      // Simulasi aplikasi dibuka kembali / quit & relaunch dengan SharedPreferences yang sama
      final reloadedPrefsService = PreferencesService(prefs);
      expect(reloadedPrefsService.activeDuitKey, equals('semua'));

      final reloadedContainer = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(reloadedPrefsService),
        ],
      );
      addTearDown(reloadedContainer.dispose);

      final reloadedActiveDuit = reloadedContainer.read(activeDuitProvider);
      expect(reloadedActiveDuit.isSemua, isTrue);
    });

    test('(2) Filter data transaksi per duit', () async {
      final catRepo = InMemoryCategoryRepository();
      final walletRepo = InMemoryWalletRepository();
      final goalRepo = InMemorySavingGoalRepository();
      final txRepo = InMemoryTransactionRepository(
        walletRepository: walletRepo,
        savingGoalRepository: goalRepo,
        categoryRepository: catRepo,
      );

      final now = DateTime.now();

      // Buat akun untuk tiap duit
      final wHarianId = await walletRepo.insertWallet(
        WalletItem(name: 'Kas Harian', type: 'daily', ledger: 'daily', initialBalance: 100000, createdAt: now),
      );
      final wSaldoId = await walletRepo.insertWallet(
        WalletItem(name: 'BCA', type: 'balance', ledger: 'balance', initialBalance: 500000, createdAt: now),
      );
      final wTabunganId = await walletRepo.insertWallet(
        WalletItem(name: 'Tabungan Nikah', type: 'saving', ledger: 'saving', initialBalance: 200000, createdAt: now),
      );

      final catId = await catRepo.insertCategory(
        const CategoryItem(name: 'Kebutuhan', type: 'expense', icon: 'fastfood', colorHex: '#F9A826'),
      );

      // Transaksi Duit Harian
      await txRepo.insertTransaction(
        TransactionItem(
          type: 'expense',
          ledger: 'daily',
          amount: 25000,
          categoryId: catId,
          walletId: wHarianId,
          date: now,
          createdAt: now,
        ),
      );

      // Transaksi Duit Saldo
      await txRepo.insertTransaction(
        TransactionItem(
          type: 'income',
          ledger: 'balance',
          amount: 150000,
          categoryId: catId,
          walletId: wSaldoId,
          date: now,
          createdAt: now,
        ),
      );

      // Transaksi Duit Tabungan
      await txRepo.insertTransaction(
        TransactionItem(
          type: 'income',
          ledger: 'saving',
          amount: 50000,
          categoryId: catId,
          walletId: wTabunganId,
          date: now,
          createdAt: now,
        ),
      );

      // Setoran ke Pencapaian
      final goalId = await goalRepo.insertSavingGoal(
        const SavingGoalItem(
          name: 'Beli HP',
          targetAmount: 3000000,
          currentAmount: 0,
          icon: 'phone',
          walletId: 1,
        ),
      );
      await txRepo.depositToGoal(
        goalId: goalId,
        amount: 300000,
        sourceWalletId: null,
      );

      // Verifikasi filter transaksi per ledger
      final dailyTx = await txRepo.getTransactionsByLedger('daily');
      expect(dailyTx.length, equals(1));
      expect(dailyTx.first.amount, equals(25000));

      final balanceTx = await txRepo.getTransactionsByLedger('balance');
      expect(balanceTx.length, equals(1));
      expect(balanceTx.first.amount, equals(150000));

      final savingTx = await txRepo.getTransactionsByLedger('saving');
      expect(savingTx.length, equals(1));
      expect(savingTx.first.amount, equals(50000));

      final goalTx = await txRepo.getTransactionsByLedger('goal');
      expect(goalTx.length, equals(1));
      expect(goalTx.first.amount, equals(300000));

      // Verifikasi saldo per ledger
      final balHarian = await txRepo.calculateLedgerBalance('daily');
      expect(balHarian, equals(75000)); // 100000 - 25000

      final balSaldo = await txRepo.calculateLedgerBalance('balance');
      expect(balSaldo, equals(650000)); // 500000 + 150000

      final balTabungan = await txRepo.calculateLedgerBalance('saving');
      expect(balTabungan, equals(250000)); // 200000 + 50000

      final balGoal = await txRepo.calculateLedgerBalance('goal');
      expect(balGoal, equals(300000));
    });

    test('(3) Fitur Atur Saldo: Tambah Saldo, Koreksi, Reset Opsi a, Reset Opsi b',
        () async {
      final catRepo = InMemoryCategoryRepository();
      final walletRepo = InMemoryWalletRepository();
      final goalRepo = InMemorySavingGoalRepository();
      final txRepo = InMemoryTransactionRepository(
        walletRepository: walletRepo,
        savingGoalRepository: goalRepo,
        categoryRepository: catRepo,
      );

      final walletId = await walletRepo.insertWallet(
        WalletItem(
          name: 'Dompet Kas',
          type: 'daily',
          ledger: 'daily',
          initialBalance: 50000,
          createdAt: DateTime.now(),
        ),
      );

      // 1. Tambah Saldo: membuat transaksi pemasukan kategori "Tambah Saldo"
      await txRepo.addBalance(
        walletId: walletId,
        amount: 25000,
        note: 'Top up uang jajan',
      );

      var currentBal = await txRepo.calculateWalletBalance(walletId);
      expect(currentBal, equals(75000)); // 50000 + 25000

      // Pastikan kategori "Tambah Saldo" tercatat di transaksi
      final txs = await txRepo.getTransactionsByLedger('daily');
      expect(txs.any((t) => t.type == 'income' && t.amount == 25000), isTrue);

      // 2. Koreksi Saldo: pengguna memasukkan saldo sebenarnya 100000 (selisih +25000)
      await txRepo.correctBalance(
        walletId: walletId,
        actualBalance: 100000,
      );
      currentBal = await txRepo.calculateWalletBalance(walletId);
      expect(currentBal, equals(100000));

      // 3. Reset Saldo Opsi a: Reset ke Rp 0 & simpan riwayat
      await txRepo.resetBalanceWithHistory(walletId: walletId);
      currentBal = await txRepo.calculateWalletBalance(walletId);
      expect(currentBal, equals(0));

      // Riwayat transaksi tetap ada
      final txsAfterResetA = await txRepo.getTransactionsByLedger('daily');
      expect(txsAfterResetA.length, greaterThanOrEqualTo(3));

      // 4. Reset Saldo Opsi b: Reset dan hapus riwayat duit ini
      await txRepo.resetLedgerAndWipeHistory(ledger: 'daily');
      final txsAfterResetB = await txRepo.getTransactionsByLedger('daily');
      expect(txsAfterResetB.isEmpty, isTrue);

      final updatedWallet = await walletRepo.getWalletById(walletId);
      expect(updatedWallet?.initialBalance, equals(0));
      currentBal = await txRepo.calculateWalletBalance(walletId);
      expect(currentBal, equals(0));

      // 5. Reset Progres untuk Duit Pencapaian
      final goalId = await goalRepo.insertSavingGoal(
        const SavingGoalItem(
          name: 'Mobil',
          targetAmount: 200000000,
          currentAmount: 15000000,
          icon: 'car',
          walletId: 1,
        ),
      );
      final goalBefore = await goalRepo.getSavingGoalById(goalId);
      expect(goalBefore?.currentAmount, equals(15000000));

      await goalRepo.resetProgress(goalId);
      final updatedGoal = await goalRepo.getSavingGoalById(goalId);
      expect(updatedGoal?.currentAmount, equals(0));
      expect(updatedGoal?.targetAmount, equals(200000000)); // target tetap ada
    });
  });
}
