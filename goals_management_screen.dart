import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'goal_model.dart';

class GoalsManagementScreen extends StatefulWidget {
  @override
  _GoalsManagementScreenState createState() => _GoalsManagementScreenState();
}

class _GoalsManagementScreenState extends State<GoalsManagementScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<GoalAnalysis> _goalAnalyses = [];
  Map<String, dynamic> _goalsSummary = {};
  bool _isLoading = true;
  
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGoalsData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadGoalsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final analyses = await _databaseHelper.getGoalAnalyses();
      final summary = await _databaseHelper.getGoalsSummary();

      setState(() {
        _goalAnalyses = analyses;
        _goalsSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      print('目標データ読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('目標管理'),
        backgroundColor: Colors.purple[700],
        bottom: _tabController != null ? TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.flag), text: '進行中'),
            Tab(icon: Icon(Icons.check_circle), text: '達成済み'),
            Tab(icon: Icon(Icons.bar_chart), text: 'サマリー'),
          ],
        ) : null,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadGoalsData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _tabController != null ? TabBarView(
              controller: _tabController,
              children: [
                _buildActiveGoalsTab(),
                _buildCompletedGoalsTab(),
                _buildSummaryTab(),
              ],
            ) : Container(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addGoal,
        backgroundColor: Colors.purple[700],
        child: Icon(Icons.add),
        tooltip: '目標を追加',
      ),
    );
  }

  Widget _buildActiveGoalsTab() {
    final activeGoals = _goalAnalyses.where((analysis) => 
        !analysis.goal.isCompleted && analysis.goal.isActive).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 概要カード
          _buildOverviewCard(),
          SizedBox(height: 20),
          
          if (activeGoals.isEmpty)
            _buildEmptyGoalsState()
          else
            ...activeGoals.map((analysis) => _buildGoalCard(analysis)).toList(),
        ],
      ),
    );
  }

  Widget _buildCompletedGoalsTab() {
    final completedGoals = _goalAnalyses.where((analysis) => 
        analysis.goal.isCompleted).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '達成した目標 (${completedGoals.length}件)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          
          if (completedGoals.isEmpty)
            _buildEmptyCompletedState()
          else
            ...completedGoals.map((analysis) => _buildCompletedGoalCard(analysis)).toList(),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '目標達成サマリー',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          
          _buildSummaryCards(),
          SizedBox(height: 20),
          
          _buildProgressChart(),
          SizedBox(height: 20),
          
          _buildRecommendations(),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    final totalGoals = _goalsSummary['totalGoals'] ?? 0;
    final onTrackGoals = _goalsSummary['onTrackGoals'] ?? 0;
    final behindGoals = _goalsSummary['behindGoals'] ?? 0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[600]!, Colors.purple[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '目標達成状況',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewItem('総目標数', '$totalGoals', Icons.flag),
              _buildOverviewItem('順調', '$onTrackGoals', Icons.trending_up),
              _buildOverviewItem('遅れ', '$behindGoals', Icons.trending_down),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(GoalAnalysis analysis) {
    final goal = analysis.goal;
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー行
            Row(
              children: [
                Text(
                  goal.categoryIcon,
                  style: TextStyle(fontSize: 28),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${goal.formattedCurrentAmount} / ${goal.formattedTargetAmount}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: goal.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    goal.statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: goal.statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () => _showGoalOptions(goal),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // プログレスバー
            LinearProgressIndicator(
              value: goal.progressPercentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(goal.statusColor),
              minHeight: 8,
            ),
            SizedBox(height: 8),
            
            Text(
              '${goal.progressPercent}% 達成',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: goal.statusColor,
              ),
            ),
            SizedBox(height: 12),
            
            // 詳細情報
            Row(
              children: [
                Expanded(
                  child: _buildGoalDetailItem(
                    '残り金額',
                    goal.formattedRemainingAmount,
                    Icons.account_balance_wallet,
                  ),
                ),
                Expanded(
                  child: _buildGoalDetailItem(
                    '残り日数',
                    '${goal.remainingDays}日',
                    Icons.calendar_today,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: _buildGoalDetailItem(
                    '1日必要額',
                    goal.formattedDailyRequired,
                    Icons.today,
                  ),
                ),
                Expanded(
                  child: _buildGoalDetailItem(
                    '月必要額',
                    goal.formattedMonthlyRequired,
                    Icons.date_range,
                  ),
                ),
              ],
            ),
            
            // アドバイス
            if (analysis.adviceText.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: analysis.isOnTrack ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: analysis.isOnTrack ? Colors.green[200]! : Colors.orange[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      analysis.isOnTrack ? Icons.check_circle : Icons.warning,
                      color: analysis.isOnTrack ? Colors.green[600] : Colors.orange[600],
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        analysis.adviceText,
                        style: TextStyle(
                          fontSize: 12,
                          color: analysis.isOnTrack ? Colors.green[700] : Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedGoalCard(GoalAnalysis analysis) {
    final goal = analysis.goal;
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.green[600]),
            ),
            SizedBox(width: 12),
            Text(
              goal.categoryIcon,
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    goal.formattedTargetAmount,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '🎉 達成',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGoalsState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.flag_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            '目標が設定されていません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '右下の＋ボタンから\n貯金目標を設定してください',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCompletedState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            '達成した目標がありません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '目標を設定して達成を目指しましょう！',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalTargetAmount = _goalsSummary['totalTargetAmount']?.toDouble() ?? 0.0;
    final totalCurrentAmount = _goalsSummary['totalCurrentAmount']?.toDouble() ?? 0.0;
    final overallProgress = _goalsSummary['overallProgress']?.toDouble() ?? 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                '総目標額',
                _formatCurrency(totalTargetAmount),
                Icons.flag,
                Colors.blue,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                '現在貯金額',
                _formatCurrency(totalCurrentAmount),
                Icons.account_balance_wallet,
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        _buildSummaryCard(
          '全体達成率',
          '${overallProgress.toInt()}%',
          Icons.trending_up,
          Colors.purple,
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, {bool isWide = false}) {
    return Container(
      width: isWide ? double.infinity : null,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
    // プログレス表示の実装（簡易版）
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '目標進捗チャート',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '詳細なチャート機能は今後実装予定です',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '改善提案',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'AI による目標達成アドバイス機能は今後実装予定です',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '¥${amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  void _addGoal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoalFormScreen(),
      ),
    ).then((result) {
      if (result == true) {
        _loadGoalsData();
      }
    });
  }

  void _showGoalOptions(SavingsGoal goal) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.add_circle, color: Colors.green),
              title: Text('貯金額を追加'),
              onTap: () {
                Navigator.pop(context);
                _addToGoal(goal);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: Colors.blue),
              title: Text('目標を編集'),
              onTap: () {
                Navigator.pop(context);
                _editGoal(goal);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('目標を削除'),
              onTap: () {
                Navigator.pop(context);
                _deleteGoal(goal);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addToGoal(SavingsGoal goal) {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('「${goal.title}」に貯金'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('現在の貯金額: ${goal.formattedCurrentAmount}'),
              SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '追加する金額',
                  prefixText: '¥',
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
              onPressed: () => _performAddToGoal(goal, amountController.text),
              child: Text('追加'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performAddToGoal(SavingsGoal goal, String amountText) async {
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('金額を入力してください')),
      );
      return;
    }

    try {
      double amount = double.parse(amountText);
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('正しい金額を入力してください')),
        );
        return;
      }

      await _databaseHelper.addToGoalAmount(goal.id!, amount);
      Navigator.pop(context);
      _loadGoalsData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¥${amount.toInt()}を「${goal.title}」に追加しました'),
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

  void _editGoal(SavingsGoal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoalFormScreen(goal: goal),
      ),
    ).then((result) {
      if (result == true) {
        _loadGoalsData();
      }
    });
  }

  void _deleteGoal(SavingsGoal goal) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('目標の削除'),
        content: Text('「${goal.title}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('削除'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await _databaseHelper.deleteSavingsGoal(goal.id!);
        _loadGoalsData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('目標を削除しました'),
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
}

// 目標追加・編集フォーム画面
class GoalFormScreen extends StatefulWidget {
  final SavingsGoal? goal;

  GoalFormScreen({this.goal});

  @override
  _GoalFormScreenState createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'その他';
  DateTime _startDate = DateTime.now();
  DateTime _targetDate = DateTime.now().add(Duration(days: 365));
  
  bool _isLoading = false;

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  final List<String> _categories = [
    '旅行', '車', '結婚式', '家', '教育', '緊急資金', '投資', '家電', '趣味', 'その他'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _loadExistingGoal();
    }
  }

  void _loadExistingGoal() {
    final goal = widget.goal!;
    _titleController.text = goal.title;
    _targetAmountController.text = goal.targetAmount.toInt().toString();
    _currentAmountController.text = goal.currentAmount.toInt().toString();
    _descriptionController.text = goal.description ?? '';
    _selectedCategory = goal.category;
    _startDate = goal.startDate;
    _targetDate = goal.targetDate;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.goal != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '目標編集' : '目標追加'),
        backgroundColor: Colors.purple[700],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 目標タイトル
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '目標タイトル *',
                  hintText: '例：海外旅行資金',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '目標タイトルを入力してください';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // カテゴリ選択
              Text(
                'カテゴリ *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Row(
                      children: [
                        Text(
                          SavingsGoal(
                            title: '',
                            targetAmount: 0,
                            startDate: DateTime.now(),
                            targetDate: DateTime.now(),
                            category: category,
                            createdAt: '',
                          ).categoryIcon,
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(width: 12),
                        Text(category),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              SizedBox(height: 20),

              // 目標金額
              TextFormField(
                controller: _targetAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '目標金額 *',
                  hintText: '500000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet),
                  prefixText: '¥',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '目標金額を入力してください';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return '正しい金額を入力してください';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // 現在の貯金額
              TextFormField(
                controller: _currentAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '現在の貯金額',
                  hintText: '0',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.savings),
                  prefixText: '¥',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null || double.parse(value) < 0) {
                      return '正しい金額を入力してください';
                    }
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // 期間設定
              Text(
                '期間設定',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: _buildDateSelector(
                      '開始日',
                      _startDate,
                      (date) => setState(() => _startDate = date),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildDateSelector(
                      '目標日',
                      _targetDate,
                      (date) => setState(() => _targetDate = date),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // 説明・メモ
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: '説明・メモ（任意）',
                  hintText: '目標に関する詳細や動機を入力',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 30),

              // 期間計算表示
              _buildPeriodInfo(),
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
                      onPressed: _isLoading ? null : _saveGoal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[700],
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

  Widget _buildDateSelector(String label, DateTime selectedDate, Function(DateTime) onDateSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) {
              onDateSelected(date);
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  '${selectedDate.year}/${selectedDate.month}/${selectedDate.day}',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodInfo() {
    if (_targetAmountController.text.isEmpty) return Container();
    
    final targetAmount = double.tryParse(_targetAmountController.text) ?? 0;
    final currentAmount = double.tryParse(_currentAmountController.text) ?? 0;
    final remainingAmount = targetAmount - currentAmount;
    final totalDays = _targetDate.difference(_startDate).inDays;
    final dailyRequired = totalDays > 0 ? remainingAmount / totalDays : 0;
    final monthlyRequired = dailyRequired * 30;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '目標達成に必要な貯金額',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(height: 8),
          Text('期間: ${totalDays}日'),
          Text('1日あたり: ¥${dailyRequired.toInt().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          )}'),
          Text('1ヶ月あたり: ¥${monthlyRequired.toInt().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          )}'),
        ],
      ),
    );
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_targetDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('目標日は開始日以降を選択してください')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String currentDate = DateTime.now().toIso8601String();
      final double targetAmount = double.parse(_targetAmountController.text);
      final double currentAmount = _currentAmountController.text.isEmpty 
          ? 0.0 
          : double.parse(_currentAmountController.text);

      if (widget.goal == null) {
        // 新規追加
        Map<String, dynamic> goalData = {
          'title': _titleController.text.trim(),
          'target_amount': targetAmount,
          'current_amount': currentAmount,
          'start_date': _startDate.toIso8601String(),
          'target_date': _targetDate.toIso8601String(),
          'description': _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          'category': _selectedCategory,
          'is_active': 1,
          'created_at': currentDate,
        };
        
        await _databaseHelper.insertSavingsGoal(goalData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('目標「${_titleController.text}」を追加しました'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // 更新
        final updatedGoal = widget.goal!.copyWith(
          title: _titleController.text.trim(),
          targetAmount: targetAmount,
          currentAmount: currentAmount,
          startDate: _startDate,
          targetDate: _targetDate,
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          category: _selectedCategory,
          updatedAt: currentDate,
        );
        
        await _databaseHelper.updateSavingsGoal(updatedGoal);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('目標「${_titleController.text}」を更新しました'),
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

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}