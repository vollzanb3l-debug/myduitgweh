import '../../core/constants/category_constants.dart';
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

  static CategoryItem _fromDef(CategoryDefinition def) => CategoryItem(
        id: def.id,
        name: def.name,
        icon: def.icon,
        colorHex: def.colorHex,
        type: def.type,
        ledger: def.ledger,
      );

  static List<CategoryItem> get defaultDailyExpenseCategories =>
      CategoryConstants.defaultDailyExpenses.map(_fromDef).toList();

  static List<CategoryItem> get defaultDailyIncomeCategories =>
      CategoryConstants.defaultDailyIncomes.map(_fromDef).toList();

  static List<CategoryItem> get defaultBalanceIncomeCategories =>
      CategoryConstants.defaultBalanceIncomes.map(_fromDef).toList();

  static List<CategoryItem> get defaultBalanceExpenseCategories =>
      CategoryConstants.defaultBalanceExpenses.map(_fromDef).toList();

  static List<CategoryItem> get defaultSavingCategories =>
      CategoryConstants.defaultSavingCategories.map(_fromDef).toList();

  static List<CategoryItem> get defaultAdjustmentCategories =>
      CategoryConstants.defaultAdjustmentCategories.map(_fromDef).toList();

  static List<CategoryItem> get defaultCategories =>
      CategoryConstants.allDefaultCategories.map(_fromDef).toList();

  static List<SavingGoalItem> get defaultSavingGoals => const [];
}
