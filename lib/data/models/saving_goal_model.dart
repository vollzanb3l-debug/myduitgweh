class SavingGoalItem {
  final int? id;
  final String name;
  final int targetAmount; // target nominal dalam Rupiah
  final int currentAmount; // nominal yang telah terkumpul
  final DateTime? deadline;
  final int walletId;

  const SavingGoalItem({
    this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
    required this.walletId,
  });

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    final progress = currentAmount / targetAmount;
    return progress > 1.0 ? 1.0 : progress;
  }

  bool get isReached => currentAmount >= targetAmount;

  SavingGoalItem copyWith({
    int? id,
    String? name,
    int? targetAmount,
    int? currentAmount,
    DateTime? deadline,
    int? walletId,
  }) {
    return SavingGoalItem(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      walletId: walletId ?? this.walletId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline?.toIso8601String(),
      'wallet_id': walletId,
    };
  }

  factory SavingGoalItem.fromMap(Map<String, dynamic> map) {
    return SavingGoalItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      targetAmount: (map['target_amount'] as num).toInt(),
      currentAmount: (map['current_amount'] as num?)?.toInt() ?? 0,
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'] as String)
          : null,
      walletId: map['wallet_id'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingGoalItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          targetAmount == other.targetAmount &&
          currentAmount == other.currentAmount &&
          deadline == other.deadline &&
          walletId == other.walletId;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      targetAmount.hashCode ^
      currentAmount.hashCode ^
      deadline.hashCode ^
      walletId.hashCode;
}
