import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myduitgweh/core/constants/backup_constants.dart';
import 'package:myduitgweh/core/services/backup_service.dart';
import 'package:myduitgweh/core/services/preferences_service.dart';
import 'package:myduitgweh/data/models/category_model.dart';
import 'package:myduitgweh/data/models/transaction_model.dart';
import 'package:myduitgweh/data/models/wallet_model.dart';
import 'package:myduitgweh/data/repositories/category_repository.dart';
import 'package:myduitgweh/data/repositories/saving_goal_repository.dart';
import 'package:myduitgweh/data/repositories/transaction_repository.dart';
import 'package:myduitgweh/data/repositories/wallet_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tahap 14b: Format Cadangan (Backup & Restore Resilience) Tests', () {
    late PreferencesService prefsService;
    late InMemoryWalletRepository walletRepo;
    late InMemoryCategoryRepository categoryRepo;
    late InMemorySavingGoalRepository goalRepo;
    late InMemoryTransactionRepository txRepo;
    late BackupService backupService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      prefsService = PreferencesService(prefs);

      walletRepo = InMemoryWalletRepository(seedInitialData: true);
      categoryRepo = InMemoryCategoryRepository(seedInitialData: true);
      goalRepo = InMemorySavingGoalRepository(seedInitialData: false);
      txRepo = InMemoryTransactionRepository(
        walletRepository: walletRepo,
        savingGoalRepository: goalRepo,
        categoryRepository: categoryRepo,
      );

      backupService = BackupService(
        walletRepo: walletRepo,
        categoryRepo: categoryRepo,
        goalRepo: goalRepo,
        txRepo: txRepo,
        prefs: prefsService,
      );
    });

    tearDown(() {
      walletRepo.dispose();
      categoryRepo.dispose();
      goalRepo.dispose();
      txRepo.dispose();
    });

    // 1. Verifikasi pembuatan backup memuat backupVersion, appVersion, createdAt
    test('1. createBackupJson memuat backupVersion, appVersion, dan tanggal pembuatan', () async {
      final jsonStr = await backupService.createBackupJson();
      expect(jsonStr, contains('"appName": "${BackupConstants.appIdentifier}"'));
      expect(jsonStr, contains('"backupVersion": ${BackupConstants.currentBackupVersion}'));
      expect(jsonStr, contains('"appVersion": "${BackupConstants.currentAppVersion}"'));
      expect(jsonStr, contains('"createdAt":'));
    });

    // (a) Backup versi lama berhasil di-import ke format terbaru
    test('(a) Backup versi lama (v0 legacy) berhasil dimigrasi dan di-import ke format terbaru', () async {
      final file = File('test/fixtures/backup_v0_legacy.json');
      final legacyJson = await file.readAsString();

      // Pastikan validasi awal mengizinkan versi lama untuk dimigrasi
      final prelim = backupService.validateBackupPrelim(legacyJson);
      expect(prelim, isNull);

      final result = await backupService.restoreBackup(legacyJson);
      expect(result.success, isTrue);
      expect(result.restoredWallets, 3);
      expect(result.restoredCategories, greaterThanOrEqualTo(1));
      expect(result.restoredTransactions, 1);

      final wallets = await walletRepo.getAllWallets();
      expect(wallets.length, 3);
      expect(wallets.map((w) => w.ledger), containsAll(['daily', 'balance', 'saving']));
      expect(prefsService.userName, 'Pengguna Lama');
    });

    // (b) Kolom hilang diisi nilai bawaan yang masuk akal
    // (c) Kolom tak dikenal diabaikan tanpa error
    test('(b & c) Kolom hilang diisi nilai bawaan dan kolom tak dikenal diabaikan tanpa error', () async {
      final file = File('test/fixtures/backup_tolerant.json');
      final tolerantJson = await file.readAsString();

      final result = await backupService.restoreBackup(tolerantJson);
      expect(result.success, isTrue);

      // Wallets: type default 'balance', initialBalance default 0
      final wallets = await walletRepo.getAllWallets();
      expect(wallets.length, 3);
      final w = wallets.firstWhere((w) => w.ledger == 'balance');
      expect(w.initialBalance, 0);

      // Categories: name 'Makanan', type default 'expense', icon default 'category_rounded'
      final categories = await categoryRepo.getAllCategories();
      expect(categories.length, 1);
      final c = categories.first;
      expect(c.name, 'Makanan');
      expect(c.type, 'expense');
      expect(c.icon, 'category_rounded');

      // SavingGoals: Target 1 (negatif) dilewati, Target 2 (valid) dipulihkan
      final goals = await goalRepo.getAllSavingGoals();
      expect(goals.length, 1);
      expect(goals.first.name, 'Target Valid');
      expect(goals.first.targetAmount, 1000000);

      // Transactions: TX1 (-25k) dilewati, TX2 (wallet 99999 tidak ada) dilewati, TX3 dipulihkan
      final txs = await txRepo.getAllTransactions();
      expect(txs.length, 1);
      expect(txs.first.amount, 75000);
      expect(txs.first.note, 'Transaksi valid dengan kolom tak dikenal');

      // Memverifikasi skippedCount dan alasan pencatatan
      expect(result.skippedCount, 3);
      expect(result.skippedReasons.any((r) => r.contains('nominal harus lebih besar dari 0')), isTrue);
      expect(result.skippedReasons.any((r) => r.contains('99999')), isTrue);
      expect(result.skippedReasons.any((r) => r.contains('nominal target negatif')), isTrue);
    });

    // (d) Versi lebih baru ditolak tanpa crash dengan pesan ramah
    test('(d) Versi lebih baru (v99) ditolak tanpa crash dengan pesan ramah', () async {
      final file = File('test/fixtures/backup_future_v99.json');
      final futureJson = await file.readAsString();

      // Pemeriksaan awal menolak versi lebih baru
      final prelim = backupService.validateBackupPrelim(futureJson);
      expect(prelim, BackupConstants.errNewerVersion);

      // restoreBackup juga menolak dan tidak crash
      final result = await backupService.restoreBackup(futureJson);
      expect(result.success, isFalse);
      expect(result.message, BackupConstants.errNewerVersion);
    });

    // (e) File rusak atau bukan JSON ditolak tanpa mengubah data
    test('(e) File rusak atau bukan JSON ditolak tanpa mengubah data yang ada', () async {
      // Ambil snapshot kondisi data awal
      final initialWallets = await walletRepo.getAllWallets();
      final initialCount = initialWallets.length;
      expect(initialCount, greaterThan(0));

      final file = File('test/fixtures/backup_corrupt.json');
      final corruptJson = await file.readAsString();

      // Validasi awal
      final prelim = backupService.validateBackupPrelim(corruptJson);
      expect(prelim, BackupConstants.errInvalidBackup);

      // restoreBackup menolak
      final result = await backupService.restoreBackup(corruptJson);
      expect(result.success, isFalse);
      expect(result.message, BackupConstants.errInvalidBackup);

      // Data lama harus tetap utuh 100%
      final currentWallets = await walletRepo.getAllWallets();
      expect(currentWallets.length, initialCount);
    });

    // (f) Kegagalan di tengah import tidak mengubah data lama (Rollback aman)
    test('(f) Kegagalan di tengah import membatalkan perubahan dan memulihkan data lama', () async {
      // Siapkan akun awal khusus dan transaksi
      walletRepo.clearAll();
      await walletRepo.insertWallet(
        WalletItem(
          id: 777,
          name: 'Dompet Lama Tetap Ada',
          type: 'balance',
          initialBalance: 123456,
          createdAt: DateTime.now(),
        ),
      );

      final catId = await categoryRepo.insertCategory(
        const CategoryItem(name: 'Belanja', icon: 'cart', colorHex: '#123456', type: 'expense'),
      );
      await txRepo.insertTransaction(
        TransactionItem(
          amount: 50000,
          type: 'expense',
          categoryId: catId,
          walletId: 777,
          date: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );

      final initialWallets = await walletRepo.getAllWallets();
      expect(initialWallets.first.name, 'Dompet Lama Tetap Ada');

      // Buat berkas cadangan valid (memiliki wallet, category, dan transaction)
      final validJson = await backupService.createBackupJson();

      // Simulasikan repositori rusak yang melempar Exception saat insert transaksi
      final failingTxRepo = _FailingTransactionRepository(
        walletRepository: walletRepo,
        savingGoalRepository: goalRepo,
        categoryRepository: categoryRepo,
      );

      final failingBackupService = BackupService(
        walletRepo: walletRepo,
        categoryRepo: categoryRepo,
        goalRepo: goalRepo,
        txRepo: failingTxRepo,
        prefs: prefsService,
      );

      // Eksekusi restore dengan failing repo
      final result = await failingBackupService.restoreBackup(validJson);
      expect(result.success, isFalse);
      expect(result.message, contains('Terjadi kesalahan saat memulihkan data'));

      // Verifikasi data lama dipulihkan kembali dan tidak hilang
      final recoveredWallets = await walletRepo.getAllWallets();
      expect(recoveredWallets.any((w) => w.name == 'Dompet Lama Tetap Ada'), isTrue);
    });
  });
}

class _FailingTransactionRepository extends InMemoryTransactionRepository {
  _FailingTransactionRepository({
    required super.walletRepository,
    required super.savingGoalRepository,
    required super.categoryRepository,
  });

  @override
  Future<int> insertTransaction(dynamic transaction) async {
    throw Exception('Simulasi kegagalan database I/O di tengah transaksi');
  }
}
