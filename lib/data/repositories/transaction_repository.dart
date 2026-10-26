import 'dart:async';

import '../models/transaction_model.dart';
import 'wallet_repository.dart';

abstract class TransactionRepository {
  Future<int> insertTransaction(TransactionItem transaction);
  Future<bool> updateTransaction(TransactionItem transaction);
  Future<int> deleteTransaction(int id);
  Future<TransactionItem?> getTransactionById(int id);
  Future<List<TransactionItem>> getAllTransactions();
  Stream<List<TransactionItem>> watchAllTransactions();

  /// Mengambil transaksi dalam rentang tanggal tertentu (inklusif)
  Future<List<TransactionItem>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  );

  /// Stream transaksi dalam rentang tanggal tertentu
  Stream<List<TransactionItem>> watchTransactionsByDateRange(
    DateTime start,
    DateTime end,
  );

  /// Menghitung total pemasukan dalam rentang tanggal
  Future<int> getTotalIncomeByDateRange(DateTime start, DateTime end);

  /// Menghitung total pengeluaran dalam rentang tanggal
  Future<int> getTotalExpenseByDateRange(DateTime start, DateTime end);

  /// Menghitung total per kategori dalam rentang tanggal (default: pengeluaran)
  /// Mengembalikan `Map<int, int>` (categoryId -> totalNominal)
  Future<Map<int, int>> getTotalByCategory(
    DateTime start,
    DateTime end, {
    String type = 'expense',
  });

  /// Menghitung saldo dompet:
  /// Saldo dompet = initialBalance + total pemasukan - total pengeluaran
  Future<int> calculateWalletBalance(int walletId);

  /// Stream saldo dompet yang terupdate otomatis saat ada perubahan transaksi
  Stream<int> watchWalletBalance(int walletId);

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
}

class InMemoryTransactionRepository implements TransactionRepository {
  final Map<int, TransactionItem> _transactions = {};
  final StreamController<List<TransactionItem>> _controller =
      StreamController<List<TransactionItem>>.broadcast();
  final WalletRepository? _walletRepository;
  int _nextId = 1;

  InMemoryTransactionRepository({WalletRepository? walletRepository})
    : _walletRepository = walletRepository;

  void _notify() {
    _controller.add(List.unmodifiable(_transactions.values));
  }

  bool _isWithinRange(DateTime date, DateTime start, DateTime end) {
    // Normalisasi perbandingan tanggal berbasis hari
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
  Stream<List<TransactionItem>> watchAllTransactions() {
    return _controller.stream.map((list) {
      final sorted = list.toList()..sort((a, b) => b.date.compareTo(a.date));
      return sorted;
    });
  }

  @override
  Future<List<TransactionItem>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final filtered = _transactions.values
        .where((t) => _isWithinRange(t.date, start, end))
        .toList();
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  @override
  Stream<List<TransactionItem>> watchTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return _controller.stream.map((list) {
      final filtered = list
          .where((t) => _isWithinRange(t.date, start, end))
          .toList();
      filtered.sort((a, b) => b.date.compareTo(a.date));
      return filtered;
    });
  }

  @override
  Future<int> getTotalIncomeByDateRange(DateTime start, DateTime end) async {
    return _transactions.values
        .where((t) => t.type == 'income' && _isWithinRange(t.date, start, end))
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  @override
  Future<int> getTotalExpenseByDateRange(DateTime start, DateTime end) async {
    return _transactions.values
        .where((t) => t.type == 'expense' && _isWithinRange(t.date, start, end))
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  @override
  Future<Map<int, int>> getTotalByCategory(
    DateTime start,
    DateTime end, {
    String type = 'expense',
  }) async {
    final map = <int, int>{};
    final items = _transactions.values.where(
      (t) => t.type == type && _isWithinRange(t.date, start, end),
    );

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
  Stream<int> watchWalletBalance(int walletId) {
    return _controller.stream.asyncMap((_) => calculateWalletBalance(walletId));
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

    if (_walletRepository != null) {
      final source = await _walletRepository.getWalletById(sourceWalletId);
      final target = await _walletRepository.getWalletById(targetWalletId);
      if (source != null) sourceName = source.name;
      if (target != null) targetName = target.name;
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
      categoryId: 7, // Kategori Lainnya (Pengeluaran)
      walletId: sourceWalletId,
      date: transferDate,
      note: outNote,
      createdAt: DateTime.now(),
    );

    // 2. Transaksi pemasukan ke dompet tujuan
    final inId = _nextId++;
    _transactions[inId] = TransactionItem(
      id: inId,
      type: 'income',
      amount: amount,
      categoryId: 11, // Kategori Lainnya (Pemasukan)
      walletId: targetWalletId,
      date: transferDate,
      note: inNote,
      createdAt: DateTime.now(),
    );

    _notify();
  }

  void dispose() {
    _controller.close();
  }
}
