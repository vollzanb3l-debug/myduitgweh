import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/providers/app_state_provider.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

class MyDuitGwehApp extends ConsumerStatefulWidget {
  const MyDuitGwehApp({super.key});

  @override
  ConsumerState<MyDuitGwehApp> createState() => _MyDuitGwehAppState();
}

class _MyDuitGwehAppState extends ConsumerState<MyDuitGwehApp>
    with WidgetsBindingObserver {
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedAt != null) {
        final elapsed = DateTime.now().difference(_pausedAt!);
        final isPinEnabled = ref.read(isPinEnabledProvider);
        if (isPinEnabled && elapsed >= const Duration(minutes: 1)) {
          ref.read(isAppLockedProvider.notifier).state = true;
          final currentLocation =
              appRouter.routerDelegate.currentConfiguration.uri.toString();
          if (currentLocation != '/kunci-pin' && currentLocation != '/') {
            appRouter.push('/kunci-pin');
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDuit = ref.watch(activeDuitProvider);
    final accentColor = activeDuit.color;
    final themeModeStr = ref.watch(themeModeProvider);
    final themeMode = switch (themeModeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(accentColor),
      darkTheme: AppTheme.darkTheme(accentColor),
      themeMode: themeMode,
      builder: (context, child) {
        return AnimatedTheme(
          duration: const Duration(milliseconds: 300),
          data: Theme.of(context),
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: appRouter,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
