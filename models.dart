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

// models.dart に追加
class MoneyTransfer {
  int? id;
  String fromPaymentMethod;    // 移行元（例：銀行口座）
  String toPaymentMethod;      // 移行先（例：電子マネー）
  double amount;               // 移行金額
  String? memo;                // メモ（オプション）
  DateTime transferDate;       // 移行日時
  
  MoneyTransfer({
    this.id,
    required this.fromPaymentMethod,
    required this.toPaymentMethod,
    required this.amount,
    this.memo,
    required this.transferDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromPaymentMethod': fromPaymentMethod,
      'toPaymentMethod': toPaymentMethod,
      'amount': amount,
      'memo': memo,
      'transferDate': transferDate.toIso8601String(),
    };
  }

  factory MoneyTransfer.fromMap(Map<String, dynamic> map) {
    return MoneyTransfer(
      id: map['id'],
      fromPaymentMethod: map['fromPaymentMethod'],
      toPaymentMethod: map['toPaymentMethod'],
      amount: map['amount'],
      memo: map['memo'],
      transferDate: DateTime.parse(map['transferDate']),
    );
  }
}

