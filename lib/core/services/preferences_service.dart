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

  bool get isBalanceHidden => _prefs.getBool(_keyIsBalanceHidden) ?? false;

  Future<bool> setIsBalanceHidden(bool value) {
    return _prefs.setBool(_keyIsBalanceHidden, value);
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
