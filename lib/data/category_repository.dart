import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hee_no_tane_app/models/category.dart';

class CategoryRepository {
  static const _assetPath = 'data/categories.json';

  Future<List<Category>> loadCategories() async {
    final jsonString = await rootBundle.loadString(_assetPath);
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((j) => Category.fromJson(j as Map<String, dynamic>)).toList();
  }
}
