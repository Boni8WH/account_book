import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'models.dart';
import 'edit_screens.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  TabController? _tabController;
  List<Expense> _expenses = [];
  List<Income> _incomes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistoryData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 支出データを取得
      List<Map<String, dynamic>> expensesList = await _databaseHelper.getExpenses();
      List<Expense> expenses = expensesList.map((map) => Expense.fromMap(map)).toList();

      // 収入データを取得
      List<Map<String, dynamic>> incomesList = await _databaseHelper.getIncomes();
      List<Income> incomes = incomesList.map((map) => Income.fromMap(map)).toList();

      setState(() {
        _expenses = expenses;
        _incomes = incomes;
        _isLoading = false;
      });
    } catch (e) {
      print('履歴データ読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('履歴'),
        backgroundColor: Colors.purple[700],
                bottom: _tabController != null ? TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.remove),
              text: '支出 (${_expenses.length})', // 動的に更新される
            ),
            Tab(
              icon: Icon(Icons.add),
              text: '収入 (${_incomes.length})', // 動的に更新される
            ),
          ],
        ) : null,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadHistoryData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _tabController != null ? TabBarView(
              controller: _tabController,
              children: [
                _buildExpensesList(),
                _buildIncomesList(),
              ],
            ) : Container(),
    );
  }

  Widget _buildExpensesList() {
    if (_expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              '支出データがありません',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              '支出を記録してみましょう',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        Expense expense = _expenses[index];
        return _buildExpenseCard(expense);
      },
    );
  }

  Widget _buildIncomesList() {
    if (_incomes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              '収入データがありません',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              '収入を記録してみましょう',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _incomes.length,
      itemBuilder: (context, index) {
        Income income = _incomes[index];
        return _buildIncomeCard(income);
      },
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    DateTime date = DateTime.parse(expense.date);
    String formattedDate = '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.remove,
            color: Colors.red[600],
          ),
        ),
        title: Text(
          '¥${_formatNumber(expense.amount)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red[600],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              '${expense.category} • ${expense.paymentMethod}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            if (expense.memo != null && expense.memo!.isNotEmpty)
              Text(
                expense.memo!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            SizedBox(height: 4),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, size: 20),
              color: Colors.blue,
              onPressed: () => _editExpense(expense), // expense を使用
              tooltip: '編集',
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete, size: 20),
              color: Colors.red,
              onPressed: () => _deleteExpense(expense), // expense を使用
              tooltip: '削除',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeCard(Income income) {
    DateTime date = DateTime.parse(income.date);
    String formattedDate = '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.add,
            color: Colors.green[600],
          ),
        ),
        title: Text(
          '¥${_formatNumber(income.amount)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green[600],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              '${income.source} • ${income.paymentMethod}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            if (income.memo != null && income.memo!.isNotEmpty)
              Text(
                income.memo!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            SizedBox(height: 4),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, size: 20),
              color: Colors.blue,
              onPressed: () => _editIncome(income), // income を使用
              tooltip: '編集',
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete, size: 20),
              color: Colors.red,
              onPressed: () => _deleteIncome(income), // income を使用
              tooltip: '削除',
            ),
          ],
        ),

      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

    // 支出編集機能
  Future<void> _editExpense(Expense expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExpenseScreen(expense: expense),
      ),
    );

    // 編集画面から戻ってきた時の処理
    if (result == true) {
      // データを再読み込み
      _loadHistoryData();
      _showSuccessSnackBar('支出データが更新されました');
    }
  }

  // 収入編集機能
  Future<void> _editIncome(Income income) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditIncomeScreen(income: income),
      ),
    );

    // 編集画面から戻ってきた時の処理
    if (result == true) {
      // データを再読み込み
      _loadHistoryData();
      _showSuccessSnackBar('収入データが更新されました');
    }
  }

  // 支出削除機能
  Future<void> _deleteExpense(Expense expense) async {
    // 削除確認ダイアログを表示
    bool? shouldDelete = await _showDeleteConfirmDialog(
      '支出データの削除',
      '¥${_formatNumber(expense.amount)} (${expense.category})\nこのデータを削除しますか？',
    );

    if (shouldDelete == true) {
      try {
        // データベースから削除
        await _databaseHelper.deleteExpense(expense.id!);
        
        // リストからも削除
        setState(() {
          _expenses.removeWhere((e) => e.id == expense.id);
        });

        // 成功メッセージを表示
        _showSuccessSnackBar('支出データを削除しました');
        
      } catch (e) {
        print('支出削除エラー: $e');
        _showErrorSnackBar('削除に失敗しました');
      }
    }
  }

  // 収入削除機能
  Future<void> _deleteIncome(Income income) async {
    // 削除確認ダイアログを表示
    bool? shouldDelete = await _showDeleteConfirmDialog(
      '収入データの削除',
      '¥${_formatNumber(income.amount)} (${income.source})\nこのデータを削除しますか？',
    );

    if (shouldDelete == true) {
      try {
        // データベースから削除
        await _databaseHelper.deleteIncome(income.id!);
        
        // リストからも削除
        setState(() {
          _incomes.removeWhere((i) => i.id == income.id);
        });

        // 成功メッセージを表示
        _showSuccessSnackBar('収入データを削除しました');
        
      } catch (e) {
        print('収入削除エラー: $e');
        _showErrorSnackBar('削除に失敗しました');
      }
    }
  }

  // 削除確認ダイアログ
  Future<bool?> _showDeleteConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.orange[600],
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          content: Text(
            content,
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // キャンセル
              },
              child: Text(
                'キャンセル',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true); // 削除実行
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: Text(
                '削除',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  // 成功メッセージ表示
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: Duration(seconds: 2),
      ),
    );
  }

  // エラーメッセージ表示
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: Duration(seconds: 3),
      ),
    );
  }
}
