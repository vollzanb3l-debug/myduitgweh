import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';
import 'initial_data.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Wallets, Categories, Transactions, SavingGoals])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _seedInitialData();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Migrasi Tahap 10: reset dan re-create database untuk 4 jenis catatan
        for (final table in allTables) {
          await m.deleteTable(table.actualTableName);
        }
        await m.createAll();
        await _seedInitialData();
      }
      if (from < 3) {
        // Tahap 13: Kosongkan data contoh pencapaian lama jika ada
        await delete(savingGoals).go();
      }
      if (from < 4) {
        // Tahap 14: Ganti nama merek menjadi nama generik di database
        await customStatement(
          "UPDATE wallets SET name = 'Bank' WHERE name LIKE '%BCA%' OR name LIKE '%Mandiri%' OR name LIKE '%BRI%' OR name LIKE '%BNI%'",
        );
        await customStatement(
          "UPDATE wallets SET name = 'E-Wallet' WHERE name LIKE '%GoPay%' OR name LIKE '%OVO%' OR name LIKE '%Dana%'",
        );
      }
      if (from < 5) {
        // Tahap 15: Tambah kolom currentAmount dan note di savingGoals, transferPartnerId di transactions
        await m.addColumn(savingGoals, savingGoals.currentAmount);
        await m.addColumn(savingGoals, savingGoals.note);
        await m.addColumn(transactions, transactions.transferPartnerId);

        // Migrasi nama dompet bawaan "Uang Harian" -> "Uang Utama" jika belum diubah
        await customStatement(
          "UPDATE wallets SET name = 'Uang Utama' WHERE name = 'Uang Harian'",
        );
      }
    },
  );

  Future<void> resetAll() async {
    await delete(transactions).go();
    await delete(savingGoals).go();
    await delete(categories).go();
    await delete(wallets).go();
    await _seedInitialData();
  }

  Future<void> _seedInitialData() async {
    // 1. Masukkan dompet default
    for (final wallet in InitialData.defaultWallets) {
      await into(wallets).insert(
        WalletsCompanion.insert(
          id: Value(wallet.id!),
          name: wallet.name,
          type: wallet.type,
          initialBalance: Value(wallet.initialBalance),
          createdAt: Value(wallet.createdAt),
        ),
      );
    }

    // 2. Masukkan kategori default
    for (final cat in InitialData.defaultCategories) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          id: Value(cat.id!),
          name: cat.name,
          icon: cat.icon,
          colorHex: cat.colorHex,
          type: cat.type,
        ),
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'myduitgweh.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
