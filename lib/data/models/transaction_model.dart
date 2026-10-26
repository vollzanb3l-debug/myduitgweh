class TransactionItem {
  final int? id;
  final String type; // 'income', 'expense'
  final int amount; // nominal dalam Rupiah (integer)
  final int categoryId;
  final int walletId;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  const TransactionItem({
    this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.walletId,
    required this.date,
    this.note,
    required this.createdAt,
  });

  TransactionItem copyWith({
    int? id,
    String? type,
    int? amount,
    int? categoryId,
    int? walletId,
    DateTime? date,
    String? note,
    DateTime? createdAt,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'amount': amount,
      'category_id': categoryId,
      'wallet_id': walletId,
      'date': date.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toInt(),
      categoryId: map['category_id'] as int,
      walletId: map['wallet_id'] as int,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          amount == other.amount &&
          categoryId == other.categoryId &&
          walletId == other.walletId &&
          date == other.date &&
          note == other.note;

  @override
  int get hashCode =>
      id.hashCode ^
      type.hashCode ^
      amount.hashCode ^
      categoryId.hashCode ^
      walletId.hashCode ^
      date.hashCode ^
      note.hashCode;
}
