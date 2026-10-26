import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category_model.dart';
import '../models/saving_goal_model.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import 'category_repository.dart';
import 'saving_goal_repository.dart';
import 'transaction_repository.dart';
import 'wallet_repository.dart';

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

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final walletRepo = ref.watch(walletRepositoryProvider);
  final repo = InMemoryTransactionRepository(walletRepository: walletRepo);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final savingGoalRepositoryProvider = Provider<SavingGoalRepository>((ref) {
  final repo = InMemorySavingGoalRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

// Stream Providers Reaktif untuk UI
final walletsStreamProvider = StreamProvider<List<WalletItem>>((ref) {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.watchAllWallets();
});

final categoriesStreamProvider = StreamProvider<List<CategoryItem>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchAllCategories();
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
