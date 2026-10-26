import 'dart:async';
import '../database/initial_data.dart';
import '../models/saving_goal_model.dart';

abstract class SavingGoalRepository {
  Future<int> insertSavingGoal(SavingGoalItem savingGoal);
  Future<bool> updateSavingGoal(SavingGoalItem savingGoal);
  Future<int> deleteSavingGoal(int id);
  Future<SavingGoalItem?> getSavingGoalById(int id);
  Future<List<SavingGoalItem>> getAllSavingGoals();
  Stream<List<SavingGoalItem>> watchAllSavingGoals();

  /// Menambah setoran tabungan ke target tertentu
  Future<bool> addSavings({required int savingGoalId, required int amount});

  /// Mengembalikan jumlah terkumpul target ke Rp 0 (target tidak dihapus)
  Future<bool> resetProgress(int savingGoalId);
}

class InMemorySavingGoalRepository implements SavingGoalRepository {
  final Map<int, SavingGoalItem> _savingGoals = {};
  final StreamController<List<SavingGoalItem>> _controller =
      StreamController<List<SavingGoalItem>>.broadcast();
  int _nextId = 1;

  InMemorySavingGoalRepository({bool seedInitialData = false}) {
    if (seedInitialData) {
      for (final g in InitialData.defaultSavingGoals) {
        _savingGoals[g.id ?? _nextId] = g;
        if ((g.id ?? 0) >= _nextId) {
          _nextId = (g.id ?? 0) + 1;
        }
      }
      _notify();
    }
  }

  void _notify() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_savingGoals.values));
    }
  }

  @override
  Future<int> insertSavingGoal(SavingGoalItem savingGoal) async {
    final id = savingGoal.id ?? _nextId++;
    final newGoal = savingGoal.copyWith(id: id);
    _savingGoals[id] = newGoal;
    _notify();
    return id;
  }

  @override
  Future<bool> updateSavingGoal(SavingGoalItem savingGoal) async {
    if (savingGoal.id == null || !_savingGoals.containsKey(savingGoal.id)) {
      return false;
    }
    _savingGoals[savingGoal.id!] = savingGoal;
    _notify();
    return true;
  }

  @override
  Future<int> deleteSavingGoal(int id) async {
    final removed = _savingGoals.remove(id);
    if (removed != null) {
      _notify();
      return 1;
    }
    return 0;
  }

  @override
  Future<SavingGoalItem?> getSavingGoalById(int id) async {
    return _savingGoals[id];
  }

  @override
  Future<List<SavingGoalItem>> getAllSavingGoals() async {
    return _savingGoals.values.toList();
  }

  @override
  Stream<List<SavingGoalItem>> watchAllSavingGoals() async* {
    yield _savingGoals.values.toList();
    yield* _controller.stream;
  }

  @override
  Future<bool> addSavings({required int savingGoalId, required int amount}) async {
    final goal = _savingGoals[savingGoalId];
    if (goal == null) return false;

    final updated = goal.copyWith(
      currentAmount: goal.currentAmount + amount,
    );
    _savingGoals[savingGoalId] = updated;
    _notify();
    return true;
  }

  @override
  Future<bool> resetProgress(int savingGoalId) async {
    final goal = _savingGoals[savingGoalId];
    if (goal == null) return false;

    final updated = goal.copyWith(currentAmount: 0);
    _savingGoals[savingGoalId] = updated;
    _notify();
    return true;
  }

  void dispose() {
    _controller.close();
  }
}
