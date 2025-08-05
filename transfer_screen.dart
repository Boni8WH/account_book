import 'package:flutter/material.dart';
import 'balance_service.dart';
import 'models.dart';

class TransferScreen extends StatefulWidget {
  @override
  _TransferScreenState createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  
  String? _selectedFromMethod;
  String? _selectedToMethod;
  
  // 利用可能な支払い方法（実際のアプリでは動的に取得）
  final List<String> _paymentMethods = [
    '現金',
    '銀行口座',
    'PayPay',
    'Suica',
    'クレジットカード',
    '楽天Edy',
    'nanaco',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('お金の移行'),
        backgroundColor: Colors.blue[600],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 移行元選択
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: '移行元',
                  border: OutlineInputBorder(),
                ),
                value: _selectedFromMethod,
                items: _paymentMethods.map((method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFromMethod = value;
                  });
                },
                validator: (value) {
                  if (value == null) return '移行元を選択してください';
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              // 移行先選択
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: '移行先',
                  border: OutlineInputBorder(),
                ),
                value: _selectedToMethod,
                items: _paymentMethods.where((method) => method != _selectedFromMethod).map((method) {
                  return DropdownMenuItem<String>(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedToMethod = value;
                  });
                },
                validator: (value) {
                  if (value == null) return '移行先を選択してください';
                  if (value == _selectedFromMethod) return '移行元と移行先は異なる方法を選択してください';
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              // 金額入力
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: '移行金額',
                  border: OutlineInputBorder(),
                  prefixText: '¥',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return '金額を入力してください';
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) return '正しい金額を入力してください';
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              // メモ入力
              TextFormField(
                controller: _memoController,
                decoration: InputDecoration(
                  labelText: 'メモ（任意）',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              
              SizedBox(height: 24),
              
              // 移行実行ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _executeTransfer,
                  child: Text('移行を実行'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // 移行履歴ボタン
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showTransferHistory(),
                  child: Text('移行履歴を確認'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _executeTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    
    // 確認ダイアログ
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('移行の確認'),
        content: Text(
          '$_selectedFromMethodから$_selectedToMethodへ\n¥${amount.toStringAsFixed(0)}を移行しますか？'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('実行'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    // 移行実行
    final success = await BalanceService.executeMoneyTransfer(
      fromPaymentMethod: _selectedFromMethod!,
      toPaymentMethod: _selectedToMethod!,
      amount: amount,
      memo: _memoController.text.isEmpty ? null : _memoController.text,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('移行が完了しました'),
          backgroundColor: Colors.green,
        ),
      );
      // フォームをクリア
      _amountController.clear();
      _memoController.clear();
      setState(() {
        _selectedFromMethod = null;
        _selectedToMethod = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('移行に失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTransferHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransferHistoryScreen(),
      ),
    );
  }
}

// 移行履歴画面
class TransferHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('移行履歴'),
        backgroundColor: Colors.blue[600],
      ),
      body: FutureBuilder<List<MoneyTransfer>>(
        future: BalanceService.getTransferHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('移行履歴がありません'),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final transfer = snapshot.data![index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(
                    '${transfer.fromPaymentMethod} → ${transfer.toPaymentMethod}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¥${transfer.amount.toStringAsFixed(0)}'),
                      Text('${transfer.transferDate.year}/${transfer.transferDate.month}/${transfer.transferDate.day}'),
                      if (transfer.memo != null && transfer.memo!.isNotEmpty)
                        Text('メモ: ${transfer.memo}'),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward),
                ),
              );
            },
          );
        },
      ),
    );
  }
}