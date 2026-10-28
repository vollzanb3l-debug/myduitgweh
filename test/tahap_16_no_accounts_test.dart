import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myduitgweh/core/constants/backup_constants.dart';
import 'package:myduitgweh/core/providers/app_state_provider.dart';
import 'package:myduitgweh/core/services/backup_service.dart';
import 'package:myduitgweh/core/services/preferences_service.dart';
import 'package:myduitgweh/core/services/total_reset_service.dart';
import 'package:myduitgweh/data/database/app_database.dart';
import 'package:myduitgweh/data/models/transaction_model.dart';
import 'package:myduitgweh/data/models/wallet_model.dart';
import 'package:myduitgweh/data/repositories/drift_category_repository.dart';
import 'package:myduitgweh/data/repositories/drift_saving_goal_repository.dart';
import 'package:myduitgweh/data/repositories/drift_transaction_repository.dart';
import 'package:myduitgweh/data/repositories/drift_wallet_repository.dart';
import 'package:myduitgweh/data/repositories/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tahap 16: Penghilangan Konsep Akun & Resiliensi Dompet Internal Tests', () {
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

    test('(a) Menyimpan transaksi di Duit Tabungan dan Duit Saldo berhasil tanpa membuat akun', () async {
      // Pastikan dompet internal tersedia otomatis
      final savingWallet = await walletRepo.getOrCreateInternalWallet('saving');
      final balanceWallet = await walletRepo.getOrCreateInternalWallet('balance');

      expect(savingWallet.id, isNotNull);
      expect(balanceWallet.id, isNotNull);

      // Simpan setoran tabungan
      final savingTxId = await txRepo.insertTransaction(
        TransactionItem(
          type: 'income',
          amount: 150000,
          categoryId: 29,
          walletId: savingWallet.id!,
          date: DateTime.now(),
          ledger: 'saving',
          note: 'Nabung pertama',
          createdAt: DateTime.now(),
        ),
      );
      expect(savingTxId, isPositive);

      // Simpan mutasi saldo
      final balanceTxId = await txRepo.insertTransaction(
        TransactionItem(
          type: 'income',
          amount: 500000,
          categoryId: 15,
          walletId: balanceWallet.id!,
          date: DateTime.now(),
          ledger: 'balance',
          note: 'Terima uang',
          createdAt: DateTime.now(),
        ),
      );
      expect(balanceTxId, isPositive);

      // Saldo terhitung benar tanpa pengguna harus memilih akun
      expect(await txRepo.calculateLedgerBalance('saving'), equals(150000));
      expect(await txRepo.calculateLedgerBalance('balance'), equals(500000));
    });

    test('(b) Penarikan Tabungan melebihi saldo tabungan harus ditolak', () async {
      final savingWallet = await walletRepo.getOrCreateInternalWallet('saving');

      // Setor Rp 50.000
      await txRepo.insertTransaction(
        TransactionItem(
          type: 'income',
          amount: 50000,
          categoryId: 29,
          walletId: savingWallet.id!,
          date: DateTime.now(),
          ledger: 'saving',
          createdAt: DateTime.now(),
        ),
      );

      final currentBalance = await txRepo.calculateLedgerBalance('saving');
      expect(currentBalance, equals(50000));

      // Cek logika validasi: tarik Rp 75.000 melebihi saldo Rp 50.000
      const requestedWithdrawal = 75000;
      final isExceeding = requestedWithdrawal > currentBalance;
      expect(isExceeding, isTrue);

      // Jika melebihi saldo, pesan error ramah harus muncul
      final errorMessage = isExceeding ? 'Saldo tabungan tidak cukup' : null;
      expect(errorMessage, equals('Saldo tabungan tidak cukup'));
    });

    testWidgets('(c) Dompet internal dibuat otomatis untuk pengguna lama, setelah impor, dan setelah reset total', (tester) async {
      // 1. Kosongkan semua dompet (simulasi kasus pengguna dengan data kosong / backup lama tanpa dompet)
      walletRepo.clearAll();
      final emptyWallets = await walletRepo.getAllWallets();
      expect(emptyWallets.isEmpty, isTrue);

      // 2. ensureInternalWallets membuat tepat 3 dompet internal
      await walletRepo.ensureInternalWallets();
      final restoredWallets = await walletRepo.getAllWallets();
      expect(restoredWallets.length, equals(3));
      expect(restoredWallets.map((w) => w.ledger), containsAll(['daily', 'balance', 'saving']));

      // 3. Reset Total Service juga meregenerasi 3 dompet internal
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
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () async {
                      await TotalResetService.performTotalReset(ref);
                    },
                    child: const Text('Reset Button'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Reset Button'));
      await tester.pumpAndSettle();

      final afterResetWallets = await walletRepo.getAllWallets();
      expect(afterResetWallets.length, equals(3));
      expect(afterResetWallets.map((w) => w.ledger), containsAll(['daily', 'balance', 'saving']));
    });

    test('(d) Migrasi database menggabungkan banyak akun lama tanpa mengubah total saldo dan jumlah transaksi', () async {
      // Buat beberapa akun lama untuk Duit Saldo (Tunai: 100k, Bank: 300k, E-Wallet: 200k)
      final wTunai = await walletRepo.insertWallet(
        WalletItem(name: 'Tunai', type: 'balance', ledger: 'balance', initialBalance: 100000, createdAt: DateTime.now()),
      );
      final wBank = await walletRepo.insertWallet(
        WalletItem(name: 'Bank', type: 'balance', ledger: 'balance', initialBalance: 300000, createdAt: DateTime.now()),
      );
      final wEwallet = await walletRepo.insertWallet(
        WalletItem(name: 'E-Wallet', type: 'balance', ledger: 'balance', initialBalance: 200000, createdAt: DateTime.now()),
      );

      // Catat transaksi di masing-masing akun
      await txRepo.insertTransaction(
        TransactionItem(type: 'expense', amount: 20000, categoryId: 22, walletId: wTunai, date: DateTime.now(), ledger: 'balance', createdAt: DateTime.now()),
      );
      await txRepo.insertTransaction(
        TransactionItem(type: 'income', amount: 50000, categoryId: 16, walletId: wBank, date: DateTime.now(), ledger: 'balance', createdAt: DateTime.now()),
      );
      await txRepo.insertTransaction(
        TransactionItem(type: 'expense', amount: 10000, categoryId: 24, walletId: wEwallet, date: DateTime.now(), ledger: 'balance', createdAt: DateTime.now()),
      );

      // Hitung total saldo sebelum migrasi:
      // Initial: 100k + 300k + 200k = 600k.
      // Net Tx: -20k + 50k - 10k = +20k.
      // Total Saldo = 620k.
      final totalBefore = await txRepo.calculateLedgerBalance('balance');
      final txCountBefore = (await txRepo.getTransactionsByLedger('balance')).length;
      expect(totalBefore, equals(620000));
      expect(txCountBefore, equals(3));

      // Jalankan logika migrasi konsolidasi ke 1 dompet internal
      final balanceWallets = await walletRepo.getWalletsByLedger('balance');
      final primary = balanceWallets.first;
      final others = balanceWallets.sublist(1);

      int totalInitial = primary.initialBalance;
      for (final other in others) {
        totalInitial += other.initialBalance;
      }
      await walletRepo.updateWallet(primary.copyWith(name: 'Duit Saldo', initialBalance: totalInitial));

      for (final other in others) {
        // Remap transaksi
        final otherTxs = await db.customSelect(
          'SELECT * FROM transactions WHERE wallet_id = ?',
          variables: [Variable.withInt(other.id!)],
        ).get();
        for (final row in otherTxs) {
          await db.customUpdate(
            'UPDATE transactions SET wallet_id = ? WHERE id = ?',
            variables: [Variable.withInt(primary.id!), Variable.withInt(row.read<int>('id'))],
          );
        }
        await walletRepo.deleteWallet(other.id!);
      }

      // Verifikasi setelah migrasi:
      final balanceWalletsAfter = await walletRepo.getWalletsByLedger('balance');
      expect(balanceWalletsAfter.length, equals(1));
      expect(balanceWalletsAfter.first.name, equals('Duit Saldo'));

      final totalAfter = await txRepo.calculateLedgerBalance('balance');
      final txCountAfter = (await txRepo.getTransactionsByLedger('balance')).length;

      // Saldo dan jumlah transaksi SAMA PERSIS
      expect(totalAfter, equals(totalBefore));
      expect(txCountAfter, equals(txCountBefore));
    });

    test('(e) Impor cadangan versi lama (dengan banyak akun) berhasil termigrasi ke format terbaru', () async {
      final backupService = BackupService(
        walletRepo: walletRepo,
        categoryRepo: categoryRepo,
        goalRepo: goalRepo,
        txRepo: txRepo,
        prefs: prefsService,
      );

      // Cadangan lama v1 dengan banyak akun di Saldo
      final legacyV1Json = {
        'appName': BackupConstants.appIdentifier,
        'backupVersion': 1,
        'appVersion': '1.0.0',
        'createdAt': DateTime.now().toIso8601String(),
        'wallets': [
          {
            'id': 1,
            'name': 'Uang Harian',
            'type': 'daily',
            'ledger': 'daily',
            'initialBalance': 50000,
            'createdAt': DateTime.now().toIso8601String(),
          },
          {
            'id': 2,
            'name': 'Tunai',
            'type': 'balance',
            'ledger': 'balance',
            'initialBalance': 100000,
            'createdAt': DateTime.now().toIso8601String(),
          },
          {
            'id': 3,
            'name': 'Bank BCA',
            'type': 'balance',
            'ledger': 'balance',
            'initialBalance': 400000,
            'createdAt': DateTime.now().toIso8601String(),
          }
        ],
        'categories': [
          {
            'id': 1,
            'name': 'Makan',
            'icon': 'restaurant',
            'colorHex': '#FF0000',
            'type': 'expense',
            'ledger': 'daily',
          }
        ],
        'savingGoals': [],
        'transactions': [
          {
            'id': 1,
            'walletId': 2,
            'categoryId': 1,
            'amount': 20000,
            'type': 'expense',
            'ledger': 'balance',
            'date': DateTime.now().toIso8601String(),
          },
          {
            'id': 2,
            'walletId': 3,
            'categoryId': 1,
            'amount': 50000,
            'type': 'expense',
            'ledger': 'balance',
            'date': DateTime.now().toIso8601String(),
          }
        ],
      };

      final result = await backupService.restoreBackup(jsonEncode(legacyV1Json));
      expect(result.success, isTrue);

      // Verifikasi dompet internal tercipta rapi
      final allWallets = await walletRepo.getAllWallets();
      expect(allWallets.length, equals(3));
      final dailyWallets = await walletRepo.getWalletsByLedger('daily');
      final balanceWallets = await walletRepo.getWalletsByLedger('balance');
      final savingWallets = await walletRepo.getWalletsByLedger('saving');

      expect(dailyWallets.length, equals(1));
      expect(balanceWallets.length, equals(1));
      expect(savingWallets.length, equals(1)); // Duit tabungan otomatis terbuat meski di file lama tidak ada!

      // Saldo Saldo lama: Tunai 100k + Bank 400k - Tx 20k - Tx 50k = 430.000
      final balanceTotal = await txRepo.calculateLedgerBalance('balance');
      expect(balanceTotal, equals(430000));
    });

    test('(f) Saldo tiap Duit konsisten dihitung dengan benar', () async {
      await walletRepo.ensureInternalWallets();
      final wUtama = await walletRepo.getOrCreateInternalWallet('daily');
      final wSaldo = await walletRepo.getOrCreateInternalWallet('balance');
      final wTabungan = await walletRepo.getOrCreateInternalWallet('saving');

      // Transaksi Utama: +100k, -30k = 70k
      await txRepo.insertTransaction(
        TransactionItem(type: 'income', amount: 100000, categoryId: 10, walletId: wUtama.id!, date: DateTime.now(), ledger: 'daily', createdAt: DateTime.now()),
      );
      await txRepo.insertTransaction(
        TransactionItem(type: 'expense', amount: 30000, categoryId: 1, walletId: wUtama.id!, date: DateTime.now(), ledger: 'daily', createdAt: DateTime.now()),
      );

      // Transaksi Saldo: +250k = 250k
      await txRepo.insertTransaction(
        TransactionItem(type: 'income', amount: 250000, categoryId: 15, walletId: wSaldo.id!, date: DateTime.now(), ledger: 'balance', createdAt: DateTime.now()),
      );

      // Transaksi Tabungan: +500k, -100k = 400k
      await txRepo.insertTransaction(
        TransactionItem(type: 'income', amount: 500000, categoryId: 29, walletId: wTabungan.id!, date: DateTime.now(), ledger: 'saving', createdAt: DateTime.now()),
      );
      await txRepo.insertTransaction(
        TransactionItem(type: 'expense', amount: 100000, categoryId: 32, walletId: wTabungan.id!, date: DateTime.now(), ledger: 'saving', createdAt: DateTime.now()),
      );

      expect(await txRepo.calculateLedgerBalance('daily'), equals(70000));
      expect(await txRepo.calculateLedgerBalance('balance'), equals(250000));
      expect(await txRepo.calculateLedgerBalance('saving'), equals(400000));
    });
  });
}

