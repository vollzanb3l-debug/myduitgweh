import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myduitgweh/core/providers/app_state_provider.dart';
import 'package:myduitgweh/core/services/preferences_service.dart';
import 'package:myduitgweh/core/services/security_service.dart';
import 'package:myduitgweh/features/onboarding/presentation/onboarding_guide_screen.dart';
import 'package:myduitgweh/features/onboarding/presentation/pin_choice_screen.dart';
import 'package:myduitgweh/features/onboarding/presentation/welcome_name_screen.dart';
import 'package:myduitgweh/features/security/presentation/create_pin_screen.dart';
import 'package:myduitgweh/features/security/presentation/pin_lock_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tahap 11: Onboarding UI & Flow Widget Tests', () {
    late PreferencesService prefsService;
    late SecurityService securityService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      prefsService = PreferencesService(prefs);
      securityService = SecurityService(storage: const FlutterSecureStorage());
    });

    testWidgets('1. Layar Panduan Onboarding menampilkan 5 slide dan navigasi', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/panduan',
        routes: [
          GoRoute(
            path: '/panduan',
            builder: (_, __) => const OnboardingGuideScreen(),
          ),
          GoRoute(
            path: '/nama',
            builder: (_, __) => const Scaffold(body: Text('Layar Nama Mock')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(prefsService),
            securityServiceProvider.overrideWithValue(securityService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Slide 1: Duit Utama
      expect(find.text('Duit Utama'), findsOneWidget);
      expect(find.text('Lewati'), findsOneWidget);

      // Swipe to slide 2: Duit Saldo
      await tester.drag(find.byType(PageView), const Offset(-450, 0));
      await tester.pumpAndSettle();
      expect(find.text('Duit Saldo'), findsOneWidget);

      // Swipe to slide 3: Duit Tabungan
      await tester.drag(find.byType(PageView), const Offset(-450, 0));
      await tester.pumpAndSettle();
      expect(find.text('Duit Tabungan'), findsOneWidget);

      // Swipe to slide 4: Duit Pencapaian
      await tester.drag(find.byType(PageView), const Offset(-450, 0));
      await tester.pumpAndSettle();
      expect(find.text('Duit Pencapaian'), findsOneWidget);

      // Swipe to slide 5: Statistik & Analisis (Halaman Terakhir -> tombol Mulai)
      await tester.drag(find.byType(PageView), const Offset(-450, 0));
      await tester.pumpAndSettle();
      expect(find.text('Statistik & Analisis'), findsOneWidget);
      expect(find.text('Mulai'), findsOneWidget);

      // Ketuk Mulai navigasi ke /nama
      await tester.tap(find.text('Mulai'));
      await tester.pumpAndSettle();
      expect(find.text('Layar Nama Mock'), findsOneWidget);
    });

    testWidgets('2. Layar Selamat Datang: validasi nama minimal 2 karakter', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/nama',
        routes: [
          GoRoute(
            path: '/nama',
            builder: (_, __) => const WelcomeNameScreen(),
          ),
          GoRoute(
            path: '/pilihan-pin',
            builder: (_, __) => const Scaffold(body: Text('Layar PIN Mock')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(prefsService),
            securityServiceProvider.overrideWithValue(securityService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      expect(find.text('Selamat Datang di MyDuitGweh!'), findsOneWidget);
      expect(find.text('Nama Panggilan'), findsOneWidget);

      // Coba klik Lanjut dengan nama kurang dari 2 karakter
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'A');
      await tester.pump();

      await tester.tap(find.text('Lanjut'));
      await tester.pump();
      expect(find.text('Nama wajib diisi minimal 2 karakter ya'), findsOneWidget);

      // Masukkan nama valid dan klik lanjut
      await tester.enterText(textField, 'Budi');
      await tester.pump();
      expect(find.text('Nama wajib diisi minimal 2 karakter ya'), findsNothing);

      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Layar PIN Mock'), findsOneWidget);
      expect(prefsService.userName, 'Budi');
    });

    testWidgets('3. Layar Pilihan PIN menampilkan Buat PIN dan Lewati dulu', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/pilihan-pin',
        routes: [
          GoRoute(
            path: '/pilihan-pin',
            builder: (_, __) => const PinChoiceScreen(),
          ),
          GoRoute(
            path: '/buat-pin',
            builder: (_, __) => const Scaffold(body: Text('Layar Buat PIN Mock')),
          ),
          GoRoute(
            path: '/beranda',
            builder: (_, __) => const Scaffold(body: Text('Layar Beranda Mock')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(prefsService),
            securityServiceProvider.overrideWithValue(securityService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      expect(find.text('Pakai PIN?'), findsOneWidget);
      expect(find.text('Buat PIN'), findsOneWidget);
      expect(find.text('Lewati dulu'), findsOneWidget);

      // Ketuk Lewati dulu menuju beranda dan set onboarding selesai
      await tester.tap(find.text('Lewati dulu'));
      await tester.pumpAndSettle();
      expect(find.text('Layar Beranda Mock'), findsOneWidget);
      expect(prefsService.hasSeenOnboarding, isTrue);
      expect(prefsService.isPinEnabled, isFalse);
    });

    testWidgets('4. Layar Buat PIN: keypad angka dan konfirmasi PIN', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/buat-pin',
        routes: [
          GoRoute(
            path: '/buat-pin',
            builder: (_, __) => const CreatePinScreen(isChangingPin: false),
          ),
          GoRoute(
            path: '/pertanyaan-pemulihan',
            builder: (_, __) => const Scaffold(body: Text('Layar Pertanyaan Pemulihan Mock')),
          ),
          GoRoute(
            path: '/beranda',
            builder: (_, __) => const Scaffold(body: Text('Layar Beranda Mock')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(prefsService),
            securityServiceProvider.overrideWithValue(securityService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      expect(find.text('Masukkan 4 Digit PIN'), findsOneWidget);

      // Ketik 1, 2, 3, 4
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Sekarang masuk ke tahap konfirmasi
      expect(find.text('Konfirmasi PIN Anda'), findsOneWidget);

      // Ketik PIN cocok: 1, 2, 3, 4
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();

      // Verifikasi PIN tersimpan di security service
      expect(await securityService.isPinConfigured(), isTrue);
      expect(await securityService.verifyPin('1234'), isTrue);
      expect(prefsService.isPinEnabled, isTrue);
      // Di Tahap 14, setelah PIN dibuat, langsung diarahkan ke layar Pertanyaan Pemulihan
      expect(find.text('Pertanyaan Pemulihan'), findsOneWidget);
    });

    testWidgets('5. Layar Kunci PIN: salah 5 kali kena blokir 30 detik & opsi Lupa PIN', (
      WidgetTester tester,
    ) async {
      // Simpan PIN awal
      await securityService.savePin('7890');
      await prefsService.setIsPinEnabled(true);
      await prefsService.setUserName('Budi');

      final router = GoRouter(
        initialLocation: '/kunci-pin',
        routes: [
          GoRoute(
            path: '/kunci-pin',
            builder: (_, __) => const PinLockScreen(),
          ),
          GoRoute(
            path: '/panduan',
            builder: (_, __) => const Scaffold(body: Text('Layar Panduan Mock')),
          ),
          GoRoute(
            path: '/beranda',
            builder: (_, __) => const Scaffold(body: Text('Layar Beranda Mock')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(prefsService),
            securityServiceProvider.overrideWithValue(securityService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      expect(find.text('Halo, Budi!'), findsOneWidget);
      expect(find.text('Masukkan 4 digit PIN untuk membuka aplikasi'), findsOneWidget);
      expect(find.text('Lupa PIN?'), findsOneWidget);

      // Masukkan PIN salah (1111) sebanyak 5 kali
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('1'));
        await tester.pump();
        await tester.tap(find.text('1'));
        await tester.pump();
        await tester.tap(find.text('1'));
        await tester.pump();
        await tester.tap(find.text('1'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
      }

      // Verifikasi pesan terblokir
      expect(find.textContaining('Terlalu banyak percobaan'), findsOneWidget);
      expect(securityService.isLockedOut, isTrue);

      // Ketuk "Lupa PIN?" menampilkan alur reset jika pertanyaan belum diatur
      await tester.ensureVisible(find.text('Lupa PIN?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lupa PIN?'));
      await tester.pumpAndSettle();

      expect(find.text('Hapus Semua Data?'), findsOneWidget);
      expect(
        find.textContaining('SEMUA DATA AKAN HILANG PERMANEN DAN TIDAK BISA DIKEMBALIKAN'),
        findsOneWidget,
      );
      expect(find.text('Lanjut'), findsOneWidget);

      // Ketuk Lanjut untuk memunculkan langkah 2 konfirmasi ketik "HAPUS"
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();

      expect(find.text('Ketik "HAPUS" untuk Konfirmasi'), findsOneWidget);
      expect(find.text('HAPUS SEMUA DATA'), findsOneWidget);

      // Masukkan teks HAPUS ke kolom konfirmasi
      await tester.enterText(find.byType(TextField), 'HAPUS');
      await tester.pumpAndSettle();

      // Ketuk HAPUS SEMUA DATA
      await tester.tap(find.text('HAPUS SEMUA DATA'));
      await tester.pumpAndSettle();

      // Memverifikasi data terhapus dan navigasi ke /panduan
      expect(await securityService.isPinConfigured(), isFalse);
      expect(prefsService.hasSeenOnboarding, isFalse);
      expect(find.text('Layar Panduan Mock'), findsOneWidget);
    });
  });
}
