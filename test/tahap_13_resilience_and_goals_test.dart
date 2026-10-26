import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myduitgweh/core/constants/app_labels.dart';
import 'package:myduitgweh/core/models/duit_type.dart';
import 'package:myduitgweh/core/utils/currency_input_formatter.dart';
import 'package:myduitgweh/core/widgets/global_error_view.dart';
import 'package:myduitgweh/data/database/initial_data.dart';
import 'package:myduitgweh/data/models/saving_goal_model.dart';
import 'package:myduitgweh/data/repositories/saving_goal_repository.dart';
import 'package:myduitgweh/features/wallets/presentation/goals_ledger_screen.dart';
import 'package:myduitgweh/data/repositories/providers.dart';

void main() {
  group('Tahap 13: Resiliensi, Duit Pencapaian & Label Merek Tests', () {
    test('(1) Duit Pencapaian kosong saat pertama kali', () async {
      // 1. InitialData bawaan untuk defaultSavingGoals harus kosong
      expect(InitialData.defaultSavingGoals, isEmpty);

      // 2. InMemorySavingGoalRepository default tidak memiliki data target
      final repo = InMemorySavingGoalRepository(seedInitialData: false);
      final allGoals = await repo.getAllSavingGoals();
      expect(allGoals, isEmpty);
    });

    test('(2) Persentase progres tidak error saat target 0 atau data kosong', () {
      // 1. Target bernilai 0
      const goalZeroTarget = SavingGoalItem(
        name: 'Target 0',
        targetAmount: 0,
        currentAmount: 0,
        walletId: 1,
      );
      expect(goalZeroTarget.progressPercentage, equals(0.0));
      expect(goalZeroTarget.progress, equals(0.0));
      expect(goalZeroTarget.isReached, isFalse);

      // 2. Target negatif
      const goalNegativeTarget = SavingGoalItem(
        name: 'Target Negatif',
        targetAmount: -50000,
        currentAmount: 10000,
        walletId: 1,
      );
      expect(goalNegativeTarget.progressPercentage, equals(0.0));

      // 3. List kosong (agregat ringkasan)
      final List<SavingGoalItem> emptyGoals = [];
      final totalCurrent = emptyGoals.fold<int>(0, (sum, g) => sum + g.currentAmount);
      final totalTarget = emptyGoals.fold<int>(0, (sum, g) => sum + g.targetAmount);
      final progress = totalTarget > 0 ? (totalCurrent / totalTarget).clamp(0.0, 1.0) : 0.0;
      expect(progress, equals(0.0));
      expect(progress.isNaN, isFalse);
      expect(progress.isInfinite, isFalse);
    });

    test('(3) Label merek dan nama pendek duit di app_labels.dart', () {
      // brandLabel & duitShortName untuk setiap jenis DuitType
      expect(brandLabel(DuitType.harian), equals('MyDuitGweh (Harian)'));
      expect(brandLabel(DuitType.saldo), equals('MyDuitGweh (Saldo)'));
      expect(brandLabel(DuitType.tabungan), equals('MyDuitGweh (Tabungan)'));
      expect(brandLabel(DuitType.pencapaian), equals('MyDuitGweh (Pencapaian)'));
      expect(brandLabel('semua'), equals('MyDuitGweh (Semua)'));
      expect(brandLabel(null), equals('MyDuitGweh (Semua)'));

      expect(duitShortName(DuitType.harian), equals('Harian'));
      expect(duitShortName(DuitType.saldo), equals('Saldo'));
      expect(duitShortName(DuitType.tabungan), equals('Tabungan'));
      expect(duitShortName(DuitType.pencapaian), equals('Pencapaian'));
      expect(duitShortName('semua'), equals('Semua'));
      expect(duitShortName(null), equals('Semua'));
    });

    test('(4) CurrencyInputFormatter membatasi maksimal 15 digit', () {
      final formatter = CurrencyInputFormatter();

      // Input 18 digit
      const inputVal = TextEditingValue(text: '123456789012345678');
      final formatted = formatter.formatEditUpdate(
        TextEditingValue.empty,
        inputVal,
      );

      // Angka harus dipotong menjadi 15 digit ('123456789012345')
      final cleanParsed = CurrencyInputFormatter.parseRupiah(formatted.text);
      expect(cleanParsed.toString().length, equals(15));
      expect(cleanParsed, equals(123456789012345));
    });

    testWidgets('(5) GlobalErrorView menampilkan teks ramah "Terjadi kendala"', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GlobalErrorView(
            details: FlutterErrorDetails(exception: Exception('Uji error')),
          ),
        ),
      );

      expect(find.text('Terjadi kendala'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.text('Kembali ke Beranda'), findsOneWidget);
    });

    testWidgets('(6) Duit Pencapaian kosong: EmptyState muncul & tombol Reset Progres menampilkan snackbar peringatan', (tester) async {
      final goalRepo = InMemorySavingGoalRepository(seedInitialData: false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savingGoalRepositoryProvider.overrideWithValue(goalRepo),
          ],
          child: const MaterialApp(
            home: GoalsLedgerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Menampilkan teks EmptyState sesuai Tahap 13 B.2
      expect(
        find.text('Belum ada pencapaian. Tentukan apa yang ingin kamu capai!'),
        findsOneWidget,
      );
      expect(find.text('Buat Pencapaian Pertama'), findsOneWidget);

      // 2. Ketuk ikon Reset Progres di AppBar saat belum ada target
      final resetProgresBtn = find.byTooltip('Reset Progres');
      expect(resetProgresBtn, findsOneWidget);

      await tester.tap(resetProgresBtn);
      await tester.pump();

      // Memastikan muncul snackbar pengingat sesuai Tahap 13 B.4
      expect(
        find.text('Buat pencapaian dulu sebelum menyetor'),
        findsOneWidget,
      );
    });
  });
}
