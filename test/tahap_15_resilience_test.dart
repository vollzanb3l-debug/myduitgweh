import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myduitgweh/core/constants/app_labels.dart';
import 'package:myduitgweh/core/constants/backup_constants.dart';
import 'package:myduitgweh/core/models/duit_type.dart';
import 'package:myduitgweh/core/providers/app_state_provider.dart';
import 'package:myduitgweh/core/services/backup_service.dart';
import 'package:myduitgweh/core/services/preferences_service.dart';
import 'package:myduitgweh/data/database/app_database.dart';
import 'package:myduitgweh/data/models/transaction_model.dart';
import 'package:myduitgweh/data/models/wallet_model.dart';
import 'package:myduitgweh/data/repositories/drift_category_repository.dart';
import 'package:myduitgweh/data/repositories/drift_saving_goal_repository.dart';
import 'package:myduitgweh/data/repositories/drift_transaction_repository.dart';
import 'package:myduitgweh/data/repositories/drift_wallet_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tahap 15: Database Persisten, Backup v2, & Fitur Resiliensi Tests', () {
    late AppDatabase db;
    late DriftWalletRepository walletRepo;
    late DriftCategoryRepository categoryRepo;
    late DriftSavingGoalRepository goalRepo;
    late DriftTransactionRepository txRepo;
    late SharedPreferences sharedPrefs;
    late PreferencesService prefsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sharedPrefs = await SharedPreferences.getInstance();
      prefsService = PreferencesService(sharedPrefs);

      // Gunakan in-memory database drift untuk isolasi pengujian yang cepat
      db = AppDatabase(NativeDatabase.memory());
      walletRepo = DriftWalletRepository(db);
      categoryRepo = DriftCategoryRepository(db);
      goalRepo = DriftSavingGoalRepository(db);
      txRepo = DriftTransactionRepository(
        db,
        walletRepository: walletRepo,
        savingGoalRepository: goalRepo,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('(Poin 1) Database Drift & Repository bekerja menyimpan & membaca data secara persisten', () async {
      // 1. Simpan dompet baru
      final walletId = await walletRepo.insertWallet(
        WalletItem(
          name: 'Dompet Uji Persisten',
          type: 'balance',
          ledger: 'balance',
          initialBalance: 50000,
          createdAt: DateTime.now(),
        ),
      );
      expect(walletId, isNotNull);

      // 2. Baca kembali dari database
      final wallet = await walletRepo.getWalletById(walletId);
      expect(wallet, isNotNull);
      expect(wallet!.name, 'Dompet Uji Persisten');
      expect(wallet.initialBalance, 50000);

      // 3. Tambahkan transaksi pada dompet tersebut
      final txId = await txRepo.insertTransaction(
        TransactionItem(
          type: 'income',
          amount: 25000,
          categoryId: 1,
          walletId: walletId,
          date: DateTime.now(),
          ledger: 'balance',
          createdAt: DateTime.now(),
        ),
      );
      expect(txId, isNotNull);

      // 4. Hitung saldo terhitung
      final balance = await txRepo.calculateWalletBalance(walletId);
      expect(balance, equals(75000));
    });

    test('(Poin 2) Cadangan Backup Versi 2 & Migrasi Bertahap dari Versi 1', () async {
      expect(BackupConstants.currentBackupVersion, greaterThanOrEqualTo(2));

      final backupService = BackupService(
        walletRepo: walletRepo,
        categoryRepo: categoryRepo,
        goalRepo: goalRepo,
        txRepo: txRepo,
        prefs: prefsService,
      );

      // Simulasikan file cadangan v1 (tanpa hideBalance map dan tanpa userName)
      final v1Json = {
        'appName': BackupConstants.appIdentifier,
        'backupVersion': 1,
        'appVersion': '1.0.0',
        'createdAt': DateTime.now().toIso8601String(),
        'wallets': [
          {
            'id': 1,
            'name': 'Uang Utama',
            'type': 'daily',
            'ledger': 'daily',
            'initialBalance': 100000,
            'createdAt': DateTime.now().toIso8601String(),
          }
        ],
        'categories': [],
        'savingGoals': [],
        'transactions': [],
      };

      final jsonString = jsonEncode(v1Json);
      final restoreResult = await backupService.restoreBackup(jsonString);

      // Pastikan pulihkan berhasil dan data termigrasi dengan aman ke format terbaru
      expect(restoreResult.success, isTrue);
      expect(restoreResult.restoredWallets, greaterThanOrEqualTo(1));

      // Cek dompet berhasil terisi dari cadangan
      final dailyWallets = await walletRepo.getWalletsByLedger('daily');
      expect(dailyWallets.isNotEmpty, isTrue);
      expect(dailyWallets.first.initialBalance, 100000);
    });

    test('(Poin 3) Hapus transaksi tertentu menghitung ulang saldo & menghapus pasangan transfer', () async {
      // Buat dua dompet untuk transfer
      final w1 = await walletRepo.insertWallet(
        WalletItem(
          name: 'Sumber Transfer',
          type: 'balance',
          ledger: 'balance',
          initialBalance: 100000,
          createdAt: DateTime.now(),
        ),
      );
      final w2 = await walletRepo.insertWallet(
        WalletItem(
          name: 'Tujuan Transfer',
          type: 'balance',
          ledger: 'balance',
          initialBalance: 0,
          createdAt: DateTime.now(),
        ),
      );

      // Lakukan transfer Rp 30.000 dari w1 ke w2
      await txRepo.transferBetweenWallets(
        sourceWalletId: w1,
        targetWalletId: w2,
        amount: 30000,
        note: 'Uji Hapus Transfer',
      );

      // Pastikan saldo awal transfer terhitung benar
      expect(await txRepo.calculateWalletBalance(w1), equals(70000));
      expect(await txRepo.calculateWalletBalance(w2), equals(30000));

      final allTx = await txRepo.getAllTransactions();
      expect(allTx.length, equals(2));

      // Hapus salah satu transaksi transfer (harus menghapus 2 transaksi berpasangan)
      final outTx = allTx.firstWhere((t) => t.type == 'expense');
      final deleted = await txRepo.deleteTransaction(outTx.id!);
      expect(deleted, equals(2));

      // Kedua transaksi terhubung harus terhapus
      final remainingTx = await txRepo.getAllTransactions();
      expect(remainingTx.isEmpty, isTrue);

      // Saldo kedua dompet otomatis kembali ke saldo semula
      expect(await txRepo.calculateWalletBalance(w1), equals(100000));
      expect(await txRepo.calculateWalletBalance(w2), equals(0));
    });

    test('(Poin 5) Perubahan Istilah Harian menjadi Utama di AppLabels & DuitType', () {
      expect(AppLabels.duitUtama, equals('Duit Utama'));
      expect(duitShortName(DuitType.harian), equals('Utama'));
      expect(brandLabel(DuitType.harian), equals('MyDuitGweh (Utama)'));
    });

    test('(Poin 6) Sembunyikan saldo independen per jenis duit di preferences & provider', () async {
      final container = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(prefsService),
        ],
      );

      final notifier = container.read(duitHideBalanceProvider.notifier);

      // Default: semua duit saldo terbuka (false)
      expect(container.read(isDuitHiddenProvider('utama')), isFalse);
      expect(container.read(isDuitHiddenProvider('saldo')), isFalse);
      expect(container.read(isDuitHiddenProvider('tabungan')), isFalse);
      expect(container.read(isDuitHiddenProvider('pencapaian')), isFalse);
      expect(container.read(isDuitHiddenProvider('semua')), isFalse);

      // Sembunyikan hanya duit 'tabungan'
      await notifier.setHidden('tabungan', true);
      expect(container.read(isDuitHiddenProvider('tabungan')), isTrue);

      // Duit lain tetap terbuka
      expect(container.read(isDuitHiddenProvider('utama')), isFalse);
      expect(container.read(isDuitHiddenProvider('saldo')), isFalse);

      // Toggle duit 'utama'
      await notifier.toggle('utama');
      expect(container.read(isDuitHiddenProvider('utama')), isTrue);

      // Nilai tersimpan di preferences dan terbaca kembali
      final reloadedMap = prefsService.getAllDuitHideBalance();
      expect(reloadedMap['tabungan'], isTrue);
      expect(reloadedMap['utama'], isTrue);
      expect(reloadedMap['saldo'] ?? false, isFalse);

      container.dispose();
    });

    test('(Poin 7) Profil Pengguna di Pengaturan: validasi dan perubahan nama', () async {
      final container = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(prefsService),
        ],
      );

      final userNotifier = container.read(userNameProvider.notifier);
      expect(container.read(userNameProvider), isEmpty);

      // Ubah nama pengguna
      await userNotifier.updateName('Sultan Duit');
      expect(container.read(userNameProvider), equals('Sultan Duit'));
      expect(prefsService.userName, equals('Sultan Duit'));

      container.dispose();
    });
  });
}
