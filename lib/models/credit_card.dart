class SavingsAccount {
  final int? id;
  final String name;
  final double amount;
  final String? notes;

  SavingsAccount({
    this.id,
    required this.name,
    required this.amount,
    this.notes,
  });

  SavingsAccount copyWith({
    int? id,
    String? name,
    double? amount,
    String? notes,
  }) {
    return SavingsAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'notes': notes,
    };
  }

  factory SavingsAccount.fromMap(Map<String, dynamic> map) {
    return SavingsAccount(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      notes: map['notes'],
    );
  }
}