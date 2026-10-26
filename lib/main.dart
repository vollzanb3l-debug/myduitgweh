import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/app_state_provider.dart';
import 'core/services/preferences_service.dart';
import 'core/widgets/global_error_view.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Flutter framework error handler (menangkap error render/widget)
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('[FlutterError] ${details.exceptionAsString()}');
    };

    // 2. Platform Dispatcher error handler (menangkap error async tak tertangani)
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('[PlatformDispatcherError] $error\n$stack');
      return true; // Mencegah crash native/aplikasi tertutup sendiri
    };

    // 3. Ganti layar merah error bawaan Flutter dengan tampilan ramah pengguna
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return GlobalErrorView(details: details);
    };

    final prefsService = await PreferencesService.create();

    runApp(
      ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(prefsService),
        ],
        child: const MyDuitGwehApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('[runZonedGuarded] Unhandled Error: $error\n$stack');
  });
}

