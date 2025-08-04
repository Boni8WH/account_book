import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'payment_method_model.dart';

class InitialBalanceSetupScreen extends StatefulWidget {
  @override
  _InitialBalanceSetupScreenState createState() => _InitialBalanceSetupScreenState();
}

class _InitialBalanceSetupScreenState extends State<InitialBalanceSetupScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<PaymentMethod> _paymentMethods = [];
  Map<int, TextEditingController> _controllers = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final List<Map<String, dynamic>> methodsList = 
          await _databaseHelper.getPaymentMethods();
      
      setState(() {
        _paymentMethods = methodsList
            .map((map) => PaymentMethod.fromMap(map))
            .toList();
        
        // 各支払い方法に対してコントローラーを作成
        for (var method in _paymentMethods) {
          _controllers[method.id!] = TextEditingController(
            text: method.balance.toString(),
          );
        }
        
        _isLoading = false;
      });
    } catch (e) {
      print('支払い方法データ読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('初期残高設定'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 説明文
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[700]),
                            SizedBox(width: 8),
                            Text(
                              '初期残高を設定',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '各支払い方法の現在の残高を入力してください。\n'
                          'この設定により正確な家計管理が可能になります。',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),

                  // 支払い方法別残高入力
                  Text(
                    '支払い方法別残高',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 16),

                  // 支払い方法リスト
                  ...(_paymentMethods.map((method) => _buildBalanceInputCard(method)).toList()),

                  SizedBox(height: 30),

                  // 総残高表示
                  _buildTotalBalanceCard(),

                  SizedBox(height: 30),

                  // 保存ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAllBalances,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: _isSaving
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('保存中...'),
                              ],
                            )
                          : Text(
                              '残高を保存',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceInputCard(PaymentMethod method) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(method.colorValue).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      method.icon,
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        method.typeDisplayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              controller: _controllers[method.id!],
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '残高',
                prefixText: '¥',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _controllers[method.id!]?.clear();
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {}); // 総残高を更新するため
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBalanceCard() {
    double totalBalance = _calculateTotalBalance();
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo, Colors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '総残高（予想）',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '¥${totalBalance.toInt().toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},',
            )}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${_paymentMethods.length}個の支払い方法',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotalBalance() {
    double total = 0.0;
    for (var method in _paymentMethods) {
      String balanceText = _controllers[method.id!]?.text ?? '0';
      double balance = double.tryParse(balanceText) ?? 0.0;
      total += balance;
    }
    return total;
  }

  Future<void> _saveAllBalances() async {
    setState(() {
      _isSaving = true;
    });

    try {
      int updatedCount = 0;
      
      for (var method in _paymentMethods) {
        String balanceText = _controllers[method.id!]?.text ?? '0';
        double newBalance = double.tryParse(balanceText) ?? 0.0;
        
        if (newBalance != method.balance) {
          await _databaseHelper.updatePaymentMethodBalance(method.id!, newBalance);
          updatedCount++;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${updatedCount}件の残高を更新しました'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('初期残高設定について'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• 各支払い方法の現在の残高を入力してください'),
              SizedBox(height: 8),
              Text('• 銀行口座：通帳やアプリで確認'),
              SizedBox(height: 8),
              Text('• 現金：お財布の中の金額'),
              SizedBox(height: 8),
              Text('• クレジットカード：利用可能額（マイナス値も可）'),
              SizedBox(height: 8),
              Text('• 電子マネー：残高確認アプリで確認'),
              SizedBox(height: 8),
              Text('• 設定後も「残高調整」で修正可能です'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
