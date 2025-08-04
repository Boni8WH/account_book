import 'package:flutter/material.dart';

class SavingsGoal {
  final int? id;
  final String title;           // 目標タイトル（例：「海外旅行資金」）
  final double targetAmount;    // 目標金額
  final double currentAmount;   // 現在の貯金額
  final DateTime startDate;     // 開始日
  final DateTime targetDate;    // 目標達成日
  final String? description;    // 説明・メモ
  final String category;        // カテゴリ（旅行、車、結婚式等）
  final bool isActive;          // アクティブフラグ
  final String createdAt;       // 作成日時
  final String? updatedAt;      // 更新日時

  SavingsGoal({
    this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.startDate,
    required this.targetDate,
    this.description,
    this.category = 'その他',
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'start_date': startDate.toIso8601String(),
      'target_date': targetDate.toIso8601String(),
      'description': description,
      'category': category,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  static SavingsGoal fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'],
      title: map['title'],
      targetAmount: map['target_amount'].toDouble(),
      currentAmount: map['current_amount']?.toDouble() ?? 0.0,
      startDate: DateTime.parse(map['start_date']),
      targetDate: DateTime.parse(map['target_date']),
      description: map['description'],
      category: map['category'] ?? 'その他',
      isActive: map['is_active'] == 1,
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  SavingsGoal copyWith({
    int? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? startDate,
    DateTime? targetDate,
    String? description,
    String? category,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      description: description ?? this.description,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 達成率を計算（0.0-1.0）
  double get progressPercentage {
    if (targetAmount == 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  // 達成率をパーセンテージで取得
  int get progressPercent {
    return (progressPercentage * 100).round();
  }

  // 残り金額
  double get remainingAmount {
    return (targetAmount - currentAmount).clamp(0.0, double.infinity);
  }

  // 経過日数
  int get elapsedDays {
    return DateTime.now().difference(startDate).inDays;
  }

  // 残り日数
  int get remainingDays {
    return targetDate.difference(DateTime.now()).inDays;
  }

  // 全期間の日数
  int get totalDays {
    return targetDate.difference(startDate).inDays;
  }

  // 1日あたりの必要貯金額
  double get dailyRequiredAmount {
    if (remainingDays <= 0) return 0.0;
    return remainingAmount / remainingDays;
  }

  // 1ヶ月あたりの必要貯金額
  double get monthlyRequiredAmount {
    if (remainingDays <= 0) return 0.0;
    return remainingAmount / (remainingDays / 30.0);
  }

  // 目標達成まで1日あたりの貯金実績
  double get dailyAverageAmount {
    if (elapsedDays <= 0) return 0.0;
    return currentAmount / elapsedDays;
  }

  // 目標が達成済みかどうか
  bool get isCompleted {
    return currentAmount >= targetAmount;
  }

  // 期限切れかどうか
  bool get isOverdue {
    return DateTime.now().isAfter(targetDate) && !isCompleted;
  }

  // ステータステキスト
  String get statusText {
    if (isCompleted) {
      return '達成済み';
    } else if (isOverdue) {
      return '期限切れ';
    } else if (remainingDays <= 30) {
      return '期限間近';
    } else if (progressPercentage >= 0.8) {
      return '順調';
    } else if (progressPercentage >= 0.5) {
      return '進行中';
    } else {
      return '開始';
    }
  }

  // ステータスカラー
  Color get statusColor {
    if (isCompleted) {
      return Colors.green;
    } else if (isOverdue) {
      return Colors.red;
    } else if (remainingDays <= 30) {
      return Colors.orange;
    } else if (progressPercentage >= 0.8) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  // カテゴリのアイコン
  String get categoryIcon {
    switch (category) {
      case '旅行':
        return '✈️';
      case '車':
        return '🚗';
      case '結婚式':
        return '💒';
      case '家':
        return '🏠';
      case '教育':
        return '🎓';
      case '緊急資金':
        return '🚨';
      case '投資':
        return '📈';
      case '家電':
        return '📺';
      case '趣味':
        return '🎮';
      default:
        return '💰';
    }
  }

  // フォーマット済みの金額表示
  String get formattedTargetAmount {
    return _formatCurrency(targetAmount);
  }

  String get formattedCurrentAmount {
    return _formatCurrency(currentAmount);
  }

  String get formattedRemainingAmount {
    return _formatCurrency(remainingAmount);
  }

  String get formattedDailyRequired {
    return _formatCurrency(dailyRequiredAmount);
  }

  String get formattedMonthlyRequired {
    return _formatCurrency(monthlyRequiredAmount);
  }

  String _formatCurrency(double amount) {
    return '¥${amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  // 期間の表示用フォーマット
  String get periodDisplay {
    final startStr = '${startDate.year}/${startDate.month}/${startDate.day}';
    final targetStr = '${targetDate.year}/${targetDate.month}/${targetDate.day}';
    return '$startStr ～ $targetStr';
  }
}

// 目標の分析データクラス
class GoalAnalysis {
  final SavingsGoal goal;
  final bool isOnTrack;         // 予定通りに進んでいるか
  final double projectedAmount; // 現在のペースでの予想達成額
  final int projectedDays;      // 現在のペースでの予想達成日数

  GoalAnalysis({
    required this.goal,
    required this.isOnTrack,
    required this.projectedAmount,
    required this.projectedDays,
  });

  factory GoalAnalysis.calculate(SavingsGoal goal) {
    final elapsedRatio = goal.elapsedDays / goal.totalDays.toDouble();
    final expectedAmount = goal.targetAmount * elapsedRatio;
    final isOnTrack = goal.currentAmount >= expectedAmount;
    
    // 現在のペースでの予想達成額
    final dailyAverage = goal.dailyAverageAmount;
    final projectedAmount = dailyAverage * goal.totalDays;
    
    // 現在のペースでの予想達成日数
    final projectedDays = goal.remainingAmount > 0 && dailyAverage > 0
        ? (goal.remainingAmount / dailyAverage).ceil()
        : 0;

    return GoalAnalysis(
      goal: goal,
      isOnTrack: isOnTrack,
      projectedAmount: projectedAmount,
      projectedDays: projectedDays,
    );
  }

  // 予想達成日
  DateTime? get projectedCompletionDate {
    if (projectedDays <= 0) return null;
    return DateTime.now().add(Duration(days: projectedDays));
  }

  // アドバイステキスト
  String get adviceText {
    if (goal.isCompleted) {
      return '目標達成おめでとうございます！';
    } else if (goal.isOverdue) {
      return '期限が過ぎています。新しい目標日を設定しましょう。';
    } else if (isOnTrack) {
      return '順調に進んでいます！この調子で続けましょう。';
    } else {
      final shortage = goal.remainingAmount - (goal.dailyAverageAmount * goal.remainingDays);
      return '目標達成には1日あたり${goal.formattedDailyRequired}の貯金が必要です。';
    }
  }
}