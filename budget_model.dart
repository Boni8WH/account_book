import 'package:flutter/material.dart';

class Budget {
  final int? id;
  final String category;        // カテゴリ名（食費、交通費など）
  final double monthlyLimit;    // 月間予算上限
  final int year;              // 対象年
  final int month;             // 対象月
  final String? notes;         // メモ
  final bool isActive;         // アクティブフラグ
  final String createdAt;      // 作成日時
  final String? updatedAt;     // 更新日時

  Budget({
    this.id,
    required this.category,
    required this.monthlyLimit,
    required this.year,
    required this.month,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'monthly_limit': monthlyLimit,
      'year': year,
      'month': month,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  static Budget fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      category: map['category'],
      monthlyLimit: map['monthly_limit'].toDouble(),
      year: map['year'],
      month: map['month'],
      notes: map['notes'],
      isActive: map['is_active'] == 1,
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  Budget copyWith({
    int? id,
    String? category,
    double? monthlyLimit,
    int? year,
    int? month,
    String? notes,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      year: year ?? this.year,
      month: month ?? this.month,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 予算の表示用フォーマット
  String get formattedLimit {
    return '¥${monthlyLimit.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  // 対象期間の表示用フォーマット
  String get periodDisplay {
    return '${year}年${month}月';
  }

  // カテゴリのアイコン取得
  String get categoryIcon {
    switch (category) {
      case '食費':
        return '🍽️';
      case '交通費':
        return '🚗';
      case '娯楽費':
        return '🎮';
      case '日用品':
        return '🏠';
      case '医療費':
        return '🏥';
      case '教育費':
        return '📚';
      case '光熱費':
        return '💡';
      case '通信費':
        return '📱';
      default:
        return '📦';
    }
  }

  // カテゴリの色取得
  int get categoryColor {
    switch (category) {
      case '食費':
        return 0xFF2196F3; // Blue
      case '交通費':
        return 0xFF4CAF50; // Green
      case '娯楽費':
        return 0xFFFF9800; // Orange
      case '日用品':
        return 0xFFE91E63; // Pink
      case '医療費':
        return 0xFFE53935; // Red
      case '教育費':
        return 0xFF9C27B0; // Purple
      case '光熱費':
        return 0xFFFFEB3B; // Yellow
      case '通信費':
        return 0xFF00BCD4; // Cyan
      default:
        return 0xFF607D8B; // Blue Grey
    }
  }
}

// 予算vs実績の比較データクラス
class BudgetAnalysis {
  final Budget budget;
  final double actualExpense;     // 実際の支出額
  final double remainingBudget;   // 残り予算
  final double usagePercentage;   // 使用率（%）
  final bool isOverBudget;        // 予算超過フラグ
  final int daysRemaining;        // 月末までの残り日数

  BudgetAnalysis({
    required this.budget,
    required this.actualExpense,
    required this.remainingBudget,
    required this.usagePercentage,
    required this.isOverBudget,
    required this.daysRemaining,
  });

  factory BudgetAnalysis.calculate(Budget budget, double actualExpense) {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(budget.year, budget.month + 1, 0);
    final daysRemaining = lastDayOfMonth.difference(now).inDays + 1;
    
    final remaining = budget.monthlyLimit - actualExpense;
    final usage = (actualExpense / budget.monthlyLimit) * 100;
    final isOver = actualExpense > budget.monthlyLimit;

    return BudgetAnalysis(
      budget: budget,
      actualExpense: actualExpense,
      remainingBudget: remaining,
      usagePercentage: usage,
      isOverBudget: isOver,
      daysRemaining: daysRemaining > 0 ? daysRemaining : 0,
    );
  }

  // 1日あたりの推奨支出額
  double get dailyRecommendedAmount {
    if (daysRemaining <= 0) return 0.0;
    return remainingBudget / daysRemaining;
  }

  // ステータステキスト
  String get statusText {
    if (isOverBudget) {
      return '予算超過';
    } else if (usagePercentage >= 90) {
      return '予算残りわずか';
    } else if (usagePercentage >= 70) {
      return '注意が必要';
    } else if (usagePercentage >= 50) {
      return '順調';
    } else {
      return '余裕あり';
    }
  }

  // ステータスカラー
  Color get statusColor {
    if (isOverBudget) {
      return Colors.red;
    } else if (usagePercentage >= 90) {
      return Colors.orange;
    } else if (usagePercentage >= 70) {
      return Colors.amber;
    } else {
      return Colors.green;
    }
  }

  // フォーマット済みの金額表示
  String get formattedActual {
    return '¥${actualExpense.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  String get formattedRemaining {
    return '¥${remainingBudget.abs().toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  String get formattedDailyRecommended {
    return '¥${dailyRecommendedAmount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }
}