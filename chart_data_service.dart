import 'package:kakeibo_app/database_helper.dart';
import 'package:kakeibo_app/models.dart';

class ChartDataService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // カテゴリ別支出データを取得
  Future<Map<String, double>> getExpensesByCategory() async {
    try {
      List<Map<String, dynamic>> expensesList = await _databaseHelper.getExpenses();
      Map<String, double> categoryTotals = {};

      for (var expenseMap in expensesList) {
        Expense expense = Expense.fromMap(expenseMap);
        categoryTotals[expense.category] = 
            (categoryTotals[expense.category] ?? 0.0) + expense.amount.toDouble();
      }

      return categoryTotals;
    } catch (e) {
      print('支出データ集計エラー: $e');
      return {};
    }
  }

  // 円グラフ用カラーマップ
  Map<String, dynamic> getCategoryColors() {
    return {
      '食費': {'color': 0xFF2196F3, 'icon': '🍽️'},      // 青
      '交通費': {'color': 0xFF4CAF50, 'icon': '🚗'},    // 緑
      '娯楽費': {'color': 0xFFFF9800, 'icon': '🎮'},    // オレンジ
      '日用品': {'color': 0xFFE91E63, 'icon': '🏠'},    // ピンク
      'その他': {'color': 0xFF9C27B0, 'icon': '📦'},    // 紫
    };
  }

  // パーセンテージ計算
  Map<String, double> calculatePercentages(Map<String, double> categoryTotals) {
    double totalAmount = categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);
    Map<String, double> percentages = {};

    if (totalAmount > 0) {
      categoryTotals.forEach((category, amount) {
        percentages[category] = (amount / totalAmount) * 100;
      });
    }

    return percentages;
  }

  // 数値フォーマット
  String formatNumber(double number) {
    return number.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
