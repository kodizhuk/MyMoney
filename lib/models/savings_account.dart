class SavingsAccount {
  final int? id;
  final String name;
  final double amount;
  final double amountUSD;
  final String? notes;
  final String currency;
  final DateTime lastUpdated;

  SavingsAccount({
    this.id,
    required this.name,
    required this.amount,
    required this.amountUSD,
    this.notes,
    required this.currency,
    required this.lastUpdated,
  });


  Map<String, dynamic> toMap() {
    return{
      'id': id,
      'name': name,
      'amount': amount,
      'amount_usd': amountUSD,
      'notes': notes,
      'currency': currency,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory SavingsAccount.fromMap(Map<String, dynamic> map) {
    return SavingsAccount(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      amountUSD: map['amount_usd'],
      notes: map['notes'],
      currency: map['currency'] ?? 'UAH',
      lastUpdated: DateTime.parse(map['last_updated'] as String),
    );
  }
}