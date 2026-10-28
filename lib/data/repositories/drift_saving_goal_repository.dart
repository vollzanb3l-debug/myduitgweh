import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/saving_goal_model.dart';
import 'saving_goal_repository.dart';

class DriftSavingGoalRepository implements SavingGoalRepository {
  final AppDatabase db;

  DriftSavingGoalRepository(this.db);

  SavingGoalItem _toItem(SavingGoal g) {
    return SavingGoalItem(
      id: g.id,
      name: g.name,
      targetAmount: g.targetAmount,
      currentAmount: g.currentAmount,
      deadline: g.deadline,
      icon: g.icon ?? 'flag_rounded',
      walletId: g.walletId,
      note: g.note,
    );
  }

  @override
  Future<int> insertSavingGoal(SavingGoalItem savingGoal) async {
    return await db.into(db.savingGoals).insert(
          SavingGoalsCompanion(
            id: savingGoal.id != null
                ? Value(savingGoal.id!)
                : const Value.absent(),
            name: Value(savingGoal.name),
            targetAmount: Value(savingGoal.targetAmount),
            currentAmount: Value(savingGoal.currentAmount),
            deadline: Value(savingGoal.deadline),
            icon: Value(savingGoal.icon),
            walletId: Value(savingGoal.walletId),
            note: Value(savingGoal.note),
          ),
        );
  }

  @override
  Future<bool> updateSavingGoal(SavingGoalItem savingGoal) async {
    if (savingGoal.id == null) return false;
    final count = await (db.update(db.savingGoals)
          ..where((t) => t.id.equals(savingGoal.id!)))
        .write(
      SavingGoalsCompanion(
        name: Value(savingGoal.name),
        targetAmount: Value(savingGoal.targetAmount),
        currentAmount: Value(savingGoal.currentAmount),
        deadline: Value(savingGoal.deadline),
        icon: Value(savingGoal.icon),
        walletId: Value(savingGoal.walletId),
        note: Value(savingGoal.note),
      ),
    );
    return count > 0;
  }

  @override
  Future<int> deleteSavingGoal(int id) async {
    return await (db.delete(db.savingGoals)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<SavingGoalItem?> getSavingGoalById(int id) async {
    final row = await (db.select(db.savingGoals)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _toItem(row) : null;
  }

  @override
  Future<List<SavingGoalItem>> getAllSavingGoals() async {
    final rows = await db.select(db.savingGoals).get();
    return rows.map(_toItem).toList();
  }

  @override
  Stream<List<SavingGoalItem>> watchAllSavingGoals() {
    return db
        .select(db.savingGoals)
        .watch()
        .map((rows) => rows.map(_toItem).toList());
  }

  @override
  Future<bool> addSavings(
      {required int savingGoalId, required int amount}) async {
    final goal = await getSavingGoalById(savingGoalId);
    if (goal == null) return false;

    final updated = goal.currentAmount + amount;
    final count = await (db.update(db.savingGoals)
          ..where((t) => t.id.equals(savingGoalId)))
        .write(
      SavingGoalsCompanion(
        currentAmount: Value(updated),
      ),
    );
    return count > 0;
  }

  @override
  Future<bool> resetProgress(int savingGoalId) async {
    final count = await (db.update(db.savingGoals)
          ..where((t) => t.id.equals(savingGoalId)))
        .write(
      const SavingGoalsCompanion(
        currentAmount: Value(0),
      ),
    );
    return count > 0;
  }

  @override
  void clearAll() {
    db.delete(db.savingGoals).go();
  }
}
