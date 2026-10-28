import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/transaction_model.dart';
import 'category_repository.dart';
import 'saving_goal_repository.dart';
import 'transaction_repository.dart';
import 'wallet_repository.dart';

class DriftTransactionRepository implements TransactionRepository {
  final AppDatabase db;
  final WalletRepository? _walletRepository;
  final SavingGoalRepository? _savingGoalRepository;
  final CategoryRepository? _categoryRepository;

  DriftTransactionRepository(
    this.db, {
    WalletRepository? walletRepository,
    SavingGoalRepository? savingGoalRepository,
    CategoryRepository? categoryRepository,
  })  : _walletRepository = walletRepository,
        _savingGoalRepository = savingGoalRepository,
        _categoryRepository = categoryRepository;

  TransactionItem _toItem(Transaction t) {
    return TransactionItem(
      id: t.id,
      type: t.type,
      amount: t.amount,
      categoryId: t.categoryId,
      walletId: t.walletId,
      date: t.date,
      note: t.note,
      ledger: t.ledger,
      goalId: t.goalId,
      transferPartnerId: t.transferPartnerId,
      createdAt: t.createdAt,
    );
  }

  @override
  Future<int> insertTransaction(TransactionItem transaction) async {
    return await db.into(db.transactions).insert(
          TransactionsCompanion(
            id: transaction.id != null
                ? Value(transaction.id!)
                : const Value.absent(),
            type: Value(transaction.type),
            amount: Value(transaction.amount),
            categoryId: Value(transaction.categoryId),
            walletId: Value(transaction.walletId),
            date: Value(transaction.date),
            note: Value(transaction.note),
            ledger: Value(transaction.ledger),
            goalId: Value(transaction.goalId),
            transferPartnerId: Value(transaction.transferPartnerId),
            createdAt: Value(transaction.createdAt),
          ),
        );
  }

  @override
  Future<bool> updateTransaction(TransactionItem transaction) async {
    if (transaction.id == null) return false;
    final count = await (db.update(db.transactions)
          ..where((t) => t.id.equals(transaction.id!)))
        .write(
      TransactionsCompanion(
        type: Value(transaction.type),
        amount: Value(transaction.amount),
        categoryId: Value(transaction.categoryId),
        walletId: Value(transaction.walletId),
        date: Value(transaction.date),
        note: Value(transaction.note),
        ledger: Value(transaction.ledger),
        goalId: Value(transaction.goalId),
        transferPartnerId: Value(transaction.transferPartnerId),
      ),
    );
    return count > 0;
  }

  @override
  Future<int> deleteTransaction(int id) async {
    return await db.transaction(() async {
      final tx = await getTransactionById(id);
      if (tx == null) return 0;

      int deletedCount = 0;

      // 1. Cek apakah ada transferPartnerId terhubung
      if (tx.transferPartnerId != null) {
        final partnerId = tx.transferPartnerId!;
        deletedCount += await (db.delete(db.transactions)
              ..where((t) => t.id.equals(partnerId)))
            .go();
      } else {
        // Fallback untuk transfer lama: cocokkan waktu, nominal, dan note transfer
        final note = tx.note ?? '';
        if (note.startsWith('Transfer ke ') || note.startsWith('Transfer dari ')) {
          final isOut = tx.type == 'expense';
          final targetType = isOut ? 'income' : 'expense';
          final partner = await (db.select(db.transactions)
                ..where((t) =>
                    t.id.isNotValue(id) &
                    t.type.equals(targetType) &
                    t.amount.equals(tx.amount) &
                    t.date.equals(tx.date)))
              .getSingleOrNull();

          if (partner != null) {
            deletedCount += await (db.delete(db.transactions)
                  ..where((t) => t.id.equals(partner.id)))
                .go();
          }
        }
      }

      // 2. Jika terkait target impian (goal), sesuaikan progress target
      if (tx.goalId != null && _savingGoalRepository != null) {
        final goal = await _savingGoalRepository.getSavingGoalById(tx.goalId!);
        if (goal != null) {
          if (tx.type == 'income' || tx.ledger == 'goal') {
            final newAmount = (goal.currentAmount - tx.amount).clamp(0, goal.targetAmount * 2);
            await _savingGoalRepository.updateSavingGoal(
              goal.copyWith(currentAmount: newAmount),
            );
          }
        }
      }

      // 3. Hapus transaksi utama
      deletedCount += await (db.delete(db.transactions)
            ..where((t) => t.id.equals(id)))
          .go();

      return deletedCount;
    });
  }

  @override
  Future<TransactionItem?> getTransactionById(int id) async {
    final row = await (db.select(db.transactions)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _toItem(row) : null;
  }

  @override
  Future<List<TransactionItem>> getAllTransactions() async {
    final query = db.select(db.transactions)
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    final rows = await query.get();
    return rows.map(_toItem).toList();
  }

  @override
  Stream<List<TransactionItem>> watchAllTransactions() {
    final query = db.select(db.transactions)
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    return query.watch().map((rows) => rows.map(_toItem).toList());
  }

  @override
  Future<List<TransactionItem>> getTransactionsByLedger(String? ledger) async {
    final query = db.select(db.transactions)
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    if (ledger != null && ledger != 'all') {
      query.where((t) => t.ledger.equals(ledger));
    }
    final rows = await query.get();
    return rows.map(_toItem).toList();
  }

  @override
  Stream<List<TransactionItem>> watchTransactionsByLedger(String? ledger) {
    final query = db.select(db.transactions)
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    if (ledger != null && ledger != 'all') {
      query.where((t) => t.ledger.equals(ledger));
    }
    return query.watch().map((rows) => rows.map(_toItem).toList());
  }

  @override
  Future<List<TransactionItem>> getTransactionsByDateRange(
    DateTime start,
    DateTime end, {
    String? ledger,
  }) async {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    final query = db.select(db.transactions)
      ..where((t) => t.date.isBiggerOrEqualValue(s) & t.date.isSmallerOrEqualValue(e))
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    if (ledger != null && ledger != 'all') {
      query.where((t) => t.ledger.equals(ledger));
    }
    final rows = await query.get();
    return rows.map(_toItem).toList();
  }

  @override
  Stream<List<TransactionItem>> watchTransactionsByDateRange(
    DateTime start,
    DateTime end, {
    String? ledger,
  }) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    final query = db.select(db.transactions)
      ..where((t) => t.date.isBiggerOrEqualValue(s) & t.date.isSmallerOrEqualValue(e))
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    if (ledger != null && ledger != 'all') {
      query.where((t) => t.ledger.equals(ledger));
    }
    return query.watch().map((rows) => rows.map(_toItem).toList());
  }

  @override
  Future<int> getTotalIncomeByDateRange(
    DateTime start,
    DateTime end, {
    String? ledger,
  }) async {
    final list = await getTransactionsByDateRange(start, end, ledger: ledger);
    int total = 0;
    for (final t in list) {
      if (t.type == 'income') total += t.amount;
    }
    return total;
  }

  @override
  Future<int> getTotalExpenseByDateRange(
    DateTime start,
    DateTime end, {
    String? ledger,
  }) async {
    final list = await getTransactionsByDateRange(start, end, ledger: ledger);
    int total = 0;
    for (final t in list) {
      if (t.type == 'expense') total += t.amount;
    }
    return total;
  }

  @override
  Future<Map<int, int>> getTotalByCategory(
    DateTime start,
    DateTime end, {
    String type = 'expense',
    String? ledger,
  }) async {
    final list = await getTransactionsByDateRange(start, end, ledger: ledger);
    final Map<int, int> result = {};
    for (final t in list) {
      if (t.type == type) {
        result[t.categoryId] = (result[t.categoryId] ?? 0) + t.amount;
      }
    }
    return result;
  }

  @override
  Future<int> calculateWalletBalance(int walletId) async {
    int initial = 0;
    if (_walletRepository != null) {
      final w = await _walletRepository.getWalletById(walletId);
      if (w != null) initial = w.initialBalance;
    }
    final rows = await (db.select(db.transactions)
          ..where((t) => t.walletId.equals(walletId)))
        .get();

    int balance = initial;
    for (final r in rows) {
      if (r.type == 'income') {
        balance += r.amount;
      } else if (r.type == 'expense') {
        balance -= r.amount;
      }
    }
    return balance;
  }

  @override
  Stream<int> watchWalletBalance(int walletId) {
    return (db.select(db.transactions)..where((t) => t.walletId.equals(walletId)))
        .watch()
        .asyncMap((_) => calculateWalletBalance(walletId));
  }

  @override
  Future<void> transferBetweenWallets({
    required int sourceWalletId,
    required int targetWalletId,
    required int amount,
    String? note,
    DateTime? date,
  }) async {
    final transferDate = date ?? DateTime.now();
    String sourceName = 'Dompet #$sourceWalletId';
    String targetName = 'Dompet #$targetWalletId';
    String sourceLedger = 'balance';
    String targetLedger = 'balance';

    if (_walletRepository != null) {
      final source = await _walletRepository.getWalletById(sourceWalletId);
      final target = await _walletRepository.getWalletById(targetWalletId);
      if (source != null) {
        sourceName = source.name;
        sourceLedger = source.ledger;
      }
      if (target != null) {
        targetName = target.name;
        targetLedger = target.ledger;
      }
    }

    final outNote = note != null && note.isNotEmpty
        ? 'Transfer ke $targetName • $note'
        : 'Transfer ke $targetName';
    final inNote = note != null && note.isNotEmpty
        ? 'Transfer dari $sourceName • $note'
        : 'Transfer dari $sourceName';

    await db.transaction(() async {
      // 1. Catat transaksi keluar
      final outId = await insertTransaction(
        TransactionItem(
          type: 'expense',
          amount: amount,
          categoryId: 20, // Transfer Keluar / Lainnya
          walletId: sourceWalletId,
          date: transferDate,
          ledger: sourceLedger,
          note: outNote,
          createdAt: DateTime.now(),
        ),
      );

      // 2. Catat transaksi masuk (merujuk ke outId)
      final inId = await insertTransaction(
        TransactionItem(
          type: 'income',
          amount: amount,
          categoryId: 16, // Transfer Masuk / Lainnya
          walletId: targetWalletId,
          date: transferDate,
          ledger: targetLedger,
          note: inNote,
          transferPartnerId: outId,
          createdAt: DateTime.now(),
        ),
      );

      // 3. Tautkan partner pada transaksi keluar
      await (db.update(db.transactions)..where((t) => t.id.equals(outId))).write(
        TransactionsCompanion(transferPartnerId: Value(inId)),
      );
    });
  }

  @override
  Future<void> depositToGoal({
    required int goalId,
    required int amount,
    int? sourceWalletId,
    String? note,
    DateTime? date,
  }) async {
    final txDate = date ?? DateTime.now();

    await db.transaction(() async {
      // 1. Tambah tabungan ke target impian
      if (_savingGoalRepository != null) {
        await _savingGoalRepository.addSavings(
          savingGoalId: goalId,
          amount: amount,
        );
      }

      String goalName = 'Target #$goalId';
      int goalWalletId = 5;
      if (_savingGoalRepository != null) {
        final goal = await _savingGoalRepository.getSavingGoalById(goalId);
        if (goal != null) {
          goalName = goal.name;
          goalWalletId = goal.walletId;
        }
      }

      int? outTxId;
      // 2. Jika ada dompet sumber (mengurangi dari catatan lain)
      if (sourceWalletId != null) {
        String sourceLedger = 'daily';
        if (_walletRepository != null) {
          final w = await _walletRepository.getWalletById(sourceWalletId);
          if (w != null) sourceLedger = w.ledger;
        }

        outTxId = await insertTransaction(
          TransactionItem(
            type: 'expense',
            amount: amount,
            categoryId: 9, // Lainnya
            walletId: sourceWalletId,
            date: txDate,
            ledger: sourceLedger,
            goalId: goalId,
            note: note != null && note.isNotEmpty
                ? 'Setor impian: $goalName • $note'
                : 'Setor impian: $goalName',
            createdAt: DateTime.now(),
          ),
        );
      }

      // 3. Catat pemasukan di catatan target impian
      final inTxId = await insertTransaction(
        TransactionItem(
          type: 'income',
          amount: amount,
          categoryId: 16, // Tabungan / Masuk
          walletId: goalWalletId,
          date: txDate,
          ledger: 'goal',
          goalId: goalId,
          transferPartnerId: outTxId,
          note: note != null && note.isNotEmpty
              ? 'Menabung target: $goalName • $note'
              : 'Menabung target: $goalName',
          createdAt: DateTime.now(),
        ),
      );

      if (outTxId != null) {
        await (db.update(db.transactions)..where((t) => t.id.equals(outTxId!))).write(
          TransactionsCompanion(transferPartnerId: Value(inTxId)),
        );
      }
    });
  }

  Future<int> _getAdjustmentCategoryId(String name, String type, String ledger) async {
    if (_categoryRepository != null) {
      try {
        final all = await _categoryRepository.getAllCategories();
        for (final c in all) {
          if (c.name.toLowerCase() == name.toLowerCase() && c.type == type) {
            return c.id ?? 1;
          }
        }
      } catch (_) {}
    }
    if (name == 'Koreksi Saldo') return 25;
    if (name == 'Tambah Saldo') return 26;
    if (name == 'Reset Saldo') return 27;
    return type == 'income' ? 16 : 20;
  }

  @override
  Future<int> addBalance({
    required int walletId,
    required int amount,
    String? note,
    DateTime? date,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Nominal tambah saldo harus lebih dari 0');
    }

    String ledger = 'daily';
    if (_walletRepository != null) {
      final w = await _walletRepository.getWalletById(walletId);
      if (w != null) ledger = w.ledger;
    }

    final catId = await _getAdjustmentCategoryId('Tambah Saldo', 'income', ledger);
    final tx = TransactionItem(
      type: 'income',
      amount: amount,
      categoryId: catId,
      walletId: walletId,
      date: date ?? DateTime.now(),
      ledger: ledger,
      note: (note != null && note.isNotEmpty) ? note : 'Tambah Saldo',
      createdAt: DateTime.now(),
    );

    return await insertTransaction(tx);
  }

  @override
  Future<int?> correctBalance({
    required int walletId,
    required int actualBalance,
    String? note,
    DateTime? date,
  }) async {
    final currentBalance = await calculateWalletBalance(walletId);
    final diff = actualBalance - currentBalance;
    if (diff == 0) return null;

    String ledger = 'daily';
    if (_walletRepository != null) {
      final w = await _walletRepository.getWalletById(walletId);
      if (w != null) ledger = w.ledger;
    }

    final type = diff > 0 ? 'income' : 'expense';
    final catId = await _getAdjustmentCategoryId('Penyesuaian Saldo', type, ledger);
    final tx = TransactionItem(
      type: type,
      amount: diff.abs(),
      categoryId: catId,
      walletId: walletId,
      date: date ?? DateTime.now(),
      ledger: ledger,
      note: (note != null && note.isNotEmpty) ? note : 'Penyesuaian Saldo',
      createdAt: DateTime.now(),
    );

    return await insertTransaction(tx);
  }

  @override
  Future<int> calculateLedgerBalance(String ledger) async {
    if (ledger == 'goal') {
      if (_savingGoalRepository != null) {
        final goals = await _savingGoalRepository.getAllSavingGoals();
        return goals.fold<int>(0, (sum, g) => sum + g.currentAmount);
      }
      return 0;
    }

    int initialSum = 0;
    if (_walletRepository != null) {
      final wallets = await _walletRepository.getWalletsByLedger(ledger);
      for (final w in wallets) {
        initialSum += w.initialBalance;
      }
    }

    final rows = await (db.select(db.transactions)
          ..where((t) => t.ledger.equals(ledger)))
        .get();

    int totalIncome = 0;
    int totalExpense = 0;
    for (final r in rows) {
      if (r.type == 'income') {
        totalIncome += r.amount;
      } else if (r.type == 'expense') {
        totalExpense += r.amount;
      }
    }

    return initialSum + totalIncome - totalExpense;
  }

  @override
  Stream<int> watchLedgerBalance(String ledger) {
    return watchTransactionsByLedger(ledger).asyncMap((_) => calculateLedgerBalance(ledger));
  }

  @override
  Future<bool> hasTransactionsForWallet(int walletId) async {
    final row = await (db.select(db.transactions)
          ..where((t) => t.walletId.equals(walletId))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  @override
  Future<int?> resetBalanceWithHistory({
    required int walletId,
    String? note,
  }) async {
    return correctBalance(
      walletId: walletId,
      actualBalance: 0,
      note: note ?? 'Reset saldo ke Rp 0 (riwayat tersimpan)',
    );
  }

  @override
  Future<void> resetLedgerAndWipeHistory({
    required String ledger,
  }) async {
    await db.transaction(() async {
      // 1. Hapus transaksi pada ledger ini
      await (db.delete(db.transactions)..where((t) => t.ledger.equals(ledger))).go();

      // 2. Setel initialBalance dompet ke 0
      if (_walletRepository != null) {
        final wallets = await _walletRepository.getWalletsByLedger(ledger);
        for (final w in wallets) {
          if (w.id != null) {
            await _walletRepository.updateWallet(w.copyWith(initialBalance: 0));
          }
        }
      }
    });
  }

  @override
  void clearAll() {
    db.delete(db.transactions).go();
  }
}
