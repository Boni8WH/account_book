class PaymentMethod {
  final int? id;
  final String name;          // 支払い方法名（例：みずほ銀行、楽天カード）
  final String type;          // 種類（cash, bank, emoney, credit, securities）
  final double balance;       // 残高
  final String? bankName;     // 銀行名（銀行口座の場合）
  final String? cardNumber;   // カード番号下4桁（カードの場合）
  final int? withdrawalDay;   // 引き落とし日（クレカの場合）
  final String? notes;        // メモ
  final bool isActive;        // 有効/無効
  final String createdAt;     // 作成日時
  final String? updatedAt;    // 更新日時

  PaymentMethod({
    this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.bankName,
    this.cardNumber,
    this.withdrawalDay,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'bank_name': bankName,
      'card_number': cardNumber,
      'withdrawal_day': withdrawalDay,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  static PaymentMethod fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      balance: map['balance'].toDouble(),
      bankName: map['bank_name'],
      cardNumber: map['card_number'],
      withdrawalDay: map['withdrawal_day'],
      notes: map['notes'],
      isActive: map['is_active'] == 1,
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  PaymentMethod copyWith({
    int? id,
    String? name,
    String? type,
    double? balance,
    String? bankName,
    String? cardNumber,
    int? withdrawalDay,
    String? notes,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      bankName: bankName ?? this.bankName,
      cardNumber: cardNumber ?? this.cardNumber,
      withdrawalDay: withdrawalDay ?? this.withdrawalDay,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 支払い方法の種類を日本語で取得
  String get typeDisplayName {
    switch (type) {
      case 'cash':
        return '現金';
      case 'bank':
        return '銀行口座';
      case 'emoney':
        return '電子マネー';
      case 'credit':
        return 'クレジットカード';
      case 'securities':
        return '証券口座';
      default:
        return 'その他';
    }
  }

  // 残高の表示用フォーマット
  String get formattedBalance {
    return '¥${balance.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  // アイコンの取得
  String get icon {
    switch (type) {
      case 'cash':
        return '💵';
      case 'bank':
        return '🏦';
      case 'emoney':
        return '📱';
      case 'credit':
        return '💳';
      case 'securities':
        return '📊';
      default:
        return '💰';
    }
  }

  // 色の取得
  int get colorValue {
    switch (type) {
      case 'cash':
        return 0xFF4CAF50; // Green
      case 'bank':
        return 0xFF2196F3; // Blue
      case 'emoney':
        return 0xFFFF9800; // Orange
      case 'credit':
        return 0xFFE91E63; // Pink
      case 'securities':
        return 0xFF9C27B0; // Purple
      default:
        return 0xFF607D8B; // Blue Grey
    }
  }
}
