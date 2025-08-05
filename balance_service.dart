import 'database_helper.dart';
import 'models.dart';

class BalanceService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
      static final DatabaseHelper _databaseHelper = DatabaseHelper();

    // お金の移行を実行
    static Future<bool> executeMoneyTransfer({
      required String fromPaymentMethod,
      required String toPaymentMethod,
      required double amount,
      String? memo,
    }) async {
      try {
        // 移行元の残高チェック
        final currentBalance = await getPaymentMethodBalance(fromPaymentMethod);
        if (currentBalance < amount) {
          throw Exception('残高不足です。現在の残高: ¥${currentBalance.toStringAsFixed(0)}');
        }

        // 移行記録を作成
        final transfer = MoneyTransfer(
          fromPaymentMethod: fromPaymentMethod,
          toPaymentMethod: toPaymentMethod,
          amount: amount,
          memo: memo,
          transferDate: DateTime.now(),
        );

        // データベースに記録
        await _databaseHelper.insertMoneyTransfer(transfer);

        // 残高を更新
        await _updateBalanceAfterTransfer(fromPaymentMethod, toPaymentMethod, amount);

        return true;
      } catch (e) {
        print('移行エラー: $e');
        return false;
      }
    }

    // 移行後の残高更新
    static Future<void> _updateBalanceAfterTransfer(
        String fromMethod, String toMethod, double amount) async {
      // 移行元から減額
      await _adjustPaymentMethodBalance(fromMethod, -amount);
      // 移行先に加算
      await _adjustPaymentMethodBalance(toMethod, amount);
    }

    // 支払い方法別残高の調整
    static Future<void> _adjustPaymentMethodBalance(String paymentMethod, double amount) async {
      // 既存の支払い方法データを取得し、残高を調整
      // payment_methods テーブルがある場合の処理
      final db = await _databaseHelper.database;
      await db.rawUpdate(
        'UPDATE payment_methods SET balance = balance + ? WHERE name = ?',
        [amount, paymentMethod],
      );
    }

    // 支払い方法別残高取得
    static Future<double> getPaymentMethodBalance(String paymentMethod) async {
      final db = await _databaseHelper.database;
      final result = await db.query(
        'payment_methods',
        columns: ['balance'],
        where: 'name = ?',
        whereArgs: [paymentMethod],
      );
      
      if (result.isNotEmpty) {
        return result.first['balance'] as double;
      }
      return 0.0;
    }

    // 移行履歴取得
    static Future<List<MoneyTransfer>> getTransferHistory() async {
      return await _databaseHelper.getMoneyTransfers();
    }
  }
  
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
