import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myduitgweh/app.dart';
import 'package:myduitgweh/core/providers/app_state_provider.dart';
import 'package:myduitgweh/core/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Aplikasi MyDuitGweh memuat splash screen awal', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final prefsService = PreferencesService(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(prefsService),
        ],
        child: const MyDuitGwehApp(),
      ),
    );
    await tester.pump();

    // Memverifikasi teks nama aplikasi pada Splash Screen
    expect(find.text('MyDuitGweh'), findsOneWidget);
    expect(find.text('Pencatat Keuangan Pribadi'), findsOneWidget);
  });
}
