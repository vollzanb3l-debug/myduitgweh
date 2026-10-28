class TransactionItem {
  final int? id;
  final String type; // 'income', 'expense'
  final int amount; // nominal dalam Rupiah (integer)
  final int categoryId;
  final int walletId;
  final DateTime date;
  final String? note;
  final String ledger; // 'daily', 'balance', 'saving', 'goal'
  final int? goalId; // opsional: id target impian jika terkait pencapaian
  final int? transferPartnerId; // opsional: id transaksi pasangan jika merupakan transfer antar akun
  final DateTime createdAt;

  const TransactionItem({
    this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.walletId,
    required this.date,
    this.note,
    this.ledger = 'daily',
    this.goalId,
    this.transferPartnerId,
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
    String? ledger,
    int? goalId,
    int? transferPartnerId,
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
      ledger: ledger ?? this.ledger,
      goalId: goalId ?? this.goalId,
      transferPartnerId: transferPartnerId ?? this.transferPartnerId,
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
      'ledger': ledger,
      if (goalId != null) 'goal_id': goalId,
      if (transferPartnerId != null) 'transfer_partner_id': transferPartnerId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toInt(),
      categoryId: (map['category_id'] ?? map['categoryId']) as int,
      walletId: (map['wallet_id'] ?? map['walletId']) as int,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      ledger: (map['ledger'] as String?) ?? 'daily',
      goalId: (map['goal_id'] ?? map['goalId']) as int?,
      transferPartnerId: (map['transfer_partner_id'] ?? map['transferPartnerId']) as int?,
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
          note == other.note &&
          ledger == other.ledger &&
          goalId == other.goalId;

  @override
  int get hashCode =>
      id.hashCode ^
      type.hashCode ^
      amount.hashCode ^
      categoryId.hashCode ^
      walletId.hashCode ^
      date.hashCode ^
      note.hashCode ^
      ledger.hashCode ^
      goalId.hashCode;
}
