class CategoryItem {
  final int? id;
  final String name;
  final String icon; // Nama identifier ikon
  final String colorHex;
  final String type; // 'income', 'expense'
  final String ledger; // 'daily', 'balance', 'saving'

  const CategoryItem({
    this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.type,
    this.ledger = 'daily',
  });

  CategoryItem copyWith({
    int? id,
    String? name,
    String? icon,
    String? colorHex,
    String? type,
    String? ledger,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      type: type ?? this.type,
      ledger: ledger ?? this.ledger,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': icon,
      'color_hex': colorHex,
      'type': type,
      'ledger': ledger,
    };
  }

  factory CategoryItem.fromMap(Map<String, dynamic> map) {
    return CategoryItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String,
      colorHex: map['color_hex'] as String,
      type: map['type'] as String,
      ledger: (map['ledger'] as String?) ?? 'daily',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          icon == other.icon &&
          colorHex == other.colorHex &&
          type == other.type &&
          ledger == other.ledger;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      icon.hashCode ^
      colorHex.hashCode ^
      type.hashCode ^
      ledger.hashCode;
}
