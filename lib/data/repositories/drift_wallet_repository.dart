import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/initial_data.dart';
import '../models/wallet_model.dart';
import 'wallet_repository.dart';

class DriftWalletRepository implements WalletRepository {
  final AppDatabase db;

  DriftWalletRepository(this.db);

  WalletItem _toItem(Wallet w) {
    return WalletItem(
      id: w.id,
      name: w.name,
      type: w.type,
      ledger: w.ledger,
      initialBalance: w.initialBalance,
      createdAt: w.createdAt,
    );
  }

  @override
  Future<int> insertWallet(WalletItem wallet) async {
    return await db.into(db.wallets).insert(
          WalletsCompanion(
            id: wallet.id != null ? Value(wallet.id!) : const Value.absent(),
            name: Value(wallet.name),
            type: Value(wallet.type),
            ledger: Value(wallet.ledger),
            initialBalance: Value(wallet.initialBalance),
            createdAt: Value(wallet.createdAt),
          ),
        );
  }

  @override
  Future<bool> updateWallet(WalletItem wallet) async {
    if (wallet.id == null) return false;
    final count = await (db.update(db.wallets)
          ..where((t) => t.id.equals(wallet.id!)))
        .write(
      WalletsCompanion(
        name: Value(wallet.name),
        type: Value(wallet.type),
        ledger: Value(wallet.ledger),
        initialBalance: Value(wallet.initialBalance),
      ),
    );
    return count > 0;
  }

  @override
  Future<int> deleteWallet(int id) async {
    return await (db.delete(db.wallets)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<WalletItem?> getWalletById(int id) async {
    final row = await (db.select(db.wallets)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _toItem(row) : null;
  }

  @override
  Future<List<WalletItem>> getAllWallets() async {
    final rows = await db.select(db.wallets).get();
    return rows.map(_toItem).toList();
  }

  @override
  Stream<List<WalletItem>> watchAllWallets() {
    return db
        .select(db.wallets)
        .watch()
        .map((rows) => rows.map(_toItem).toList());
  }

  @override
  Future<List<WalletItem>> getWalletsByLedger(String ledger) async {
    final rows = await (db.select(db.wallets)
          ..where((t) => t.ledger.equals(ledger)))
        .get();
    return rows.map(_toItem).toList();
  }

  @override
  Stream<List<WalletItem>> watchWalletsByLedger(String ledger) {
    return (db.select(db.wallets)..where((t) => t.ledger.equals(ledger)))
        .watch()
        .map((rows) => rows.map(_toItem).toList());
  }

  @override
  void clearAll() {
    db.delete(db.wallets).go();
  }

  @override
  void resetToInitial() async {
    await db.delete(db.wallets).go();
    for (final w in InitialData.defaultWallets) {
      await insertWallet(w);
    }
  }
}
