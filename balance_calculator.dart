import 'database_helper.dart';
import 'models.dart';

class BalanceCalculator {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // 支払い方法別の残高を計算
  Future<Map<String, double>> calculateBalancesByPaymentMethod() async {
    // 初期残高（実際のアプリでは初期設定で入力）
    Map<String, double> balances = {
      '現金': 100000.0,  // 初期現金残高
      'クレジットカード': 0.0,  // クレカ請求額
      '電子マネー': 50000.0,  // 初期電子マネー残高
      '銀行口座': 500000.0,  // 初期銀行口座残高
    };

    // 収入データを取得して加算
    List<Map<String, dynamic>> incomes = await _databaseHelper.getIncomes();
    for (var incomeMap in incomes) {
      Income income = Income.fromMap(incomeMap);
      String paymentMethod = _normalizePaymentMethod(income.paymentMethod);
      balances[paymentMethod] = (balances[paymentMethod] ?? 0.0) + income.amount;
    }

    // 支出データを取得して減算
    List<Map<String, dynamic>> expenses = await _databaseHelper.getExpenses();
    for (var expenseMap in expenses) {
      Expense expense = Expense.fromMap(expenseMap);
      String paymentMethod = _normalizePaymentMethod(expense.paymentMethod);
      
      if (paymentMethod == 'クレジットカード') {
        // クレジットカードの場合は請求額として加算（負債）
        balances[paymentMethod] = (balances[paymentMethod] ?? 0.0) + expense.amount;
      } else {
        // その他の支払い方法は残高から減算
        balances[paymentMethod] = (balances[paymentMethod] ?? 0.0) - expense.amount;
      }
    }

    return balances;
  }

  // 総資産を計算
  Future<double> calculateTotalAssets() async {
    Map<String, double> balances = await calculateBalancesByPaymentMethod();
    
    double total = 0.0;
    balances.forEach((method, balance) {
      if (method == 'クレジットカード') {
        total -= balance;  // クレカ請求額は負債として引く
      } else {
        total += balance;  // その他は資産として加える
      }
    });
    
    return total;
  }

  // 支払い方法名を正規化
  String _normalizePaymentMethod(String paymentMethod) {
    switch (paymentMethod) {
      case '銀行口座':
        return '現金';  // 銀行口座は現金カテゴリに統合
      default:
        return paymentMethod;
    }
  }

  // カテゴリ別の支出統計を取得
  Future<Map<String, double>> getExpensesByCategory() async {
    List<Map<String, dynamic>> expenses = await _databaseHelper.getExpenses();
    Map<String, double> categoryTotals = {};

    for (var expenseMap in expenses) {
      Expense expense = Expense.fromMap(expenseMap);
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0.0) + expense.amount;
    }

    return categoryTotals;
  }

  // 今月の支出合計を取得
  Future<double> getMonthlyExpenseTotal() async {
    List<Map<String, dynamic>> expenses = await _databaseHelper.getExpenses();
    DateTime now = DateTime.now();
    double total = 0.0;

    for (var expenseMap in expenses) {
      Expense expense = Expense.fromMap(expenseMap);
      DateTime expenseDate = DateTime.parse(expense.date);
      
      if (expenseDate.year == now.year && expenseDate.month == now.month) {
        total += expense.amount;
      }
    }

    return total;
  }
}