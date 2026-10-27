import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/duit_type.dart';
import '../providers/app_state_provider.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/saving_goal_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/wallet_repository.dart';

class TotalResetService {
  TotalResetService._();

  /// Menjalankan reset total aplikasi:
  /// - Menghapus seluruh isi database & membuat ulang data awal (seed)
  /// - Menghapus shared_preferences (nama, tema, filter riwayat, sembunyikan saldo, penanda panduan)
  /// - Menghapus flutter_secure_storage (PIN, pertanyaan, jawaban pemulihan)
  /// - Mengembalikan seluruh state provider ke kondisi awal seperti baru diinstal
  static Future<void> performTotalReset(WidgetRef ref) async {
    try {
      // 1. Reset database Drift (jika aktif)
      try {
        final db = ref.read(appDatabaseProvider);
        await db.resetAll().timeout(const Duration(milliseconds: 200));
      } catch (_) {
        // Abaikan jika database in-memory atau mock testing
      }

      // 2. Reset repository in-memory
      try {
        final walletRepo = ref.read(walletRepositoryProvider);
        if (walletRepo is InMemoryWalletRepository) {
          walletRepo.resetToInitial();
        }

        final categoryRepo = ref.read(categoryRepositoryProvider);
        if (categoryRepo is InMemoryCategoryRepository) {
          categoryRepo.resetToInitial();
        }

        final goalRepo = ref.read(savingGoalRepositoryProvider);
        if (goalRepo is InMemorySavingGoalRepository) {
          goalRepo.clearAll();
        }

        final txRepo = ref.read(transactionRepositoryProvider);
        if (txRepo is InMemoryTransactionRepository) {
          txRepo.clearAll();
        }
      } catch (_) {}

      // 3. Hapus shared_preferences
      final prefs = ref.read(preferencesServiceProvider);
      await prefs.clearAll();

      // 4. Hapus flutter_secure_storage (PIN, pertanyaan pemulihan)
      final security = ref.read(securityServiceProvider);
      await security.wipeAllSecurityData();

      // 5. Kembalikan semua state notifier ke kondisi awal
      try {
        await ref.read(userNameProvider.notifier).updateName('');
        await ref.read(isPinEnabledProvider.notifier).setEnabled(false);
        ref.read(isAppLockedProvider.notifier).state = false;
        ref.read(activeDuitProvider.notifier).select(DuitSelection.semua);
        await ref.read(hideBalanceProvider.notifier).setHidden(false);
        await ref.read(historyFilterProvider.notifier).setFilter('daily');
        await ref.read(themeModeProvider.notifier).setThemeMode('system');
      } catch (_) {}

      // 6. Invalidate provider stream
      ref.invalidate(walletsStreamProvider);
      ref.invalidate(categoriesStreamProvider);
      ref.invalidate(savingGoalsStreamProvider);
      ref.invalidate(transactionsStreamProvider);
      ref.invalidate(ledgerBalanceStreamProvider('daily'));
      ref.invalidate(ledgerBalanceStreamProvider('balance'));
      ref.invalidate(ledgerBalanceStreamProvider('saving'));
      ref.invalidate(ledgerBalanceStreamProvider('goal'));
      ref.invalidate(activeLedgerFilterProvider);
    } catch (_) {}
  }
}
