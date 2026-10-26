import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/splash_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/transactions/presentation/history_screen.dart';
import '../../features/transactions/presentation/add_transaction_screen.dart';
import '../../features/statistics/presentation/statistics_screen.dart';
import '../../features/wallets/presentation/wallets_screen.dart';
import '../widgets/main_scaffold.dart';

import '../../data/models/transaction_model.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
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
  ],
);
