import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as Math;
import 'goal_model.dart';
import 'database_helper.dart';

class GoalDetailAnalysisScreen extends StatefulWidget {
  final SavingsGoal goal;

  GoalDetailAnalysisScreen({required this.goal});

  @override
  _GoalDetailAnalysisScreenState createState() => _GoalDetailAnalysisScreenState();
}

class _GoalDetailAnalysisScreenState extends State<GoalDetailAnalysisScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  TabController? _tabController;
  
  Map<String, dynamic> _analysisData = {};
  List<Map<String, dynamic>> _progressHistory = [];
  Map<String, double> _projectionData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalysisData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadAnalysisData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final analysis = await _analyzeGoal();
      final history = await _getProgressHistory();
      final projection = await _calculateProjections();

      setState(() {
        _analysisData = analysis;
        _progressHistory = history;
        _projectionData = projection;
        _isLoading = false;
      });
    } catch (e) {
      print('目標分析データ読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _analyzeGoal() async {
    final goal = widget.goal;
    final analysis = GoalAnalysis.calculate(goal);
    
    // より詳細な分析データを計算
    final now = DateTime.now();
    final totalDays = goal.totalDays;
    final elapsedDays = goal.elapsedDays;
    final remainingDays = goal.remainingDays;
    
    // 進捗の傾向分析
    final expectedProgress = elapsedDays / totalDays.toDouble();
    final actualProgress = goal.progressPercentage;
    final progressDifference = actualProgress - expectedProgress;
    
    // パフォーマンス評価
    String performanceRating;
    Color performanceColor;
    
    if (progressDifference >= 0.1) {
      performanceRating = '優秀';
      performanceColor = Colors.green;
    } else if (progressDifference >= 0) {
      performanceRating = '良好';
      performanceColor = Colors.blue;
    } else if (progressDifference >= -0.1) {
      performanceRating = '注意';
      performanceColor = Colors.orange;
    } else {
      performanceRating = '要改善';
      performanceColor = Colors.red;
    }
    
    // 週平均・月平均の貯金額
    final weeklyAverage = elapsedDays > 0 ? (goal.currentAmount / elapsedDays) * 7 : 0.0;
    final monthlyAverage = elapsedDays > 0 ? (goal.currentAmount / elapsedDays) * 30 : 0.0;
    
    return {
      'performanceRating': performanceRating,
      'performanceColor': performanceColor,
      'progressDifference': progressDifference,
      'expectedProgress': expectedProgress,
      'weeklyAverage': weeklyAverage,
      'monthlyAverage': monthlyAverage,
      'projectedCompletionDate': analysis.projectedCompletionDate,
      'isOnTrack': analysis.isOnTrack,
      'adviceText': analysis.adviceText,
    };
  }

  Future<List<Map<String, dynamic>>> _getProgressHistory() async {
    // 実際の実装では、目標の更新履歴テーブルから取得
    // 簡易版として、現在のデータから推定値を生成
    final goal = widget.goal;
    final elapsedDays = goal.elapsedDays;
    final List<Map<String, dynamic>> history = [];
    
    // 過去30日分のデータを生成（実際の実装では実データを使用）
    for (int i = 0; i <= Math.min(elapsedDays, 30); i++) {
      final day = DateTime.now().subtract(Duration(days: 30 - i));
      final progressRatio = (elapsedDays - (30 - i)) / elapsedDays.toDouble();
      final estimatedAmount = goal.currentAmount * progressRatio.clamp(0.0, 1.0);
      
      history.add({
        'date': day,
        'amount': estimatedAmount,
        'targetAmount': goal.targetAmount,
        'progressPercentage': (estimatedAmount / goal.targetAmount) * 100,
      });
    }
    
    return history;
  }

  Future<Map<String, double>> _calculateProjections() async {
    final goal = widget.goal;
    final dailyAverage = goal.dailyAverageAmount;
    
    // 現在のペースでの予想
    final currentPaceProjection = dailyAverage * goal.totalDays;
    
    // 必要ペースでの予想
    final requiredPaceProjection = goal.targetAmount;
    
    // 楽観的シナリオ（現在のペースの120%）
    final optimisticProjection = currentPaceProjection * 1.2;
    
    // 悲観的シナリオ（現在のペースの80%）
    final pessimisticProjection = currentPaceProjection * 0.8;
    
    return {
      'currentPace': currentPaceProjection,
      'requiredPace': requiredPaceProjection,
      'optimistic': optimisticProjection,
      'pessimistic': pessimisticProjection,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('「${widget.goal.title}」詳細分析'),
        backgroundColor: Colors.purple[700],
        bottom: _tabController != null ? TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.analytics), text: '分析'),
            Tab(icon: Icon(Icons.trending_up), text: '進捗'),
            Tab(icon: Icon(Icons.predictions), text: '予測'),
          ],
        ) : null,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAnalysisData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _tabController != null ? TabBarView(
              controller: _tabController,
              children: [
                _buildAnalysisTab(),
                _buildProgressTab(),
                _buildProjectionTab(),
              ],
            ) : Container(),
    );
  }

  Widget _buildAnalysisTab() {
    final goal = widget.goal;
    final analysis = _analysisData;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 目標概要カード
          _buildGoalOverviewCard(),
          SizedBox(height: 20),
          
          // パフォーマンス評価
          _buildPerformanceCard(),
          SizedBox(height: 20),
          
          // 統計データ
          _buildStatisticsCard(),
          SizedBox(height: 20),
          
          // アドバイスカード
          _buildAdviceCard(),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '進捗履歴',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          
          // 進捗チャート
          Container(
            height: 300,
            child: _buildProgressChart(),
          ),
          SizedBox(height: 20),
          
          // 重要マイルストーン
          _buildMilestonesCard(),
        ],
      ),
    );
  }

  Widget _buildProjectionTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '達成予測シナリオ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          
          // 予測チャート
          Container(
            height: 250,
            child: _buildProjectionChart(),
          ),
          SizedBox(height: 20),
          
          // シナリオ分析
          _buildScenarioAnalysis(),
          SizedBox(height: 20),
          
          // 改善提案
          _buildImprovementSuggestions(),
        ],
      ),
    );
  }

  Widget _buildGoalOverviewCard() {
    final goal = widget.goal;
    
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  goal.categoryIcon,
                  style: TextStyle(fontSize: 32),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        goal.periodDisplay,
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
            SizedBox(height: 16),
            
            LinearProgressIndicator(
              value: goal.progressPercentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(goal.statusColor),
              minHeight: 10,
            ),
            SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${goal.formattedCurrentAmount}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: goal.statusColor,
                  ),
                ),
                Text(
                  '${goal.progressPercent}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: goal.statusColor,
                  ),
                ),
                Text(
                  '${goal.formattedTargetAmount}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard() {
    final analysis = _analysisData;
    final performanceRating = analysis['performanceRating'] ?? '評価中';
    final performanceColor = analysis['performanceColor'] ?? Colors.grey;
    final progressDifference = analysis['progressDifference'] ?? 0.0;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'パフォーマンス評価',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: performanceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: performanceColor),
                  ),
                  child: Text(
                    performanceRating,
                    style: TextStyle(
                      color: performanceColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  '予定より${progressDifference >= 0 ? '+' : ''}${(progressDifference * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: progressDifference >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            Text(
              progressDifference >= 0 
                  ? '目標期間内での達成が期待できます！'
                  : 'ペースアップが必要です。計画の見直しを検討しましょう。',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final analysis = _analysisData;
    final weeklyAverage = analysis['weeklyAverage'] ?? 0.0;
    final monthlyAverage = analysis['monthlyAverage'] ?? 0.0;
    final goal = widget.goal;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '貯金統計',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '週平均',
                    _formatCurrency(weeklyAverage),
                    Icons.calendar_view_week,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '月平均',
                    _formatCurrency(monthlyAverage),
                    Icons.calendar_today,
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '1日必要額',
                    goal.formattedDailyRequired,
                    Icons.today,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '残り日数',
                    '${goal.remainingDays}日',
                    Icons.schedule,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceCard() {
    final analysis = _analysisData;
    final adviceText = analysis['adviceText'] ?? 'データを分析中です...';
    final isOnTrack = analysis['isOnTrack'] ?? true;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOnTrack ? Icons.lightbulb : Icons.warning,
                  color: isOnTrack ? Colors.blue : Colors.orange,
                ),
                SizedBox(width: 8),
                Text(
                  'AIアドバイス',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            Text(
              adviceText,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart() {
    if (_progressHistory.isEmpty) {
      return Center(
        child: Text(
          '進捗データを収集中です...',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    
    List<FlSpot> progressSpots = [];
    List<FlSpot> targetSpots = [];
    
    for (int i = 0; i < _progressHistory.length; i++) {
      final data = _progressHistory[i];
      final x = i.toDouble();
      final progressY = (data['progressPercentage'] as double).clamp(0.0, 100.0);
      final targetY = (data['amount'] / data['targetAmount'] * 100).clamp(0.0, 100.0);
      
      progressSpots.add(FlSpot(x, progressY));
      targetSpots.add(FlSpot(x, targetY));
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < _progressHistory.length) {
                  final date = _progressHistory[value.toInt()]['date'] as DateTime;
                  return Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(fontSize: 10),
                  );
                }
                return Text('');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: progressSpots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesCard() {
    final goal = widget.goal;
    final milestones = [
      {'percent': 25, 'label': '25%達成', 'amount': goal.targetAmount * 0.25},
      {'percent': 50, 'label': '半分達成', 'amount': goal.targetAmount * 0.50},
      {'percent': 75, 'label': '75%達成', 'amount': goal.targetAmount * 0.75},
      {'percent': 100, 'label': '目標達成', 'amount': goal.targetAmount},
    ];
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'マイルストーン',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            
            ...milestones.map((milestone) {
              final percent = milestone['percent'] as int;
              final label = milestone['label'] as String;
              final amount = milestone['amount'] as double;
              final isAchieved = goal.progressPercent >= percent;
              
              return Container(
                margin: EdgeInsets.symmetric(vertical: 4),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isAchieved ? Colors.green[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isAchieved ? Colors.green[300]! : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAchieved ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isAchieved ? Colors.green : Colors.grey,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isAchieved ? Colors.green[700] : Colors.grey[700],
                        ),
                      ),
                    ),
                    Text(
                      _formatCurrency(amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isAchieved ? Colors.green[700] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionChart() {
    final projections = _projectionData;
    
    if (projections.isEmpty) {
      return Center(
        child: Text(
          '予測データを計算中です...',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    
    final scenarios = [
      {'label': '楽観的', 'value': projections['optimistic']!, 'color': Colors.green},
      {'label': '現在ペース', 'value': projections['currentPace']!, 'color': Colors.blue},
      {'label': '必要ペース', 'value': projections['requiredPace']!, 'color': Colors.orange},
      {'label': '悲観的', 'value': projections['pessimistic']!, 'color': Colors.red},
    ];
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: scenarios.map((s) => s['value'] as double).reduce((a, b) => a > b ? a : b) * 1.2,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatShortCurrency(value),
                  style: TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < scenarios.length) {
                  return Text(
                    scenarios[value.toInt()]['label'] as String,
                    style: TextStyle(fontSize: 10),
                  );
                }
                return Text('');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        barGroups: scenarios.asMap().entries.map((entry) {
          final index = entry.key;
          final scenario = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: scenario['value'] as double,
                color: scenario['color'] as Color,
                width: 30,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScenarioAnalysis() {
    final goal = widget.goal;
    final projections = _projectionData;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'シナリオ分析',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            
            _buildScenarioItem(
              '現在のペース',
              projections['currentPace'] ?? 0.0,
              goal.targetAmount,
              Colors.blue,
              '現在の貯金ペースを維持した場合',
            ),
            SizedBox(height: 8),
            
            _buildScenarioItem(
              '必要なペース',
              projections['requiredPace'] ?? 0.0,
              goal.targetAmount,
              Colors.orange,
              '目標期間内に達成するために必要な金額',
            ),
            SizedBox(height: 8),
            
            _buildScenarioItem(
              '楽観的予測',
              projections['optimistic'] ?? 0.0,
              goal.targetAmount,
              Colors.green,
              '現在のペースの120%で貯金した場合',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioItem(String label, double value, double target, Color color, String description) {
    final achievementRate = (value / target) * 100;
    final isAchievable = value >= target;
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Row(
                children: [
                  Text(
                    _formatCurrency(value),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    isAchievable ? Icons.check_circle : Icons.warning,
                    color: isAchievable ? Colors.green : Colors.red,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            '達成率: ${achievementRate.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementSuggestions() {
    final goal = widget.goal;
    final analysis = GoalAnalysis.calculate(goal);
    
    List<Map<String, dynamic>> suggestions = [];
    
    if (!analysis.isOnTrack) {
      final shortfall = goal.remainingAmount - (goal.dailyAverageAmount * goal.remainingDays);
      final additionalDaily = shortfall / goal.remainingDays;
      
      suggestions.add({
        'icon': Icons.trending_up,
        'title': 'ペースアップが必要',
        'description': '1日あたり${_formatCurrency(additionalDaily)}の追加貯金で目標達成可能',
        'color': Colors.orange,
      });
      
      suggestions.add({
        'icon': Icons.cut,
        'title': '支出の見直し',
        'description': '不要な支出を削減して貯金額を増やしましょう',
        'color': Colors.red,
      });
    } else {
      suggestions.add({
        'icon': Icons.thumb_up,
        'title': '順調な進捗',
        'description': '現在のペースを維持して目標達成を目指しましょう',
        'color': Colors.green,
      });
    }
    
    if (goal.remainingDays > 90) {
      suggestions.add({
        'icon': Icons.schedule,
        'title': '長期目標の継続',
        'description': 'モチベーション維持のために中間目標を設定することをお勧めします',
        'color': Colors.blue,
      });
    }
    
    suggestions.add({
      'icon': Icons.auto_graph,
      'title': '自動貯金の活用',
      'description': '給与の一定割合を自動で貯金口座に移すことを検討してみてください',
      'color': Colors.purple,
    });
    
    return Card(
      elevation: 2,
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
            
            ...suggestions.map((suggestion) => _buildSuggestionItem(
              suggestion['icon'],
              suggestion['title'],
              suggestion['description'],
              suggestion['color'],
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(IconData icon, String title, String description, Color color) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '¥${amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  String _formatShortCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}