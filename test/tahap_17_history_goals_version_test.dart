import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myduitgweh/core/constants/about_text.dart';
import 'package:myduitgweh/core/constants/backup_constants.dart';
import 'package:myduitgweh/core/providers/app_state_provider.dart';
import 'package:myduitgweh/core/services/backup_service.dart';
import 'package:myduitgweh/core/services/preferences_service.dart';
import 'package:myduitgweh/data/database/app_database.dart';
import 'package:myduitgweh/data/models/saving_goal_model.dart';
import 'package:myduitgweh/data/models/transaction_model.dart';
import 'package:myduitgweh/data/repositories/drift_category_repository.dart';
import 'package:myduitgweh/data/repositories/drift_saving_goal_repository.dart';
import 'package:myduitgweh/data/repositories/drift_transaction_repository.dart';
import 'package:myduitgweh/data/repositories/drift_wallet_repository.dart';
import 'package:myduitgweh/data/repositories/providers.dart';
import 'package:myduitgweh/features/transactions/presentation/history_screen.dart';
import 'package:myduitgweh/features/wallets/presentation/goals_ledger_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tahap 17: Riwayat Lintas Periode, Setor Pencapaian & Versi Tests', () {
    late AppDatabase db;
    late DriftWalletRepository walletRepo;
    late DriftCategoryRepository categoryRepo;
    late DriftSavingGoalRepository goalRepo;
    late DriftTransactionRepository txRepo;
    late SharedPreferences sharedPrefs;
    late PreferencesService prefsService;
    late BackupService backupService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sharedPrefs = await SharedPreferences.getInstance();
      prefsService = PreferencesService(sharedPrefs);

      db = AppDatabase(NativeDatabase.memory());
      walletRepo = DriftWalletRepository(db);
      categoryRepo = DriftCategoryRepository(db);
      goalRepo = DriftSavingGoalRepository(db);
      txRepo = DriftTransactionRepository(
        db,
        walletRepository: walletRepo,
        savingGoalRepository: goalRepo,
      );
      backupService = BackupService(
        walletRepo: walletRepo,
        categoryRepo: categoryRepo,
        goalRepo: goalRepo,
        txRepo: txRepo,
        prefs: prefsService,
      );
      await walletRepo.ensureInternalWallets();
    });

    tearDown(() async {
      await db.close();
    });

    // 1. RIWAYAT: Navigasi Periode & Filter Semua
    testWidgets('(Poin 1) Riwayat memungkinkan navigasi periode ke masa lalu dan filter Semua', (tester) async {
      final wUtama = await walletRepo.getOrCreateInternalWallet('daily');
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 15);

      // Transaksi bulan lalu
      await txRepo.insertTransaction(
        TransactionItem(
          type: 'income',
          amount: 250000,
          categoryId: 10,
          walletId: wUtama.id!,
          date: lastMonth,
          ledger: 'daily',
          note: 'Gaji Bulan Lalu',
          createdAt: lastMonth,
        ),
      );

      // Transaksi hari ini
      await txRepo.insertTransaction(
        TransactionItem(
          type: 'expense',
          amount: 50000,
          categoryId: 1,
          walletId: wUtama.id!,
          date: now,
          ledger: 'daily',
          note: 'Makan Siang Hari Ini',
          createdAt: now,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          walletRepositoryProvider.overrideWithValue(walletRepo),
          categoryRepositoryProvider.overrideWithValue(categoryRepo),
          savingGoalRepositoryProvider.overrideWithValue(goalRepo),
          transactionRepositoryProvider.overrideWithValue(txRepo),
          preferencesServiceProvider.overrideWithValue(prefsService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: HistoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Secara default (filter Harian), hanya transaksi hari ini yang tampil
      expect(find.text('Makan Siang Hari Ini'), findsOneWidget);
      expect(find.text('Gaji Bulan Lalu'), findsNothing);

      // Pindah ke tab Bulanan
      await tester.tap(find.text('Bulanan'));
      await tester.pumpAndSettle();
      expect(find.text('Makan Siang Hari Ini'), findsOneWidget);

      // Geser panah kiri (ke bulan lalu)
      await tester.tap(find.byTooltip('Periode Sebelumnya'));
      await tester.pumpAndSettle();

      // Sekarang transaksi bulan lalu tampil, dan ada tombol kembali ke bulan ini
      expect(find.text('Gaji Bulan Lalu'), findsOneWidget);
      expect(find.text('Makan Siang Hari Ini'), findsNothing);
      expect(find.text('Kembali ke Bulan Ini'), findsOneWidget);

      // Tekan tombol kembali ke Bulan Ini
      await tester.tap(find.text('Kembali ke Bulan Ini'));
      await tester.pumpAndSettle();
      expect(find.text('Makan Siang Hari Ini'), findsOneWidget);

      // Pindah ke tab "Semua" -> kedua transaksi harus tampil bersamaan
      await tester.tap(find.text('Semua'));
      await tester.pumpAndSettle();
      expect(find.text('Makan Siang Hari Ini'), findsOneWidget);
      expect(find.text('Gaji Bulan Lalu'), findsOneWidget);
      expect(find.text('Menampilkan Seluruh Riwayat'), findsOneWidget);
    });

    // 2. IMPOR CADANGAN: Transaksi multi-bulan masuk utuh & tanggal asli dipertahankan
    test('(Poin 2) Impor cadangan berisi transaksi multi-bulan mempertahankan tanggal asli & query per periode benar', () async {
      final now = DateTime.now();
      final dateMonth1 = DateTime(now.year, now.month - 2, 10, 14, 0);
      final dateMonth2 = DateTime(now.year, now.month - 1, 5, 9, 30);
      final dateToday = now;

      final multiMonthBackup = {
        'appName': BackupConstants.appIdentifier,
        'backupVersion': 3,
        'appVersion': '1.0.1',
        'createdAt': now.toIso8601String(),
        'wallets': [
          {'id': 1, 'name': 'Uang Utama', 'type': 'daily', 'ledger': 'daily', 'initialBalance': 100000, 'createdAt': now.toIso8601String()},
          {'id': 2, 'name': 'Duit Saldo', 'type': 'balance', 'ledger': 'balance', 'initialBalance': 200000, 'createdAt': now.toIso8601String()},
          {'id': 3, 'name': 'Duit Tabungan', 'type': 'saving', 'ledger': 'saving', 'initialBalance': 500000, 'createdAt': now.toIso8601String()},
        ],
        'categories': [
          {'id': 1, 'name': 'Makan', 'type': 'expense', 'ledger': 'daily', 'icon': 'fastfood', 'colorHex': '#FF5722'},
          {'id': 2, 'name': 'Gaji', 'type': 'income', 'ledger': 'daily', 'icon': 'payments', 'colorHex': '#4CAF50'},
        ],
        'savingGoals': [],
        'transactions': [
          {
            'id': 101,
            'walletId': 1,
            'categoryId': 2,
            'amount': 3000000,
            'type': 'income',
            'ledger': 'daily',
            'date': dateMonth1.toIso8601String(),
            'note': 'Gaji 2 Bulan Lalu',
          },
          {
            'id': 102,
            'walletId': 1,
            'categoryId': 1,
            'amount': 150000,
            'type': 'expense',
            'ledger': 'daily',
            'date': dateMonth2.toIso8601String(),
            'note': 'Makan 1 Bulan Lalu',
          },
          {
            'id': 103,
            'walletId': 1,
            'categoryId': 1,
            'amount': 25000,
            'type': 'expense',
            'ledger': 'daily',
            'date': dateToday.toIso8601String(),
            'note': 'Makan Hari Ini',
          },
        ],
        'preferences': {
          'userName': 'Kolektor Riwayat',
          'activeDuitKey': 'harian',
          'historyFilter': 'monthly',
        },
      };

      final result = await backupService.restoreBackup(jsonEncode(multiMonthBackup));
      expect(result.success, isTrue);
      expect(result.restoredTransactions, equals(3));

      // Verifikasi query rentang tanggal untuk tiap bulan secara presisi
      final m1Start = DateTime(dateMonth1.year, dateMonth1.month, 1);
      final m1End = DateTime(dateMonth1.year, dateMonth1.month + 1, 0);
      final txMonth1 = await txRepo.getTransactionsByDateRange(m1Start, m1End, ledger: 'daily');
      expect(txMonth1.length, equals(1));
      expect(txMonth1.first.note, equals('Gaji 2 Bulan Lalu'));

      final m2Start = DateTime(dateMonth2.year, dateMonth2.month, 1);
      final m2End = DateTime(dateMonth2.year, dateMonth2.month + 1, 0);
      final txMonth2 = await txRepo.getTransactionsByDateRange(m2Start, m2End, ledger: 'daily');
      expect(txMonth2.length, equals(1));
      expect(txMonth2.first.note, equals('Makan 1 Bulan Lalu'));

      // Total saldo terhitung tetap akurat: Saldo Awal (100k) + 3.000k - 150k - 25k = 2.925.000
      final dailyBalance = await txRepo.calculateLedgerBalance('daily');
      expect(dailyBalance, equals(2925000));
    });

    // 3. DUIT PENCAPAIAN: Buat Target -> Setor langsung mandiri tanpa mewajibkan transaksi di duit lain
    testWidgets('(Poin 3) Setor ke Duit Pencapaian langsung bisa digunakan tepat setelah target dibuat', (tester) async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          walletRepositoryProvider.overrideWithValue(walletRepo),
          categoryRepositoryProvider.overrideWithValue(categoryRepo),
          savingGoalRepositoryProvider.overrideWithValue(goalRepo),
          transactionRepositoryProvider.overrideWithValue(txRepo),
          preferencesServiceProvider.overrideWithValue(prefsService),
        ],
      );
      addTearDown(container.dispose);

      // Buat target baru
      final newGoalId = await goalRepo.insertSavingGoal(
        const SavingGoalItem(
          name: 'Beli Laptop Impian',
          targetAmount: 10000000,
          currentAmount: 0,
          walletId: 1,
          icon: 'laptop_chromebook_rounded',
        ),
      );
      expect(newGoalId, isPositive);

      // Tampilkan layar GoalsLedgerScreen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: GoalsLedgerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Beli Laptop Impian'), findsOneWidget);
      expect(find.text('0% tercapai'), findsOneWidget);

      // Ketuk tombol "Setor" pada kartu target
      await tester.tap(find.widgetWithText(ElevatedButton, 'Setor'));
      await tester.pumpAndSettle();

      // Modal bottom sheet setor terbuka
      expect(find.text('Setor ke Pencapaian'), findsOneWidget);
      expect(find.text('Target: Beli Laptop Impian'), findsOneWidget);

      // Masukkan nominal setoran 2.500.000 (mandiri tanpa centang potong akun lain)
      await tester.enterText(find.byType(TextField).first, '2500000');
      await tester.pumpAndSettle();

      // Tekan tombol "Konfirmasi Setoran"
      await tester.tap(find.text('Konfirmasi Setoran'));
      await tester.pumpAndSettle();

      // Verifikasi target bertambah saldonya dan persentasenya 25% tercapai
      final updatedGoal = await goalRepo.getSavingGoalById(newGoalId);
      expect(updatedGoal, isNotNull);
      expect(updatedGoal!.currentAmount, equals(2500000));

      expect(find.text('25% tercapai'), findsOneWidget);
      expect(find.text('Rp 2.500.000'), findsWidgets);
    });

    // 4. VERSI APLIKASI: pubspec.yaml, AboutText, dan BackupConstants sinkron
    test('(Poin 4) Versi aplikasi terpusat pada AboutText dan sinkron dengan BackupConstants', () {
      expect(AboutText.appVersion, isNotEmpty);
      expect(BackupConstants.currentAppVersion, equals(AboutText.appVersion));
      expect(BackupConstants.currentBackupVersion, equals(3));
    });
  });
}

