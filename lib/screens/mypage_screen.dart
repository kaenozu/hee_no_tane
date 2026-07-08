import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/data/user_repository.dart';
import 'package:hee_no_tane_app/models/category.dart';
import 'package:hee_no_tane_app/data/category_repository.dart';

final Map<String, IconData> _categoryIcons = {
  'daily_why': Icons.help_outline_rounded,
  'history_bite': Icons.history_rounded,
  'science_nearby': Icons.science_rounded,
  'food_origin': Icons.restaurant_rounded,
  'language_trivia': Icons.translate_rounded,
  'culture_japan': Icons.palette_rounded,
};

final Map<String, Color> _categoryColors = {
  'daily_why': Color(0xFFE67E22),
  'history_bite': Color(0xFFC0392B),
  'science_nearby': Color(0xFF2980B9),
  'food_origin': Color(0xFF27AE60),
  'language_trivia': Color(0xFF8E44AD),
  'culture_japan': Color(0xFFD35400),
};

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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('マイページ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStreakCard(context),
          const SizedBox(height: 24),
          _sectionHeader(context, Icons.favorite_rounded, '興味のあるジャンル'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _categories.map((cat) {
              final isSelected = _selectedCategories.contains(cat.slug);
              final catColor = _categoryColors[cat.slug] ?? cs.primary;
              final icon = _categoryIcons[cat.slug] ?? Icons.circle;
              return FilterChip(
                selected: isSelected,
                onSelected: (_) => _toggleCategory(cat.slug),
                avatar: Icon(icon, size: 18, color: isSelected ? Colors.white : catColor),
                label: Text(cat.name),
                selectedColor: catColor,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isSelected ? catColor : cs.outlineVariant),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStreakCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary.withValues(alpha: 0.08), cs.secondary.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.local_fire_department_rounded, size: 32, color: Colors.orangeAccent),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: '$_streak',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800, color: Colors.orange[700]),
                    children: [
                      TextSpan(
                        text: ' 日連続',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '毎日読むと継続マークがつくよ',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                ),
                if (_streak > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(
                      _streak > 7 ? 7 : _streak,
                      (i) => Container(
                        width: 8, height: 8,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
