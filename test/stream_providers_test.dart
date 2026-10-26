import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myduitgweh/core/widgets/widgets.dart';
import 'package:myduitgweh/data/repositories/category_repository.dart';
import 'package:myduitgweh/data/repositories/saving_goal_repository.dart';
import 'package:myduitgweh/data/repositories/transaction_repository.dart';
import 'package:myduitgweh/data/repositories/wallet_repository.dart';

void main() {
  group('Repository Stream Immediate Emission Tests (Anti Infinite Loading)', () {
    test('WalletRepository.watchAllWallets emits initial data immediately', () async {
      final repo = InMemoryWalletRepository(seedInitialData: true);
      addTearDown(() => repo.dispose());

      // Should emit first event without requiring any insert/mutation
      final wallets = await repo.watchAllWallets().first;
      expect(wallets, isNotEmpty);
      expect(wallets.length, greaterThanOrEqualTo(3));
    });

    test('TransactionRepository.watchWalletBalance emits immediately', () async {
      final walletRepo = InMemoryWalletRepository(seedInitialData: true);
      final txRepo = InMemoryTransactionRepository(walletRepository: walletRepo);
      addTearDown(() {
        walletRepo.dispose();
        txRepo.dispose();
      });

      final balance = await txRepo.watchWalletBalance(1).first;
      expect(balance, isA<int>());
    });

    test('CategoryRepository.watchAllCategories emits immediately', () async {
      final repo = InMemoryCategoryRepository(seedInitialData: true);
      addTearDown(() => repo.dispose());

      final categories = await repo.watchAllCategories().first;
      expect(categories, isNotEmpty);
    });

    test('SavingGoalRepository.watchAllSavingGoals emits immediately', () async {
      final repo = InMemorySavingGoalRepository();
      addTearDown(() => repo.dispose());

      final goals = await repo.watchAllSavingGoals().first;
      expect(goals, isEmpty);
    });

    test('TransactionRepository.watchAllTransactions emits immediately', () async {
      final repo = InMemoryTransactionRepository();
      addTearDown(() => repo.dispose());

      final txs = await repo.watchAllTransactions().first;
      expect(txs, isEmpty);
    });
  });

  group('ComingSoonState and ErrorState Widget Tests', () {
    testWidgets('ComingSoonState displays required text and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ComingSoonState(),
          ),
        ),
      );

      expect(find.text('Belum tersedia'), findsOneWidget);
      expect(find.text('Fitur ini sedang disiapkan'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
    });

    testWidgets('ErrorState displays friendly message and triggers onRetry', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorState(
              title: 'Gagal Memuat Data',
              message: 'Pesan ramah kendala sistem.',
              onRetry: () {
                retried = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Gagal Memuat Data'), findsOneWidget);
      expect(find.text('Pesan ramah kendala sistem.'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);

      await tester.tap(find.text('Coba lagi'));
      expect(retried, isTrue);
    });
  });
}
