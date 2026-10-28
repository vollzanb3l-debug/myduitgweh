import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myduitgweh/core/models/duit_type.dart';
import 'package:myduitgweh/core/providers/app_state_provider.dart';
import 'package:myduitgweh/core/services/preferences_service.dart';
import 'package:myduitgweh/core/services/security_service.dart';
import 'package:myduitgweh/core/services/total_reset_service.dart';
import 'package:myduitgweh/core/widgets/atur_saldo_sheet.dart';
import 'package:myduitgweh/core/widgets/money_text.dart';
import 'package:myduitgweh/data/repositories/category_repository.dart';
import 'package:myduitgweh/data/repositories/providers.dart';
import 'package:myduitgweh/data/repositories/saving_goal_repository.dart';
import 'package:myduitgweh/data/repositories/transaction_repository.dart';
import 'package:myduitgweh/data/repositories/wallet_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tahap 14: Ketahanan, Privasi, & Pemulihan Tests', () {
    late PreferencesService prefsService;
    late SecurityService securityService;
    late InMemoryWalletRepository walletRepo;
    late InMemoryCategoryRepository categoryRepo;
    late InMemorySavingGoalRepository goalRepo;
    late InMemoryTransactionRepository txRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      prefsService = PreferencesService(prefs);
      securityService = SecurityService(storage: const FlutterSecureStorage());

      walletRepo = InMemoryWalletRepository(seedInitialData: true);
      categoryRepo = InMemoryCategoryRepository(seedInitialData: true);
      goalRepo = InMemorySavingGoalRepository(seedInitialData: false);
      txRepo = InMemoryTransactionRepository(
        walletRepository: walletRepo,
        savingGoalRepository: goalRepo,
        categoryRepository: categoryRepo,
      );
    });

    tearDown(() {
      walletRepo.dispose();
      categoryRepo.dispose();
      goalRepo.dispose();
      txRepo.dispose();
    });

    // (a) Sembunyikan saldo tersimpan dan terbaca kembali
    test('a. Sembunyikan saldo tersimpan dan terbaca kembali di preferences & provider', () async {
      expect(prefsService.isBalanceHidden, isFalse);

      await prefsService.setIsBalanceHidden(true);
      expect(prefsService.isBalanceHidden, isTrue);

      final container = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(prefsService),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(hideBalanceProvider), isTrue);

      await container.read(hideBalanceProvider.notifier).setHidden(false);
      expect(container.read(hideBalanceProvider), isFalse);
      expect(prefsService.isBalanceHidden, isFalse);
    });

    // Widget test untuk MoneyText saat disembunyikan / ditampilkan
    testWidgets('a.2 MoneyText masking nominal saat sembunyikan saldo aktif', (tester) async {
      final container = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(prefsService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: MoneyText(amount: 500000),
            ),
          ),
        ),
      );

      // Default: Saldo tampil
      expect(find.text('Rp 500.000'), findsOneWidget);
      expect(find.text('Rp ••••••'), findsNothing);

      // Aktifkan sembunyikan saldo
      await container.read(hideBalanceProvider.notifier).setHidden(true);
      await tester.pump();

      // Sekarang disembunyikan
      expect(find.text('Rp ••••••'), findsOneWidget);
      expect(find.text('Rp 500.000'), findsNothing);
    });

    // (b) Filter riwayat default Harian dan tersimpan
    test('b. Filter riwayat default Harian dan tersimpan di preferences', () async {
      // Default awal harus 'daily' (Harian, paling kiri)
      expect(prefsService.historyFilter, 'daily');

      // Simpan perubahan filter ke 'monthly'
      await prefsService.setHistoryFilter('monthly');
      expect(prefsService.historyFilter, 'monthly');

      // Provider membaca nilai tersimpan dari preferences
      final container = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(prefsService),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(historyFilterProvider), 'monthly');

      // Ganti kembali ke weekly
      await container.read(historyFilterProvider.notifier).setFilter('weekly');
      expect(container.read(historyFilterProvider), 'weekly');
      expect(prefsService.historyFilter, 'weekly');
    });

    // (c) Verifikasi jawaban pemulihan (benar/salah, normalisasi huruf dan spasi)
    test('c. Verifikasi jawaban pemulihan (benar/salah, normalisasi huruf/spasi)', () async {
      await securityService.saveRecoveryQuestions(
        q1: 'Siapa nama kucing kesayanganmu?',
        a1: '  Mochi Putih  ',
        q2: 'Apa makanan favoritmu?',
        a2: ' Nasi Goreng ',
      );

      final questions = await securityService.getRecoveryQuestions();
      expect(questions, isNotNull);
      expect(questions!.length, 2);
      expect(questions[0], 'Siapa nama kucing kesayanganmu?');
      expect(questions[1], 'Apa makanan favoritmu?');

      // Verifikasi jawaban dengan huruf besar/kecil & spasi berbeda -> HARUS BENAR (karena dinormalisasi)
      final isCorrectNormalized = await securityService.verifyRecoveryAnswers(
        a1: 'mochi putih',
        a2: 'NASI GORENG',
      );
      expect(isCorrectNormalized, isTrue);

      // Verifikasi jawaban salah
      final isWrong = await securityService.verifyRecoveryAnswers(
        a1: 'kucing oren',
        a2: 'nasi padang',
      );
      expect(isWrong, isFalse);
      expect(securityService.failedRecoveryAttempts, 1);
    });

    // (d) Reset total mengosongkan database, preferences, dan secure storage
    testWidgets('d. Reset total mengosongkan database, preferences, dan secure storage', (tester) async {
      // Persiapkan data
      await prefsService.setUserName('Rafi');
      await prefsService.setIsPinEnabled(true);
      await prefsService.setIsBalanceHidden(true);
      await prefsService.setHistoryFilter('monthly');
      await securityService.savePin('4321');
      await securityService.saveRecoveryQuestions(
        q1: 'Pertanyaan satu',
        a1: 'Jawaban satu',
        q2: 'Pertanyaan dua',
        a2: 'Jawaban dua',
      );

      expect(prefsService.userName, 'Rafi');
      expect(await securityService.isPinConfigured(), isTrue);

      final container = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(prefsService),
          securityServiceProvider.overrideWithValue(securityService),
          walletRepositoryProvider.overrideWithValue(walletRepo),
          categoryRepositoryProvider.overrideWithValue(categoryRepo),
          savingGoalRepositoryProvider.overrideWithValue(goalRepo),
          transactionRepositoryProvider.overrideWithValue(txRepo),
        ],
      );
      addTearDown(container.dispose);

      // Jalankan reset total via Consumer
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () async {
                      await TotalResetService.performTotalReset(ref);
                    },
                    child: const Text('Reset Button'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Reset Button'));
      await tester.pumpAndSettle();

      // Verifikasi semua preferences kosong/kembali ke default
      expect(prefsService.userName, isEmpty);
      expect(prefsService.isPinEnabled, isFalse);
      expect(prefsService.isBalanceHidden, isFalse);
      expect(prefsService.historyFilter, 'daily');
      expect(prefsService.hasSeenOnboarding, isFalse);

      // Verifikasi secure storage bersih
      expect(await securityService.isPinConfigured(), isFalse);
      final questions = await securityService.getRecoveryQuestions();
      expect(questions, isNull);
    });

    // (e) Dialog tanpa opsi tidak perlu dropdown (tampil label biasa jika 1 opsi)
    testWidgets('e. Dialog Atur Saldo tanpa opsi hanya menampilkan teks/badge bukan Dropdown', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            walletRepositoryProvider.overrideWithValue(walletRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () {
                      showAturSaldoBottomSheet(
                        context: context,
                        ref: ref,
                        duit: DuitSelection.harian,
                      );
                    },
                    child: const Text('Buka Menu Atur'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Menu Atur'));
      await tester.pumpAndSettle();

      // Pilih "Tambah Saldo"
      await tester.tap(find.text('Tambah Saldo'));
      await tester.pumpAndSettle();

      // Verifikasi bahwa untuk Duit Harian (hanya 1 akun: 'Uang Harian'):
      // Label menjadi "Tujuan:" (bukan "Pilih Akun Tujuan")
      expect(find.text('Tujuan:'), findsOneWidget);

      // Tidak menampilkan DropdownButtonFormField
      expect(find.byType(DropdownButtonFormField<int>), findsNothing);

      // Menampilkan teks nama akun
      expect(find.text('Uang Utama'), findsOneWidget);
    });

    testWidgets('e.2 Dialog Atur Saldo Duit Saldo menampilkan badge tujuan tunggal tanpa dropdown (Tahap 16)', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            walletRepositoryProvider.overrideWithValue(walletRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () {
                      showAturSaldoBottomSheet(
                        context: context,
                        ref: ref,
                        duit: DuitSelection.saldo,
                      );
                    },
                    child: const Text('Buka Menu Atur'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Menu Atur'));
      await tester.pumpAndSettle();

      // Pilih "Tambah Saldo"
      await tester.tap(find.text('Tambah Saldo'));
      await tester.pumpAndSettle();

      // Untuk Duit Saldo:
      // Label tetap "Tujuan:" karena memakai dompet internal tunggal
      expect(find.text('Tujuan:'), findsOneWidget);

      // Tidak menampilkan DropdownButtonFormField<int>
      expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    });
  });
}
