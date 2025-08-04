import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kakeibo_app/database_helper.dart';
import 'package:kakeibo_app/models.dart';
import 'package:kakeibo_app/balance_service.dart';
import 'package:kakeibo_app/history_screen.dart';
import 'package:kakeibo_app/pin_setup_screen.dart';
import 'package:kakeibo_app/pin_auth_screen.dart';
import 'package:kakeibo_app/pie_chart_widget.dart';
import 'package:kakeibo_app/chart_data_service.dart';
import 'payment_methods_screen.dart';
import 'payment_method_model.dart';
import 'initial_balance_setup_screen.dart';
import 'budget_management_screen.dart';
import 'advanced_analytics_screen.dart';
import 'notification_settings_screen.dart';
import 'goals_management_screen.dart'; // 目標管理画面を追加
import 'notification_service.dart'; // ファイル名を修正

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 通知サービスの初期化
  await NotificationService().initialize();
  
  runApp(KakeiboApp());
}

class KakeiboApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '家計簿',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'NotoSansJP',
      ),
      home: LaunchDecider(),
      routes: {
        '/home': (context) => TopScreen(),
        '/pinSetup': (context) => PinSetupScreen(),
        '/pinAuth': (context) => PinAuthScreen(),
      },
    );
  }
}

// 起動時に適切な画面を判定するクラス
class LaunchDecider extends StatefulWidget {
  @override
  _LaunchDeciderState createState() => _LaunchDeciderState();
}

class _LaunchDeciderState extends State<LaunchDecider> {
  bool? _isPinSetupCompleted;

  @override
  void initState() {
    super.initState();
    _checkPinSetupStatus();
  }

  Future<void> _checkPinSetupStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool? isCompleted = prefs.getBool('pin_setup_completed');
    
    setState(() {
      _isPinSetupCompleted = isCompleted ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isPinSetupCompleted == null) {
      return Scaffold(
        backgroundColor: Colors.blue,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                '家計簿',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 30),
              CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      );
    }

    if (_isPinSetupCompleted!) {
      return PinAuthScreen();
    } else {
      return PinSetupScreen();
    }
  }
}

// トップ画面（メイン画面）- 新機能統合版
class TopScreen extends StatefulWidget {
  @override
  _TopScreenState createState() => _TopScreenState();
}

class _TopScreenState extends State<TopScreen> {
  final BalanceService _balanceService = BalanceService();
  final NotificationService _notificationService = NotificationService();
  double _availableToday = 3500.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _calculateAvailableAmount();
  }

  Future<void> _calculateAvailableAmount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> summary = await _balanceService.calculateSummary();
      double monthlyExpenses = await _balanceService.getMonthlyExpenses();
      
      double totalAsset = summary['totalAsset'];
      DateTime now = DateTime.now();
      int remainingDays = DateTime(now.year, now.month + 1, 0).day - now.day + 1;
      
      if (remainingDays > 0) {
        _availableToday = (totalAsset * 0.05) / remainingDays;
      } else {
        _availableToday = totalAsset * 0.001;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('家計簿'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdvancedAnalyticsScreen()),
              );
            },
            tooltip: '高度な分析',
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              _showSettingsMenu(context);
            },
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 現在の日付表示
            Text(
              '${DateTime.now().year}年${DateTime.now().month}月${DateTime.now().day}日',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 30),
            
            // 今日使える金額
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue),
              ),
              child: Column(
                children: [
                  Text(
                    '今日使える金額',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 10),
                  _isLoading
                      ? CircularProgressIndicator()
                      : Text(
                          '¥${_balanceService.formatNumber(_availableToday)}',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                ],
              ),
            ),
            
            SizedBox(height: 30),
            
            // 今月の目標達成状況
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                children: [
                  Text(
                    '今月の目標達成状況',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 15),
                  LinearProgressIndicator(
                    value: 0.65,
                    backgroundColor: Colors.grey,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 8,
                  ),
                  SizedBox(height: 10),
                  Text(
                    '65% 達成',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 50),
            
            // メインボタン群（新機能追加版）
            Column(
              children: [
                // 支出を記録ボタン
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ExpenseInputScreen()),
                      );
                      if (result == true) {
                        _calculateAvailableAmount();
                      }
                    },
                    child: Text(
                      '支出を記録',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 15),
                
                // 収入を記録ボタン
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => IncomeInputScreen()),
                      );
                      if (result == true) {
                        _calculateAvailableAmount();
                      }
                    },
                    child: Text(
                      '収入を記録',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 15),
                
                // 予算管理ボタン（新機能）
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BudgetManagementScreen()),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet),
                        SizedBox(width: 8),
                        Text(
                          '予算管理',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 15),
                
                // 目標管理ボタン（新機能）
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GoalsManagementScreen()),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flag),
                        SizedBox(width: 8),
                        Text(
                          '目標管理',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 15),
                
                // サマリーを見るボタン
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SummaryScreen()),
                      );
                    },
                    child: Text(
                      'サマリーを見る',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 15),
                
                // 履歴を見るボタン
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HistoryScreen()),
                      );
                    },
                    child: Text(
                      '履歴を見る',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 700,  // AI機能追加のため高さを増加
          child: Column(
            children: [
              // AI家計診断（新機能）
              ListTile(
                leading: Icon(Icons.psychology, color: Colors.deepPurple),
                title: Text('AI家計診断'),
                subtitle: Text('AIによる詳細な家計分析・改善提案'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AIFinancialAdvisorScreen()),
                  );
                },
              ),
              
              // 目標管理
              ListTile(
                leading: Icon(Icons.flag, color: Colors.purple),
                title: Text('目標管理'),
                subtitle: Text('貯金目標の設定・進捗確認'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GoalsManagementScreen()),
                  );
                },
              ),
              
              // 予算管理
              ListTile(
                leading: Icon(Icons.account_balance_wallet, color: Colors.green),
                title: Text('予算管理'),
                subtitle: Text('月間予算の設定・確認'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BudgetManagementScreen()),
                  );
                },
              ),
              
              // 高度な分析
              ListTile(
                leading: Icon(Icons.analytics, color: Colors.indigo),
                title: Text('高度な分析'),
                subtitle: Text('トレンド分析・詳細レポート'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdvancedAnalyticsScreen()),
                  );
                },
              ),
              
              // 通知設定
              ListTile(
                leading: Icon(Icons.notifications, color: Colors.orange),
                title: Text('通知設定'),
                subtitle: Text('リマインダー・アラートの設定'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationSettingsScreen()),
                  );
                },
              ),
              
              // 既存の機能
              ListTile(
                leading: Icon(Icons.payment),
                title: Text('支払い方法管理'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PaymentMethodsScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.account_balance_wallet),
                title: Text('初期残高設定'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => InitialBalanceSetupScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.lock),
                title: Text('PIN変更'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PinSetupScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('ログアウト'),
                onTap: () async {
                  Navigator.pop(context);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('pin_setup_completed', false);
                  Navigator.pushReplacementNamed(context, '/pinSetup');
                },
              ),
              ListTile(
                leading: Icon(Icons.close),
                title: Text('キャンセル'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// 支出入力画面（通知機能統合版）
class ExpenseInputScreen extends StatefulWidget {
  @override
  _ExpenseInputScreenState createState() => _ExpenseInputScreenState();
}

class _ExpenseInputScreenState extends State<ExpenseInputScreen> {
  final _amountController = TextEditingController();
  String _selectedCategory = '食費';
  String _selectedPaymentMethod = '';
  final _memoController = TextEditingController();
  final List<String> _categories = ['食費', '交通費', '娯楽費', '日用品', 'その他'];
  List<String> _paymentMethods = [];
  bool _isLoadingPaymentMethods = true;

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      List<String> methods = await _databaseHelper.getPaymentMethodNames();
      setState(() {
        _paymentMethods = methods;
        if (_paymentMethods.isNotEmpty) {
          _selectedPaymentMethod = _paymentMethods.first;
        }
        _isLoadingPaymentMethods = false;
      });
    } catch (e) {
      print('支払い方法読み込みエラー: $e');
      setState(() {
        _paymentMethods = ['現金'];
        _selectedPaymentMethod = '現金';
        _isLoadingPaymentMethods = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('支出を記録'),
        backgroundColor: Colors.red[700],
        actions: [
          IconButton(
            icon: Icon(Icons.payment),
            tooltip: '支払い方法管理',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaymentMethodsScreen()),
              ).then((result) {
                if (result == true) {
                  _loadPaymentMethods();
                }
              });
            },
          ),
        ],
      ),
      body: _isLoadingPaymentMethods
          ? Center(child: CircularProgressIndicator())
          : Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
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
                    value: _selectedPaymentMethod.isEmpty ? null : _selectedPaymentMethod,
                    decoration: InputDecoration(
                      labelText: '支払い方法',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.add),
                        tooltip: '支払い方法を追加',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentMethodFormScreen(),
                            ),
                          ).then((result) {
                            if (result == true) {
                              _loadPaymentMethods();
                            }
                          });
                        },
                      ),
                    ),
                    items: _paymentMethods.isEmpty
                        ? [
                            DropdownMenuItem<String>(
                              value: '現金',
                              child: Text('現金'),
                            )
                          ]
                        : _paymentMethods.map((String method) {
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
                            Navigator.pop(context);
                          },
                          child: Text('キャンセル'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[400],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveExpense,
                          child: Text('保存'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[400],
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

  // 支出データを保存するメソッド（通知機能統合版）
  Future<void> _saveExpense() async {
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

      String currentDate = DateTime.now().toIso8601String();

      Expense expense = Expense(
        amount: amount,
        category: _selectedCategory,
        paymentMethod: _selectedPaymentMethod,
        memo: _memoController.text.isEmpty ? null : _memoController.text,
        date: currentDate,
      );

      // データベースに保存
      await _databaseHelper.insertExpense(expense.toMap());
      
      // 予算チェックと通知（非同期で実行）
      _performBudgetCheck();
      
      _showSuccessDialog();
    } catch (e) {
      _showErrorDialog('数字のみを入力してください');
    }
  }

  // 予算チェックと通知処理
  Future<void> _performBudgetCheck() async {
    try {
      // SharedPreferencesから通知設定を確認
      final prefs = await SharedPreferences.getInstance();
      final budgetAlertsEnabled = prefs.getBool('notification_budget_alerts') ?? true;
      
      if (budgetAlertsEnabled) {
        await _notificationService.checkBudgetStatus();
      }
    } catch (e) {
      print('予算チェックエラー: $e');
      // エラーが発生しても支出記録は完了しているので、ユーザーには通知しない
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
          title: Text('保存完了'),
          content: Text('支出データが保存されました'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
                Navigator.of(context).pop(true); // 入力画面を閉じる（戻り値付き）
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }
}

// 収入入力画面（通知機能統合版）
class IncomeInputScreen extends StatefulWidget {
  @override
  _IncomeInputScreenState createState() => _IncomeInputScreenState();
}

class _IncomeInputScreenState extends State<IncomeInputScreen> {
  final _amountController = TextEditingController();
  String _selectedSource = '給与';
  String _selectedPaymentMethod = '';
  final _memoController = TextEditingController();
  final List<String> _sources = ['給与', 'ボーナス', '副業', 'その他'];
  List<String> _paymentMethods = [];
  bool _isLoadingPaymentMethods = true;

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      List<String> methods = await _databaseHelper.getPaymentMethodNames();
      setState(() {
        _paymentMethods = methods;
        if (_paymentMethods.isNotEmpty) {
          _selectedPaymentMethod = _paymentMethods.first;
        }
        _isLoadingPaymentMethods = false;
      });
    } catch (e) {
      print('支払い方法読み込みエラー: $e');
      setState(() {
        _paymentMethods = ['現金'];
        _selectedPaymentMethod = '現金';
        _isLoadingPaymentMethods = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('収入を記録'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: Icon(Icons.payment),
            tooltip: '支払い方法管理',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaymentMethodsScreen()),
              ).then((result) {
                if (result == true) {
                  _loadPaymentMethods();
                }
              });
            },
          ),
        ],
      ),
      body: _isLoadingPaymentMethods
          ? Center(child: CircularProgressIndicator())
          : Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
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
                    value: _selectedPaymentMethod.isEmpty ? null : _selectedPaymentMethod,
                    decoration: InputDecoration(
                      labelText: '受取方法',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.add),
                        tooltip: '支払い方法を追加',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentMethodFormScreen(),
                            ),
                          ).then((result) {
                            if (result == true) {
                              _loadPaymentMethods();
                            }
                          });
                        },
                      ),
                    ),
                    items: _paymentMethods.isEmpty
                        ? [
                            DropdownMenuItem<String>(
                              value: '現金',
                              child: Text('現金'),
                            )
                          ]
                        : _paymentMethods.map((String method) {
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
                            Navigator.pop(context);
                          },
                          child: Text('キャンセル'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[400],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveIncome,
                          child: Text('保存'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[400],
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

  // 収入データを保存するメソッド
  Future<void> _saveIncome() async {
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

      String currentDate = DateTime.now().toIso8601String();

      Income income = Income(
        amount: amount,
        source: _selectedSource,
        paymentMethod: _selectedPaymentMethod,
        memo: _memoController.text.isEmpty ? null : _memoController.text,
        date: currentDate,
      );

      await _databaseHelper.insertIncome(income.toMap());
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
          title: Text('保存完了'),
          content: Text('収入データが保存されました'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
                Navigator.of(context).pop(true); // 入力画面を閉じる（戻り値付き）
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }
}

// サマリー画面（既存）
class SummaryScreen extends StatefulWidget {
  @override
  _SummaryScreenState createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final BalanceService _balanceService = BalanceService();
  
  double _totalAsset = 1000000.0;
  double _totalIncomes = 0.0;
  double _totalExpenses = 0.0;
  int _expensesCount = 0;
  int _incomesCount = 0;
  bool _isLoading = false;
  final GlobalKey<DynamicPieChartState> _pieChartKey = GlobalKey<DynamicPieChartState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> summary = await _balanceService.calculateSummary();
      
      setState(() {
        _totalAsset = summary['totalAsset'];
        _totalIncomes = summary['totalIncomes'];
        _totalExpenses = summary['totalExpenses'];
        _expensesCount = summary['expensesCount'];
        _incomesCount = summary['incomesCount'];
        _isLoading = false;
      });
    } catch (e) {
      print('データ読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('サマリー'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // 総資産表示
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Text(
                    '総資産',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 10),
                  _isLoading
                      ? CircularProgressIndicator()
                      : Text(
                          '¥${_balanceService.formatNumber(_totalAsset)}',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: _totalAsset >= 0 ? Colors.blue[800] : Colors.red[800],
                          ),
                        ),
                ],
              ),
            ),
            SizedBox(height: 20),
            
            // データ統計表示
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '総収入',
                    '¥${_balanceService.formatNumber(_totalIncomes)}',
                    '${_incomesCount}件',
                    Colors.green,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    '総支出',
                    '¥${_balanceService.formatNumber(_totalExpenses)}',
                    '${_expensesCount}件',
                    Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            
            // ステータス表示
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600]),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '✓ 全機能統合完了\n予算管理・通知・高度な分析機能が利用可能',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            
            // 支出内訳タイトル
            Text(
              '支出内訳',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 20),
            
            // 円グラフ表示
            DynamicPieChart(key: _pieChartKey),
            
            SizedBox(height: 20),
            
            // 更新ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading 
                    ? Text('更新中...')
                    : Text('最新データに更新'),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String amount, String count, Color color) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}