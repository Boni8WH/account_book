import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart'; // 元のファイル名に修正

class NotificationSettingsScreen extends StatefulWidget {
  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  
  bool _dailyReminder = true;
  bool _budgetAlerts = true;
  bool _weeklyReport = true;
  bool _monthlyReport = true;
  
  int _reminderHour = 20;
  int _reminderMinute = 0;
  
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkPermission();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _dailyReminder = prefs.getBool('notification_daily_reminder') ?? true;
        _budgetAlerts = prefs.getBool('notification_budget_alerts') ?? true;
        _weeklyReport = prefs.getBool('notification_weekly_report') ?? true;
        _monthlyReport = prefs.getBool('notification_monthly_report') ?? true;
        _reminderHour = prefs.getInt('notification_reminder_hour') ?? 20;
        _reminderMinute = prefs.getInt('notification_reminder_minute') ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      print('設定読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _notificationService.hasNotificationPermission();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('notification_daily_reminder', _dailyReminder);
      await prefs.setBool('notification_budget_alerts', _budgetAlerts);
      await prefs.setBool('notification_weekly_report', _weeklyReport);
      await prefs.setBool('notification_monthly_report', _monthlyReport);
      await prefs.setInt('notification_reminder_hour', _reminderHour);
      await prefs.setInt('notification_reminder_minute', _reminderMinute);

      // 通知サービスの設定を更新
      await _notificationService.updateNotificationSettings(
        dailyReminder: _dailyReminder,
        reminderHour: _reminderHour,
        reminderMinute: _reminderMinute,
        weeklyReport: _weeklyReport,
        budgetAlerts: _budgetAlerts,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('通知設定を保存しました'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('設定保存に失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('通知設定'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: '設定を保存',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 通知権限状態
                  _buildPermissionCard(),
                  SizedBox(height: 20),
                  
                  // 基本通知設定
                  _buildSectionHeader('基本通知設定'),
                  _buildNotificationToggle(
                    title: '毎日のリマインダー',
                    subtitle: '支出記録を忘れないようにお知らせします',
                    value: _dailyReminder,
                    onChanged: (value) {
                      setState(() {
                        _dailyReminder = value;
                      });
                    },
                    icon: Icons.schedule,
                  ),
                  
                  // リマインダー時間設定
                  if (_dailyReminder) _buildTimeSelector(),
                  
                  SizedBox(height: 20),
                  
                  // 予算関連通知
                  _buildSectionHeader('予算関連通知'),
                  _buildNotificationToggle(
                    title: '予算アラート',
                    subtitle: '予算の80%使用時と超過時にお知らせします',
                    value: _budgetAlerts,
                    onChanged: (value) {
                      setState(() {
                        _budgetAlerts = value;
                      });
                    },
                    icon: Icons.warning,
                  ),
                  
                  SizedBox(height: 20),
                  
                  // レポート通知
                  _buildSectionHeader('レポート通知'),
                  _buildNotificationToggle(
                    title: '週次レポート',
                    subtitle: '毎週日曜日に支出サマリーをお知らせします',
                    value: _weeklyReport,
                    onChanged: (value) {
                      setState(() {
                        _weeklyReport = value;
                      });
                    },
                    icon: Icons.assessment,
                  ),
                  
                  _buildNotificationToggle(
                    title: '月次レポート',
                    subtitle: '月末に予算達成状況をお知らせします',
                    value: _monthlyReport,
                    onChanged: (value) {
                      setState(() {
                        _monthlyReport = value;
                      });
                    },
                    icon: Icons.calendar_today,
                  ),
                  
                  SizedBox(height: 30),
                  
                  // テスト通知
                  _buildTestSection(),
                  
                  SizedBox(height: 20),
                  
                  // 保存ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: Icon(Icons.save),
                      label: Text('設定を保存'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPermissionCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _hasPermission ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasPermission ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _hasPermission ? Icons.check_circle : Icons.error,
                color: _hasPermission ? Colors.green[600] : Colors.red[600],
              ),
              SizedBox(width: 12),
              Text(
                '通知権限',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _hasPermission ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _hasPermission
                ? '通知権限が許可されています。すべての通知機能を利用できます。'
                : '通知権限が許可されていません。通知を受け取るには権限を許可してください。',
            style: TextStyle(
              fontSize: 14,
              color: _hasPermission ? Colors.green[600] : Colors.red[600],
            ),
          ),
          if (!_hasPermission) ...[
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                await _notificationService.openNotificationSettings();
                // 設定画面から戻ってきた時に権限を再チェック
                await Future.delayed(Duration(seconds: 1));
                _checkPermission();
              },
              icon: Icon(Icons.settings),
              label: Text('設定を開く'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildNotificationToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value ? Colors.blue[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: value ? Colors.blue[600] : Colors.grey[600],
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: _hasPermission ? onChanged : null,
          activeColor: Colors.blue[600],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'リマインダー時刻',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue[600]),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[600],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _selectTime,
                  child: Text('変更'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('テスト通知'),
        Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '通知のテスト',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '設定した通知が正常に動作するかテストできます',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTestButton(
                      '記録リマインダー',
                      Icons.schedule,
                      () => _notificationService.showExpenseReminder(),
                    ),
                    _buildTestButton(
                      '予算警告',
                      Icons.warning,
                      () => _notificationService.showBudgetWarning('食費', 40000, 50000),
                    ),
                    _buildTestButton(
                      '予算超過',
                      Icons.error,
                      () => _notificationService.showBudgetExceededNotification('交通費', 18000, 15000),
                    ),
                    _buildTestButton(
                      '週次サマリー',
                      Icons.assessment,
                      () => _notificationService.showWeeklySummary(85000, 75.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: _hasPermission ? onPressed : null,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        _reminderHour = selectedTime.hour;
        _reminderMinute = selectedTime.minute;
      });
    }
  }
}