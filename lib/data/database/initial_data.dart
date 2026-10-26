import '../models/category_model.dart';
import '../models/wallet_model.dart';

class InitialData {
  InitialData._();

  static List<WalletItem> get defaultWallets => [
    WalletItem(
      id: 1,
      name: 'Uang Harian',
      type: 'daily',
      initialBalance: 0,
      createdAt: DateTime(2026, 1, 1),
    ),
    WalletItem(
      id: 2,
      name: 'Saldo',
      type: 'balance',
      initialBalance: 0,
      createdAt: DateTime(2026, 1, 1),
    ),
    WalletItem(
      id: 3,
      name: 'Tabungan',
      type: 'saving',
      initialBalance: 0,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  static List<CategoryItem> get defaultExpenseCategories => [
    const CategoryItem(
      id: 1,
      name: 'Makan',
      icon: 'restaurant_rounded',
      colorHex: '#FF7675',
      type: 'expense',
    ),
    const CategoryItem(
      id: 2,
      name: 'Transport',
      icon: 'directions_car_rounded',
      colorHex: '#74B9FF',
      type: 'expense',
    ),
    const CategoryItem(
      id: 3,
      name: 'Belanja',
      icon: 'shopping_bag_rounded',
      colorHex: '#FDCB6E',
      type: 'expense',
    ),
    const CategoryItem(
      id: 4,
      name: 'Tagihan',
      icon: 'receipt_long_rounded',
      colorHex: '#E17055',
      type: 'expense',
    ),
    const CategoryItem(
      id: 5,
      name: 'Hiburan',
      icon: 'sports_esports_rounded',
      colorHex: '#A29BFE',
      type: 'expense',
    ),
    const CategoryItem(
      id: 6,
      name: 'Kesehatan',
      icon: 'medical_services_rounded',
      colorHex: '#00B894',
      type: 'expense',
    ),
    const CategoryItem(
      id: 7,
      name: 'Lainnya',
      icon: 'more_horiz_rounded',
      colorHex: '#B2BEC3',
      type: 'expense',
    ),
  ];

  static List<CategoryItem> get defaultIncomeCategories => [
    const CategoryItem(
      id: 8,
      name: 'Gaji',
      icon: 'payments_rounded',
      colorHex: '#00B894',
      type: 'income',
    ),
    const CategoryItem(
      id: 9,
      name: 'Uang Saku',
      icon: 'savings_rounded',
      colorHex: '#F9A826',
      type: 'income',
    ),
    const CategoryItem(
      id: 10,
      name: 'Bonus',
      icon: 'card_giftcard_rounded',
      colorHex: '#6C5CE7',
      type: 'income',
    ),
    const CategoryItem(
      id: 11,
      name: 'Lainnya',
      icon: 'more_horiz_rounded',
      colorHex: '#B2BEC3',
      type: 'income',
    ),
  ];

  static List<CategoryItem> get defaultCategories => [
    ...defaultExpenseCategories,
    ...defaultIncomeCategories,
  ];
}
