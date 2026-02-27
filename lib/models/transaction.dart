class Transaction {
  final int? id;
  final String type; // 'income', 'expense', or 'saving'
  final DateTime date;
  final String name;
  final double amount;
  final double amount_usd; // field for USD equivalent
  final String? source; // can be null for some types
  final String currency;

  Transaction({
    this.id,
    required this.type,
    required this.date,
    required this.name,
    required this.amount,
    required this.amount_usd,
    this.source,
    this.currency = 'UAH',
  });

  Transaction copyWith({
    int? id,
    String? type,
    DateTime? date,
    String? name,
    double? amount,
    double? amount_usd,
    String? source,
    String? currency,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      date: date ?? this.date,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      amount_usd: amount_usd ?? this.amount_usd,
      source: source ?? this.source,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'type': type,
      'date': date.toIso8601String(),
      'name': name,
      'amount': amount,
      'amount_usd': amount_usd,
      'source': source,
      'currency': currency,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      type: map['type'],
      date: DateTime.parse(map['date']),
      name: map['name'],
      amount: map['amount'],
      amount_usd: map['amount_usd'],
      source: map['source'],
      currency: map['currency'] ?? 'UAH',
    );
  }
}