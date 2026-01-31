class Transaction {
  final int? id;
  final String type; // 'income', 'expense', or 'saving'
  final DateTime date;
  final String name;
  final double amount;
  final String? source; // can be null for some types
  final String currency;
  final double usdRate;

  Transaction({
    this.id,
    required this.type,
    required this.date,
    required this.name,
    required this.amount,
    this.source,
    this.currency = 'UAH',
    this.usdRate = 42,
  });

  Transaction copyWith({
    int? id,
    String? type,
    DateTime? date,
    String? name,
    double? amount,
    String? source,
    String? currency,
    double? usdRate,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      date: date ?? this.date,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      currency: currency ?? this.currency,
      usdRate: usdRate ?? this.usdRate,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'type': type,
      'date': date.toIso8601String(),
      'name': name,
      'amount': amount,
      'source': source,
      'currency': currency,
      'usd_rate': usdRate,
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
      source: map['source'],
      currency: map['currency'] ?? 'UAH',
      usdRate: (map['usd_rate'] as num?)?.toDouble() ?? 42.0,
    );
  }
}