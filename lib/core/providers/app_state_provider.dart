import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/duit_type.dart';
import '../services/preferences_service.dart';
import '../services/security_service.dart';

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError('preferencesServiceProvider must be overridden in ProviderScope');
});

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService();
});

class UserNameNotifier extends StateNotifier<String> {
  final PreferencesService _prefs;

  UserNameNotifier(this._prefs) : super(_prefs.userName);

  Future<void> updateName(String newName) async {
    await _prefs.setUserName(newName);
    state = newName;
  }
}

final userNameProvider = StateNotifierProvider<UserNameNotifier, String>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return UserNameNotifier(prefs);
});

class PinEnabledNotifier extends StateNotifier<bool> {
  final PreferencesService _prefs;

  PinEnabledNotifier(this._prefs) : super(_prefs.isPinEnabled);

  Future<void> setEnabled(bool value) async {
    await _prefs.setIsPinEnabled(value);
    state = value;
  }
}

final isPinEnabledProvider = StateNotifierProvider<PinEnabledNotifier, bool>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return PinEnabledNotifier(prefs);
});

/// Penanda apakah aplikasi sedang dalam kondisi terkunci PIN saat ini
final isAppLockedProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  // Jika PIN aktif, secara default aplikasi dalam keadaan terkunci
  return prefs.isPinEnabled;
});

class ActiveDuitNotifier extends StateNotifier<DuitSelection> {
  final PreferencesService _prefs;

  ActiveDuitNotifier(this._prefs)
      : super(DuitSelection.fromString(_prefs.activeDuitKey));

  Future<void> select(dynamic choice) async {
    DuitSelection selection;
    if (choice == null || choice == 'semua' || choice == DuitSelection.semua) {
      selection = DuitSelection.semua;
    } else if (choice is DuitType) {
      selection = DuitSelection(choice);
    } else if (choice is DuitSelection) {
      selection = choice;
    } else if (choice is String) {
      selection = DuitSelection.fromString(choice);
    } else {
      selection = DuitSelection.harian;
    }

    state = selection;
    await _prefs.setActiveDuitKey(
      selection.isSemua ? 'semua' : selection.type!.name,
    );
  }
}

final activeDuitProvider =
    StateNotifierProvider<ActiveDuitNotifier, DuitSelection>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return ActiveDuitNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<String> {
  final PreferencesService _prefs;

  ThemeModeNotifier(this._prefs) : super(_prefs.themeMode);

  Future<void> setThemeMode(String mode) async {
    await _prefs.setThemeMode(mode);
    state = mode;
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, String>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return ThemeModeNotifier(prefs);
});
