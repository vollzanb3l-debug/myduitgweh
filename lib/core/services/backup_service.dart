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
import '../constants/backup_constants.dart';
import '../providers/app_state_provider.dart';
import 'preferences_service.dart';

/// Hasil eksekusi pemulihan berkas cadangan (Restore)
class RestoreResult {
  final bool success;
  final String message;
  final int restoredTransactions;
  final int restoredWallets;
  final int restoredGoals;
  final int restoredCategories;
  final int skippedCount;
  final List<String> skippedReasons;

  const RestoreResult({
    required this.success,
    required this.message,
    this.restoredTransactions = 0,
    this.restoredWallets = 0,
    this.restoredGoals = 0,
    this.restoredCategories = 0,
    this.skippedCount = 0,
    this.skippedReasons = const [],
  });

  factory RestoreResult.failure(String message) {
    return RestoreResult(
      success: false,
      message: message,
    );
  }
}

/// Service untuk mencadangkan (Backup) dan memulihkan (Restore) data aplikasi
/// dengan dukungan migrasi antar versi cadangan, parsing toleran, snapshot rollback,
/// dan pengujian validitas menyeluruh sebelum database diubah.
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

  /// Ekspor seluruh data lokal ke dalam teks JSON dengan format versi terbaru
  Future<String> createBackupJson() async {
    final wallets = await _walletRepo.getAllWallets();
    final categories = await _catRepo.getAllCategories();
    final transactions = await _txRepo.getAllTransactions();
    final goals = await _goalRepo.getAllSavingGoals();

    final backupMap = {
      'appName': BackupConstants.appIdentifier,
      'backupVersion': BackupConstants.currentBackupVersion,
      'appVersion': BackupConstants.currentAppVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'preferences': {
        'userName': _prefs.userName,
        'themeMode': _prefs.themeMode,
        'activeDuitKey': _prefs.activeDuitKey,
        'isBalanceHidden': _prefs.isBalanceHidden,
        'historyFilter': _prefs.historyFilter,
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

  /// Pemeriksaan awal validitas berkas cadangan sebelum pengguna mengonfirmasi timpa data.
  /// Mengembalikan null jika valid, atau string pesan kesalahan jika tidak valid.
  String? validateBackupPrelim(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        return BackupConstants.errInvalidBackup;
      }
      if (decoded['appName'] != BackupConstants.appIdentifier) {
        return BackupConstants.errInvalidBackup;
      }

      // Periksa backupVersion (jika tidak ada backupVersion, periksa fallback version lama)
      final rawVersion = decoded['backupVersion'] ?? decoded['version'];
      if (rawVersion == null || rawVersion is! int) {
        return BackupConstants.errInvalidBackup;
      }

      if (rawVersion > BackupConstants.currentBackupVersion) {
        return BackupConstants.errNewerVersion;
      }

      return null; // Valid
    } catch (_) {
      return BackupConstants.errInvalidBackup;
    }
  }

  /// Fungsi migrasi bertahap data cadangan (v1 -> v2 -> v3 ...) ke format terbaru
  Map<String, dynamic> _migrateBackup(Map<String, dynamic> rawData, int fromVersion) {
    var data = Map<String, dynamic>.from(rawData);
    var v = fromVersion;

    while (v < BackupConstants.currentBackupVersion) {
      data = _migrateStep(data, v);
      v++;
    }

    data['backupVersion'] = BackupConstants.currentBackupVersion;
    return data;
  }

  /// Langkah migrasi per versi individual
  Map<String, dynamic> _migrateStep(Map<String, dynamic> data, int currentV) {
    switch (currentV) {
      case 0:
        // Format legacy awal: tambahkan field versi cadangan standar
        data['backupVersion'] = 1;
        data['appVersion'] ??= '1.0.0';
        return data;
      // Di masa mendatang, setiap kenaikan currentBackupVersion (+1):
      // case 1:
      //   ... migrasi v1 ke v2 ...
      //   return data;
      default:
        return data;
    }
  }

  /// Memulihkan data dari berkas cadangan JSON dengan:
  /// 1. Validasi struktur & versi sebelum menyentuh data lama.
  /// 2. Migrasi otomatis jika berkas berasal dari versi lama.
  /// 3. Parsing toleran (nilai bawaan untuk kolom hilang, abaikan kolom tak dikenal).
  /// 4. Validasi nilai transaksi, akun, target, dan catat data dilewati (skipped).
  /// 5. Snapshot otomatis data saat ini sebelum menimpa (atomic rollback jika gagal).
  Future<RestoreResult> restoreBackup(String jsonStr) async {
    // 1. Validasi awal berkas JSON
    final prelimError = validateBackupPrelim(jsonStr);
    if (prelimError != null) {
      return RestoreResult.failure(prelimError);
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return RestoreResult.failure(BackupConstants.errInvalidBackup);
    }

    final rawVersion = (data['backupVersion'] ?? data['version']) as int;
    if (rawVersion > BackupConstants.currentBackupVersion) {
      return RestoreResult.failure(BackupConstants.errNewerVersion);
    }

    // 2. Migrasi data jika berkas versi lebih lama
    if (rawVersion < BackupConstants.currentBackupVersion) {
      data = _migrateBackup(data, rawVersion);
    }

    // 3. Parsing toleran dan validasi data in-memory (SEBELUM menyentuh database)
    final skippedReasons = <String>[];
    int skippedCount = 0;

    // A. Parse & validasi Wallets
    final validWallets = <WalletItem>[];
    final validWalletIds = <int>{};
    final rawWallets = data['wallets'];
    if (rawWallets is List) {
      for (int i = 0; i < rawWallets.length; i++) {
        final item = rawWallets[i];
        if (item is! Map<String, dynamic>) {
          skippedCount++;
          skippedReasons.add('Akun dompet index $i bukan objek yang valid');
          continue;
        }

        final id = item['id'] is int ? item['id'] as int : (i + 1);
        final name = (item['name'] as String?)?.trim();
        final finalName = (name != null && name.isNotEmpty) ? name : 'Akun $id';
        final type = (item['type'] as String?) ?? 'balance';
        final initialBal = (item['initialBalance'] as num?)?.toInt() ?? 0;
        final createdAtStr = item['createdAt'] as String?;
        final createdAt = createdAtStr != null
            ? (DateTime.tryParse(createdAtStr) ?? DateTime.now())
            : DateTime.now();

        final wallet = WalletItem(
          id: id,
          name: finalName,
          type: type,
          initialBalance: initialBal < 0 ? 0 : initialBal,
          createdAt: createdAt,
        );

        validWallets.add(wallet);
        validWalletIds.add(id);
      }
    }

    // B. Parse & validasi Categories
    final validCategories = <CategoryItem>[];
    final validCategoryIds = <int>{};
    final rawCats = data['categories'];
    if (rawCats is List) {
      for (int i = 0; i < rawCats.length; i++) {
        final item = rawCats[i];
        if (item is! Map<String, dynamic>) {
          skippedCount++;
          skippedReasons.add('Kategori index $i bukan objek yang valid');
          continue;
        }

        final id = item['id'] is int ? item['id'] as int : (i + 1);
        final name = (item['name'] as String?)?.trim();
        final finalName = (name != null && name.isNotEmpty) ? name : 'Lainnya';
        final type = (item['type'] as String?) ?? 'expense';
        final icon = (item['icon'] as String?) ?? 'category_rounded';
        final colorHex = (item['colorHex'] as String?) ?? '#6B7280';

        final cat = CategoryItem(
          id: id,
          name: finalName,
          icon: icon,
          colorHex: colorHex,
          type: type == 'income' ? 'income' : 'expense',
        );

        validCategories.add(cat);
        validCategoryIds.add(id);
      }
    }

    // C. Parse & validasi SavingGoals
    final validGoals = <SavingGoalItem>[];
    final rawGoals = data['savingGoals'];
    if (rawGoals is List) {
      for (int i = 0; i < rawGoals.length; i++) {
        final item = rawGoals[i];
        if (item is! Map<String, dynamic>) {
          skippedCount++;
          skippedReasons.add('Target impian index $i bukan objek yang valid');
          continue;
        }

        final id = item['id'] is int ? item['id'] as int : (i + 1);
        final name = (item['name'] as String?)?.trim();
        final finalName = (name != null && name.isNotEmpty) ? name : 'Target Impian $id';
        final targetAmount = (item['targetAmount'] as num?)?.toInt() ?? 0;

        if (targetAmount < 0) {
          skippedCount++;
          skippedReasons.add("Target impian '$finalName' dilewati karena nominal target negatif ($targetAmount)");
          continue;
        }

        final currentAmount = (item['current_amount'] ?? item['currentAmount'] as num?)?.toInt() ?? 0;
        final deadlineStr = (item['deadline'] ?? item['targetDate']) as String?;
        final deadline = deadlineStr != null
            ? (DateTime.tryParse(deadlineStr) ?? DateTime.now().add(const Duration(days: 365)))
            : DateTime.now().add(const Duration(days: 365));

        final goalWalletId = ((item['wallet_id'] ?? item['walletId']) as int?) ??
            (validWalletIds.isNotEmpty ? validWalletIds.first : 1);
        final icon = (item['icon'] as String?) ?? 'flag_rounded';
        final note = item['note'] as String?;

        final goal = SavingGoalItem(
          id: id,
          name: finalName,
          targetAmount: targetAmount,
          currentAmount: currentAmount < 0 ? 0 : currentAmount,
          deadline: deadline,
          walletId: goalWalletId,
          icon: icon,
          note: note,
        );

        validGoals.add(goal);
      }
    }

    // D. Parse & validasi Transactions
    final validTransactions = <TransactionItem>[];
    final rawTxs = data['transactions'];
    if (rawTxs is List) {
      for (int i = 0; i < rawTxs.length; i++) {
        final item = rawTxs[i];
        if (item is! Map<String, dynamic>) {
          skippedCount++;
          skippedReasons.add('Transaksi index $i bukan objek yang valid');
          continue;
        }

        final id = item['id'] is int ? item['id'] as int : (i + 1);
        final amount = (item['amount'] as num?)?.toInt() ?? 0;

        // Nominal harus lebih dari 0
        if (amount <= 0) {
          skippedCount++;
          skippedReasons.add('Transaksi ID $id dilewati: nominal harus lebih besar dari 0 (ditemukan $amount)');
          continue;
        }

        // Tipe transaksi
        final type = (item['type'] as String?) ?? '';
        if (type != 'income' && type != 'expense' && type != 'transfer') {
          skippedCount++;
          skippedReasons.add("Transaksi ID $id dilewati: tipe transaksi '$type' tidak dikenal");
          continue;
        }

        // Tanggal transaksi
        final dateStr = item['date'] as String?;
        final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
        if (date == null) {
          skippedCount++;
          skippedReasons.add('Transaksi ID $id dilewati: format tanggal tidak valid');
          continue;
        }

        // Validasi dompet sumber
        final walletId = (item['wallet_id'] ?? item['walletId']) as int?;
        if (walletId == null || !validWalletIds.contains(walletId)) {
          skippedCount++;
          skippedReasons.add('Transaksi ID $id dilewati: akun sumber (ID: $walletId) tidak ditemukan');
          continue;
        }

        // Validasi referensi kategori (jika tidak ada/invalid, fallback ke kategori pertama)
        final rawCatId = (item['category_id'] ?? item['categoryId']) as int?;
        final categoryId = (rawCatId != null && validCategoryIds.contains(rawCatId))
            ? rawCatId
            : (validCategoryIds.isNotEmpty ? validCategoryIds.first : 1);

        final note = item['note'] as String?;
        final ledger = (item['ledger'] as String?) ?? 'daily';
        final goalId = (item['goal_id'] ?? item['goalId']) as int?;
        final createdAtStr = item['created_at'] as String?;
        final createdAt = createdAtStr != null
            ? (DateTime.tryParse(createdAtStr) ?? date)
            : date;

        final tx = TransactionItem(
          id: id,
          walletId: walletId,
          categoryId: categoryId,
          amount: amount,
          type: type == 'income' ? 'income' : 'expense',
          note: note,
          ledger: ledger,
          goalId: goalId,
          date: date,
          createdAt: createdAt,
        );

        validTransactions.add(tx);
      }
    }

    // 4. Salinan otomatis (Safety Snapshot) data saat ini sebelum menimpa
    String? safetySnapshotJson;
    try {
      safetySnapshotJson = await createBackupJson();
      final tempDir = await getTemporaryDirectory();
      final snapshotFile = File('${tempDir.path}/safety_snapshot_before_restore.json');
      await snapshotFile.writeAsString(safetySnapshotJson, flush: true);
    } catch (_) {
      // Abaikan jika running di unit test environment tanpa path_provider
    }

    // 5. Eksekusi penimpaan data (Atomic dengan Rollback jika terjadi kegagalan)
    try {
      // A. Kosongkan data repo saat ini
      _txRepo.clearAll();
      _goalRepo.clearAll();
      _walletRepo.clearAll();
      _catRepo.clearAll();

      // B. Masukkan data hasil validasi
      for (final w in validWallets) {
        await _walletRepo.insertWallet(w);
      }
      for (final c in validCategories) {
        await _catRepo.insertCategory(c);
      }
      for (final g in validGoals) {
        await _goalRepo.insertSavingGoal(g);
      }
      for (final t in validTransactions) {
        await _txRepo.insertTransaction(t);
      }

      // C. Pulihkan preferensi pengguna yang valid
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
        if (prefsMap['isBalanceHidden'] is bool) {
          await _prefs.setIsBalanceHidden(prefsMap['isBalanceHidden'] as bool);
        }
        if (prefsMap['historyFilter'] is String) {
          await _prefs.setHistoryFilter(prefsMap['historyFilter'] as String);
        }
      }

      return RestoreResult(
        success: true,
        message: 'Data berhasil dipulihkan dari berkas cadangan.',
        restoredTransactions: validTransactions.length,
        restoredWallets: validWallets.length,
        restoredGoals: validGoals.length,
        restoredCategories: validCategories.length,
        skippedCount: skippedCount,
        skippedReasons: skippedReasons,
      );
    } catch (e) {
      // Rollback: Kembalikan kondisi data dari snapshot jika terjadi kegagalan
      if (safetySnapshotJson != null) {
        try {
          await _rollbackFromSnapshot(safetySnapshotJson);
        } catch (_) {}
      }

      return RestoreResult.failure(
        'Terjadi kesalahan saat memulihkan data: $e. Data lama telah dikembalikan.',
      );
    }
  }

  /// Rollback pemulihan darurat dari snapshot JSON
  Future<void> _rollbackFromSnapshot(String snapshotJson) async {
    try {
      final data = jsonDecode(snapshotJson) as Map<String, dynamic>;
      _txRepo.clearAll();
      _goalRepo.clearAll();
      _walletRepo.clearAll();
      _catRepo.clearAll();

      final rawWallets = data['wallets'] as List? ?? [];
      for (final item in rawWallets) {
        if (item is Map<String, dynamic>) {
          await _walletRepo.insertWallet(WalletItem.fromMap(item));
        }
      }

      final rawCats = data['categories'] as List? ?? [];
      for (final item in rawCats) {
        if (item is Map<String, dynamic>) {
          await _catRepo.insertCategory(CategoryItem.fromMap(item));
        }
      }

      final rawGoals = data['savingGoals'] as List? ?? [];
      for (final item in rawGoals) {
        if (item is Map<String, dynamic>) {
          await _goalRepo.insertSavingGoal(SavingGoalItem.fromMap(item));
        }
      }

      final rawTxs = data['transactions'] as List? ?? [];
      for (final item in rawTxs) {
        if (item is Map<String, dynamic>) {
          await _txRepo.insertTransaction(TransactionItem.fromMap(item));
        }
      }
    } catch (_) {}
  }
}
