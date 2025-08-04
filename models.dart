class Expense {
  final int? id;
  final int amount;
  final String category;
  final String paymentMethod;
  final String? memo;
  final String date;

  Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    this.memo,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'payment_method': paymentMethod,
      'memo': memo,
      'date': date,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: map['amount'],
      category: map['category'],
      paymentMethod: map['payment_method'],
      memo: map['memo'],
      date: map['date'],
    );
  }
}

class Income {
  final int? id;
  final int amount;
  final String source;
  final String paymentMethod;
  final String? memo;
  final String date;

  Income({
    this.id,
    required this.amount,
    required this.source,
    required this.paymentMethod,
    this.memo,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'source': source,
      'payment_method': paymentMethod,
      'memo': memo,
      'date': date,
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'],
      amount: map['amount'],
      source: map['source'],
      paymentMethod: map['payment_method'],
      memo: map['memo'],
      date: map['date'],
    );
  }
}
