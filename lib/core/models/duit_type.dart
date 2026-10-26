import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_labels.dart';

/// 4 Jenis Duit utama dalam aplikasi MyDuitGweh
enum DuitType {
  harian,
  saldo,
  tabungan,
  pencapaian,
}

/// Mewakili pilihan duit aktif di aplikasi (bisa berupa salah satu DuitType atau "semua").
/// Mendukung perbandingan langsung dengan DuitType maupun string "semua".
class DuitSelection {
  final DuitType? type;

  const DuitSelection(this.type);

  static const DuitSelection semua = DuitSelection(null);
  static const DuitSelection harian = DuitSelection(DuitType.harian);
  static const DuitSelection saldo = DuitSelection(DuitType.saldo);
  static const DuitSelection tabungan = DuitSelection(DuitType.tabungan);
  static const DuitSelection pencapaian = DuitSelection(DuitType.pencapaian);

  bool get isSemua => type == null;
  bool get isHarian => type == DuitType.harian;
  bool get isSaldo => type == DuitType.saldo;
  bool get isTabungan => type == DuitType.tabungan;
  bool get isPencapaian => type == DuitType.pencapaian;

  String get label {
    switch (type) {
      case DuitType.harian:
        return AppLabels.duitHarian;
      case DuitType.saldo:
        return AppLabels.duitSaldo;
      case DuitType.tabungan:
        return AppLabels.duitTabungan;
      case DuitType.pencapaian:
        return AppLabels.duitPencapaian;
      case null:
        return AppLabels.semuaDuit;
    }
  }

  String get chipLabel {
    switch (type) {
      case DuitType.harian:
        return 'Harian';
      case DuitType.saldo:
        return 'Saldo';
      case DuitType.tabungan:
        return 'Tabungan';
      case DuitType.pencapaian:
        return 'Pencapaian';
      case null:
        return 'Semua';
    }
  }

  String? get ledgerKey {
    switch (type) {
      case DuitType.harian:
        return 'daily';
      case DuitType.saldo:
        return 'balance';
      case DuitType.tabungan:
        return 'saving';
      case DuitType.pencapaian:
        return 'goal';
      case null:
        return null;
    }
  }

  Color get color {
    switch (type) {
      case DuitType.harian:
        return AppColors.duitHarian;
      case DuitType.saldo:
        return AppColors.duitSaldo;
      case DuitType.tabungan:
        return AppColors.duitTabungan;
      case DuitType.pencapaian:
        return AppColors.duitPencapaian;
      case null:
        return AppColors.duitSemua;
    }
  }

  IconData get icon {
    switch (type) {
      case DuitType.harian:
        return Icons.shopping_basket_rounded;
      case DuitType.saldo:
        return Icons.account_balance_wallet_rounded;
      case DuitType.tabungan:
        return Icons.savings_rounded;
      case DuitType.pencapaian:
        return Icons.stars_rounded;
      case null:
        return Icons.all_inclusive_rounded;
    }
  }

  static DuitSelection fromLedger(String? ledger) => fromString(ledger);
  static DuitSelection fromType(DuitType? type) => DuitSelection(type);

  static DuitSelection fromString(String? key) {
    if (key == null || key == 'semua' || key == 'all') {
      return DuitSelection.semua;
    }
    switch (key.toLowerCase()) {
      case 'harian':
      case 'daily':
        return DuitSelection.harian;
      case 'saldo':
      case 'balance':
        return DuitSelection.saldo;
      case 'tabungan':
      case 'saving':
        return DuitSelection.tabungan;
      case 'pencapaian':
      case 'goal':
        return DuitSelection.pencapaian;
      default:
        return DuitSelection.harian;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is DuitSelection) return type == other.type;
    if (other is DuitType) return type == other;
    if (other is String) {
      if (other.toLowerCase() == 'semua' || other.toLowerCase() == 'all') {
        return isSemua;
      }
      return type?.name.toLowerCase() == other.toLowerCase();
    }
    return false;
  }

  @override
  int get hashCode => type.hashCode;

  @override
  String toString() => isSemua ? 'semua' : type!.name;
}
