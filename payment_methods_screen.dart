import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'payment_method_model.dart';

class PaymentMethodsScreen extends StatefulWidget {
  @override
  _PaymentMethodsScreenState createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<Map<String, dynamic>> methodsList = 
          await _databaseHelper.getPaymentMethods();
      
      setState(() {
        _paymentMethods = methodsList
            .map((map) => PaymentMethod.fromMap(map))
            .toList();
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
        title: Text('支払い方法管理'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadPaymentMethods,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildPaymentMethodsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPaymentMethod,
        backgroundColor: Colors.indigo,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildPaymentMethodsList() {
    if (_paymentMethods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '支払い方法が登録されていません',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '右下の + ボタンから追加してください',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // 種類別にグループ化
    Map<String, List<PaymentMethod>> groupedMethods = {};
    for (var method in _paymentMethods) {
      groupedMethods.putIfAbsent(method.type, () => []).add(method);
    }

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // 総残高表示
        _buildTotalBalanceCard(),
        SizedBox(height: 20),
        
        // 種類別支払い方法表示
        ...groupedMethods.entries.map((entry) {
          return _buildTypeSection(entry.key, entry.value);
        }).toList(),
      ],
    );
  }

  Widget _buildTotalBalanceCard() {
    double totalBalance = _paymentMethods
        .fold(0.0, (sum, method) => sum + method.balance);

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
            '総資産',
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

  Widget _buildTypeSection(String type, List<PaymentMethod> methods) {
    String sectionTitle = methods.first.typeDisplayName;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            sectionTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        ...methods.map((method) => _buildPaymentMethodCard(method)).toList(),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Container(
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
        title: Text(
          method.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              method.formattedBalance,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(method.colorValue),
              ),
            ),
            if (method.type == 'credit' && method.withdrawalDay != null)
              Text(
                '引き落とし日: ${method.withdrawalDay}日',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            if (method.notes != null && method.notes!.isNotEmpty)
              Text(
                method.notes!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
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
              onPressed: () => _editPaymentMethod(method),
            ),
            IconButton(
              icon: Icon(Icons.delete, size: 20),
              color: Colors.red,
              onPressed: () => _deletePaymentMethod(method),
            ),
          ],
        ),
        onTap: () => _showPaymentMethodDetails(method),
      ),
    );
  }

  void _addPaymentMethod() {
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
  }

  void _editPaymentMethod(PaymentMethod method) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentMethodFormScreen(paymentMethod: method),
      ),
    ).then((result) {
      if (result == true) {
        _loadPaymentMethods();
      }
    });
  }

  Future<void> _deletePaymentMethod(PaymentMethod method) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('支払い方法の削除'),
          content: Text('「${method.name}」を削除しますか？\n'
              '削除後は復元できません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('削除'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        await _databaseHelper.deletePaymentMethod(method.id!);
        _loadPaymentMethods();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${method.name}」を削除しました'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('削除に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPaymentMethodDetails(PaymentMethod method) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    method.icon,
                    style: TextStyle(fontSize: 32),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          method.typeDisplayName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              _buildDetailRow('残高', method.formattedBalance),
              
              if (method.bankName != null)
                _buildDetailRow('銀行名', method.bankName!),
              
              if (method.cardNumber != null)
                _buildDetailRow('カード番号', '**** **** **** ${method.cardNumber}'),
              
              if (method.withdrawalDay != null)
                _buildDetailRow('引き落とし日', '毎月${method.withdrawalDay}日'),
              
              if (method.notes != null && method.notes!.isNotEmpty)
                _buildDetailRow('メモ', method.notes!),
              
              _buildDetailRow('作成日', _formatDate(method.createdAt)),
              
              SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _editPaymentMethod(method);
                      },
                      icon: Icon(Icons.edit),
                      label: Text('編集'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _adjustBalance(method);
                      },
                      icon: Icon(Icons.tune),
                      label: Text('残高調整'),
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
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    final DateTime date = DateTime.parse(dateString);
    return '${date.year}年${date.month}月${date.day}日';
  }

  void _adjustBalance(PaymentMethod method) {
    final TextEditingController adjustmentController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('残高調整'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('現在の残高: ${method.formattedBalance}'),
              SizedBox(height: 16),
              TextField(
                controller: adjustmentController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '調整額',
                  hintText: '例: +1000, -500',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: '調整理由（任意）',
                  hintText: '例: ポイント加算、手数料',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => _performBalanceAdjustment(
                method,
                adjustmentController.text,
                reasonController.text,
              ),
              child: Text('調整'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performBalanceAdjustment(
    PaymentMethod method,
    String adjustmentText,
    String reason,
  ) async {
    if (adjustmentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('調整額を入力してください')),
      );
      return;
    }

    try {
      double adjustment = double.parse(adjustmentText);
      double newBalance = method.balance + adjustment;

      await _databaseHelper.updatePaymentMethodBalance(method.id!, newBalance);
      
      Navigator.pop(context);
      _loadPaymentMethods();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('残高を調整しました: ${method.formattedBalance} → ¥${newBalance.toInt()}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('無効な金額です'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// 支払い方法追加・編集画面
class PaymentMethodFormScreen extends StatefulWidget {
  final PaymentMethod? paymentMethod;

  PaymentMethodFormScreen({this.paymentMethod});

  @override
  _PaymentMethodFormScreenState createState() => _PaymentMethodFormScreenState();
}

class _PaymentMethodFormScreenState extends State<PaymentMethodFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedType = 'cash';
  int? _withdrawalDay;
  
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isLoading = false;

  final List<Map<String, String>> _paymentTypes = [
    {'value': 'cash', 'label': '現金', 'icon': '💵'},
    {'value': 'bank', 'label': '銀行口座', 'icon': '🏦'},
    {'value': 'emoney', 'label': '電子マネー', 'icon': '📱'},
    {'value': 'credit', 'label': 'クレジットカード', 'icon': '💳'},
    {'value': 'securities', 'label': '証券口座', 'icon': '📊'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.paymentMethod != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final method = widget.paymentMethod!;
    _nameController.text = method.name;
    _balanceController.text = method.balance.toString();
    _selectedType = method.type;
    _bankNameController.text = method.bankName ?? '';
    _cardNumberController.text = method.cardNumber ?? '';
    _notesController.text = method.notes ?? '';
    _withdrawalDay = method.withdrawalDay;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.paymentMethod != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '支払い方法編集' : '支払い方法追加'),
        backgroundColor: Colors.indigo,
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deletePaymentMethod,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 支払い方法名
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '支払い方法名 *',
                  hintText: '例：みずほ銀行、楽天カード',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '支払い方法名を入力してください';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // 種類選択
              Text(
                '種類 *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: _paymentTypes.map((type) {
                    return RadioListTile<String>(
                      title: Row(
                        children: [
                          Text(
                            type['icon']!,
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(width: 12),
                          Text(type['label']!),
                        ],
                      ),
                      value: type['value']!,
                      groupValue: _selectedType,
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 20),

              // 初期残高
              TextFormField(
                controller: _balanceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '初期残高',
                  hintText: '0',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet),
                  prefixText: '¥',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return '正しい金額を入力してください';
                    }
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // 銀行口座の場合の追加項目
              if (_selectedType == 'bank') ...[
                TextFormField(
                  controller: _bankNameController,
                  decoration: InputDecoration(
                    labelText: '銀行名',
                    hintText: '例：みずほ銀行',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                ),
                SizedBox(height: 20),
              ],

              // クレジットカードの場合の追加項目
              if (_selectedType == 'credit') ...[
                TextFormField(
                  controller: _cardNumberController,
                  decoration: InputDecoration(
                    labelText: 'カード番号下4桁',
                    hintText: '1234',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                
                // 引き落とし日選択
                Text(
                  '引き落とし日',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _withdrawalDay,
                      hint: Text('引き落とし日を選択'),
                      isExpanded: true,
                      items: List.generate(31, (index) {
                        int day = index + 1;
                        return DropdownMenuItem<int>(
                          value: day,
                          child: Text('毎月${day}日'),
                        );
                      }),
                      onChanged: (value) {
                        setState(() {
                          _withdrawalDay = value;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],

              // メモ
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'メモ（任意）',
                  hintText: '例：メインカード、普段使い',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 30),

              // ボタン群
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text('キャンセル'),
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _savePaymentMethod,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(isEditing ? '更新' : '追加'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePaymentMethod() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String currentDate = DateTime.now().toIso8601String();
      double balance = _balanceController.text.isEmpty 
          ? 0.0 
          : double.parse(_balanceController.text);

      Map<String, dynamic> paymentMethodData = {
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'balance': balance,
        'bank_name': _selectedType == 'bank' ? _bankNameController.text.trim() : null,
        'card_number': _selectedType == 'credit' ? _cardNumberController.text.trim() : null,
        'withdrawal_day': _selectedType == 'credit' ? _withdrawalDay : null,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'is_active': 1,
        'updated_at': currentDate,
      };

      if (widget.paymentMethod == null) {
        // 新規追加
        paymentMethodData['created_at'] = currentDate;
        await _databaseHelper.insertPaymentMethod(paymentMethodData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${_nameController.text}」を追加しました'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // 更新
        await _databaseHelper.updatePaymentMethod(
          widget.paymentMethod!.id!,
          paymentMethodData,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${_nameController.text}」を更新しました'),
            backgroundColor: Colors.blue,
          ),
        );
      }

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
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePaymentMethod() async {
    if (widget.paymentMethod == null) return;

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('支払い方法の削除'),
          content: Text('「${widget.paymentMethod!.name}」を削除しますか？\n'
              '削除後は復元できません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('削除'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        await _databaseHelper.deletePaymentMethod(widget.paymentMethod!.id!);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${widget.paymentMethod!.name}」を削除しました'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('削除に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _bankNameController.dispose();
    _cardNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
