class Category {
  final String slug;
  final String name;
  final int sortOrder;

  const Category({
    required this.slug,
    required this.name,
    required this.sortOrder,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      slug: json['slug'] as String,
      name: json['name'] as String,
      sortOrder: json['sort_order'] as int,
    );
  }
}
