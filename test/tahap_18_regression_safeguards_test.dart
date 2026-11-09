import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:myduitgweh/core/constants/category_constants.dart';
import 'package:myduitgweh/data/database/app_database.dart';
import 'package:myduitgweh/data/models/category_model.dart';
import 'package:myduitgweh/data/models/saving_goal_model.dart';
import 'package:myduitgweh/data/models/transaction_model.dart';
import 'package:myduitgweh/data/repositories/drift_category_repository.dart';
import 'package:myduitgweh/data/repositories/drift_saving_goal_repository.dart';
import 'package:myduitgweh/data/repositories/drift_transaction_repository.dart';
import 'package:myduitgweh/data/repositories/drift_wallet_repository.dart';

void main() {
  late AppDatabase db;
  late DriftWalletRepository walletRepo;
  late DriftCategoryRepository categoryRepo;
  late DriftSavingGoalRepository goalRepo;
  late DriftTransactionRepository txRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    walletRepo = DriftWalletRepository(db);
    categoryRepo = DriftCategoryRepository(db);
    goalRepo = DriftSavingGoalRepository(db);
    txRepo = DriftTransactionRepository(
      db,
      walletRepository: walletRepo,
      savingGoalRepository: goalRepo,
      categoryRepository: categoryRepo,
    );
    await walletRepo.ensureInternalWallets();
  });

  tearDown(() async {
    await db.close();
  });

  group('Tahap 18: Pengaman Kualitas & Tes Regresi', () {
    // 1. Kategori terisolasi per Duit
    test('1. Kategori terisolasi per Duit: Utama, Saldo, dan Tabungan tidak saling campur', () async {
      final allCats = await categoryRepo.getAllCategories();
      expect(allCats, isNotEmpty);

      final dailyCats = allCats.where((c) => c.ledger == 'daily').toList();
      final balanceCats = allCats.where((c) => c.ledger == 'balance').toList();
      final savingCats = allCats.where((c) => c.ledger == 'saving').toList();

      expect(dailyCats, isNotEmpty);
      expect(balanceCats, isNotEmpty);
      expect(savingCats, isNotEmpty);

      // Kategori daily tidak boleh ada di balance
      for (final c in dailyCats) {
        expect(c.ledger, equals('daily'));
      }

      // Kategori khusus balance (Tunai, Bank, Tagihan, Transfer Masuk/Keluar) harus ledger balance
      final balanceNames = balanceCats.map((c) => c.name).toSet();
      expect(balanceNames.contains('Bank'), isTrue);
      expect(balanceNames.contains('Tagihan'), isTrue);
      expect(balanceNames.contains('Transfer Masuk'), isTrue);

      // Kategori khusus tabungan (Setoran, Penarikan, Bunga/Bonus) harus ledger saving
      final savingNames = savingCats.map((c) => c.name).toSet();
      expect(savingNames.contains('Setoran'), isTrue);
      expect(savingNames.contains('Penarikan'), isTrue);

      // Duit Utama tidak boleh menampung kategori Bank, Tagihan, atau Penarikan
      final dailyNames = dailyCats.map((c) => c.name).toSet();
      expect(dailyNames.contains('Bank'), isFalse);
      expect(dailyNames.contains('Tagihan'), isFalse);
      expect(dailyNames.contains('Penarikan'), isFalse);
    });

    // 2. Warna kategori tidak null/kosong dan sesuai palet konstan
    test('2. Warna kategori tidak kosong, tidak abu-abu mati, dan sesuai palet konstan', () async {
      final allCats = await categoryRepo.getAllCategories();
      for (final cat in allCats) {
        expect(cat.colorHex, isNotEmpty);
        expect(cat.colorHex.startsWith('#'), isTrue);
        // Kecuali kategori "Lainnya" yang sengaja abu-abu lembut (#B2BEC3), kategori tidak boleh mati
        if (cat.name.toLowerCase() != 'lainnya') {
          expect(cat.colorHex, isNot(equals('#6B7280')));
        }
      }

      // Uji fungsi fallback konstan deterministik
      final fallback1 = CategoryConstants.getFallbackColorHex('Kategori A');
      final fallback2 = CategoryConstants.getFallbackColorHex('Kategori A');
      expect(fallback1, equals(fallback2)); // Konsisten deterministik
      expect(CategoryConstants.vibrantPaletteHex.contains(fallback1), isTrue);
    });

    // 3. Setor pencapaian mandiri berhasil
    test('3. Setor pencapaian mandiri menambah saldo target & tercatat di riwayat tanpa potong duit lain', () async {
      final wUtama = await walletRepo.getOrCreateInternalWallet('daily');
      final initialDaily = await txRepo.calculateLedgerBalance('daily');

      // Buat target impian
      final goalId = await goalRepo.insertSavingGoal(
        SavingGoalItem(
          name: 'Beli Sepeda',
          targetAmount: 2000000,
          currentAmount: 0,
          walletId: wUtama.id!,
        ),
      );

      // Setor mandiri Rp 300.000
      await txRepo.depositToGoal(
        goalId: goalId,
        amount: 300000,
        note: 'Nabung mandiri',
      );

      final updatedGoal = await goalRepo.getSavingGoalById(goalId);
      expect(updatedGoal, isNotNull);
      expect(updatedGoal!.currentAmount, equals(300000));

      final goalBalance = await txRepo.calculateLedgerBalance('goal');
      expect(goalBalance, equals(300000));

      // Saldo Duit Utama TIDAK berkurang karena setor mandiri
      final afterDaily = await txRepo.calculateLedgerBalance('daily');
      expect(afterDaily, equals(initialDaily));

      // Tercatat di riwayat Duit Pencapaian
      final goalTxs = await txRepo.getTransactionsByLedger('goal');
      expect(goalTxs.length, equals(1));
      expect(goalTxs.first.amount, equals(300000));
      expect(goalTxs.first.goalId, equals(goalId));
      expect(goalTxs.first.transferPartnerId, isNull);
    });

    // 4. Setor pencapaian dengan potong duit lain
    test('4. Setor pencapaian potong duit lain menambah target & mengurangi saldo asal secara atomik', () async {
      final wUtama = await walletRepo.getOrCreateInternalWallet('daily');

      // Tambah saldo utama awal Rp 1.000.000
      await txRepo.insertTransaction(
        TransactionItem(
          type: 'income',
          amount: 1000000,
          categoryId: 11, // Gaji
          walletId: wUtama.id!,
          date: DateTime.now(),
          ledger: 'daily',
          createdAt: DateTime.now(),
        ),
      );

      final beforeDaily = await txRepo.calculateLedgerBalance('daily');
      expect(beforeDaily, equals(1000000));

      // Buat target impian
      final goalId = await goalRepo.insertSavingGoal(
        SavingGoalItem(
          name: 'Renovasi Kamar',
          targetAmount: 5000000,
          currentAmount: 0,
          walletId: wUtama.id!,
        ),
      );

      // Setor Rp 400.000 potong dari Duit Utama
      await txRepo.depositToGoal(
        goalId: goalId,
        amount: 400000,
        sourceWalletId: wUtama.id!,
        note: 'Dari gaji',
      );

      // Progres target naik
      final updatedGoal = await goalRepo.getSavingGoalById(goalId);
      expect(updatedGoal!.currentAmount, equals(400000));

      // Saldo Duit Utama berkurang Rp 400.000
      final afterDaily = await txRepo.calculateLedgerBalance('daily');
      expect(afterDaily, equals(600000));

      // Kedua riwayat ada dan terhubung transferPartnerId
      final dailyTxs = await txRepo.getTransactionsByLedger('daily');
      final goalTxs = await txRepo.getTransactionsByLedger('goal');

      final expenseTx = dailyTxs.firstWhere((t) => t.type == 'expense');
      final incomeGoalTx = goalTxs.firstWhere((t) => t.type == 'income');

      expect(expenseTx.amount, equals(400000));
      expect(expenseTx.transferPartnerId, equals(incomeGoalTx.id));
      expect(incomeGoalTx.transferPartnerId, equals(expenseTx.id));
    });

    // 5. Hapus transaksi memulihkan saldo dan progres target secara bersih
    test('5. Hapus transaksi atomik: transaksi biasa, setor target, dan transfer pasangan', () async {
      final wUtama = await walletRepo.getOrCreateInternalWallet('daily');
      final wSaldo = await walletRepo.getOrCreateInternalWallet('balance');

      // A. Uji Hapus Transaksi Biasa
      final regularTxId = await txRepo.insertTransaction(
        TransactionItem(
          type: 'expense',
          amount: 75000,
          categoryId: 1,
          walletId: wUtama.id!,
          date: DateTime.now(),
          ledger: 'daily',
          createdAt: DateTime.now(),
        ),
      );
      final balWithTx = await txRepo.calculateLedgerBalance('daily');
      expect(balWithTx, equals(-75000));

      await txRepo.deleteTransaction(regularTxId);
      final balRestored = await txRepo.calculateLedgerBalance('daily');
      expect(balRestored, equals(0)); // Kembali utuh

      // B. Uji Hapus Setor Target dengan Potong Duit Lain
      final goalId = await goalRepo.insertSavingGoal(
        SavingGoalItem(
          name: 'Dana Liburan',
          targetAmount: 3000000,
          currentAmount: 0,
          walletId: wUtama.id!,
        ),
      );

      await txRepo.depositToGoal(
        goalId: goalId,
        amount: 250000,
        sourceWalletId: wUtama.id!,
      );

      var goal = await goalRepo.getSavingGoalById(goalId);
      expect(goal!.currentAmount, equals(250000));
      expect(await txRepo.calculateLedgerBalance('daily'), equals(-250000));

      // Hapus dari sisi goal
      final goalTx = (await txRepo.getTransactionsByLedger('goal')).first;
      await txRepo.deleteTransaction(goalTx.id!);

      goal = await goalRepo.getSavingGoalById(goalId);
      expect(goal!.currentAmount, equals(0)); // Progres kembali berkurang
      expect(await txRepo.calculateLedgerBalance('daily'), equals(0)); // Saldo asal kembali
      expect((await txRepo.getTransactionsByLedger('daily')).isEmpty, isTrue); // Pasangan terhapus
      expect((await txRepo.getTransactionsByLedger('goal')).isEmpty, isTrue);

      // C. Uji Hapus Transfer Antar-Duit
      await txRepo.transferBetweenWallets(
        sourceWalletId: wUtama.id!,
        targetWalletId: wSaldo.id!,
        amount: 500000,
        note: 'Pindah ke saldo',
      );
      expect(await txRepo.calculateLedgerBalance('daily'), equals(-500000));
      expect(await txRepo.calculateLedgerBalance('balance'), equals(500000));

      final transferOut = (await txRepo.getTransactionsByLedger('daily')).first;
      await txRepo.deleteTransaction(transferOut.id!);

      expect(await txRepo.calculateLedgerBalance('daily'), equals(0));
      expect(await txRepo.calculateLedgerBalance('balance'), equals(0));
      expect((await txRepo.getTransactionsByLedger('daily')).isEmpty, isTrue);
      expect((await txRepo.getTransactionsByLedger('balance')).isEmpty, isTrue);
    });

    // 6. Konsistensi saldo: total saldo dihitung ulang dari riwayat cocok dengan saldo yang tampil
    test('6. Konsistensi saldo: rekalkulasi dari riwayat transaksi 100% cocok dengan calculateLedgerBalance', () async {
      final wUtama = await walletRepo.getOrCreateInternalWallet('daily');
      final amounts = [150000, -25000, -45000, 80000, -12000];

      int manualSum = 0;
      for (final a in amounts) {
        manualSum += a;
        await txRepo.insertTransaction(
          TransactionItem(
            type: a >= 0 ? 'income' : 'expense',
            amount: a.abs(),
            categoryId: a >= 0 ? 10 : 1,
            walletId: wUtama.id!,
            date: DateTime.now(),
            ledger: 'daily',
            createdAt: DateTime.now(),
          ),
        );
      }

      final calculated = await txRepo.calculateLedgerBalance('daily');
      expect(calculated, equals(manualSum));
    });

    // 7. Pengguna kustom tidak tertimpa & tetap utuh
    test('7. Kategori kustom buatan pengguna tidak tertimpa dan tetap memiliki penanda ledger yang benar', () async {
      final customId = await categoryRepo.insertCategory(
        const CategoryItem(
          name: 'Langganan AI',
          icon: 'star_rounded',
          colorHex: '#6C5CE7',
          type: 'expense',
          ledger: 'daily',
        ),
      );

      final custom = await categoryRepo.getCategoryById(customId);
      expect(custom, isNotNull);
      expect(custom!.name, equals('Langganan AI'));
      expect(custom.colorHex, equals('#6C5CE7'));
      expect(custom.ledger, equals('daily'));
    });
  });
}
