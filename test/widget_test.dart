import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myduitgweh/app.dart';

void main() {
  testWidgets('Aplikasi MyDuitGweh memuat splash screen awal', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyDuitGwehApp()));

    // Memverifikasi teks nama aplikasi pada Splash Screen
    expect(find.text('MyDuitGweh'), findsOneWidget);
    expect(find.text('Pencatat Keuangan Pribadi'), findsOneWidget);
  });
}
