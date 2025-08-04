import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'database_helper.dart';
import 'budget_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // 通知ID定数
  static const int DAILY_REMINDER_ID = 1;
  static const int BUDGET_WARNING_ID = 2;
  static const int WEEKLY_SUMMARY_ID = 3;
  static const int BUDGET_EXCEEDED_ID = 4;
  static const int DAILY_BUDGET_CHECK_ID = 5;

  // 初期化
  Future<void> initialize() async {
    // タイムゾーンデータの初期化
    tz.initializeTimeZones();

    // Android設定
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS設定
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 初期化設定
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 通知プラグインの初期化
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 権限の要求
    await _requestPermissions();
    
    // 初回起動時のスケジュール設定
    await _scheduleDefaultNotifications();
  }

  // 権限要求
  Future<void> _requestPermissions() async {
    // Android 13以上での通知権限要求
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    // 通知権限をPermission Handlerでも確認
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  // 通知タップ時の処理
  void _onNotificationTapped(NotificationResponse response) {
    print('通知がタップされました: ${response.payload}');
    
    // ペイロードに基づいて適切な画面に遷移
    switch (response.payload) {
      case 'expense_reminder':
        // 支出記録画面へ遷移（実装時に追加）
        break;
      case 'budget_warning':
      case 'budget_exceeded':
        // 予算管理画面へ遷移（実装時に追加）
        break;
      case 'weekly_summary':
        // サマリー画面へ遷移（実装時に追加）
        break;
    }
  }

  // シンプルな通知表示
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'default',
    String channelName = '一般通知',
    String channelDescription = '一般的な通知',
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) async {
    final AndroidNotificationDetails androidDetails = 
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: importance,
      priority: priority,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // 家計簿用の支出記録リマインダー
  Future<void> showExpenseReminder() async {
    await showInstantNotification(
      id: DateTime.now().millisecond,
      title: '💰 支出記録のお時間です',
      body: '今日の支出を記録して、家計管理を続けましょう！',
      payload: 'expense_reminder',
      channelId: 'reminders',
      channelName: 'リマインダー',
      channelDescription: '支出記録のリマインダー通知',
    );
  }

  // 予算超過警告通知
  Future<void> showBudgetWarning(String category, double currentAmount, double budget) async {
    final percentage = (currentAmount / budget * 100).toInt();
    
    await showInstantNotification(
      id: BUDGET_WARNING_ID,
      title: '⚠️ 予算警告: $category',
      body: '予算の${percentage}%を使用しました（¥${_formatCurrency(currentAmount)} / ¥${_formatCurrency(budget)}）',
      payload: 'budget_warning',
      channelId: 'budget_alerts',
      channelName: '予算アラート',
      channelDescription: '予算に関する警告通知',
      importance: Importance.high,
      priority: Priority.high,
    );
  }

  // 予算完全超過通知
  Future<void> showBudgetExceededNotification(String category, double currentAmount, double budget) async {
    final exceededAmount = currentAmount - budget;
    
    await showInstantNotification(
      id: BUDGET_EXCEEDED_ID,
      title: '🚨 予算超過: $category',
      body: '予算を¥${_formatCurrency(exceededAmount)}超過しました！今月の残り期間は注意しましょう。',
      payload: 'budget_exceeded',
      channelId: 'budget_alerts',
      channelName: '予算アラート',
      channelDescription: '予算超過の警告通知',
      importance: Importance.max,
      priority: Priority.max,
    );
  }

  // 週次サマリー通知
  Future<void> showWeeklySummary(double totalExpenses, double budgetUsagePercentage) async {
    String message;
    String emoji;
    
    if (budgetUsagePercentage <= 50) {
      emoji = '😊';
      message = '順調な家計管理ができています！';
    } else if (budgetUsagePercentage <= 80) {
      emoji = '😐';
      message = '予算の使いすぎに注意しましょう。';
    } else {
      emoji = '😰';
      message = '予算管理の見直しが必要かもしれません。';
    }
    
    await showInstantNotification(
      id: WEEKLY_SUMMARY_ID,
      title: '$emoji 今週の家計サマリー',
      body: '今週の支出: ¥${_formatCurrency(totalExpenses)} | $message',
      payload: 'weekly_summary',
      channelId: 'weekly_summary',
      channelName: '週次サマリー',
      channelDescription: '週間支出サマリー通知',
    );
  }

  // 予算状況の日次チェック（支出入力時に呼び出し）
  Future<void> checkBudgetStatus() async {
    final now = DateTime.now();
    final budgetAnalyses = await _databaseHelper.getBudgetAnalysisByPeriod(now.year, now.month);
    
    for (final analysis in budgetAnalyses) {
      // 80%超過で警告
      if (analysis.usagePercentage >= 80 && !analysis.isOverBudget) {
        await showBudgetWarning(
          analysis.budget.category,
          analysis.actualExpense,
          analysis.budget.monthlyLimit,
        );
      }
      // 予算完全超過で重要通知
      else if (analysis.isOverBudget) {
        await showBudgetExceededNotification(
          analysis.budget.category,
          analysis.actualExpense,
          analysis.budget.monthlyLimit,
        );
      }
    }
  }

  // スケジュール通知（毎日決まった時間）
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await _notifications.zonedSchedule(
      DAILY_REMINDER_ID,
      '📝 家計簿の時間',
      '今日の収支を記録しませんか？継続が成功の鍵です！',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          '毎日のリマインダー',
          channelDescription: '毎日決まった時間の家計簿リマインダー',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 毎日繰り返し
    );
  }

  // 週次サマリーのスケジュール通知（毎週日曜日）
  Future<void> scheduleWeeklySummary({
    int hour = 19,
    int minute = 0,
  }) async {
    await _notifications.zonedSchedule(
      WEEKLY_SUMMARY_ID,
      '📊 週間家計レポート',
      'この一週間の支出をチェックしてみましょう！',
      _nextInstanceOfWeekday(DateTime.sunday, hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_summary',
          '週間サマリー',
          channelDescription: '週間の家計サマリー通知',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // 月末予算チェック通知（毎月最終日）
  Future<void> scheduleMonthEndBudgetCheck() async {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final scheduledDate = tz.TZDateTime(
      tz.local,
      lastDayOfMonth.year,
      lastDayOfMonth.month,
      lastDayOfMonth.day,
      18, // 18時
      0,
    );

    await _notifications.zonedSchedule(
      DAILY_BUDGET_CHECK_ID,
      '📅 月末予算チェック',
      '今月の予算使用状況を確認しましょう！',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_monthly',
          '月次予算チェック',
          channelDescription: '月末の予算確認通知',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // 指定時間の次のインスタンスを取得
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // 指定曜日の次のインスタンスを取得
  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
    
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  // デフォルト通知のスケジュール設定
  Future<void> _scheduleDefaultNotifications() async {
    // 毎日20時にリマインダー
    await scheduleDailyReminder(hour: 20, minute: 0);
    
    // 毎週日曜日19時にサマリー
    await scheduleWeeklySummary(hour: 19, minute: 0);
    
    // 月末予算チェック
    await scheduleMonthEndBudgetCheck();
  }

  // 通知設定の更新
  Future<void> updateNotificationSettings({
    bool dailyReminder = true,
    int reminderHour = 20,
    int reminderMinute = 0,
    bool weeklyReport = true,
    bool budgetAlerts = true,
  }) async {
    // 既存の通知をキャンセル
    await cancelAllScheduledNotifications();
    
    // 新しい設定で通知をスケジュール
    if (dailyReminder) {
      await scheduleDailyReminder(hour: reminderHour, minute: reminderMinute);
    }
    
    if (weeklyReport) {
      await scheduleWeeklySummary();
    }
    
    // 予算アラートは設定でオン/オフを管理（実際のチェックは支出入力時に行う）
    // 設定をSharedPreferencesに保存（実装時に追加）
  }

  // 全ての通知をキャンセル
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // スケジュール通知のみキャンセル
  Future<void> cancelAllScheduledNotifications() async {
    await _notifications.cancel(DAILY_REMINDER_ID);
    await _notifications.cancel(WEEKLY_SUMMARY_ID);
    await _notifications.cancel(DAILY_BUDGET_CHECK_ID);
  }

  // 特定の通知をキャンセル
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // 金額フォーマット
  String _formatCurrency(double amount) {
    return amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // 通知権限の確認
  Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // 通知設定画面への誘導
  Future<void> openNotificationSettings() async {
    await openAppSettings();
  }

  // アプリがアクティブでない時の予算チェック（バックグラウンド処理用）
  Future<void> performBackgroundBudgetCheck() async {
    try {
      await checkBudgetStatus();
    } catch (e) {
      print('バックグラウンド予算チェックエラー: $e');
    }
  }
}