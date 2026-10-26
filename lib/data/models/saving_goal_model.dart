class SavingGoalItem {
  final int? id;
  final String name;
  final int targetAmount; // target nominal dalam Rupiah
  final int currentAmount; // nominal yang telah terkumpul
  final DateTime? deadline;
  final String icon; // nama ikon pilihan
  final int walletId;
  final String? note; // catatan opsional

  const SavingGoalItem({
    this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
    this.icon = 'flag_rounded',
    required this.walletId,
    this.note,
  });

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    final progress = currentAmount / targetAmount;
    return progress > 1.0 ? 1.0 : progress;
  }

  double get progress => progressPercentage;

  bool get isReached => targetAmount > 0 && currentAmount >= targetAmount;

  bool get isCompleted => isReached;

  SavingGoalItem copyWith({
    int? id,
    String? name,
    int? targetAmount,
    int? currentAmount,
    DateTime? deadline,
    String? icon,
    int? walletId,
    String? note,
  }) {
    return SavingGoalItem(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      icon: icon ?? this.icon,
      walletId: walletId ?? this.walletId,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline?.toIso8601String(),
      'icon': icon,
      'wallet_id': walletId,
      if (note != null) 'note': note,
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
      icon: (map['icon'] as String?) ?? 'flag_rounded',
      walletId: map['wallet_id'] as int,
      note: map['note'] as String?,
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
          icon == other.icon &&
          walletId == other.walletId &&
          note == other.note;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      targetAmount.hashCode ^
      currentAmount.hashCode ^
      deadline.hashCode ^
      icon.hashCode ^
      walletId.hashCode ^
      note.hashCode;
}
