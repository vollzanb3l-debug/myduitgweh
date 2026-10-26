import 'dart:async';

import '../database/initial_data.dart';
import '../models/category_model.dart';

abstract class CategoryRepository {
  Future<int> insertCategory(CategoryItem category);
  Future<bool> updateCategory(CategoryItem category);
  Future<int> deleteCategory(int id);
  Future<CategoryItem?> getCategoryById(int id);
  Future<List<CategoryItem>> getAllCategories();
  Future<List<CategoryItem>> getCategoriesByType(String type);
  Stream<List<CategoryItem>> watchAllCategories();
  Stream<List<CategoryItem>> watchCategoriesByType(String type);
}

class InMemoryCategoryRepository implements CategoryRepository {
  final Map<int, CategoryItem> _categories = {};
  final StreamController<List<CategoryItem>> _controller =
      StreamController<List<CategoryItem>>.broadcast();
  int _nextId = 1;

  InMemoryCategoryRepository({bool seedInitialData = true}) {
    if (seedInitialData) {
      for (final c in InitialData.defaultCategories) {
        _categories[c.id ?? _nextId] = c;
        if ((c.id ?? 0) >= _nextId) {
          _nextId = (c.id ?? 0) + 1;
        }
      }
      _notify();
    }
  }

  void _notify() {
    _controller.add(List.unmodifiable(_categories.values));
  }

  @override
  Future<int> insertCategory(CategoryItem category) async {
    final id = category.id ?? _nextId++;
    final newCat = category.copyWith(id: id);
    _categories[id] = newCat;
    _notify();
    return id;
  }

  @override
  Future<bool> updateCategory(CategoryItem category) async {
    if (category.id == null || !_categories.containsKey(category.id)) {
      return false;
    }
    _categories[category.id!] = category;
    _notify();
    return true;
  }

  @override
  Future<int> deleteCategory(int id) async {
    final removed = _categories.remove(id);
    if (removed != null) {
      _notify();
      return 1;
    }
    return 0;
  }

  @override
  Future<CategoryItem?> getCategoryById(int id) async {
    return _categories[id];
  }

  @override
  Future<List<CategoryItem>> getAllCategories() async {
    return _categories.values.toList();
  }

  @override
  Future<List<CategoryItem>> getCategoriesByType(String type) async {
    return _categories.values.where((c) => c.type == type).toList();
  }

  @override
  Stream<List<CategoryItem>> watchAllCategories() {
    return _controller.stream;
  }

  @override
  Stream<List<CategoryItem>> watchCategoriesByType(String type) {
    return _controller.stream.map(
      (list) => list.where((c) => c.type == type).toList(),
    );
  }

  void dispose() {
    _controller.close();
  }
}
