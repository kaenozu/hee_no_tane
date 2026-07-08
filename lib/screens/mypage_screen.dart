import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/data/user_repository.dart';
import 'package:hee_no_tane_app/models/category.dart';
import 'package:hee_no_tane_app/data/category_repository.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  late final UserRepository _userRepo;
  late final CategoryRepository _categoryRepo;

  int _streak = 0;
  List<Category> _categories = [];
  List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _userRepo = UserRepository();
    _categoryRepo = CategoryRepository();
    _loadData();
  }

  Future<void> _loadData() async {
    final streak = await _userRepo.getStreakCurrent();
    final categories = await _categoryRepo.loadCategories();
    final preferred = await _userRepo.getPreferredCategories();
    setState(() {
      _streak = streak;
      _categories = categories;
      _selectedCategories = preferred;
    });
  }

  Future<void> _toggleCategory(String slug) async {
    final updated = List<String>.from(_selectedCategories);
    if (updated.contains(slug)) {
      updated.remove(slug);
    } else {
      updated.add(slug);
    }
    await _userRepo.setPreferredCategories(updated);
    setState(() => _selectedCategories = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('マイページ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStreakCard(context),
          const SizedBox(height: 24),
          Text('興味のあるジャンル', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = _selectedCategories.contains(cat.slug);
              return FilterChip(
                label: Text(cat.name),
                selected: isSelected,
                onSelected: (selected) => _toggleCategory(cat.slug),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.local_fire_department, size: 40, color: Colors.orangeAccent),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_streak 日連続',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text('毎日へぇを読んでいると継続マークがつきます'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
