import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'models.dart';

// 支出編集画面
class EditExpenseScreen extends StatefulWidget {
  final Expense expense;

  EditExpenseScreen({required this.expense});

  @override
  _EditExpenseScreenState createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _amountController = TextEditingController();
  String _selectedCategory = '食費';
  String _selectedPaymentMethod = '現金';
  final _memoController = TextEditingController();

  final List<String> _categories = ['食費', '交通費', '娯楽費', '日用品', 'その他'];
  final List<String> _paymentMethods = ['現金', 'クレジットカード', '電子マネー'];

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    // 既存データを入力フィールドに設定
    _amountController.text = widget.expense.amount.toString();
    _selectedCategory = widget.expense.category;
    _selectedPaymentMethod = widget.expense.paymentMethod;
    _memoController.text = widget.expense.memo ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('支出の編集'),
        backgroundColor: Colors.orange,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // 元データ表示
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '編集中のデータ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '元の金額: ¥${_formatNumber(widget.expense.amount)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    '作成日時: ${_formatDate(widget.expense.date)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            
            // 金額入力
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '金額 (¥)',
                border: OutlineInputBorder(),
                prefixText: '¥',
              ),
            ),
            SizedBox(height: 20),
            
            // 用途選択
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: '用途',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
            ),
            SizedBox(height: 20),
            
            // 支払い方法選択
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: InputDecoration(
                labelText: '支払い方法',
                border: OutlineInputBorder(),
              ),
              items: _paymentMethods.map((String method) {
                return DropdownMenuItem<String>(
                  value: method,
                  child: Text(method),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPaymentMethod = newValue!;
                });
              },
            ),
            SizedBox(height: 20),
            
            // メモ入力
            TextField(
              controller: _memoController,
              decoration: InputDecoration(
                labelText: 'メモ（任意）',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 30),
            
            // ボタン群
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, false); // 変更なしで戻る
                    },
                    child: Text('キャンセル'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateExpense,
                    child: Text('更新'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateExpense() async {
    // 入力チェック
    if (_amountController.text.isEmpty) {
      _showErrorDialog('金額を入力してください');
      return;
    }

    try {
      int amount = int.parse(_amountController.text);
      
      if (amount <= 0) {
        _showErrorDialog('正しい金額を入力してください');
        return;
      }

      // 更新されたExpenseオブジェクトを作成
      Expense updatedExpense = Expense(
        id: widget.expense.id,
        amount: amount,
        category: _selectedCategory,
        paymentMethod: _selectedPaymentMethod,
        memo: _memoController.text.isEmpty ? null : _memoController.text,
        date: widget.expense.date, // 作成日時は変更しない
      );

      // データベースを更新
      await _databaseHelper.updateExpense(updatedExpense);

      // 成功メッセージを表示
      _showSuccessDialog();

    } catch (e) {
      _showErrorDialog('数字のみを入力してください');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('入力エラー'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('更新完了'),
          content: Text('支出データが更新されました'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
                Navigator.of(context).pop(true); // 編集画面を閉じる（更新ありで戻る）
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m},',
    );
  }

  String _formatDate(String dateString) {
    DateTime date = DateTime.parse(dateString);
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }
}

// 収入編集画面
class EditIncomeScreen extends StatefulWidget {
  final Income income;

  EditIncomeScreen({required this.income});

  @override
  _EditIncomeScreenState createState() => _EditIncomeScreenState();
}

class _EditIncomeScreenState extends State<EditIncomeScreen> {
  final _amountController = TextEditingController();
  String _selectedSource = '給与';
  String _selectedPaymentMethod = '銀行口座';
  final _memoController = TextEditingController();

  final List<String> _sources = ['給与', 'ボーナス', '副業', 'その他'];
  final List<String> _paymentMethods = ['銀行口座', '現金', '電子マネー'];

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    // 既存データを入力フィールドに設定
    _amountController.text = widget.income.amount.toString();
    _selectedSource = widget.income.source;
    _selectedPaymentMethod = widget.income.paymentMethod;
    _memoController.text = widget.income.memo ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('収入の編集'),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // 元データ表示
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.teal.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '編集中のデータ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.teal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '元の金額: ¥${_formatNumber(widget.income.amount)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    '作成日時: ${_formatDate(widget.income.date)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            
            // 金額入力
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '金額 (¥)',
                border: OutlineInputBorder(),
                prefixText: '¥',
              ),
            ),
            SizedBox(height: 20),
            
            // 収入源選択
            DropdownButtonFormField<String>(
              value: _selectedSource,
              decoration: InputDecoration(
                labelText: '収入源',
                border: OutlineInputBorder(),
              ),
              items: _sources.map((String source) {
                return DropdownMenuItem<String>(
                  value: source,
                  child: Text(source),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSource = newValue!;
                });
              },
            ),
            SizedBox(height: 20),
            
            // 受取方法選択
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: InputDecoration(
                labelText: '受取方法',
                border: OutlineInputBorder(),
              ),
              items: _paymentMethods.map((String method) {
                return DropdownMenuItem<String>(
                  value: method,
                  child: Text(method),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPaymentMethod = newValue!;
                });
              },
            ),
            SizedBox(height: 20),
            
            // メモ入力
            TextField(
              controller: _memoController,
              decoration: InputDecoration(
                labelText: 'メモ（任意）',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 30),
            
            // ボタン群
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, false); // 変更なしで戻る
                    },
                    child: Text('キャンセル'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateIncome,
                    child: Text('更新'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateIncome() async {
    // 入力チェック
    if (_amountController.text.isEmpty) {
      _showErrorDialog('金額を入力してください');
      return;
    }

    try {
      int amount = int.parse(_amountController.text);
      
      if (amount <= 0) {
        _showErrorDialog('正しい金額を入力してください');
        return;
      }

      // 更新されたIncomeオブジェクトを作成
      Income updatedIncome = Income(
        id: widget.income.id,
        amount: amount,
        source: _selectedSource,
        paymentMethod: _selectedPaymentMethod,
        memo: _memoController.text.isEmpty ? null : _memoController.text,
        date: widget.income.date, // 作成日時は変更しない
      );

      // データベースを更新
      await _databaseHelper.updateIncome(updatedIncome);

      // 成功メッセージを表示
      _showSuccessDialog();

    } catch (e) {
      _showErrorDialog('数字のみを入力してください');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('入力エラー'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('更新完了'),
          content: Text('収入データが更新されました'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
                Navigator.of(context).pop(true); // 編集画面を閉じる（更新ありで戻る）
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m},',
    );
  }

  String _formatDate(String dateString) {
    DateTime date = DateTime.parse(dateString);
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }
}
