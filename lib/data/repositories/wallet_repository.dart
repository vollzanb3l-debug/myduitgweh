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
    _controller.add(List.unmodifiable(_wallets.values));
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
  Stream<List<WalletItem>> watchAllWallets() {
    return _controller.stream.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) => sink.add(data),
      ),
    );
  }

  void dispose() {
    _controller.close();
  }
}
