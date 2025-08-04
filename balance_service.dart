import 'database_helper.dart';
import 'models.dart';

class BalanceService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // 簡単な残高計算
  Future<Map<String, dynamic>> calculateSummary() async {
    try {
      // 全ての支出を取得
      List<Map<String, dynamic>> expensesList = await _databaseHelper.getExpenses();
      double totalExpenses = 0.0;
      
      for (var expenseMap in expensesList) {
        totalExpenses += expenseMap['amount'];
      }

      // 全ての収入を取得
      List<Map<String, dynamic>> incomesList = await _databaseHelper.getIncomes();
      double totalIncomes = 0.0;
      
      for (var incomeMap in incomesList) {
        totalIncomes += incomeMap['amount'];
      }

      // 初期資産（実際のアプリでは設定画面で入力）
      double initialAsset = 1000000.0; // 100万円からスタート
      
      // 現在の総資産 = 初期資産 + 収入合計 - 支出合計
      double currentAsset = initialAsset + totalIncomes - totalExpenses;

      return {
        'totalAsset': currentAsset,
        'totalIncomes': totalIncomes,
        'totalExpenses': totalExpenses,
        'expensesCount': expensesList.length,
        'incomesCount': incomesList.length,
      };
    } catch (e) {
      print('残高計算エラー: $e');
      return {
        'totalAsset': 1000000.0,
        'totalIncomes': 0.0,
        'totalExpenses': 0.0,
        'expensesCount': 0,
        'incomesCount': 0,
      };
    }
  }

  // 今月の支出を取得
  Future<double> getMonthlyExpenses() async {
    try {
      List<Map<String, dynamic>> expensesList = await _databaseHelper.getExpenses();
      DateTime now = DateTime.now();
      double monthlyTotal = 0.0;

      for (var expenseMap in expensesList) {
        DateTime expenseDate = DateTime.parse(expenseMap['date']);
        if (expenseDate.year == now.year && expenseDate.month == now.month) {
          monthlyTotal += expenseMap['amount'];
        }
      }

      return monthlyTotal;
    } catch (e) {
      print('月次支出計算エラー: $e');
      return 0.0;
    }
  }

  // カンマ区切りフォーマット
  String formatNumber(double number) {
    return number.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
