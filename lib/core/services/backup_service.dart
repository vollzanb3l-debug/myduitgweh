import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/category_model.dart';
import '../../data/models/saving_goal_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/saving_goal_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../data/repositories/providers.dart';
import '../providers/app_state_provider.dart';
import 'preferences_service.dart';

/// Service untuk mencadangkan (Backup) dan memulihkan (Restore) data aplikasi
/// menggunakan Storage Access Framework (SAF) dan Share tanpa memerlukan izin MANAGE_EXTERNAL_STORAGE.
class BackupService {
  final WalletRepository _walletRepo;
  final CategoryRepository _catRepo;
  final SavingGoalRepository _goalRepo;
  final TransactionRepository _txRepo;
  final PreferencesService _prefs;

  BackupService({
    required WalletRepository walletRepo,
    required CategoryRepository categoryRepo,
    required SavingGoalRepository goalRepo,
    required TransactionRepository txRepo,
    required PreferencesService prefs,
  })  : _walletRepo = walletRepo,
        _catRepo = categoryRepo,
        _goalRepo = goalRepo,
        _txRepo = txRepo,
        _prefs = prefs;

  factory BackupService.fromRef(WidgetRef ref) {
    return BackupService(
      walletRepo: ref.read(walletRepositoryProvider),
      categoryRepo: ref.read(categoryRepositoryProvider),
      goalRepo: ref.read(savingGoalRepositoryProvider),
      txRepo: ref.read(transactionRepositoryProvider),
      prefs: ref.read(preferencesServiceProvider),
    );
  }

  /// Ekspor seluruh data lokal ke dalam teks JSON
  Future<String> createBackupJson() async {
    final wallets = await _walletRepo.getAllWallets();
    final categories = await _catRepo.getAllCategories();
    final transactions = await _txRepo.getAllTransactions();
    final goals = await _goalRepo.getAllSavingGoals();

    final backupMap = {
      'appName': 'MyDuitGweh',
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'preferences': {
        'userName': _prefs.userName,
        'themeMode': _prefs.themeMode,
        'activeDuitKey': _prefs.activeDuitKey,
      },
      'wallets': wallets.map((w) => w.toMap()).toList(),
      'categories': categories.map((c) => c.toMap()).toList(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'savingGoals': goals.map((g) => g.toMap()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(backupMap);
  }

  /// Simpan berkas cadangan ke lokasi sementara dan buka pemilih simpan / bagikan (SAF)
  Future<bool> exportBackupFile() async {
    final jsonContent = await createBackupJson();
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'MyDuitGweh_Backup_$timestamp.json';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(jsonContent, flush: true);

    final xFile = XFile(file.path, mimeType: 'application/json', name: fileName);
    final result = await Share.shareXFiles(
      [xFile],
      subject: 'Cadangan Data MyDuitGweh',
      text: 'Berkas cadangan data keuangan MyDuitGweh ($fileName)',
    );

    return result.status == ShareResultStatus.success ||
        result.status == ShareResultStatus.dismissed;
  }

  /// Memilih berkas .json melalui FilePicker SAF
  Future<String?> pickBackupFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (file == null) {
      return null;
    }

    try {
      return await file.xFile.readAsString();
    } catch (_) {
      if (file.path != null) {
        return File(file.path!).readAsString();
      }
      return null;
    }
  }

  /// Validasi struktur berkas cadangan JSON sebelum diterapkan
  bool validateBackup(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) return false;
      if (decoded['appName'] != 'MyDuitGweh') return false;
      if (!decoded.containsKey('wallets') ||
          !decoded.containsKey('categories') ||
          !decoded.containsKey('transactions')) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Terapkan data dari berkas cadangan (menimpa data saat ini)
  Future<bool> restoreBackup(String jsonStr) async {
    if (!validateBackup(jsonStr)) return false;

    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // 1. Kosongkan data lama
      _txRepo.clearAll();
      _goalRepo.clearAll();
      _walletRepo.resetToInitial();
      _catRepo.resetToInitial();

      // 2. Pulihkan wallets
      final rawWallets = data['wallets'] as List? ?? [];
      for (final item in rawWallets) {
        if (item is Map<String, dynamic>) {
          await _walletRepo.insertWallet(WalletItem.fromMap(item));
        }
      }

      // 3. Pulihkan categories
      final rawCats = data['categories'] as List? ?? [];
      for (final item in rawCats) {
        if (item is Map<String, dynamic>) {
          await _catRepo.insertCategory(CategoryItem.fromMap(item));
        }
      }

      // 4. Pulihkan savingGoals
      final rawGoals = data['savingGoals'] as List? ?? [];
      for (final item in rawGoals) {
        if (item is Map<String, dynamic>) {
          await _goalRepo.insertSavingGoal(SavingGoalItem.fromMap(item));
        }
      }

      // 5. Pulihkan transactions
      final rawTxs = data['transactions'] as List? ?? [];
      for (final item in rawTxs) {
        if (item is Map<String, dynamic>) {
          await _txRepo.insertTransaction(TransactionItem.fromMap(item));
        }
      }

      // 6. Pulihkan preferensi pengguna
      final prefsMap = data['preferences'] as Map<String, dynamic>?;
      if (prefsMap != null) {
        if (prefsMap['userName'] is String) {
          await _prefs.setUserName(prefsMap['userName'] as String);
        }
        if (prefsMap['themeMode'] is String) {
          await _prefs.setThemeMode(prefsMap['themeMode'] as String);
        }
        if (prefsMap['activeDuitKey'] is String) {
          await _prefs.setActiveDuitKey(prefsMap['activeDuitKey'] as String);
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}
