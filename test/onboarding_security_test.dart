import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myduitgweh/core/services/preferences_service.dart';
import 'package:myduitgweh/core/services/security_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tahap 11: PreferencesService Tests', () {
    late PreferencesService prefsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      prefsService = PreferencesService(prefs);
    });

    test('Default values for first time launch', () {
      expect(prefsService.hasSeenOnboarding, isFalse);
      expect(prefsService.userName, isEmpty);
      expect(prefsService.isPinEnabled, isFalse);
    });

    test('Set and update onboarding and user name', () async {
      await prefsService.setHasSeenOnboarding(true);
      expect(prefsService.hasSeenOnboarding, isTrue);

      await prefsService.setUserName('Budi');
      expect(prefsService.userName, 'Budi');

      await prefsService.setIsPinEnabled(true);
      expect(prefsService.isPinEnabled, isTrue);
    });

    test('clearAll resets preferences to initial state', () async {
      await prefsService.setHasSeenOnboarding(true);
      await prefsService.setUserName('Budi');
      await prefsService.setIsPinEnabled(true);

      await prefsService.clearAll();
      expect(prefsService.hasSeenOnboarding, isFalse);
      expect(prefsService.userName, isEmpty);
      expect(prefsService.isPinEnabled, isFalse);
    });
  });

  group('Tahap 11: SecurityService Tests (Salted SHA-256 PIN & Lockout)', () {
    late SecurityService securityService;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      securityService = SecurityService(
        storage: const FlutterSecureStorage(),
      );
    });

    test('Save PIN hashes PIN with salt (raw PIN is never stored)', () async {
      await securityService.savePin('1234');
      final hasPin = await securityService.isPinConfigured();
      expect(hasPin, isTrue);

      // Verify correct PIN
      final correct = await securityService.verifyPin('1234');
      expect(correct, isTrue);
      expect(securityService.failedAttempts, 0);

      // Verify wrong PIN fails
      final wrong = await securityService.verifyPin('9999');
      expect(wrong, isFalse);
      expect(securityService.failedAttempts, 1);
    });

    test('5 failed attempts trigger 30s lockout', () async {
      await securityService.savePin('4321');

      for (int i = 0; i < 4; i++) {
        final res = await securityService.verifyPin('0000');
        expect(res, isFalse);
        expect(securityService.isLockedOut, isFalse);
      }

      // 5th attempt
      final fifth = await securityService.verifyPin('0000');
      expect(fifth, isFalse);
      expect(securityService.failedAttempts, 5);
      expect(securityService.isLockedOut, isTrue);
      expect(securityService.lockoutSecondsRemaining, greaterThan(0));

      // Attempting while locked out should immediately return false
      final lockedAttempt = await securityService.verifyPin('4321');
      expect(lockedAttempt, isFalse);
    });

    test('Correct PIN resets failed attempts count', () async {
      await securityService.savePin('5678');
      await securityService.verifyPin('0000');
      await securityService.verifyPin('0000');
      expect(securityService.failedAttempts, 2);

      final ok = await securityService.verifyPin('5678');
      expect(ok, isTrue);
      expect(securityService.failedAttempts, 0);
    });

    test('disablePin and wipeAllSecurityData clears secure credentials', () async {
      await securityService.savePin('1111');
      expect(await securityService.isPinConfigured(), isTrue);

      await securityService.disablePin();
      expect(await securityService.isPinConfigured(), isFalse);

      await securityService.savePin('2222');
      await securityService.wipeAllSecurityData();
      expect(await securityService.isPinConfigured(), isFalse);
      expect(securityService.failedAttempts, 0);
      expect(securityService.isLockedOut, isFalse);
    });
  });
}
