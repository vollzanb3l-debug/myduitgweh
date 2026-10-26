import 'package:drift/drift.dart';

class Wallets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get type => text()(); // 'daily', 'balance', 'saving'
  TextColumn get ledger => text().withDefault(const Constant('daily'))(); // 'daily', 'balance', 'saving'
  IntColumn get initialBalance => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get icon => text()();
  TextColumn get colorHex => text()();
  TextColumn get type => text()(); // 'income', 'expense'
  TextColumn get ledger => text().withDefault(const Constant('daily'))(); // 'daily', 'balance', 'saving'
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'income', 'expense'
  IntColumn get amount => integer()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get walletId => integer().references(Wallets, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get ledger => text().withDefault(const Constant('daily'))(); // 'daily', 'balance', 'saving', 'goal'
  IntColumn get goalId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class SavingGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get targetAmount => integer()();
  DateTimeColumn get deadline => dateTime().nullable()();
  TextColumn get icon => text().nullable()();
  IntColumn get walletId => integer().references(Wallets, #id)();
}
