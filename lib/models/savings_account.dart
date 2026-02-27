class SavingsAccount {
  final int? id;
  final String name;
  final double amount;
  final double amountUSD;
  final String? notes;
  final String currency;

  SavingsAccount({
    this.id,
    required this.name,
    required this.amount,
    this.amountUSD = 0.0,
    this.notes,
    this.currency = 'UAH',
  });

  SavingsAccount copyWith({
    int? id,
    String? name,
    double? amount,
    double? amountUSD,
    String? notes,
    String? currency,
  }) {
    return SavingsAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      amountUSD: amount != null ? amount / (usdRate ?? this.usdRate) : this.amountUSD,
      notes: notes ?? this.notes,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'amount': amount,
      'amount_usd': amountUSD,
      'notes': notes,
      'currency': currency,
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
      amountUSD: map['amount_usd'],
      notes: map['notes'],
      currency: map['currency'] ?? 'UAH',
    );
  }
}