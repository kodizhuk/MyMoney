class SavingsAccount {
  final int? id;
  final String name;
  final double amount;
  final String? notes;
  final String currency;
  final double usdRate;

  SavingsAccount({
    this.id,
    required this.name,
    required this.amount,
    this.notes,
    this.currency = 'UAH',
    this.usdRate = 42,
  });

  SavingsAccount copyWith({
    int? id,
    String? name,
    double? amount,
    String? notes,
    String? currency,
    double? usdRate,
  }) {
    return SavingsAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      currency: currency ?? this.currency,
      usdRate: usdRate ?? this.usdRate,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'amount': amount,
      'notes': notes,
      'currency': currency,
      'usd_rate': usdRate,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory SavingsAccount.fromMap(Map<String, dynamic> map) {
    return SavingsAccount(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      notes: map['notes'],
      currency: map['currency'] ?? 'UAH',
      usdRate: (map['usd_rate'] as num?)?.toDouble() ?? 42.0,
    );
  }
}