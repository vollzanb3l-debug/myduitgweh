import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

import '../../data/models/transaction_model.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_guide_screen.dart';
import '../../features/onboarding/presentation/pin_choice_screen.dart';
import '../../features/onboarding/presentation/welcome_name_screen.dart';
import '../../features/savings/presentation/savings_screen.dart';
import '../../features/security/presentation/create_pin_screen.dart';
import '../../features/security/presentation/pin_lock_screen.dart';
import '../../features/settings/presentation/about_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/user_guide_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/statistics/presentation/statistics_screen.dart';
import '../../features/transactions/presentation/add_transaction_screen.dart';
import '../../features/transactions/presentation/history_screen.dart';
import '../../features/wallets/presentation/balance_ledger_screen.dart';
import '../../features/wallets/presentation/daily_ledger_screen.dart';
import '../../features/wallets/presentation/goals_ledger_screen.dart';
import '../../features/wallets/presentation/savings_ledger_screen.dart';
import '../../features/wallets/presentation/wallets_screen.dart';
import '../widgets/main_scaffold.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),

    // Alur Onboarding Pertama Kali
    GoRoute(
      path: '/panduan',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OnboardingGuideScreen(),
    ),
    GoRoute(
      path: '/nama',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const WelcomeNameScreen(),
    ),
    GoRoute(
      path: '/pilihan-pin',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PinChoiceScreen(),
    ),
    GoRoute(
      path: '/buat-pin',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreatePinScreen(),
    ),

    // Kunci Layar PIN
    GoRoute(
      path: '/kunci-pin',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PinLockScreen(),
    ),

    // Main App Shell
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/beranda',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const HomeScreen(),
            transitionDuration: const Duration(milliseconds: 200),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/riwayat',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const HistoryScreen(),
            transitionDuration: const Duration(milliseconds: 200),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/statistik',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const StatisticsScreen(),
            transitionDuration: const Duration(milliseconds: 200),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/dompet',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const WalletsScreen(),
            transitionDuration: const Duration(milliseconds: 200),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/tambah-transaksi',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final extra = state.extra;
        late final Widget screen;
        if (extra is TransactionItem) {
          screen = AddTransactionScreen(transactionToEdit: extra);
        } else if (extra is String) {
          screen = AddTransactionScreen(initialType: extra);
        } else {
          screen = const AddTransactionScreen();
        }

        return CustomTransitionPage(
          key: state.pageKey,
          child: screen,
          transitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(
                opacity: curved,
                child: child,
              ),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/catatan/harian',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DailyLedgerScreen(),
    ),
    GoRoute(
      path: '/duit/harian',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DailyLedgerScreen(),
    ),
    GoRoute(
      path: '/catatan/saldo',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BalanceLedgerScreen(),
    ),
    GoRoute(
      path: '/duit/saldo',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BalanceLedgerScreen(),
    ),
    GoRoute(
      path: '/catatan/tabungan',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SavingsLedgerScreen(),
    ),
    GoRoute(
      path: '/duit/tabungan',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SavingsLedgerScreen(),
    ),
    GoRoute(
      path: '/catatan/pencapaian',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GoalsLedgerScreen(),
    ),
    GoRoute(
      path: '/duit/pencapaian',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GoalsLedgerScreen(),
    ),
    GoRoute(
      path: '/pengaturan',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/panduan-penggunaan',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const UserGuideScreen(),
    ),
    GoRoute(
      path: '/tentang',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: '/tabungan',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SavingsScreen(),
    ),
  ],
  errorBuilder: (context, state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Halaman Tidak Ditemukan'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Halaman Tidak Ditemukan',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rute "${state.uri.path}" tidak tersedia atau telah dipindahkan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.darkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Kembali ke Beranda'),
                onPressed: () => context.go('/beranda'),
              ),
            ],
          ),
        ),
      ),
    );
  },
);

