import '../database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category_model.dart';
import '../models/saving_goal_model.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import 'category_repository.dart';
import 'saving_goal_repository.dart';
import 'transaction_repository.dart';
import 'wallet_repository.dart';

// Database Provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Provider Repository
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final repo = InMemoryWalletRepository(seedInitialData: true);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final repo = InMemoryCategoryRepository(seedInitialData: true);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final savingGoalRepositoryProvider = Provider<SavingGoalRepository>((ref) {
  final repo = InMemorySavingGoalRepository(seedInitialData: false);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final walletRepo = ref.watch(walletRepositoryProvider);
  final goalRepo = ref.watch(savingGoalRepositoryProvider);
  final categoryRepo = ref.watch(categoryRepositoryProvider);
  final repo = InMemoryTransactionRepository(
    walletRepository: walletRepo,
    savingGoalRepository: goalRepo,
    categoryRepository: categoryRepo,
  );
  ref.onDispose(() => repo.dispose());
  return repo;
});

// Filter Catatan Aktif ('all', 'daily', 'balance', 'saving', 'goal')
final activeLedgerFilterProvider = StateProvider<String>((ref) => 'all');

// Stream Providers Reaktif untuk UI
final walletsStreamProvider = StreamProvider<List<WalletItem>>((ref) {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.watchAllWallets();
});

final walletsByLedgerStreamProvider =
    StreamProvider.family<List<WalletItem>, String>((ref, ledger) {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.watchWalletsByLedger(ledger);
});

final categoriesStreamProvider = StreamProvider<List<CategoryItem>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchAllCategories();
});

final categoriesByLedgerStreamProvider = StreamProvider.family<
    List<CategoryItem>,
    ({String ledger, String? type})>((ref, arg) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchCategoriesByLedger(arg.ledger, type: arg.type);
});

final expenseCategoriesStreamProvider = StreamProvider<List<CategoryItem>>((
  ref,
) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchCategoriesByType('expense');
});

final incomeCategoriesStreamProvider = StreamProvider<List<CategoryItem>>((
  ref,
) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchCategoriesByType('income');
});

final transactionsStreamProvider = StreamProvider<List<TransactionItem>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchAllTransactions();
});

final transactionsByLedgerStreamProvider =
    StreamProvider.family<List<TransactionItem>, String?>((ref, ledger) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchTransactionsByLedger(ledger);
});

final savingGoalsStreamProvider = StreamProvider<List<SavingGoalItem>>((ref) {
  final repo = ref.watch(savingGoalRepositoryProvider);
  return repo.watchAllSavingGoals();
});

final walletBalanceProvider = FutureProvider.family<int, int>((
  ref,
  walletId,
) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.calculateWalletBalance(walletId);
});

final walletBalanceStreamProvider = StreamProvider.family<int, int>((
  ref,
  walletId,
) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchWalletBalance(walletId);
});

final ledgerBalanceStreamProvider = StreamProvider.family<int, String>((
  ref,
  ledger,
) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchLedgerBalance(ledger);
});

