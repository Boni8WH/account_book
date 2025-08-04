import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinSetupScreen extends StatefulWidget {
  @override
  _PinSetupScreenState createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  final int _pinLength = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.security,
                      size: 80,
                      color: Colors.white,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'PIN を設定してください',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '4桁の数字を入力してください',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 30),
                    _buildPinDisplay(),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: _buildNumberPad(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 10),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _pin.length ? Colors.white : Colors.white30,
          ),
        );
      }),
    );
  }

  Widget _buildNumberPad() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildNumberRow(['1', '2', '3']),
          _buildNumberRow(['4', '5', '6']),
          _buildNumberRow(['7', '8', '9']),
          _buildNumberRow(['', '0', '⌫']),
        ],
      ),
    );
  }

  Widget _buildNumberRow(List<String> numbers) {
    return Expanded(
      child: Row(
        children: numbers.map((number) => _buildNumberButton(number)).toList(),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    if (number.isEmpty) {
      return Expanded(child: Container());
    }

    return Expanded(
      child: Container(
        margin: EdgeInsets.all(10),
        child: ElevatedButton(
          onPressed: () => _onNumberPressed(number),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue,
            shape: CircleBorder(),
            padding: EdgeInsets.all(20),
          ),
          child: Text(
            number,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _onNumberPressed(String number) {
    if (number == '⌫') {
      _onBackspacePressed();
      return;
    }

    if (_pin.length < _pinLength) {
      setState(() {
        _pin += number;
      });

      // 4桁入力完了と同時に保存
      if (_pin.length == _pinLength) {
        _savePinAndComplete();
      }
    }
  }

  void _onBackspacePressed() {
    setState(() {
      if (_pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  Future<void> _savePinAndComplete() async {
    // 保存中の表示
    _showSavingDialog();
    
    await Future.delayed(Duration(milliseconds: 500)); // 少しの間待機
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_pin', _pin);
    await prefs.setBool('pin_setup_completed', true);
    
    Navigator.of(context).pop(); // ダイアログを閉じる
    _showSuccessDialog();
  }

  void _showSavingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('PIN を保存中...'),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text('設定完了'),
            ],
          ),
          content: Text('PIN が正常に設定されました'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text('開始'),
            ),
          ],
        );
      },
    );
  }
}
