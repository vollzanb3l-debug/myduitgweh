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

String normalizeDuitKey(dynamic duit) {
  if (duit == null) return 'utama';
  if (duit is DuitType) {
    return duit == DuitType.harian ? 'utama' : duit.name;
  }
  if (duit is DuitSelection) {
    if (duit.isSemua) return 'semua';
    return duit.type == DuitType.harian ? 'utama' : (duit.type?.name ?? 'utama');
  }
  if (duit is String) {
    final lower = duit.toLowerCase().trim();
    if (lower == 'harian' || lower == 'daily') return 'utama';
    if (lower == 'saving') return 'tabungan';
    if (lower == 'goal') return 'pencapaian';
    return lower;
  }
  return 'utama';
}

class DuitHideBalanceNotifier extends StateNotifier<Map<String, bool>> {
  final PreferencesService _prefs;

  DuitHideBalanceNotifier(this._prefs) : super(_prefs.getAllDuitHideBalance());

  bool isHidden(String duitKey) {
    final key = normalizeDuitKey(duitKey);
    return state[key] ?? false;
  }

  Future<void> toggle(String duitKey) async {
    final key = normalizeDuitKey(duitKey);
    final current = state[key] ?? false;
    final next = !current;
    await _prefs.setHideBalanceForDuit(key, next);
    state = {...state, key: next};
  }

  Future<void> setHidden(String duitKey, bool hidden) async {
    final key = normalizeDuitKey(duitKey);
    await _prefs.setHideBalanceForDuit(key, hidden);
    state = {...state, key: hidden};
  }

  Future<void> setAll(bool hidden) async {
    for (final k in ['utama', 'saldo', 'tabungan', 'pencapaian', 'semua']) {
      await _prefs.setHideBalanceForDuit(k, hidden);
    }
    state = {
      'utama': hidden,
      'saldo': hidden,
      'tabungan': hidden,
      'pencapaian': hidden,
      'semua': hidden,
    };
  }

  void refreshFromPrefs() {
    state = _prefs.getAllDuitHideBalance();
  }
}

final duitHideBalanceProvider =
    StateNotifierProvider<DuitHideBalanceNotifier, Map<String, bool>>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return DuitHideBalanceNotifier(prefs);
});

final isDuitHiddenProvider = Provider.family<bool, String>((ref, duitKey) {
  final hideMap = ref.watch(duitHideBalanceProvider);
  final key = normalizeDuitKey(duitKey);
  return hideMap[key] ?? false;
});

class HideBalanceNotifier extends StateNotifier<bool> {
  final Ref _ref;
  final PreferencesService _prefs;

  HideBalanceNotifier(this._ref, this._prefs)
      : super(_prefs.isBalanceHidden) {
    _ref.listen<Map<String, bool>>(duitHideBalanceProvider, (prev, next) {
      final active = _ref.read(activeDuitProvider);
      final key = active.isSemua
          ? 'semua'
          : (active.type == DuitType.harian ? 'utama' : active.type?.name ?? 'utama');
      final val = next[key] ?? _prefs.isBalanceHidden;
      if (mounted && state != val) {
        state = val;
      }
    });

    _ref.listen<DuitSelection>(activeDuitProvider, (prev, next) {
      final key = next.isSemua
          ? 'semua'
          : (next.type == DuitType.harian ? 'utama' : next.type?.name ?? 'utama');
      final hideMap = _ref.read(duitHideBalanceProvider);
      final val = hideMap[key] ?? _prefs.isBalanceHidden;
      if (mounted && state != val) {
        state = val;
      }
    });

    final active = _ref.read(activeDuitProvider);
    final key = active.isSemua
        ? 'semua'
        : (active.type == DuitType.harian ? 'utama' : active.type?.name ?? 'utama');
    final hideMap = _ref.read(duitHideBalanceProvider);
    state = hideMap[key] ?? _prefs.isBalanceHidden;
  }

  Future<void> toggle([String? specificKey]) async {
    final active = _ref.read(activeDuitProvider);
    final key = specificKey ??
        (active.isSemua
            ? 'semua'
            : (active.type == DuitType.harian ? 'utama' : active.type?.name ?? 'utama'));
    await _ref.read(duitHideBalanceProvider.notifier).toggle(key);
    final isHid = _ref.read(duitHideBalanceProvider.notifier).isHidden(key);
    if (mounted) {
      state = isHid;
    }
    await _prefs.setIsBalanceHidden(isHid);
  }

  Future<void> setHidden(bool value, [String? specificKey]) async {
    if (specificKey != null) {
      await _ref.read(duitHideBalanceProvider.notifier).setHidden(specificKey, value);
    } else {
      final active = _ref.read(activeDuitProvider);
      final key = active.isSemua
          ? 'semua'
          : (active.type == DuitType.harian ? 'utama' : active.type?.name ?? 'utama');
      await _ref.read(duitHideBalanceProvider.notifier).setHidden(key, value);
    }
    if (mounted) {
      state = value;
    }
    await _prefs.setIsBalanceHidden(value);
  }
}

final hideBalanceProvider =
    StateNotifierProvider<HideBalanceNotifier, bool>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return HideBalanceNotifier(ref, prefs);
});

class HistoryFilterNotifier extends StateNotifier<String> {
  final PreferencesService _prefs;

  HistoryFilterNotifier(this._prefs) : super(_prefs.historyFilter);

  Future<void> setFilter(String filter) async {
    await _prefs.setHistoryFilter(filter);
    state = filter;
  }
}

final historyFilterProvider =
    StateNotifierProvider<HistoryFilterNotifier, String>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return HistoryFilterNotifier(prefs);
});
