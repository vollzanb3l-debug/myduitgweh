class WalletItem {
  final int? id;
  final String name;
  final String type; // 'daily', 'balance', 'saving'
  final String ledger; // 'daily', 'balance', 'saving'
  final int initialBalance;
  final DateTime createdAt;

  const WalletItem({
    this.id,
    required this.name,
    required this.type,
    String? ledger,
    this.initialBalance = 0,
    required this.createdAt,
  }) : ledger = ledger ?? type;

  WalletItem copyWith({
    int? id,
    String? name,
    String? type,
    String? ledger,
    int? initialBalance,
    DateTime? createdAt,
  }) {
    return WalletItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      ledger: ledger ?? this.ledger,
      initialBalance: initialBalance ?? this.initialBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'ledger': ledger,
      'initial_balance': initialBalance,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WalletItem.fromMap(Map<String, dynamic> map) {
    final typeStr = map['type'] as String;
    return WalletItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: typeStr,
      ledger: (map['ledger'] as String?) ?? typeStr,
      initialBalance: (map['initial_balance'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          ledger == other.ledger &&
          initialBalance == other.initialBalance;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      type.hashCode ^
      ledger.hashCode ^
      initialBalance.hashCode;
}
