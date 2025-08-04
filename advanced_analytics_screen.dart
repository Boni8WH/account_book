import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database_helper.dart';
import 'models.dart';
import 'budget_model.dart';

class AdvancedAnalyticsScreen extends StatefulWidget {
  @override
  _AdvancedAnalyticsScreenState createState() => _AdvancedAnalyticsScreenState();
}

class _AdvancedAnalyticsScreenState extends State<AdvancedAnalyticsScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  TabController? _tabController;
  
  // データ
  Map<String, dynamic> _monthlyComparison = {};
  Map<String, dynamic> _trendAnalysis = {};
  Map<String, dynamic> _spendingPatterns = {};
  Map<String, dynamic> _budgetPerformance = {};
  
  bool _isLoading = true;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 並列でデータを取得
      final results = await Future.wait([
        _getMonthlyComparison(),
        _getTrendAnalysis(),
        _getSpendingPatterns(),
        _getBudgetPerformance(),
      ]);

      setState(() {
        _monthlyComparison = results[0];
        _trendAnalysis = results[1];
        _spendingPatterns = results[2];
        _budgetPerformance = results[3];
        _isLoading = false;
      });
    } catch (e) {
      print('分析データ読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('高度な分析'),
        backgroundColor: Colors.indigo[700],
        bottom: _tabController != null ? TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.trending_up), text: 'トレンド'),
            Tab(icon: Icon(Icons.bar_chart), text: '月次比較'),
            Tab(icon: Icon(Icons.pie_chart), text: '支出パターン'),
            Tab(icon: Icon(Icons.assessment), text: '予算分析'),
          ],
        ) : null,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _selectYear,
            tooltip: '年を選択',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
            tooltip: '更新',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _tabController != null ? TabBarView(
              controller: _tabController,
              children: [
                _buildTrendAnalysisTab(),
                _buildMonthlyComparisonTab(),
                _buildSpendingPatternsTab(),
                _buildBudgetPerformanceTab(),
              ],
            ) : Container(),
    );
  }

  Widget _buildTrendAnalysisTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('支出トレンド - ${_selectedYear}年'),
          SizedBox(height: 16),
          
          // 年間トレンドグラフ
          Container(
            height: 300,
            child: _buildTrendChart(),
          ),
          SizedBox(height: 20),
          
          // トレンド分析サマリー
          _buildTrendSummary(),
          SizedBox(height: 20),
          
          // 季節性分析
          _buildSeasonalAnalysis(),
        ],
      ),
    );
  }

  Widget _buildMonthlyComparisonTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('月次比較分析'),
          SizedBox(height: 16),
          
          // 月次比較チャート
          Container(
            height: 250,
            child: _buildMonthlyComparisonChart(),
          ),
          SizedBox(height: 20),
          
          // 前年同月比較
          _buildYearOverYearComparison(),
          SizedBox(height: 20),
          
          // カテゴリ別月次推移
          _buildCategoryMonthlyTrend(),
        ],
      ),
    );
  }

  Widget _buildSpendingPatternsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('支出パターン分析'),
          SizedBox(height: 16),
          
          // 曜日別支出パターン
          _buildWeeklyPattern(),
          SizedBox(height: 20),
          
          // 時間帯別支出パターン
          _buildHourlyPattern(),
          SizedBox(height: 20),
          
          // 支払い方法別分析
          _buildPaymentMethodAnalysis(),
        ],
      ),
    );
  }

  Widget _buildBudgetPerformanceTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('予算達成度分析'),
          SizedBox(height: 16),
          
          // 年間予算達成度
          _buildAnnualBudgetPerformance(),
          SizedBox(height: 20),
          
          // カテゴリ別予算分析
          _buildCategoryBudgetAnalysis(),
          SizedBox(height: 20),
          
          // 予算改善提案
          _buildBudgetRecommendations(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildTrendChart() {
    // 月別支出データを取得
    final monthlyData = _trendAnalysis['monthlyExpenses'] as Map<String, double>? ?? {};
    
    if (monthlyData.isEmpty) {
      return _buildNoDataWidget('トレンドデータがありません');
    }

    List<FlSpot> spots = [];
    for (int month = 1; month <= 12; month++) {
      final amount = monthlyData[month.toString()] ?? 0.0;
      spots.add(FlSpot(month.toDouble(), amount));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  '¥${_formatShortCurrency(value)}',
                  style: TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}月',
                  style: TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue[600],
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue[600]!.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendSummary() {
    final totalExpense = _trendAnalysis['totalExpense'] as double? ?? 0.0;
    final averageMonthly = _trendAnalysis['averageMonthly'] as double? ?? 0.0;
    final trend = _trendAnalysis['trend'] as String? ?? 'データ不足';
    final maxMonth = _trendAnalysis['maxMonth'] as String? ?? '';
    final minMonth = _trendAnalysis['minMonth'] as String? ?? '';

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'トレンド分析サマリー',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    '年間総支出',
                    _formatCurrency(totalExpense),
                    Icons.account_balance_wallet,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    '月平均',
                    _formatCurrency(averageMonthly),
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    '最高額月',
                    maxMonth,
                    Icons.keyboard_arrow_up,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    '最低額月',
                    minMonth,
                    Icons.keyboard_arrow_down,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.insights, color: Colors.indigo[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'トレンド: $trend',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.indigo[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonalAnalysis() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '季節性分析',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            
            // 四季別の支出傾向
            Row(
              children: [
                _buildSeasonCard('春', '3-5月', 0.0, Colors.pink),
                _buildSeasonCard('夏', '6-8月', 0.0, Colors.orange),
                _buildSeasonCard('秋', '9-11月', 0.0, Colors.brown),
                _buildSeasonCard('冬', '12-2月', 0.0, Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonCard(String season, String period, double amount, Color color) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              season,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              period,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Text(
              _formatCurrency(amount),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyComparisonChart() {
    // 実装はここに追加（スペースの都合で省略）
    return _buildNoDataWidget('月次比較データを準備中...');
  }

  Widget _buildYearOverYearComparison() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '前年同月比較',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '前年同月比較機能は今後実装予定です',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryMonthlyTrend() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'カテゴリ別月次推移',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'カテゴリ別トレンド分析は今後実装予定です',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyPattern() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '曜日別支出パターン',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '曜日別分析機能は今後実装予定です',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyPattern() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '時間帯別支出パターン',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '時間帯別分析機能は今後実装予定です',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodAnalysis() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '支払い方法別分析',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '支払い方法別分析機能は今後実装予定です',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnualBudgetPerformance() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '年間予算達成度',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Container(
              height: 200,
              child: _buildAnnualBudgetChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnualBudgetChart() {
    // 年間予算達成度の円グラフ
    final categories = ['食費', '交通費', '娯楽費', '日用品'];
    final achievements = [0.85, 0.92, 1.15, 0.78]; // 仮データ（達成率）
    final colors = [Colors.blue, Colors.green, Colors.red, Colors.orange];
    
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final achievement = achievements[index];
        final color = achievement > 1.0 ? Colors.red : 
                     achievement > 0.8 ? Colors.green : Colors.orange;
        final percentage = (achievement * 100).toInt();
        
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 60,
                child: Text(category, style: TextStyle(fontSize: 12)),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: achievement.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: 50,
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryBudgetAnalysis() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'カテゴリ別予算分析',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            
            Container(
              height: 200,
              child: _buildCategoryBudgetChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBudgetChart() {
    final categories = ['食費', '交通費', '娯楽費', '日用品'];
    final budgets = [50000.0, 15000.0, 20000.0, 10000.0]; // 仮データ
    final actuals = [42500.0, 13800.0, 23000.0, 7800.0]; // 仮データ
    
    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < categories.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: budgets[i],
              color: Colors.blue[300],
              width: 15,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: actuals[i],
              color: actuals[i] > budgets[i] ? Colors.red : Colors.green,
              width: 15,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: budgets.reduce((a, b) => a > b ? a : b) * 1.2,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value / 1000).toInt()}k',
                  style: TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  categories[value.toInt()],
                  style: TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        barGroups: barGroups,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.black,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final category = categories[group.x.toInt()];
              final isActual = rodIndex == 1;
              final label = isActual ? '実績' : '予算';
              return BarTooltipItem(
                '$category\n$label: ¥${rod.toY.toInt()}',
                TextStyle(color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetRecommendations() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '予算改善提案',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            
            _buildRecommendationItem(
              Icons.trending_down,
              '娯楽費の見直し',
              '予算を15%超過しています。月2回の外食を控えることをお勧めします。',
              Colors.red,
            ),
            SizedBox(height: 8),
            _buildRecommendationItem(
              Icons.trending_up,
              '交通費の効率化',
              '順調に予算内です。定期券の活用で更に節約できる可能性があります。',
              Colors.green,
            ),
            SizedBox(height: 8),
            _buildRecommendationItem(
              Icons.lightbulb,
              '食費の最適化',
              '平均的な支出です。まとめ買いで5-10%の節約が期待できます。',
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(IconData icon, String title, String description, Color color) {
    return Container(
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

  Widget _buildNoDataWidget(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // データ取得メソッド群
  Future<Map<String, dynamic>> _getMonthlyComparison() async {
    try {
      final expenses = await _databaseHelper.getExpenses();
      Map<String, double> monthlyData = {};
      
      for (var expenseMap in expenses) {
        final expense = Expense.fromMap(expenseMap);
        final date = DateTime.parse(expense.date);
        
        if (date.year == _selectedYear) {
          final monthKey = date.month.toString();
          monthlyData[monthKey] = (monthlyData[monthKey] ?? 0.0) + expense.amount;
        }
      }
      
      return {
        'monthlyExpenses': monthlyData,
        'totalExpense': monthlyData.values.fold(0.0, (sum, amount) => sum + amount),
        'averageMonthly': monthlyData.isEmpty ? 0.0 : monthlyData.values.reduce((a, b) => a + b) / monthlyData.length,
      };
    } catch (e) {
      print('月次比較データ取得エラー: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getTrendAnalysis() async {
    try {
      final expenses = await _databaseHelper.getExpenses();
      Map<String, double> monthlyData = {};
      
      // 月別データを集計
      for (var expenseMap in expenses) {
        final expense = Expense.fromMap(expenseMap);
        final date = DateTime.parse(expense.date);
        
        if (date.year == _selectedYear) {
          final monthKey = date.month.toString();
          monthlyData[monthKey] = (monthlyData[monthKey] ?? 0.0) + expense.amount;
        }
      }
      
      // 統計計算
      final values = monthlyData.values.toList();
      final totalExpense = values.fold(0.0, (sum, amount) => sum + amount);
      final averageMonthly = values.isEmpty ? 0.0 : totalExpense / values.length;
      
      // 最高・最低月の特定
      String maxMonth = '';
      String minMonth = '';
      double maxAmount = 0.0;
      double minAmount = double.infinity;
      
      monthlyData.forEach((month, amount) {
        if (amount > maxAmount) {
          maxAmount = amount;
          maxMonth = '${month}月 (¥${_formatCurrency(amount)})';
        }
        if (amount < minAmount) {
          minAmount = amount;
          minMonth = '${month}月 (¥${_formatCurrency(amount)})';
        }
      });
      
      // トレンド分析（簡易版）
      String trend = '安定';
      if (values.length >= 2) {
        final firstHalf = values.take(values.length ~/ 2).toList();
        final secondHalf = values.skip(values.length ~/ 2).toList();
        final firstAvg = firstHalf.fold(0.0, (sum, amount) => sum + amount) / firstHalf.length;
        final secondAvg = secondHalf.fold(0.0, (sum, amount) => sum + amount) / secondHalf.length;
        
        final changePercent = ((secondAvg - firstAvg) / firstAvg * 100);
        if (changePercent > 10) {
          trend = '増加傾向 (+${changePercent.toInt()}%)';
        } else if (changePercent < -10) {
          trend = '減少傾向 (${changePercent.toInt()}%)';
        }
      }
      
      return {
        'monthlyExpenses': monthlyData,
        'totalExpense': totalExpense,
        'averageMonthly': averageMonthly,
        'maxMonth': maxMonth,
        'minMonth': minMonth,
        'trend': trend,
      };
    } catch (e) {
      print('トレンド分析データ取得エラー: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getSpendingPatterns() async {
    try {
      // 支出パターン分析（今後実装）
      return {
        'weeklyPattern': {},
        'hourlyPattern': {},
        'paymentMethodPattern': {},
      };
    } catch (e) {
      print('支出パターンデータ取得エラー: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getBudgetPerformance() async {
    try {
      // 予算パフォーマンス分析（今後実装）
      return {
        'annualPerformance': {},
        'categoryPerformance': {},
        'recommendations': [],
      };
    } catch (e) {
      print('予算パフォーマンスデータ取得エラー: $e');
      return {};
    }
  }

  // ユーティリティメソッド
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

  void _selectYear() async {
    final int? selectedYear = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('分析対象年を選択'),
        content: Container(
          width: double.maxFinite,
          height: 200,
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              final year = DateTime.now().year - index;
              return ListTile(
                title: Text('${year}年'),
                selected: year == _selectedYear,
                onTap: () => Navigator.pop(context, year),
              );
            },
          ),
        ),
      ),
    );

    if (selectedYear != null && selectedYear != _selectedYear) {
      setState(() {
        _selectedYear = selectedYear;
      });
      _loadAnalyticsData();
    }
  }
}