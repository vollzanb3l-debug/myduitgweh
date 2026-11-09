import 'package:flutter/material.dart';

class CategoryDefinition {
  final int id;
  final String name;
  final String icon;
  final String colorHex;
  final String type; // 'income', 'expense'
  final String ledger; // 'daily', 'balance', 'saving', 'all'

  const CategoryDefinition({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.type,
    required this.ledger,
  });
}

class CategoryConstants {
  CategoryConstants._();

  // Palet warna cerah dan konsisten untuk kategori bawaan & kustom
  static const List<Color> vibrantPalette = [
    Color(0xFFF9A826), // Oranye hangat khas MyDuitGweh
    Color(0xFF00B894), // Hijau mint cerah
    Color(0xFF0984E3), // Biru laut
    Color(0xFF6C5CE7), // Ungu elektrik
    Color(0xFFFD79A8), // Merah muda
    Color(0xFFFF7675), // Coral merah lembut
    Color(0xFF00CEC9), // Cyan toska
    Color(0xFFFFA502), // Jingga emas
    Color(0xFFA29BFE), // Lavender pastel
    Color(0xFF2ED573), // Hijau zamrud
    Color(0xFF1E90FF), // Biru dodger
    Color(0xFFE056FD), // Magenta cerah
    Color(0xFFE17055), // Terakota
    Color(0xFF2ECC71), // Hijau daun
  ];

  static const List<String> vibrantPaletteHex = [
    '#F9A826',
    '#00B894',
    '#0984E3',
    '#6C5CE7',
    '#FD79A8',
    '#FF7675',
    '#00CEC9',
    '#FFA502',
    '#A29BFE',
    '#2ED573',
    '#1E90FF',
    '#E056FD',
    '#E17055',
    '#2ECC71',
  ];

  /// Menghasilkan warna fallback deterministik berdasarkan nama/id (tidak pernah abu-abu mati)
  static Color getFallbackColor(String name, {int? id}) {
    if (name.isEmpty) return vibrantPalette.first;
    final seed = id ?? name.codeUnits.fold<int>(0, (prev, curr) => prev + curr);
    final index = seed.abs() % vibrantPalette.length;
    return vibrantPalette[index];
  }

  /// Menghasilkan kode hex fallback deterministik berdasarkan nama/id
  static String getFallbackColorHex(String name, {int? id}) {
    if (name.isEmpty) return vibrantPaletteHex.first;
    final seed = id ?? name.codeUnits.fold<int>(0, (prev, curr) => prev + curr);
    final index = seed.abs() % vibrantPaletteHex.length;
    return vibrantPaletteHex[index];
  }

  // --- KATEGORI BAWAAN: DUIT UTAMA (DAILY) ---
  static const List<CategoryDefinition> defaultDailyExpenses = [
    CategoryDefinition(
      id: 1,
      name: 'Makan & Minum',
      icon: 'restaurant_rounded',
      colorHex: '#FF7675',
      type: 'expense',
      ledger: 'daily',
    ),
    CategoryDefinition(
      id: 2,
      name: 'Transport',
      icon: 'directions_car_rounded',
      colorHex: '#74B9FF',
      type: 'expense',
      ledger: 'daily',
    ),
    CategoryDefinition(
      id: 3,
      name: 'Jajan',
      icon: 'fastfood_rounded',
      colorHex: '#FFA502',
      type: 'expense',
      ledger: 'daily',
    ),
    CategoryDefinition(
      id: 4,
      name: 'Pulsa & Paket Data',
      icon: 'phone_android_rounded',
      colorHex: '#00CEC9',
      type: 'expense',
      ledger: 'daily',
    ),
    CategoryDefinition(
      id: 5,
      name: 'Belanja',
      icon: 'shopping_bag_rounded',
      colorHex: '#FDCB6E',
      type: 'expense',
      ledger: 'daily',
    ),
    CategoryDefinition(
      id: 6,
      name: 'Hiburan',
      icon: 'sports_esports_rounded',
      colorHex: '#A29BFE',
      type: 'expense',
      ledger: 'daily',
    ),
    CategoryDefinition(
      id: 7,
      name: 'Pendidikan',
      icon: 'school_rounded',
      colorHex: '#0984E3',
      type: 'expense',
      ledger: 'daily',
    ),
    CategoryDefinition(
      id: 8,
      name: 'Kesehatan',
      icon: 'medical_services_rounded',
      colorHex: '#00B894',
      type: 'expense',
      ledger: 'daily',
    ),
    CategoryDefinition(
      id: 9,
      name: 'Lainnya',
      icon: 'more_horiz_rounded',
      colorHex: '#B2BEC3',
      type: 'expense',
      ledger: 'daily',
    ),
  ];

  static const List<CategoryDefinition> defaultDailyIncomes = [
    CategoryDefinition(
      id: 10,
      name: 'Uang Saku',
      icon: 'savings_rounded',
      colorHex: '#F9A826',
      type: 'income',
      ledger: 'daily',
    ),
    CategoryDefinition(
      id: 11,
      name: 'Gaji',
      icon: 'payments_rounded',
      colorHex: '#00B894',
      type: 'income',
      ledger: 'daily',
    ),
    CategoryDefinition(
      id: 12,
      name: 'Bonus',
      icon: 'card_giftcard_rounded',
      colorHex: '#6C5CE7',
      type: 'income',
      ledger: 'daily',
    ),
    CategoryDefinition(
      id: 13,
      name: 'Hadiah',
      icon: 'redeem_rounded',
      colorHex: '#FD79A8',
      type: 'income',
      ledger: 'daily',
    ),
    CategoryDefinition(
      id: 14,
      name: 'Lainnya',
      icon: 'more_horiz_rounded',
      colorHex: '#B2BEC3',
      type: 'income',
      ledger: 'daily',
    ),
  ];

  // --- KATEGORI BAWAAN: DUIT SALDO (BALANCE) ---
  static const List<CategoryDefinition> defaultBalanceIncomes = [
    CategoryDefinition(
      id: 15,
      name: 'Tunai',
      icon: 'payments_rounded',
      colorHex: '#2ED573',
      type: 'income',
      ledger: 'balance',
    ),
    CategoryDefinition(
      id: 16,
      name: 'Bank',
      icon: 'account_balance_rounded',
      colorHex: '#1E90FF',
      type: 'income',
      ledger: 'balance',
    ),
    CategoryDefinition(
      id: 17,
      name: 'E-Wallet',
      icon: 'account_balance_wallet_rounded',
      colorHex: '#9B59B6',
      type: 'income',
      ledger: 'balance',
    ),
    CategoryDefinition(
      id: 18,
      name: 'Transfer Masuk',
      icon: 'arrow_downward_rounded',
      colorHex: '#00B894',
      type: 'income',
      ledger: 'balance',
    ),
    CategoryDefinition(
      id: 19,
      name: 'Isi Saldo',
      icon: 'add_circle_outline_rounded',
      colorHex: '#F39C12',
      type: 'income',
      ledger: 'balance',
    ),
    CategoryDefinition(
      id: 20,
      name: 'Gaji',
      icon: 'monetization_on_rounded',
      colorHex: '#27AE60',
      type: 'income',
      ledger: 'balance',
    ),
    CategoryDefinition(
      id: 21,
      name: 'Lainnya',
      icon: 'more_horiz_rounded',
      colorHex: '#B2BEC3',
      type: 'income',
      ledger: 'balance',
    ),
  ];

  static const List<CategoryDefinition> defaultBalanceExpenses = [
    CategoryDefinition(
      id: 22,
      name: 'Tunai',
      icon: 'payments_rounded',
      colorHex: '#FF7675',
      type: 'expense',
      ledger: 'balance',
    ),
    CategoryDefinition(
      id: 23,
      name: 'Bank',
      icon: 'account_balance_rounded',
      colorHex: '#3498DB',
      type: 'expense',
      ledger: 'balance',
    ),
    CategoryDefinition(
      id: 24,
      name: 'E-Wallet',
      icon: 'account_balance_wallet_rounded',
      colorHex: '#E056FD',
      type: 'expense',
      ledger: 'balance',
    ),
    CategoryDefinition(
      id: 25,
      name: 'Tagihan',
      icon: 'receipt_long_rounded',
      colorHex: '#E17055',
      type: 'expense',
      ledger: 'balance',
    ),
    CategoryDefinition(
      id: 26,
      name: 'Transfer Keluar',
      icon: 'arrow_upward_rounded',
      colorHex: '#FF4757',
      type: 'expense',
      ledger: 'balance',
    ),
    CategoryDefinition(
      id: 27,
      name: 'Biaya Admin',
      icon: 'credit_card_rounded',
      colorHex: '#747D8C',
      type: 'expense',
      ledger: 'balance',
    ),
    CategoryDefinition(
      id: 28,
      name: 'Lainnya',
      icon: 'more_horiz_rounded',
      colorHex: '#B2BEC3',
      type: 'expense',
      ledger: 'balance',
    ),
  ];

  // --- KATEGORI BAWAAN: DUIT TABUNGAN (SAVING) ---
  static const List<CategoryDefinition> defaultSavingCategories = [
    CategoryDefinition(
      id: 29,
      name: 'Setoran',
      icon: 'add_circle_outline_rounded',
      colorHex: '#00B894',
      type: 'income',
      ledger: 'saving',
    ),
    CategoryDefinition(
      id: 30,
      name: 'Bunga/Bonus',
      icon: 'trending_up_rounded',
      colorHex: '#F9A826',
      type: 'income',
      ledger: 'saving',
    ),
    CategoryDefinition(
      id: 31,
      name: 'Lainnya',
      icon: 'more_horiz_rounded',
      colorHex: '#B2BEC3',
      type: 'income',
      ledger: 'saving',
    ),
    CategoryDefinition(
      id: 32,
      name: 'Penarikan',
      icon: 'remove_circle_outline_rounded',
      colorHex: '#FF7675',
      type: 'expense',
      ledger: 'saving',
    ),
    CategoryDefinition(
      id: 33,
      name: 'Lainnya',
      icon: 'more_horiz_rounded',
      colorHex: '#B2BEC3',
      type: 'expense',
      ledger: 'saving',
    ),
  ];

  // --- KATEGORI PENYESUAIAN SALDO ---
  static const List<CategoryDefinition> defaultAdjustmentCategories = [
    CategoryDefinition(
      id: 34,
      name: 'Tambah Saldo',
      icon: 'add_circle_rounded',
      colorHex: '#2ECC71',
      type: 'income',
      ledger: 'all',
    ),
    CategoryDefinition(
      id: 35,
      name: 'Penyesuaian Saldo',
      icon: 'tune_rounded',
      colorHex: '#3B82F6',
      type: 'income',
      ledger: 'all',
    ),
    CategoryDefinition(
      id: 36,
      name: 'Penyesuaian Saldo',
      icon: 'tune_rounded',
      colorHex: '#EB5757',
      type: 'expense',
      ledger: 'all',
    ),
  ];

  static const List<CategoryDefinition> allDefaultCategories = [
    ...defaultDailyExpenses,
    ...defaultDailyIncomes,
    ...defaultBalanceIncomes,
    ...defaultBalanceExpenses,
    ...defaultSavingCategories,
    ...defaultAdjustmentCategories,
  ];
}

