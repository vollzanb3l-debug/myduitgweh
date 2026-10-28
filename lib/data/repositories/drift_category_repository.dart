import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/initial_data.dart';
import '../models/category_model.dart';
import 'category_repository.dart';

class DriftCategoryRepository implements CategoryRepository {
  final AppDatabase db;

  DriftCategoryRepository(this.db);

  CategoryItem _toItem(Category c) {
    return CategoryItem(
      id: c.id,
      name: c.name,
      icon: c.icon,
      colorHex: c.colorHex,
      type: c.type,
      ledger: c.ledger,
    );
  }

  @override
  Future<int> insertCategory(CategoryItem category) async {
    return await db.into(db.categories).insert(
          CategoriesCompanion(
            id: category.id != null
                ? Value(category.id!)
                : const Value.absent(),
            name: Value(category.name),
            icon: Value(category.icon),
            colorHex: Value(category.colorHex),
            type: Value(category.type),
            ledger: Value(category.ledger),
          ),
        );
  }

  @override
  Future<bool> updateCategory(CategoryItem category) async {
    if (category.id == null) return false;
    final count = await (db.update(db.categories)
          ..where((t) => t.id.equals(category.id!)))
        .write(
      CategoriesCompanion(
        name: Value(category.name),
        icon: Value(category.icon),
        colorHex: Value(category.colorHex),
        type: Value(category.type),
        ledger: Value(category.ledger),
      ),
    );
    return count > 0;
  }

  @override
  Future<int> deleteCategory(int id) async {
    return await (db.delete(db.categories)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<CategoryItem?> getCategoryById(int id) async {
    final row = await (db.select(db.categories)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _toItem(row) : null;
  }

  @override
  Future<List<CategoryItem>> getAllCategories() async {
    final rows = await db.select(db.categories).get();
    return rows.map(_toItem).toList();
  }

  @override
  Stream<List<CategoryItem>> watchAllCategories() {
    return db
        .select(db.categories)
        .watch()
        .map((rows) => rows.map(_toItem).toList());
  }

  @override
  Future<List<CategoryItem>> getCategoriesByLedger(String ledger,
      {String? type}) async {
    final query = db.select(db.categories)
      ..where((t) => t.ledger.equals(ledger));
    if (type != null) {
      query.where((t) => t.type.equals(type));
    }
    final rows = await query.get();
    return rows.map(_toItem).toList();
  }

  @override
  Stream<List<CategoryItem>> watchCategoriesByLedger(String ledger,
      {String? type}) {
    final query = db.select(db.categories)
      ..where((t) => t.ledger.equals(ledger));
    if (type != null) {
      query.where((t) => t.type.equals(type));
    }
    return query.watch().map((rows) => rows.map(_toItem).toList());
  }

  @override
  Stream<List<CategoryItem>> watchCategoriesByType(String type) {
    return (db.select(db.categories)..where((t) => t.type.equals(type)))
        .watch()
        .map((rows) => rows.map(_toItem).toList());
  }

  @override
  Future<List<CategoryItem>> getCategoriesByType(String type) async {
    final rows = await (db.select(db.categories)..where((t) => t.type.equals(type))).get();
    return rows.map(_toItem).toList();
  }

  @override
  void clearAll() {
    db.delete(db.categories).go();
  }

  @override
  void resetToInitial() async {
    await db.delete(db.categories).go();
    for (final c in InitialData.defaultCategories) {
      await insertCategory(c);
    }
  }
}
