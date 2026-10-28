import 'dart:async';

import '../database/initial_data.dart';
import '../models/wallet_model.dart';

abstract class WalletRepository {
  Future<int> insertWallet(WalletItem wallet);
  Future<bool> updateWallet(WalletItem wallet);
  Future<int> deleteWallet(int id);
  Future<WalletItem?> getWalletById(int id);
  Future<List<WalletItem>> getAllWallets();
  Stream<List<WalletItem>> watchAllWallets();
  Future<List<WalletItem>> getWalletsByLedger(String ledger);
  Stream<List<WalletItem>> watchWalletsByLedger(String ledger);
  Future<WalletItem> getOrCreateInternalWallet(String ledger);
  Future<void> ensureInternalWallets();
  void clearAll();
  void resetToInitial();
}

class InMemoryWalletRepository implements WalletRepository {
  final Map<int, WalletItem> _wallets = {};
  final StreamController<List<WalletItem>> _controller =
      StreamController<List<WalletItem>>.broadcast();
  int _nextId = 1;

  InMemoryWalletRepository({bool seedInitialData = true}) {
    if (seedInitialData) {
      for (final w in InitialData.defaultWallets) {
        _wallets[w.id ?? _nextId] = w;
        if ((w.id ?? 0) >= _nextId) {
          _nextId = (w.id ?? 0) + 1;
        }
      }
      _notify();
    }
  }

  void _notify() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_wallets.values));
    }
  }

  @override
  Future<int> insertWallet(WalletItem wallet) async {
    final id = wallet.id ?? _nextId++;
    final newWallet = wallet.copyWith(id: id);
    _wallets[id] = newWallet;
    _notify();
    return id;
  }

  @override
  Future<bool> updateWallet(WalletItem wallet) async {
    if (wallet.id == null || !_wallets.containsKey(wallet.id)) {
      return false;
    }
    _wallets[wallet.id!] = wallet;
    _notify();
    return true;
  }

  @override
  Future<int> deleteWallet(int id) async {
    final removed = _wallets.remove(id);
    if (removed != null) {
      _notify();
      return 1;
    }
    return 0;
  }

  @override
  Future<WalletItem?> getWalletById(int id) async {
    return _wallets[id];
  }

  @override
  Future<List<WalletItem>> getAllWallets() async {
    return _wallets.values.toList();
  }

  @override
  Stream<List<WalletItem>> watchAllWallets() async* {
    yield _wallets.values.toList();
    yield* _controller.stream;
  }

  @override
  Future<List<WalletItem>> getWalletsByLedger(String ledger) async {
    return _wallets.values.where((w) => w.ledger == ledger).toList();
  }

  @override
  Stream<List<WalletItem>> watchWalletsByLedger(String ledger) async* {
    yield await getWalletsByLedger(ledger);
    yield* _controller.stream.map(
      (list) => list.where((w) => w.ledger == ledger).toList(),
    );
  }

  @override
  Future<WalletItem> getOrCreateInternalWallet(String ledger) async {
    final list = await getWalletsByLedger(ledger);
    if (list.isNotEmpty) return list.first;

    String name;
    switch (ledger) {
      case 'daily':
        name = 'Uang Utama';
        break;
      case 'balance':
        name = 'Duit Saldo';
        break;
      case 'saving':
        name = 'Duit Tabungan';
        break;
      default:
        name = 'Duit $ledger';
    }

    final id = await insertWallet(
      WalletItem(
        name: name,
        type: ledger,
        ledger: ledger,
        initialBalance: 0,
        createdAt: DateTime.now(),
      ),
    );
    return (await getWalletById(id))!;
  }

  @override
  Future<void> ensureInternalWallets() async {
    for (final l in ['daily', 'balance', 'saving']) {
      await getOrCreateInternalWallet(l);
    }
  }

  @override
  void clearAll() {
    _wallets.clear();
    _notify();
  }

  @override
  void resetToInitial() {
    _wallets.clear();
    for (final w in InitialData.defaultWallets) {
      _wallets[w.id ?? _nextId] = w;
      if ((w.id ?? 0) >= _nextId) {
        _nextId = (w.id ?? 0) + 1;
      }
    }
    _notify();
  }

  void dispose() {
    _controller.close();
  }
}
