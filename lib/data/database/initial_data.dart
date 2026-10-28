import '../models/category_model.dart';
import '../models/saving_goal_model.dart';
import '../models/wallet_model.dart';

class InitialData {
  InitialData._();

  static List<WalletItem> get defaultWallets => [
    WalletItem(
      id: 1,
      name: 'Uang Utama',
      type: 'daily',
      ledger: 'daily',
      initialBalance: 0,
      createdAt: DateTime(2026, 1, 1),
    ),
    WalletItem(
      id: 2,
      name: 'Duit Saldo',
      type: 'balance',
      ledger: 'balance',
      initialBalance: 0,
      createdAt: DateTime(2026, 1, 1),
    ),
    WalletItem(
      id: 3,
      name: 'Duit Tabungan',
      type: 'saving',
      ledger: 'saving',
      initialBalance: 0,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  static List<CategoryItem> get defaultDailyExpenseCategories => [
    const CategoryItem(
      id: 1,
      name: 'Makan & Minum',
      icon: 'restaurant_rounded',
      colorHex: '#FF7675',
      type: 'expense',
      ledger: 'daily',
    ),
    const CategoryItem(
      id: 2,
      name: 'Transport',
      icon: 'directions_car_rounded',
      colorHex: '#74B9FF',
      type: 'expense',
      ledger: 'daily',
    ),
    const CategoryItem(
      id: 3,
      name: 'Jajan',
      icon: 'fastfood_rounded',
      colorHex: '#FFA502',
      type: 'expense',
      ledger: 'daily',
    ),
    const CategoryItem(
      id: 4,
      name: 'Pulsa & Paket Data',
      icon: 'phone_android_rounded',
      colorHex: '#00CEC9',
      type: 'expense',
      ledger: 'daily',
    ),
    const CategoryItem(
      id: 5,
      name: 'Belanja',
      icon: 'shopping_bag_rounded',
      colorHex: '#FDCB6E',
      type: 'expense',
      ledger: 'daily',
    ),
    const CategoryItem(
      id: 6,
      name: 'Hiburan',
      icon: 'sports_esports_rounded',
      colorHex: '#A29BFE',
      type: 'expense',
      ledger: 'daily',
    ),
    const CategoryItem(
      id: 7,
      name: 'Pendidikan',
      icon: 'school_rounded',
      colorHex: '#0984E3',
      type: 'expense',
      ledger: 'daily',
    ),
    const CategoryItem(
      id: 8,
      name: 'Kesehatan',
      icon: 'medical_services_rounded',
      colorHex: '#00B894',
      type: 'expense',
      ledger: 'daily',
    ),
    const CategoryItem(
      id: 9,
      name: 'Lainnya',
      icon: 'more_horiz_rounded',
      colorHex: '#B2BEC3',
      type: 'expense',
      ledger: 'daily',
    ),
  ];

  static List<CategoryItem> get defaultDailyIncomeCategories => [
    const CategoryItem(
      id: 10,
      name: 'Uang Saku',
      icon: 'savings_rounded',
      colorHex: '#F9A826',
      type: 'income',
      ledger: 'daily',
    ),
    const CategoryItem(
      id: 11,
      name: 'Gaji',
      icon: 'payments_rounded',
      colorHex: '#00B894',
      type: 'income',
      ledger: 'daily',
    ),
    const CategoryItem(
      id: 12,
      name: 'Bonus',
      icon: 'card_giftcard_rounded',
      colorHex: '#6C5CE7',
      type: 'income',
      ledger: 'daily',
    ),
    const CategoryItem(
      id: 13,
      name: 'Hadiah',
      icon: 'redeem_rounded',
      colorHex: '#FD79A8',
      type: 'income',
      ledger: 'daily',
    ),
    const CategoryItem(
      id: 14,
      name: 'Lainnya',
      icon: 'more_horiz_rounded',
      colorHex: '#B2BEC3',
      type: 'income',
      ledger: 'daily',
    ),
  ];

  static List<CategoryItem> get defaultBalanceIncomeCategories => [
    const CategoryItem(
      id: 15,
      name: 'Tunai',
      icon: 'payments_rounded',
      colorHex: '#2ED573',
      type: 'income',
      ledger: 'balance',
    ),
    const CategoryItem(
      id: 16,
      name: 'Bank',
      icon: 'account_balance_rounded',
      colorHex: '#1E90FF',
      type: 'income',
      ledger: 'balance',
    ),
    const CategoryItem(
      id: 17,
      name: 'E-Wallet',
      icon: 'account_balance_wallet_rounded',
      colorHex: '#9B59B6',
      type: 'income',
      ledger: 'balance',
    ),
    const CategoryItem(
      id: 18,
      name: 'Transfer Masuk',
      icon: 'arrow_downward_rounded',
      colorHex: '#00B894',
      type: 'income',
      ledger: 'balance',
    ),
    const CategoryItem(
      id: 19,
      name: 'Isi Saldo',
      icon: 'add_circle_outline_rounded',
      colorHex: '#F39C12',
      type: 'income',
      ledger: 'balance',
    ),
    const CategoryItem(
      id: 20,
      name: 'Gaji',
      icon: 'monetization_on_rounded',
      colorHex: '#27AE60',
      type: 'income',
      ledger: 'balance',
    ),
    const CategoryItem(
      id: 21,
      name: 'Lainnya',
      icon: 'more_horiz_rounded',
      colorHex: '#B2BEC3',
      type: 'income',
      ledger: 'balance',
    ),
  ];

  static List<CategoryItem> get defaultBalanceExpenseCategories => [
    const CategoryItem(
      id: 22,
      name: 'Tunai',
      icon: 'payments_rounded',
      colorHex: '#FF7675',
      type: 'expense',
      ledger: 'balance',
    ),
    const CategoryItem(
      id: 23,
      name: 'Bank',
      icon: 'account_balance_rounded',
      colorHex: '#3498DB',
      type: 'expense',
      ledger: 'balance',
    ),
    const CategoryItem(
      id: 24,
      name: 'E-Wallet',
      icon: 'account_balance_wallet_rounded',
      colorHex: '#E056FD',
      type: 'expense',
      ledger: 'balance',
    ),
    const CategoryItem(
      id: 25,
      name: 'Tagihan',
      icon: 'receipt_long_rounded',
      colorHex: '#E17055',
      type: 'expense',
      ledger: 'balance',
    ),
    const CategoryItem(
      id: 26,
      name: 'Transfer Keluar',
      icon: 'arrow_upward_rounded',
      colorHex: '#FF4757',
      type: 'expense',
      ledger: 'balance',
    ),
    const CategoryItem(
      id: 27,
      name: 'Biaya Admin',
      icon: 'credit_card_rounded',
      colorHex: '#747D8C',
      type: 'expense',
      ledger: 'balance',
    ),
    const CategoryItem(
      id: 28,
      name: 'Lainnya',
      icon: 'more_horiz_rounded',
      colorHex: '#B2BEC3',
      type: 'expense',
      ledger: 'balance',
    ),
  ];

  static List<CategoryItem> get defaultSavingCategories => [
    const CategoryItem(
      id: 29,
      name: 'Setoran',
      icon: 'add_circle_outline_rounded',
      colorHex: '#00B894',
      type: 'income',
      ledger: 'saving',
    ),
    const CategoryItem(
      id: 30,
      name: 'Bunga/Bonus',
      icon: 'trending_up_rounded',
      colorHex: '#F9A826',
      type: 'income',
      ledger: 'saving',
    ),
    const CategoryItem(
      id: 31,
      name: 'Lainnya',
      icon: 'more_horiz_rounded',
      colorHex: '#B2BEC3',
      type: 'income',
      ledger: 'saving',
    ),
    const CategoryItem(
      id: 32,
      name: 'Penarikan',
      icon: 'remove_circle_outline_rounded',
      colorHex: '#FF7675',
      type: 'expense',
      ledger: 'saving',
    ),
    const CategoryItem(
      id: 33,
      name: 'Lainnya',
      icon: 'more_horiz_rounded',
      colorHex: '#B2BEC3',
      type: 'expense',
      ledger: 'saving',
    ),
  ];

  static List<CategoryItem> get defaultAdjustmentCategories => [
    const CategoryItem(
      id: 34,
      name: 'Tambah Saldo',
      icon: 'add_circle_rounded',
      colorHex: '#2ECC71',
      type: 'income',
      ledger: 'all',
    ),
    const CategoryItem(
      id: 35,
      name: 'Penyesuaian Saldo',
      icon: 'tune_rounded',
      colorHex: '#3B82F6',
      type: 'income',
      ledger: 'all',
    ),
    const CategoryItem(
      id: 36,
      name: 'Penyesuaian Saldo',
      icon: 'tune_rounded',
      colorHex: '#EB5757',
      type: 'expense',
      ledger: 'all',
    ),
  ];

  static List<CategoryItem> get defaultCategories => [
    ...defaultDailyExpenseCategories,
    ...defaultDailyIncomeCategories,
    ...defaultBalanceIncomeCategories,
    ...defaultBalanceExpenseCategories,
    ...defaultSavingCategories,
    ...defaultAdjustmentCategories,
  ];

  static List<SavingGoalItem> get defaultSavingGoals => const [];
}

