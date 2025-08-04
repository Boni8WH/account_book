import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database_helper.dart';
import 'models.dart';
import 'budget_model.dart';

class AIFinancialAdvisorScreen extends StatefulWidget {
  @override
  _AIFinancialAdvisorScreenState createState() => _AIFinancialAdvisorScreenState();
}

class _AIFinancialAdvisorScreenState extends State<AIFinancialAdvisorScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  TabController? _tabController;
  
  Map<String, dynamic> _analysisData = {};
  List<Map<String, dynamic>> _recommendations = [];
  Map<String, double> _riskAssessment = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFinancialAnalysis();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadFinancialAnalysis() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final analysis = await _performFinancialAnalysis();
      final recommendations = await _generateRecommendations();
      final riskAssessment = await _assessFinancialRisk();

      setState(() {
        _analysisData = analysis;
        _recommendations = recommendations;
        _riskAssessment = riskAssessment;
        _isLoading = false;
      });
    } catch (e) {
      print('AI分析エラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _performFinancialAnalysis() async {
    // 収支データを取得
    final expenses = await _databaseHelper.getExpenses();
    final incomes = await _databaseHelper.getIncomes();
    final now = DateTime.now();
    
    // 月別集計
    Map<String, double> monthlyExpenses = {};
    Map<String, double> monthlyIncomes = {};
    Map<String, double> categoryExpenses = {};
    
    // 過去6ヶ月のデータを分析
    for (int i = 0; i < 6; i++) {
      final targetMonth = DateTime(now.year, now.month - i);
      final monthKey = '${targetMonth.year}-${targetMonth.month.toString().padLeft(2, '0')}';
      monthlyExpenses[monthKey] = 0.0;
      monthlyIncomes[monthKey] = 0.0;
    }
    
    // 支出データの集計
    for (var expenseMap in expenses) {
      final expense = Expense.fromMap(expenseMap);
      final date = DateTime.parse(expense.date);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      
      if (monthlyExpenses.containsKey(monthKey)) {
        monthlyExpenses[monthKey] = monthlyExpenses[monthKey]! + expense.amount;
      }
      
      categoryExpenses[expense.category] = 
          (categoryExpenses[expense.category] ?? 0.0) + expense.amount;
    }
    
    // 収入データの集計
    for (var incomeMap in incomes) {
      final income = Income.fromMap(incomeMap);
      final date = DateTime.parse(income.date);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      
      if (monthlyIncomes.containsKey(monthKey)) {
        monthlyIncomes[monthKey] = monthlyIncomes[monthKey]! + income.amount;
      }
    }
    
    // 分析指標の計算
    final totalExpenses = monthlyExpenses.values.fold(0.0, (sum, amount) => sum + amount);
    final totalIncomes = monthlyIncomes.values.fold(0.0, (sum, amount) => sum + amount);
    final avgMonthlyExpense = totalExpenses / 6;
    final avgMonthlyIncome = totalIncomes / 6;
    final savingsRate = totalIncomes > 0 ? ((totalIncomes - totalExpenses) / totalIncomes) * 100 : 0.0;
    
    // 支出の安定性（標準偏差）
    final expenseValues = monthlyExpenses.values.toList();
    final expenseVariance = _calculateVariance(expenseValues, avgMonthlyExpense);
    final expenseStability = expenseVariance < (avgMonthlyExpense * 0.2) ? 'stable' : 'unstable';
    
    // カテゴリ別分析
    final largestCategory = categoryExpenses.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    return {
      'totalExpenses': totalExpenses,
      'totalIncomes': totalIncomes,
      'avgMonthlyExpense': avgMonthlyExpense,
      'avgMonthlyIncome': avgMonthlyIncome,
      'savingsRate': savingsRate,
      'expenseStability': expenseStability,
      'largestCategory': largestCategory,
      'monthlyExpenses': monthlyExpenses,
      'monthlyIncomes': monthlyIncomes,
      'categoryExpenses': categoryExpenses,
      'analysisDate': DateTime.now().toIso8601String(),
    };
  }

  Future<List<Map<String, dynamic>>> _generateRecommendations() async {
    final analysis = _analysisData;
    final List<Map<String, dynamic>> recommendations = [];
    
    final savingsRate = analysis['savingsRate'] ?? 0.0;
    final expenseStability = analysis['expenseStability'] ?? 'stable';
    final avgMonthlyExpense = analysis['avgMonthlyExpense'] ?? 0.0;
    final avgMonthlyIncome = analysis['avgMonthlyIncome'] ?? 0.0;
    final categoryExpenses = analysis['categoryExpenses'] as Map<String, double>? ?? {};
    
    // 貯蓄率に基づく推奨
    if (savingsRate < 10) {
      recommendations.add({
        'type': 'critical',
        'icon': Icons.warning,
        'title': '貯蓄率の改善が急務',
        'description': '現在の貯蓄率は${savingsRate.toStringAsFixed(1)}%です。理想的な貯蓄率20%を目指しましょう。',
        'action': '支出の見直しを行い、月額${_formatCurrency((avgMonthlyIncome * 0.2) - (avgMonthlyIncome - avgMonthlyExpense))}の追加貯蓄を目指してください。',
        'priority': 1,
        'color': Colors.red,
      });
    } else if (savingsRate < 20) {
      recommendations.add({
        'type': 'improvement',
        'icon': Icons.trending_up,
        'title': '貯蓄率をさらに向上',
        'description': '現在の貯蓄率${savingsRate.toStringAsFixed(1)}%は良好ですが、20%を目指すとより安定します。',
        'action': 'あと${_formatCurrency((avgMonthlyIncome * 0.2) - (avgMonthlyIncome - avgMonthlyExpense))}の貯蓄増加で理想的な水準に到達します。',
        'priority': 2,
        'color': Colors.orange,
      });
    } else {
      recommendations.add({
        'type': 'excellent',
        'icon': Icons.emoji_events,
        'title': '優秀な貯蓄率',
        'description': '貯蓄率${savingsRate.toStringAsFixed(1)}%は非常に優秀です！',
        'action': '現在のペースを維持し、余裕資金の投資も検討してみてください。',
        'priority': 3,
        'color': Colors.green,
      });
    }
    
    // 支出安定性に基づく推奨
    if (expenseStability == 'unstable') {
      recommendations.add({
        'type': 'stability',
        'icon': Icons.equalizer,
        'title': '支出の安定化',
        'description': '月々の支出にばらつきがあります。',
        'action': '予算を設定し、計画的な支出を心がけることで家計の安定化を図りましょう。',
        'priority': 2,
        'color': Colors.blue,
      });
    }
    
    // カテゴリ別分析に基づく推奨
    final totalCategoryExpense = categoryExpenses.values.fold(0.0, (sum, amount) => sum + amount);
    categoryExpenses.forEach((category, amount) {
      final percentage = (amount / totalCategoryExpense) * 100;
      
      if (category == '食費' && percentage > 30) {
        recommendations.add({
          'type': 'category',
          'icon': Icons.restaurant,
          'title': '食費の最適化',
          'description': '食費が支出の${percentage.toStringAsFixed(1)}%を占めています。',
          'action': 'まとめ買いや自炊の頻度を増やすことで、月${_formatCurrency(amount * 0.15)}程度の節約が期待できます。',
          'priority': 2,
          'color': Colors.orange,
        });
      } else if (category == '娯楽費' && percentage > 20) {
        recommendations.add({
          'type': 'category',
          'icon': Icons.sports_esports,
          'title': '娯楽費の見直し',
          'description': '娯楽費が支出の${percentage.toStringAsFixed(1)}%を占めています。',
          'action': '必要な娯楽と不要な支出を見極め、メリハリのある使い方を心がけましょう。',
          'priority': 2,
          'color': Colors.purple,
        });
      }
    });
    
    // 緊急資金に関する推奨
    final emergencyFund = avgMonthlyExpense * 6; // 6ヶ月分の生活費
    recommendations.add({
      'type': 'emergency',
      'icon': Icons.security,
      'title': '緊急資金の確保',
      'description': '万が一に備えて生活費6ヶ月分の緊急資金を準備しましょう。',
      'action': '目標金額は${_formatCurrency(emergencyFund)}です。まずは1ヶ月分から始めることをお勧めします。',
      'priority': 1,
      'color': Colors.indigo,
    });
    
    // 投資に関する推奨
    if (savingsRate > 15) {
      recommendations.add({
        'type': 'investment',
        'icon': Icons.show_chart,
        'title': '資産運用の検討',
        'description': '安定した貯蓄ができているため、投資も検討してみましょう。',
        'action': '余裕資金の一部（貯蓄の10-20%程度）から積立投資を始めることをお勧めします。',
        'priority': 3,
        'color': Colors.teal,
      });
    }
    
    // 優先度順にソート
    recommendations.sort((a, b) => a['priority'].compareTo(b['priority']));
    
    return recommendations;
  }

  Future<Map<String, double>> _assessFinancialRisk() async {
    final analysis = _analysisData;
    final savingsRate = analysis['savingsRate'] ?? 0.0;
    final expenseStability = analysis['expenseStability'] ?? 'stable';
    final avgMonthlyIncome = analysis['avgMonthlyIncome'] ?? 0.0;
    
    // リスク要因の評価（0-100、低いほど良い）
    double liquidityRisk = 0.0;  // 流動性リスク
    double budgetRisk = 0.0;     // 予算管理リスク
    double savingsRisk = 0.0;    // 貯蓄リスク
    double stabilityRisk = 0.0;  // 安定性リスク
    
    // 貯蓄率によるリスク評価
    if (savingsRate < 5) {
      savingsRisk = 90.0;
    } else if (savingsRate < 10) {
      savingsRisk = 70.0;
    } else if (savingsRate < 15) {
      savingsRisk = 40.0;
    } else if (savingsRate < 20) {
      savingsRisk = 20.0;
    } else {
      savingsRisk = 10.0;
    }
    
    // 支出安定性によるリスク評価
    stabilityRisk = expenseStability == 'unstable' ? 60.0 : 20.0;
    
    // 収入レベルによる流動性リスク評価
    if (avgMonthlyIncome < 200000) {
      liquidityRisk = 70.0;
    } else if (avgMonthlyIncome < 300000) {
      liquidityRisk = 50.0;
    } else if (avgMonthlyIncome < 500000) {
      liquidityRisk = 30.0;
    } else {
      liquidityRisk = 15.0;
    }
    
    // 予算管理状況（予算設定の有無で判定）
    final budgets = await _databaseHelper.getBudgets();
    budgetRisk = budgets.isEmpty ? 80.0 : 30.0;
    
    // 総合リスクスコア
    final overallRisk = (liquidityRisk + budgetRisk + savingsRisk + stabilityRisk) / 4;
    
    return {
      'liquidityRisk': liquidityRisk,
      'budgetRisk': budgetRisk,
      'savingsRisk': savingsRisk,
      'stabilityRisk': stabilityRisk,
      'overallRisk': overallRisk,
    };
  }

  double _calculateVariance(List<double> values, double mean) {
    if (values.isEmpty) return 0.0;
    
    double sumSquaredDifferences = 0.0;
    for (double value in values) {
      sumSquaredDifferences += (value - mean) * (value - mean);
    }
    
    return sumSquaredDifferences / values.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI家計診断'),
        backgroundColor: Colors.indigo[700],
        bottom: _tabController != null ? TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.analytics), text: '分析結果'),
            Tab(icon: Icon(Icons.lightbulb), text: '改善提案'),
            Tab(icon: Icon(Icons.shield), text: 'リスク診断'),
          ],
        ) : null,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadFinancialAnalysis,
            tooltip: '再分析',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AIが家計を分析中...'),
                ],
              ),
            )
          : _tabController != null ? TabBarView(
              controller: _tabController,
              children: [
                _buildAnalysisTab(),
                _buildRecommendationsTab(),
                _buildRiskAssessmentTab(),
              ],
            ) : Container(),
    );
  }

  Widget _buildAnalysisTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分析サマリーカード
          _buildAnalysisSummaryCard(),
          SizedBox(height: 20),
          
          // 貯蓄率表示
          _buildSavingsRateCard(),
          SizedBox(height: 20),
          
          // 月次収支トレンド
          _buildMonthlyTrendCard(),
          SizedBox(height: 20),
          
          // カテゴリ別支出分析
          _buildCategoryAnalysisCard(),
        ],
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI改善提案',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'あなたの家計データを分析して、個別の改善提案を作成しました',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          
          if (_recommendations.isEmpty)
            _buildNoRecommendationsWidget()
          else
            ..._recommendations.map((recommendation) => 
              _buildRecommendationCard(recommendation)).toList(),
        ],
      ),
    );
  }

  Widget _buildRiskAssessmentTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ファイナンシャルリスク診断',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          
          // 総合リスクスコア
          _buildOverallRiskCard(),
          SizedBox(height: 20),
          
          // 個別リスク要因
          _buildIndividualRisksCard(),
          SizedBox(height: 20),
          
          // リスク軽減アドバイス
          _buildRiskMitigationCard(),
        ],
      ),
    );
  }

  Widget _buildAnalysisSummaryCard() {
    final analysis = _analysisData;
    final totalIncomes = analysis['totalIncomes'] ?? 0.0;
    final totalExpenses = analysis['totalExpenses'] ?? 0.0;
    final savingsRate = analysis['savingsRate'] ?? 0.0;
    final balance = totalIncomes - totalExpenses;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[600]!, Colors.indigo[400]!],
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
            'AI分析結果サマリー',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  '総収入',
                  _formatCurrency(totalIncomes),
                  Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  '総支出',
                  _formatCurrency(totalExpenses),
                  Icons.trending_down,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  '収支バランス',
                  _formatCurrency(balance),
                  balance >= 0 ? Icons.add : Icons.remove,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  '貯蓄率',
                  '${savingsRate.toStringAsFixed(1)}%',
                  Icons.savings,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
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

  Widget _buildSavingsRateCard() {
    final savingsRate = _analysisData['savingsRate'] ?? 0.0;
    Color rateColor;
    String rateStatus;
    
    if (savingsRate >= 20) {
      rateColor = Colors.green;
      rateStatus = '優秀';
    } else if (savingsRate >= 15) {
      rateColor = Colors.blue;
      rateStatus = '良好';
    } else if (savingsRate >= 10) {
      rateColor = Colors.orange;
      rateStatus = '改善余地あり';
    } else {
      rateColor = Colors.red;
      rateStatus = '要改善';
    }
    
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '貯蓄率分析',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${savingsRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: rateColor,
                        ),
                      ),
                      Text(
                        rateStatus,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: rateColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildRateBar('理想', 20.0, savingsRate, Colors.green),
                      SizedBox(height: 4),
                      _buildRateBar('良好', 15.0, savingsRate, Colors.blue),
                      SizedBox(height: 4),
                      _buildRateBar('最低', 10.0, savingsRate, Colors.orange),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            Text(
              '一般的に貯蓄率20%以上が理想とされています。現在の貯蓄率を維持・向上させることで、将来の安心につながります。',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateBar(String label, double targetRate, double currentRate, Color color) {
    final isAchieved = currentRate >= targetRate;
    
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
        SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: isAchieved ? color : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        SizedBox(width: 4),
        Icon(
          isAchieved ? Icons.check : Icons.close,
          size: 12,
          color: isAchieved ? color : Colors.grey[400],
        ),
      ],
    );
  }

  Widget _buildMonthlyTrendCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '月次収支トレンド',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            Container(
              height: 200,
              child: _buildTrendChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    final monthlyExpenses = _analysisData['monthlyExpenses'] as Map<String, double>? ?? {};
    final monthlyIncomes = _analysisData['monthlyIncomes'] as Map<String, double>? ?? {};
    
    if (monthlyExpenses.isEmpty && monthlyIncomes.isEmpty) {
      return Center(
        child: Text(
          'データが不足しています',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    
    List<FlSpot> expenseSpots = [];
    List<FlSpot> incomeSpots = [];
    List<String> monthLabels = [];
    
    int index = 0;
    for (String monthKey in monthlyExpenses.keys) {
      expenseSpots.add(FlSpot(index.toDouble(), monthlyExpenses[monthKey] ?? 0.0));
      incomeSpots.add(FlSpot(index.toDouble(), monthlyIncomes[monthKey] ?? 0.0));
      
      final parts = monthKey.split('-');
      monthLabels.add('${parts[1]}月');
      index++;
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
                if (value.toInt() < monthLabels.length) {
                  return Text(
                    monthLabels[value.toInt()],
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
            spots: incomeSpots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.1),
            ),
          ),
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAnalysisCard() {
    final categoryExpenses = _analysisData['categoryExpenses'] as Map<String, double>? ?? {};
    
    if (categoryExpenses.isEmpty) {
      return Container();
    }
    
    final sortedCategories = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = categoryExpenses.values.fold(0.0, (sum, amount) => sum + amount);
    
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'カテゴリ別支出分析',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            ...sortedCategories.take(5).map((entry) {
              final percentage = (entry.value / total) * 100;
              return _buildCategoryItem(entry.key, entry.value, percentage);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category, double amount, double percentage) {
    Color color = _getCategoryColor(category);
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              category,
              style: TextStyle(fontSize: 14),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(amount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    final type = recommendation['type'];
    final icon = recommendation['icon'];
    final title = recommendation['title'];
    final description = recommendation['description'];
    final action = recommendation['action'];
    final color = recommendation['color'];
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.orange[600],
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      action,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
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

  Widget _buildNoRecommendationsWidget() {
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
            Icons.emoji_events,
            size: 64,
            color: Colors.green[400],
          ),
          SizedBox(height: 16),
          Text(
            '素晴らしい家計管理！',
            style: TextStyle(
              fontSize: 18,
              color: Colors.green[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '現在の家計状況は非常に良好です。\nこの調子で継続してください。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallRiskCard() {
    final overallRisk = _riskAssessment['overallRisk'] ?? 50.0;
    Color riskColor;
    String riskLevel;
    String riskDescription;
    
    if (overallRisk < 25) {
      riskColor = Colors.green;
      riskLevel = '低リスク';
      riskDescription = '家計状況は非常に安定しています';
    } else if (overallRisk < 50) {
      riskColor = Colors.blue;
      riskLevel = '中リスク';
      riskDescription = '概ね安定していますが、改善の余地があります';
    } else if (overallRisk < 75) {
      riskColor = Colors.orange;
      riskLevel = '高リスク';
      riskDescription = '注意が必要な状況です';
    } else {
      riskColor = Colors.red;
      riskLevel = '危険';
      riskDescription = '早急な改善が必要です';
    }
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: riskColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.shield, color: riskColor, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '総合リスクスコア',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      riskLevel,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: riskColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(100 - overallRisk).toStringAsFixed(0)}/100',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: riskColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          LinearProgressIndicator(
            value: (100 - overallRisk) / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(riskColor),
            minHeight: 8,
          ),
          SizedBox(height: 8),
          
          Text(
            riskDescription,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualRisksCard() {
    final risks = [
      {'name': '流動性リスク', 'value': _riskAssessment['liquidityRisk'] ?? 0.0, 'icon': Icons.water_drop},
      {'name': '予算管理リスク', 'value': _riskAssessment['budgetRisk'] ?? 0.0, 'icon': Icons.account_balance_wallet},
      {'name': '貯蓄リスク', 'value': _riskAssessment['savingsRisk'] ?? 0.0, 'icon': Icons.savings},
      {'name': '安定性リスク', 'value': _riskAssessment['stabilityRisk'] ?? 0.0, 'icon': Icons.trending_up},
    ];
    
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '個別リスク要因',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            ...risks.map((risk) => _buildRiskItem(
              risk['name'] as String,
              risk['value'] as double,
              risk['icon'] as IconData,
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskItem(String name, double value, IconData icon) {
    Color color = _getRiskColor(value);
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                LinearProgressIndicator(
                  value: value / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Text(
            _getRiskLabel(value),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskMitigationCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'リスク軽減アドバイス',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            _buildMitigationItem(
              Icons.emergency,
              '緊急資金の確保',
              '生活費の3-6ヶ月分の緊急資金を準備しましょう',
              Colors.red,
            ),
            SizedBox(height: 12),
            
            _buildMitigationItem(
              Icons.pie_chart,
              '予算管理の導入',
              '各カテゴリに予算を設定して支出をコントロールしましょう',
              Colors.blue,
            ),
            SizedBox(height: 12),
            
            _buildMitigationItem(
              Icons.show_chart,
              '収入源の多様化',
              '副業やスキルアップで収入の安定性を高めましょう',
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMitigationItem(IconData icon, String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
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
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '食費':
        return Colors.blue;
      case '交通費':
        return Colors.green;
      case '娯楽費':
        return Colors.orange;
      case '日用品':
        return Colors.purple;
      case '医療費':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getRiskColor(double risk) {
    if (risk < 25) return Colors.green;
    if (risk < 50) return Colors.blue;
    if (risk < 75) return Colors.orange;
    return Colors.red;
  }

  String _getRiskLabel(double risk) {
    if (risk < 25) return '低';
    if (risk < 50) return '中';
    if (risk < 75) return '高';
    return '危険';
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