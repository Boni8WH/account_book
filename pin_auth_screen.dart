import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinAuthScreen extends StatefulWidget {
  @override
  _PinAuthScreenState createState() => _PinAuthScreenState();
}

class _PinAuthScreenState extends State<PinAuthScreen> {
  String _enteredPin = '';
  String _savedPin = '';
  final int _pinLength = 4;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPin();
  }

  Future<void> _loadSavedPin() async {
    final prefs = await SharedPreferences.getInstance();
    _savedPin = prefs.getString('user_pin') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
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
                      Icons.lock,
                      size: 80,
                      color: Colors.white,
                    ),
                    SizedBox(height: 20),
                    Text(
                      '家計簿',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 30),
                    Text(
                      'PIN を入力してください',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 30),
                    _buildPinDisplay(),
                    if (_isError) ...[
                      SizedBox(height: 20),
                      Text(
                        'PIN が間違っています',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
            color: index < _enteredPin.length 
                ? (_isError ? Colors.red : Colors.white)
                : Colors.white30,
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
            foregroundColor: Colors.indigo,
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

    if (_enteredPin.length < _pinLength) {
      setState(() {
        _enteredPin += number;
        _isError = false; // エラー状態をリセット
      });

      // 4桁入力完了時に認証チェック
      if (_enteredPin.length == _pinLength) {
        _checkPin();
      }
    }
  }

  void _onBackspacePressed() {
    setState(() {
      if (_enteredPin.isNotEmpty) {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _isError = false;
      }
    });
  }

  void _checkPin() {
    Future.delayed(Duration(milliseconds: 300), () {
      if (_enteredPin == _savedPin) {
        // 認証成功
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // 認証失敗
        setState(() {
          _isError = true;
        });
        
        // 1秒後に入力をクリア
        Future.delayed(Duration(seconds: 1), () {
          setState(() {
            _enteredPin = '';
            _isError = false;
          });
        });
      }
    });
  }
}
