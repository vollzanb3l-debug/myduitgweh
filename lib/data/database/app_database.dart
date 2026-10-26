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
  int get schemaVersion => 3;

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
    },
  );

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
