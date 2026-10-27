import 'dart:async';

import '../models/transaction_model.dart';
import 'saving_goal_repository.dart';
import 'wallet_repository.dart';

abstract class TransactionRepository {
  Future<int> insertTransaction(TransactionItem transaction);
  Future<bool> updateTransaction(TransactionItem transaction);
  Future<int> deleteTransaction(int id);
  Future<TransactionItem?> getTransactionById(int id);
  Future<List<TransactionItem>> getAllTransactions();
  Stream<List<TransactionItem>> watchAllTransactions();

  /// Mengambil transaksi berdasarkan jenis catatan (opsional, null = semua)
  Future<List<TransactionItem>> getTransactionsByLedger(String? ledger);

  /// Stream transaksi berdasarkan jenis catatan (opsional, null = semua)
  Stream<List<TransactionItem>> watchTransactionsByLedger(String? ledger);

  /// Mengambil transaksi dalam rentang tanggal tertentu (inklusif, opsional ledger)
  Future<List<TransactionItem>> getTransactionsByDateRange(
    DateTime start,
    DateTime end, {
    String? ledger,
  });

  /// Stream transaksi dalam rentang tanggal tertentu (opsional ledger)
  Stream<List<TransactionItem>> watchTransactionsByDateRange(
    DateTime start,
    DateTime end, {
    String? ledger,
  });

  /// Menghitung total pemasukan dalam rentang tanggal (opsional ledger)
  Future<int> getTotalIncomeByDateRange(
    DateTime start,
    DateTime end, {
    String? ledger,
  });

  /// Menghitung total pengeluaran dalam rentang tanggal (opsional ledger)
  Future<int> getTotalExpenseByDateRange(
    DateTime start,
    DateTime end, {
    String? ledger,
  });

  /// Menghitung total per kategori dalam rentang tanggal (opsional ledger)
  /// Mengembalikan `Map<int, int>` (categoryId -> totalNominal)
  Future<Map<int, int>> getTotalByCategory(
    DateTime start,
    DateTime end, {
    String type = 'expense',
    String? ledger,
  });

  /// Menghitung saldo dompet spesifik
  Future<int> calculateWalletBalance(int walletId);

  /// Stream saldo dompet yang terupdate otomatis saat ada perubahan transaksi
  Stream<int> watchWalletBalance(int walletId);

  /// Menghitung total saldo untuk satu jenis catatan (daily, balance, saving, goal)
  Future<int> calculateLedgerBalance(String ledger);

  /// Stream saldo untuk satu jenis catatan
  Stream<int> watchLedgerBalance(String ledger);

  /// Mengecek apakah dompet memiliki riwayat transaksi
  Future<bool> hasTransactionsForWallet(int walletId);

  /// Melakukan transfer antar dompet (menyimpan 2 transaksi yang saling terhubung)
  Future<void> transferBetweenWallets({
    required int sourceWalletId,
    required int targetWalletId,
    required int amount,
    String? note,
    DateTime? date,
  });

  /// Setoran ke catatan pencapaian (target impian)
  /// Dapat memotong dari dompet lain jika `sourceWalletId` diisi, atau berdiri sendiri jika null.
  Future<void> depositToGoal({
    required int goalId,
    required int amount,
    int? sourceWalletId,
    String? note,
    DateTime? date,
  });

  /// Tambah Saldo: disimpan sebagai transaksi pemasukan kategori "Tambah Saldo"
  Future<int> addBalance({
    required int walletId,
    required int amount,
    String? note,
    DateTime? date,
  });

  /// Koreksi Saldo: menghitung selisih dan membuat transaksi penyesuaian
  Future<int?> correctBalance({
    required int walletId,
    required int actualBalance,
    String? note,
    DateTime? date,
  });

  /// Reset Saldo Opsi A: reset ke Rp 0 dan simpan riwayat lama (membuat transaksi penyesuaian)
  Future<int?> resetBalanceWithHistory({
    required int walletId,
    String? note,
  });

  /// Reset Saldo Opsi B: menghapus semua riwayat transaksi duit/dompet dan mengembalikan saldo awal ke 0
  Future<void> resetLedgerAndWipeHistory({
    required String ledger,
  });
  void clearAll();
}

class InMemoryTransactionRepository implements TransactionRepository {
  final Map<int, TransactionItem> _transactions = {};
  final StreamController<List<TransactionItem>> _controller =
      StreamController<List<TransactionItem>>.broadcast();
  final WalletRepository? _walletRepository;
  final SavingGoalRepository? _savingGoalRepository;
  final dynamic _categoryRepository;
  StreamSubscription? _walletSubscription;
  StreamSubscription? _goalSubscription;
  int _nextId = 1;

  InMemoryTransactionRepository({
    WalletRepository? walletRepository,
    SavingGoalRepository? savingGoalRepository,
    dynamic categoryRepository,
  })  : _walletRepository = walletRepository,
        _savingGoalRepository = savingGoalRepository,
        _categoryRepository = categoryRepository {
    if (_walletRepository != null) {
      _walletSubscription = _walletRepository.watchAllWallets().listen((_) {
        _notify();
      });
    }
    if (_savingGoalRepository != null) {
      _goalSubscription =
          _savingGoalRepository.watchAllSavingGoals().listen((_) {
        _notify();
      });
    }
  }

  void _notify() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_transactions.values));
    }
  }

  bool _isWithinRange(DateTime date, DateTime start, DateTime end) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  @override
  Future<int> insertTransaction(TransactionItem transaction) async {
    final id = transaction.id ?? _nextId++;
    final newTx = transaction.copyWith(id: id);
    _transactions[id] = newTx;
    _notify();
    return id;
  }

  @override
  Future<bool> updateTransaction(TransactionItem transaction) async {
    if (transaction.id == null || !_transactions.containsKey(transaction.id)) {
      return false;
    }
    _transactions[transaction.id!] = transaction;
    _notify();
    return true;
  }

  @override
  Future<int> deleteTransaction(int id) async {
    final removed = _transactions.remove(id);
    if (removed != null) {
      _notify();
      return 1;
    }
    return 0;
  }

  @override
  Future<TransactionItem?> getTransactionById(int id) async {
    return _transactions[id];
  }

  @override
  Future<List<TransactionItem>> getAllTransactions() async {
    final list = _transactions.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Stream<List<TransactionItem>> watchAllTransactions() async* {
    yield await getAllTransactions();
    yield* _controller.stream.map((list) {
      final sorted = list.toList()..sort((a, b) => b.date.compareTo(a.date));
      return sorted;
    });
  }

  @override
  Future<List<TransactionItem>> getTransactionsByLedger(String? ledger) async {
    final list = _transactions.values.where((t) {
      if (ledger == null || ledger == 'all') return true;
      return t.ledger == ledger;
    }).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Stream<List<TransactionItem>> watchTransactionsByLedger(
      String? ledger) async* {
    yield await getTransactionsByLedger(ledger);
    yield* _controller.stream.map((list) {
      final filtered = list.where((t) {
        if (ledger == null || ledger == 'all') return true;
        return t.ledger == ledger;
      }).toList();
      filtered.sort((a, b) => b.date.compareTo(a.date));
      return filtered;
    });
  }

  @override
  Future<List<TransactionItem>> getTransactionsByDateRange(
    DateTime start,
    DateTime end, {
    String? ledger,
  }) async {
    final filtered = _transactions.values.where((t) {
      final inRange = _isWithinRange(t.date, start, end);
      final inLedger = ledger == null || ledger == 'all' || t.ledger == ledger;
      return inRange && inLedger;
    }).toList();
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  @override
  Stream<List<TransactionItem>> watchTransactionsByDateRange(
    DateTime start,
    DateTime end, {
    String? ledger,
  }) async* {
    yield await getTransactionsByDateRange(start, end, ledger: ledger);
    yield* _controller.stream.map((list) {
      final filtered = list.where((t) {
        final inRange = _isWithinRange(t.date, start, end);
        final inLedger =
            ledger == null || ledger == 'all' || t.ledger == ledger;
        return inRange && inLedger;
      }).toList();
      filtered.sort((a, b) => b.date.compareTo(a.date));
      return filtered;
    });
  }

  @override
  Future<int> getTotalIncomeByDateRange(
    DateTime start,
    DateTime end, {
    String? ledger,
  }) async {
    return _transactions.values.where((t) {
      final inRange = _isWithinRange(t.date, start, end);
      final isIncome = t.type == 'income';
      final inLedger = ledger == null || ledger == 'all' || t.ledger == ledger;
      return inRange && isIncome && inLedger;
    }).fold<int>(0, (sum, t) => sum + t.amount);
  }

  @override
  Future<int> getTotalExpenseByDateRange(
    DateTime start,
    DateTime end, {
    String? ledger,
  }) async {
    return _transactions.values.where((t) {
      final inRange = _isWithinRange(t.date, start, end);
      final isExpense = t.type == 'expense';
      final inLedger = ledger == null || ledger == 'all' || t.ledger == ledger;
      return inRange && isExpense && inLedger;
    }).fold<int>(0, (sum, t) => sum + t.amount);
  }

  @override
  Future<Map<int, int>> getTotalByCategory(
    DateTime start,
    DateTime end, {
    String type = 'expense',
    String? ledger,
  }) async {
    final map = <int, int>{};
    final items = _transactions.values.where((t) {
      final inRange = _isWithinRange(t.date, start, end);
      final matchesType = t.type == type;
      final inLedger = ledger == null || ledger == 'all' || t.ledger == ledger;
      return inRange && matchesType && inLedger;
    });

    for (final item in items) {
      map[item.categoryId] = (map[item.categoryId] ?? 0) + item.amount;
    }
    return map;
  }

  @override
  Future<int> calculateWalletBalance(int walletId) async {
    int initialBalance = 0;
    if (_walletRepository != null) {
      final wallet = await _walletRepository.getWalletById(walletId);
      if (wallet != null) {
        initialBalance = wallet.initialBalance;
      }
    }

    int totalIncome = 0;
    int totalExpense = 0;

    for (final t in _transactions.values) {
      if (t.walletId == walletId) {
        if (t.type == 'income') {
          totalIncome += t.amount;
        } else if (t.type == 'expense') {
          totalExpense += t.amount;
        }
      }
    }

    return initialBalance + totalIncome - totalExpense;
  }

  @override
  Stream<int> watchWalletBalance(int walletId) async* {
    yield await calculateWalletBalance(walletId);
    yield* _controller.stream.asyncMap((_) => calculateWalletBalance(walletId));
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
    final walletIds = <int>{};
    if (_walletRepository != null) {
      final wallets = await _walletRepository.getWalletsByLedger(ledger);
      for (final w in wallets) {
        if (w.id != null) {
          walletIds.add(w.id!);
          initialSum += w.initialBalance;
        }
      }
    }

    int totalIncome = 0;
    int totalExpense = 0;

    for (final t in _transactions.values) {
      final matchesLedger = t.ledger.isNotEmpty
          ? t.ledger == ledger
          : walletIds.contains(t.walletId);
      if (matchesLedger) {
        if (t.type == 'income') {
          totalIncome += t.amount;
        } else if (t.type == 'expense') {
          totalExpense += t.amount;
        }
      }
    }

    return initialSum + totalIncome - totalExpense;
  }

  @override
  Stream<int> watchLedgerBalance(String ledger) async* {
    yield await calculateLedgerBalance(ledger);
    yield* _controller.stream.asyncMap((_) => calculateLedgerBalance(ledger));
  }

  @override
  Future<bool> hasTransactionsForWallet(int walletId) async {
    return _transactions.values.any((t) => t.walletId == walletId);
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

    // 1. Transaksi pengeluaran dari dompet asal
    final outId = _nextId++;
    _transactions[outId] = TransactionItem(
      id: outId,
      type: 'expense',
      amount: amount,
      categoryId: 20, // Transfer Keluar / Lainnya
      walletId: sourceWalletId,
      date: transferDate,
      ledger: sourceLedger,
      note: outNote,
      createdAt: DateTime.now(),
    );

    // 2. Transaksi pemasukan ke dompet tujuan
    final inId = _nextId++;
    _transactions[inId] = TransactionItem(
      id: inId,
      type: 'income',
      amount: amount,
      categoryId: 16, // Transfer Masuk / Lainnya
      walletId: targetWalletId,
      date: transferDate,
      ledger: targetLedger,
      note: inNote,
      createdAt: DateTime.now(),
    );

    _notify();
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

    // 1. Tambah tabungan ke goal
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

    // 2. Jika ada dompet sumber (mengurangi/memindahkan dari catatan lain)
    if (sourceWalletId != null) {
      final outId = _nextId++;
      String sourceLedger = 'daily';
      if (_walletRepository != null) {
        final w = await _walletRepository.getWalletById(sourceWalletId);
        if (w != null) sourceLedger = w.ledger;
      }

      _transactions[outId] = TransactionItem(
        id: outId,
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
      );
    }

    // 3. Catat transaksi pencapaian (masuk ke catatan pencapaian)
    final inId = _nextId++;
    _transactions[inId] = TransactionItem(
      id: inId,
      type: 'income',
      amount: amount,
      categoryId: 23, // Setoran
      walletId: goalWalletId,
      date: txDate,
      ledger: 'goal',
      goalId: goalId,
      note: note != null && note.isNotEmpty
          ? 'Setoran ke $goalName • $note'
          : 'Setoran ke $goalName',
      createdAt: DateTime.now(),
    );

    _notify();
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
    if (name == 'Tambah Saldo') return 26;
    return type == 'income' ? 27 : 28;
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
      id: _nextId++,
      type: 'income',
      amount: amount,
      categoryId: catId,
      walletId: walletId,
      date: date ?? DateTime.now(),
      ledger: ledger,
      note: (note != null && note.isNotEmpty) ? note : 'Tambah Saldo',
      createdAt: DateTime.now(),
    );

    _transactions[tx.id!] = tx;
    _notify();
    return tx.id!;
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
      id: _nextId++,
      type: type,
      amount: diff.abs(),
      categoryId: catId,
      walletId: walletId,
      date: date ?? DateTime.now(),
      ledger: ledger,
      note: (note != null && note.isNotEmpty) ? note : 'Penyesuaian Saldo',
      createdAt: DateTime.now(),
    );

    _transactions[tx.id!] = tx;
    _notify();
    return tx.id!;
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
    final walletIds = <int>{};
    if (_walletRepository != null) {
      final wallets = await _walletRepository.getWalletsByLedger(ledger);
      for (final w in wallets) {
        if (w.id != null) {
          walletIds.add(w.id!);
          await _walletRepository.updateWallet(w.copyWith(initialBalance: 0));
        }
      }
    }

    _transactions.removeWhere((id, tx) =>
        tx.ledger == ledger || walletIds.contains(tx.walletId));

    _notify();
  }

  @override
  void clearAll() {
    _transactions.clear();
    _nextId = 1;
    _notify();
  }

  void dispose() {
    _walletSubscription?.cancel();
    _goalSubscription?.cancel();
    _controller.close();
  }
}
