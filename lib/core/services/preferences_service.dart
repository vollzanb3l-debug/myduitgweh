import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String _keyUserName = 'user_name';
  static const String _keyIsPinEnabled = 'is_pin_enabled';
  static const String _keyActiveDuit = 'active_duit_type';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  bool get hasSeenOnboarding => _prefs.getBool(_keyHasSeenOnboarding) ?? false;

  Future<bool> setHasSeenOnboarding(bool value) {
    return _prefs.setBool(_keyHasSeenOnboarding, value);
  }

  String get userName => _prefs.getString(_keyUserName) ?? '';

  Future<bool> setUserName(String name) {
    return _prefs.setString(_keyUserName, name);
  }

  bool get isPinEnabled => _prefs.getBool(_keyIsPinEnabled) ?? false;

  Future<bool> setIsPinEnabled(bool value) {
    return _prefs.setBool(_keyIsPinEnabled, value);
  }

  /// Pilihan duit aktif terakhir. Default pertama kali: 'harian'.
  String get activeDuitKey => _prefs.getString(_keyActiveDuit) ?? 'harian';

  Future<bool> setActiveDuitKey(String value) {
    return _prefs.setString(_keyActiveDuit, value);
  }

  static const String _keyThemeMode = 'app_theme_mode';

  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'system';

  Future<bool> setThemeMode(String value) {
    return _prefs.setString(_keyThemeMode, value);
  }

  static const String _keyIsBalanceHidden = 'is_balance_hidden';
  static const String _keyHideBalanceUtama = 'hide_balance_utama';
  static const String _keyHideBalanceSaldo = 'hide_balance_saldo';
  static const String _keyHideBalanceTabungan = 'hide_balance_tabungan';
  static const String _keyHideBalancePencapaian = 'hide_balance_pencapaian';
  static const String _keyHideBalanceSemua = 'hide_balance_semua';

  String _duitToHideKey(String duitKey) {
    final lower = duitKey.toLowerCase();
    if (lower.contains('utama') || lower.contains('harian') || lower.contains('daily')) {
      return _keyHideBalanceUtama;
    }
    if (lower.contains('saldo') || lower.contains('balance')) {
      return _keyHideBalanceSaldo;
    }
    if (lower.contains('tabungan') || lower.contains('saving')) {
      return _keyHideBalanceTabungan;
    }
    if (lower.contains('pencapaian') || lower.contains('goal')) {
      return _keyHideBalancePencapaian;
    }
    return _keyHideBalanceSemua;
  }

  bool get isBalanceHidden => _prefs.getBool(_keyIsBalanceHidden) ?? false;

  Future<bool> setIsBalanceHidden(bool value) async {
    await setHideBalanceForDuit('utama', value);
    await setHideBalanceForDuit('saldo', value);
    await setHideBalanceForDuit('tabungan', value);
    await setHideBalanceForDuit('pencapaian', value);
    await setHideBalanceForDuit('semua', value);
    return _prefs.setBool(_keyIsBalanceHidden, value);
  }

  bool isBalanceHiddenForDuit(String duitKey) {
    final key = _duitToHideKey(duitKey);
    final val = _prefs.getBool(key);
    if (val != null) return val;
    return _prefs.getBool(_keyIsBalanceHidden) ?? false;
  }

  Future<bool> setHideBalanceForDuit(String duitKey, bool value) async {
    final key = _duitToHideKey(duitKey);
    await _prefs.setBool(key, value);
    return true;
  }

  Map<String, bool> getAllDuitHideBalance() {
    return {
      'utama': isBalanceHiddenForDuit('utama'),
      'saldo': isBalanceHiddenForDuit('saldo'),
      'tabungan': isBalanceHiddenForDuit('tabungan'),
      'pencapaian': isBalanceHiddenForDuit('pencapaian'),
      'semua': isBalanceHiddenForDuit('semua'),
    };
  }

  Future<void> migrateHideBalanceSettings() async {
    final oldGlobal = _prefs.getBool(_keyIsBalanceHidden);
    if (oldGlobal != null) {
      if (!_prefs.containsKey(_keyHideBalanceUtama)) await _prefs.setBool(_keyHideBalanceUtama, oldGlobal);
      if (!_prefs.containsKey(_keyHideBalanceSaldo)) await _prefs.setBool(_keyHideBalanceSaldo, oldGlobal);
      if (!_prefs.containsKey(_keyHideBalanceTabungan)) await _prefs.setBool(_keyHideBalanceTabungan, oldGlobal);
      if (!_prefs.containsKey(_keyHideBalancePencapaian)) await _prefs.setBool(_keyHideBalancePencapaian, oldGlobal);
      if (!_prefs.containsKey(_keyHideBalanceSemua)) await _prefs.setBool(_keyHideBalanceSemua, oldGlobal);
    }
  }

  static const String _keyHistoryFilter = 'history_active_filter';

  /// Default filter pertama kali: 'daily' (Harian).
  String get historyFilter => _prefs.getString(_keyHistoryFilter) ?? 'daily';

  Future<bool> setHistoryFilter(String value) {
    return _prefs.setString(_keyHistoryFilter, value);
  }

  Future<bool> clearAll() {
    return _prefs.clear();
  }
}
