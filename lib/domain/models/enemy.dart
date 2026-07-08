class Enemy {
  final String id;
  final String name;
  final String type;
  final int maxHp;
  final int attack;
  final String imageAsset;

  const Enemy({
    required this.id,
    required this.name,
    required this.type,
    required this.maxHp,
    required this.attack,
    required this.imageAsset,
  });

  factory Enemy.fromJson(Map<String, dynamic> json) {
    return Enemy(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      maxHp: json['maxHp'] as int,
      attack: json['attack'] as int,
      imageAsset: (json['imageAsset'] as String?) ?? '',
    );
  }
}
