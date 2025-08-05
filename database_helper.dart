import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';
import 'budget_model.dart';
import 'goal_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  
  final int _databaseVersion = 4; // バージョンアップ

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'kakeibo.db');
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount INTEGER NOT NULL,
        category TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        memo TEXT,
        date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE incomes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount INTEGER NOT NULL,
        source TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        memo TEXT,
        date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE payment_methods(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        bank_name TEXT,
        card_number TEXT,
        withdrawal_day INTEGER,
        notes TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        monthly_limit REAL NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        notes TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        UNIQUE(category, year, month)
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0.0,
        start_date TEXT NOT NULL,
        target_date TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL DEFAULT 'その他',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE money_transfers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fromPaymentMethod TEXT NOT NULL,
        toPaymentMethod TEXT NOT NULL,
        amount REAL NOT NULL,
        memo TEXT,
        transferDate TEXT NOT NULL
      )
    ''');

    // お金の移行記録を挿入
    Future<int> insertMoneyTransfer(MoneyTransfer transfer) async {
      final db = await database;
      return await db.insert('money_transfers', transfer.toMap());
    }

    // お金の移行記録を取得
    Future<List<MoneyTransfer>> getMoneyTransfers() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'money_transfers',
        orderBy: 'transferDate DESC',
      );
      
      return List.generate(maps.length, (i) {
        return MoneyTransfer.fromMap(maps[i]);
      });
    }

    // 特定期間の移行記録を取得
    Future<List<MoneyTransfer>> getMoneyTransfersByDateRange(
        DateTime startDate, DateTime endDate) async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'money_transfers',
        where: 'transferDate BETWEEN ? AND ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
        orderBy: 'transferDate DESC',
      );
      
      return List.generate(maps.length, (i) {
        return MoneyTransfer.fromMap(maps[i]);
      });
    }

    // 移行記録を削除
    Future<void> deleteMoneyTransfer(int id) async {
      final db = await database;
      await db.delete(
        'money_transfers',
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    await _insertDefaultPaymentMethods(db);
    await _insertDefaultBudgets(db);
    await _insertDefaultGoals(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS payment_methods(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          balance REAL NOT NULL DEFAULT 0.0,
          bank_name TEXT,
          card_number TEXT,
          withdrawal_day INTEGER,
          notes TEXT,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');
      
      await _insertDefaultPaymentMethods(db);
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          monthly_limit REAL NOT NULL,
          year INTEGER NOT NULL,
          month INTEGER NOT NULL,
          notes TEXT,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          UNIQUE(category, year, month)
        )
      ''');

      await _insertDefaultBudgets(db);
    }

    if (oldVersion < 4) {
      // 目標管理テーブルを追加
      await db.execute('''
        CREATE TABLE IF NOT EXISTS savings_goals(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          target_amount REAL NOT NULL,
          current_amount REAL NOT NULL DEFAULT 0.0,
          start_date TEXT NOT NULL,
          target_date TEXT NOT NULL,
          description TEXT,
          category TEXT NOT NULL DEFAULT 'その他',
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      await _insertDefaultGoals(db);
    }
  }

  Future<void> _insertDefaultPaymentMethods(Database db) async {
    final String currentDate = DateTime.now().toIso8601String();
    
    final List<Map<String, dynamic>> defaultMethods = [
      {
        'name': '現金',
        'type': 'cash',
        'balance': 0.0,
        'created_at': currentDate,
      },
      {
        'name': 'メイン銀行',
        'type': 'bank',
        'balance': 0.0,
        'created_at': currentDate,
      },
      {
        'name': '電子マネー',
        'type': 'emoney',
        'balance': 0.0,
        'created_at': currentDate,
      },
    ];

    for (var method in defaultMethods) {
      await db.insert('payment_methods', method, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _insertDefaultBudgets(Database db) async {
    final String currentDate = DateTime.now().toIso8601String();
    final DateTime now = DateTime.now();
    
    final List<Map<String, dynamic>> defaultBudgets = [
      {
        'category': '食費',
        'monthly_limit': 50000.0,
        'year': now.year,
        'month': now.month,
        'notes': '外食・食材費',
        'created_at': currentDate,
      },
      {
        'category': '交通費',
        'monthly_limit': 15000.0,
        'year': now.year,
        'month': now.month,
        'notes': '電車・バス・ガソリン代',
        'created_at': currentDate,
      },
      {
        'category': '娯楽費',
        'monthly_limit': 20000.0,
        'year': now.year,
        'month': now.month,
        'notes': '映画・ゲーム・趣味',
        'created_at': currentDate,
      },
      {
        'category': '日用品',
        'monthly_limit': 10000.0,
        'year': now.year,
        'month': now.month,
        'notes': '洗剤・消耗品など',
        'created_at': currentDate,
      },
    ];

    for (var budget in defaultBudgets) {
      await db.insert('budgets', budget, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _insertDefaultGoals(Database db) async {
    final String currentDate = DateTime.now().toIso8601String();
    final DateTime now = DateTime.now();
    final DateTime sixMonthsLater = now.add(Duration(days: 180));
    
    final List<Map<String, dynamic>> defaultGoals = [
      {
        'title': '緊急資金',
        'target_amount': 500000.0,
        'current_amount': 0.0,
        'start_date': now.toIso8601String(),
        'target_date': sixMonthsLater.toIso8601String(),
        'description': '万が一に備えた緊急資金',
        'category': '緊急資金',
        'created_at': currentDate,
      },
    ];

    for (var goal in defaultGoals) {
      await db.insert('savings_goals', goal, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // 既存メソッド（省略可能）
  Future<int> insertExpense(Map<String, dynamic> expense) async {
    final db = await database;
    return await db.insert('expenses', expense);
  }

  Future<int> insertIncome(Map<String, dynamic> income) async {
    final db = await database;
    return await db.insert('incomes', income);
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final db = await database;
    return await db.query('expenses', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getIncomes() async {
    final db = await database;
    return await db.query('incomes', orderBy: 'date DESC');
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> updateIncome(Income income) async {
    final db = await database;
    return await db.update(
      'incomes',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteIncome(int id) async {
    final db = await database;
    return await db.delete('incomes', where: 'id = ?', whereArgs: [id]);
  }

  // 支払い方法関連メソッド
  Future<int> insertPaymentMethod(Map<String, dynamic> paymentMethod) async {
    final db = await database;
    return await db.insert('payment_methods', paymentMethod);
  }

  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    final db = await database;
    return await db.query(
      'payment_methods',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at ASC',
    );
  }

  Future<int> updatePaymentMethod(int id, Map<String, dynamic> paymentMethod) async {
    final db = await database;
    return await db.update(
      'payment_methods',
      paymentMethod,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePaymentMethod(int id) async {
    final db = await database;
    return await db.update(
      'payment_methods',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updatePaymentMethodBalance(int id, double newBalance) async {
    final db = await database;
    return await db.update(
      'payment_methods',
      {
        'balance': newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<String>> getPaymentMethodNames() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_methods',
      columns: ['name'],
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => map['name'] as String).toList();
  }

  // === 予算管理関連メソッド ===

  Future<int> insertBudget(Map<String, dynamic> budget) async {
    final db = await database;
    return await db.insert('budgets', budget, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getBudgets() async {
    final db = await database;
    return await db.query(
      'budgets',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'year DESC, month DESC, category ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getBudgetsByPeriod(int year, int month) async {
    final db = await database;
    return await db.query(
      'budgets',
      where: 'is_active = ? AND year = ? AND month = ?',
      whereArgs: [1, year, month],
      orderBy: 'category ASC',
    );
  }

  Future<int> updateBudget(Budget budget) async {
    final db = await database;
    return await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<int> deleteBudget(int id) async {
    final db = await database;
    return await db.update(
      'budgets',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getExpensesByPeriodAndCategory(int year, int month, String category) async {
    final db = await database;
    
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();
    
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM expenses
      WHERE category = ? AND date >= ? AND date <= ?
    ''', [category, startDate, endDate]);
    
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, dynamic>> getMonthlyBudgetSummary(int year, int month) async {
    final budgets = await getBudgetsByPeriod(year, month);
    
    double totalBudget = 0.0;
    double totalActual = 0.0;
    int overBudgetCount = 0;
    
    for (var budgetMap in budgets) {
      final budget = Budget.fromMap(budgetMap);
      final actual = await getExpensesByPeriodAndCategory(year, month, budget.category);
      
      totalBudget += budget.monthlyLimit;
      totalActual += actual;
      
      if (actual > budget.monthlyLimit) {
        overBudgetCount++;
      }
    }
    
    return {
      'totalBudget': totalBudget,
      'totalActual': totalActual,
      'remaining': totalBudget - totalActual,
      'usagePercentage': totalBudget > 0 ? (totalActual / totalBudget) * 100 : 0.0,
      'overBudgetCount': overBudgetCount,
      'categoryCount': budgets.length,
    };
  }

  Future<List<String>> getExpenseCategories() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT category
      FROM expenses
      ORDER BY category ASC
    ''');
    
    final List<String> categories = result.map((row) => row['category'] as String).toList();
    
    final defaultCategories = ['食費', '交通費', '娯楽費', '日用品', '医療費', '教育費', '光熱費', '通信費', 'その他'];
    
    final Set<String> allCategories = {...categories, ...defaultCategories};
    return allCategories.toList()..sort();
  }

  Future<List<BudgetAnalysis>> getBudgetAnalysisByPeriod(int year, int month) async {
    final budgets = await getBudgetsByPeriod(year, month);
    final List<BudgetAnalysis> analyses = [];
    
    for (var budgetMap in budgets) {
      final budget = Budget.fromMap(budgetMap);
      final actualExpense = await getExpensesByPeriodAndCategory(year, month, budget.category);
      
      final analysis = BudgetAnalysis.calculate(budget, actualExpense);
      analyses.add(analysis);
    }
    
    return analyses;
  }

  // === 目標管理関連メソッド ===

  // 目標を挿入
  Future<int> insertSavingsGoal(Map<String, dynamic> goal) async {
    final db = await database;
    return await db.insert('savings_goals', goal);
  }

  // アクティブな目標一覧を取得
  Future<List<Map<String, dynamic>>> getSavingsGoals() async {
    final db = await database;
    return await db.query(
      'savings_goals',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'target_date ASC',
    );
  }

  // 特定の目標を取得
  Future<Map<String, dynamic>?> getSavingsGoalById(int id) async {
    final db = await database;
    final results = await db.query(
      'savings_goals',
      where: 'id = ? AND is_active = ?',
      whereArgs: [id, 1],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // 目標を更新
  Future<int> updateSavingsGoal(SavingsGoal goal) async {
    final db = await database;
    return await db.update(
      'savings_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  // 目標の現在額を更新
  Future<int> updateGoalCurrentAmount(int goalId, double newAmount) async {
    final db = await database;
    return await db.update(
      'savings_goals',
      {
        'current_amount': newAmount,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  // 目標に金額を追加
  Future<int> addToGoalAmount(int goalId, double addAmount) async {
    final db = await database;
    
    // 現在の金額を取得
    final goalData = await getSavingsGoalById(goalId);
    if (goalData == null) return 0;
    
    final currentAmount = goalData['current_amount'].toDouble();
    final newAmount = currentAmount + addAmount;
    
    return await updateGoalCurrentAmount(goalId, newAmount);
  }

  // 目標を削除（論理削除）
  Future<int> deleteSavingsGoal(int id) async {
    final db = await database;
    return await db.update(
      'savings_goals',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 目標の分析データを取得
  Future<List<GoalAnalysis>> getGoalAnalyses() async {
    final goalsData = await getSavingsGoals();
    final List<GoalAnalysis> analyses = [];
    
    for (var goalMap in goalsData) {
      final goal = SavingsGoal.fromMap(goalMap);
      final analysis = GoalAnalysis.calculate(goal);
      analyses.add(analysis);
    }
    
    return analyses;
  }

  // 達成済みの目標を取得
  Future<List<Map<String, dynamic>>> getCompletedGoals() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT * FROM savings_goals
      WHERE is_active = 1 AND current_amount >= target_amount
      ORDER BY updated_at DESC
    ''');
  }

  // 期限切れの目標を取得
  Future<List<Map<String, dynamic>>> getOverdueGoals() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.rawQuery('''
      SELECT * FROM savings_goals
      WHERE is_active = 1 AND target_date < ? AND current_amount < target_amount
      ORDER BY target_date ASC
    ''', [now]);
  }

  // 今月の目標貯金額を取得
  Future<double> getMonthlyGoalSavingsAmount() async {
    final goals = await getSavingsGoals();
    double totalMonthly = 0.0;
    
    for (var goalMap in goals) {
      final goal = SavingsGoal.fromMap(goalMap);
      if (!goal.isCompleted && !goal.isOverdue) {
        totalMonthly += goal.monthlyRequiredAmount;
      }
    }
    
    return totalMonthly;
  }

  // === 予算管理の拡張機能 ===

  // 前月の予算をコピー
  Future<int> copyPreviousMonthBudget(int targetYear, int targetMonth) async {
    final db = await database;
    
    // 前月の年月を計算
    DateTime targetDate = DateTime(targetYear, targetMonth);
    DateTime previousMonth = DateTime(targetDate.year, targetDate.month - 1);
    
    // 前月の予算を取得
    final previousBudgets = await getBudgetsByPeriod(previousMonth.year, previousMonth.month);
    
    if (previousBudgets.isEmpty) {
      throw Exception('前月の予算が設定されていません');
    }
    
    int copiedCount = 0;
    final String currentDate = DateTime.now().toIso8601String();
    
    for (var budgetMap in previousBudgets) {
      final previousBudget = Budget.fromMap(budgetMap);
      
      // 新しい予算データを作成
      Map<String, dynamic> newBudgetData = {
        'category': previousBudget.category,
        'monthly_limit': previousBudget.monthlyLimit,
        'year': targetYear,
        'month': targetMonth,
        'notes': previousBudget.notes,
        'is_active': 1,
        'created_at': currentDate,
      };
      
      try {
        await db.insert('budgets', newBudgetData, conflictAlgorithm: ConflictAlgorithm.replace);
        copiedCount++;
      } catch (e) {
        print('予算コピーエラー (${previousBudget.category}): $e');
      }
    }
    
    return copiedCount;
  }

  // 過去データから自動予算設定
  Future<Map<String, double>> generateAutoBudgetSuggestions(int targetYear, int targetMonth) async {
    final db = await database;
    
    // 過去6ヶ月のデータを取得
    final DateTime targetDate = DateTime(targetYear, targetMonth);
    final DateTime sixMonthsAgo = DateTime(targetDate.year, targetDate.month - 6);
    
    final result = await db.rawQuery('''
      SELECT category, AVG(monthly_total) as avg_amount
      FROM (
        SELECT 
          category,
          strftime('%Y', date) as year,
          strftime('%m', date) as month,
          SUM(amount) as monthly_total
        FROM expenses
        WHERE date >= ? AND date < ?
        GROUP BY category, year, month
      )
      GROUP BY category
      HAVING COUNT(*) >= 2
      ORDER BY avg_amount DESC
    ''', [
      sixMonthsAgo.toIso8601String(),
      targetDate.toIso8601String(),
    ]);
    
    Map<String, double> suggestions = {};
    
    for (var row in result) {
      final category = row['category'] as String;
      final avgAmount = (row['avg_amount'] as num).toDouble();
      
      // 平均の110%を推奨予算とする（少し余裕を持たせる）
      final suggestedAmount = (avgAmount * 1.1).roundToDouble();
      suggestions[category] = suggestedAmount;
    }
    
    return suggestions;
  }

  // 自動予算を適用
  Future<int> applyAutoBudget(int targetYear, int targetMonth, Map<String, double> suggestions) async {
    final db = await database;
    int appliedCount = 0;
    final String currentDate = DateTime.now().toIso8601String();
    
    for (var entry in suggestions.entries) {
      Map<String, dynamic> budgetData = {
        'category': entry.key,
        'monthly_limit': entry.value,
        'year': targetYear,
        'month': targetMonth,
        'notes': '過去データから自動設定',
        'is_active': 1,
        'created_at': currentDate,
      };
      
      try {
        await db.insert('budgets', budgetData, conflictAlgorithm: ConflictAlgorithm.replace);
        appliedCount++;
      } catch (e) {
        print('自動予算適用エラー (${entry.key}): $e');
      }
    }
    
    return appliedCount;
  }

  // カテゴリ別支出統計を取得
  Future<Map<String, dynamic>> getCategoryExpenseStats(String category, {int months = 6}) async {
    final db = await database;
    final DateTime now = DateTime.now();
    final DateTime startDate = DateTime(now.year, now.month - months);
    
    final result = await db.rawQuery('''
      SELECT 
        AVG(amount) as avg_amount,
        MIN(amount) as min_amount,
        MAX(amount) as max_amount,
        COUNT(*) as transaction_count,
        SUM(amount) as total_amount
      FROM expenses
      WHERE category = ? AND date >= ?
    ''', [category, startDate.toIso8601String()]);
    
    if (result.isEmpty || result.first['avg_amount'] == null) {
      return {
        'avgAmount': 0.0,
        'minAmount': 0.0,
        'maxAmount': 0.0,
        'transactionCount': 0,
        'totalAmount': 0.0,
        'monthlyAverage': 0.0,
      };
    }
    
    final row = result.first;
    return {
      'avgAmount': (row['avg_amount'] as num).toDouble(),
      'minAmount': (row['min_amount'] as num).toDouble(),
      'maxAmount': (row['max_amount'] as num).toDouble(),
      'transactionCount': row['transaction_count'] as int,
      'totalAmount': (row['total_amount'] as num).toDouble(),
      'monthlyAverage': (row['total_amount'] as num).toDouble() / months,
    };
  }

  // 月別支出トレンドを取得
  Future<List<Map<String, dynamic>>> getMonthlyExpenseTrend({int months = 12}) async {
    final db = await database;
    final DateTime now = DateTime.now();
    final DateTime startDate = DateTime(now.year, now.month - months);
    
    final result = await db.rawQuery('''
      SELECT 
        strftime('%Y', date) as year,
        strftime('%m', date) as month,
        SUM(amount) as total_amount,
        COUNT(*) as transaction_count
      FROM expenses
      WHERE date >= ?
      GROUP BY year, month
      ORDER BY year, month
    ''', [startDate.toIso8601String()]);
    
    return result;
  }

  // 支出予測機能
  Future<double> predictNextMonthExpense(String? category) async {
    final db = await database;
    final DateTime now = DateTime.now();
    final DateTime threeMonthsAgo = DateTime(now.year, now.month - 3);
    
    String query;
    List<dynamic> params;
    
    if (category != null) {
      query = '''
        SELECT AVG(monthly_total) as predicted_amount
        FROM (
          SELECT 
            strftime('%Y-%m', date) as month,
            SUM(amount) as monthly_total
          FROM expenses
          WHERE category = ? AND date >= ?
          GROUP BY month
        )
      ''';
      params = [category, threeMonthsAgo.toIso8601String()];
    } else {
      query = '''
        SELECT AVG(monthly_total) as predicted_amount
        FROM (
          SELECT 
            strftime('%Y-%m', date) as month,
            SUM(amount) as monthly_total
          FROM expenses
          WHERE date >= ?
          GROUP BY month
        )
      ''';
      params = [threeMonthsAgo.toIso8601String()];
    }
    
    final result = await db.rawQuery(query, params);
    
    if (result.isEmpty || result.first['predicted_amount'] == null) {
      return 0.0;
    }
    
    return (result.first['predicted_amount'] as num).toDouble();
  }
}