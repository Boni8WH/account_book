import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'budget_model.dart';

class BudgetManagementScreen extends StatefulWidget {
  @override
  _BudgetManagementScreenState createState() => _BudgetManagementScreenState();
}

class _BudgetManagementScreenState extends State<BudgetManagementScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<BudgetAnalysis> _budgetAnalyses = [];
  Map<String, dynamic> _monthlySummary = {};
  bool _isLoading = true;
  
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final analyses = await _databaseHelper.getBudgetAnalysisByPeriod(_selectedYear, _selectedMonth);
      final summary = await _databaseHelper.getMonthlyBudgetSummary(_selectedYear, _selectedMonth);

      setState(() {
        _budgetAnalyses = analyses;
        _monthlySummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      print('予算データ読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('予算管理'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadBudgetData,
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _showBudgetSettings,
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
                  // 期間選択
                  _buildPeriodSelector(),
                  SizedBox(height: 20),
                  
                  // 月次サマリー
                  _buildMonthlySummaryCard(),
                  SizedBox(height: 20),
                  
                  // 予算vs実績一覧
                  _buildBudgetAnalysisSection(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBudget,
        backgroundColor: Colors.green[700],
        child: Icon(Icons.add),
        tooltip: '予算を追加',
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.blue[700]),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '対象期間: ${_selectedYear}年${_selectedMonth}月',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _selectPeriod,
            icon: Icon(Icons.edit_calendar),
            label: Text('変更'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryCard() {
    final double totalBudget = _monthlySummary['totalBudget']?.toDouble() ?? 0.0;
    final double totalActual = _monthlySummary['totalActual']?.toDouble() ?? 0.0;
    final double remaining = _monthlySummary['remaining']?.toDouble() ?? 0.0;
    final double usagePercentage = _monthlySummary['usagePercentage']?.toDouble() ?? 0.0;
    final int overBudgetCount = _monthlySummary['overBudgetCount'] ?? 0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: remaining >= 0 
              ? [Colors.green[600]!, Colors.green[400]!]
              : [Colors.red[600]!, Colors.red[400]!],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '月次予算サマリー',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
                              if (overBudgetCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '⚠️ ${overBudgetCount}件超過',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          
          // 予算使用率プログレスバー
          LinearProgressIndicator(
            value: usagePercentage / 100,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
          SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '総予算',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _formatCurrency(totalBudget),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '使用率',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${usagePercentage.toInt()}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    remaining >= 0 ? '残り予算' : '予算超過',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _formatCurrency(remaining.abs()),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetAnalysisSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'カテゴリ別予算管理',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            TextButton.icon(
              onPressed: _addBudget,
              icon: Icon(Icons.add),
              label: Text('追加'),
            ),
          ],
        ),
        SizedBox(height: 12),
        
        if (_budgetAnalyses.isEmpty)
          _buildEmptyBudgetState()
        else
          ..._budgetAnalyses.map((analysis) => _buildBudgetAnalysisCard(analysis)).toList(),
      ],
    );
  }

  Widget _buildEmptyBudgetState() {
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
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            '予算が設定されていません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '右下の＋ボタンまたは上部の「追加」から\n予算を設定してください',
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

  Widget _buildBudgetAnalysisCard(BudgetAnalysis analysis) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // ヘッダー行
            Row(
              children: [
                Text(
                  analysis.budget.categoryIcon,
                  style: TextStyle(fontSize: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analysis.budget.category,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '予算: ${analysis.budget.formattedLimit}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: analysis.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    analysis.statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: analysis.statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () => _showBudgetOptions(analysis),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // プログレスバー
            LinearProgressIndicator(
              value: (analysis.usagePercentage / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(analysis.statusColor),
              minHeight: 6,
            ),
            SizedBox(height: 12),
            
            // 詳細情報
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '使用済み',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      analysis.formattedActual,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: analysis.statusColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '使用率',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${analysis.usagePercentage.toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      analysis.isOverBudget ? '超過額' : '残り',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      analysis.formattedRemaining,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: analysis.isOverBudget ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // 1日あたりの推奨金額（予算超過していない場合のみ）
            if (!analysis.isOverBudget && analysis.daysRemaining > 0) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.blue[600]),
                    SizedBox(width: 8),
                    Text(
                      '残り${analysis.daysRemaining}日 • 1日あたり推奨: ${analysis.formattedDailyRecommended}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
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

  String _formatCurrency(double amount) {
    return '¥${amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  void _selectPeriod() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear, _selectedMonth),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      selectableDayPredicate: (date) => date.day == 1, // 月の1日のみ選択可能
    );

    if (selectedDate != null) {
      setState(() {
        _selectedYear = selectedDate.year;
        _selectedMonth = selectedDate.month;
      });
      _loadBudgetData();
    }
  }

  void _addBudget() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetFormScreen(
          year: _selectedYear,
          month: _selectedMonth,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadBudgetData();
      }
    });
  }

  void _showBudgetOptions(BudgetAnalysis analysis) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: Colors.blue),
              title: Text('予算を編集'),
              onTap: () {
                Navigator.pop(context);
                _editBudget(analysis.budget);
              },
            ),
            ListTile(
              leading: Icon(Icons.bar_chart, color: Colors.green),
              title: Text('詳細分析を見る'),
              onTap: () {
                Navigator.pop(context);
                _showDetailedAnalysis(analysis);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('予算を削除'),
              onTap: () {
                Navigator.pop(context);
                _deleteBudget(analysis.budget);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editBudget(Budget budget) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetFormScreen(
          budget: budget,
          year: _selectedYear,
          month: _selectedMonth,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadBudgetData();
      }
    });
  }

  void _showDetailedAnalysis(BudgetAnalysis analysis) {
    // 詳細分析画面の実装（後で追加予定）
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('詳細分析画面は今後実装予定です')),
    );
  }

  void _deleteBudget(Budget budget) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('予算の削除'),
        content: Text('「${budget.category}」の予算を削除しますか？'),
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
        await _databaseHelper.deleteBudget(budget.id!);
        _loadBudgetData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('予算を削除しました'),
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

  void _showBudgetSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.copy, color: Colors.blue),
              title: Text('前月予算をコピー'),
              subtitle: Text('前月の予算設定を今月にコピーします'),
              onTap: () {
                Navigator.pop(context);
                _copyPreviousMonthBudget();
              },
            ),
            ListTile(
              leading: Icon(Icons.auto_fix_high, color: Colors.green),
              title: Text('自動予算設定'),
              subtitle: Text('過去の支出データから予算を自動設定'),
              onTap: () {
                Navigator.pop(context);
                _autoSetBudget();
              },
            ),
            ListTile(
              leading: Icon(Icons.file_download, color: Colors.orange),
              title: Text('予算データエクスポート'),
              subtitle: Text('予算データをCSVファイルで出力'),
              onTap: () {
                Navigator.pop(context);
                _exportBudgetData();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _copyPreviousMonthBudget() async {
    try {
      // 前月の年月を計算
      DateTime targetDate = DateTime(_selectedYear, _selectedMonth);
      DateTime previousMonth = DateTime(targetDate.year, targetDate.month - 1);
      
      final copiedCount = await _databaseHelper.copyPreviousMonthBudget(_selectedYear, _selectedMonth);
      
      _loadBudgetData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${previousMonth.year}年${previousMonth.month}月の予算${copiedCount}件をコピーしました'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('予算コピーに失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _autoSetBudget() async {
    try {
      // 自動予算提案を取得
      final suggestions = await _databaseHelper.generateAutoBudgetSuggestions(_selectedYear, _selectedMonth);
      
      if (suggestions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('自動予算設定に十分なデータがありません'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // 確認ダイアログを表示
      final bool? shouldApply = await _showAutoBudgetDialog(suggestions);
      
      if (shouldApply == true) {
        final appliedCount = await _databaseHelper.applyAutoBudget(_selectedYear, _selectedMonth, suggestions);
        
        _loadBudgetData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${appliedCount}件の自動予算を設定しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('自動予算設定に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool?> _showAutoBudgetDialog(Map<String, double> suggestions) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('自動予算設定の確認'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '過去のデータから以下の予算を提案します：',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Container(
                height: 200,
                child: ListView.builder(
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final entry = suggestions.entries.elementAt(index);
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key),
                          Text(
                            _formatCurrency(entry.value),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 12),
              Text(
                '※ 過去6ヶ月の平均支出の110%で計算されています',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('適用'),
          ),
        ],
      ),
    );
  }

  void _exportBudgetData() {
    // エクスポート機能（後で実装）
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('エクスポート機能は今後実装予定です')),
    );
  }
}

// 予算追加・編集フォーム画面
class BudgetFormScreen extends StatefulWidget {
  final Budget? budget;
  final int year;
  final int month;

  BudgetFormScreen({this.budget, required this.year, required this.month});

  @override
  _BudgetFormScreenState createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedCategory = '';
  List<String> _availableCategories = [];
  bool _isLoading = false;
  bool _isLoadingCategories = true;

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.budget != null) {
      _loadExistingBudget();
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _databaseHelper.getExpenseCategories();
      setState(() {
        _availableCategories = categories;
        if (_selectedCategory.isEmpty && categories.isNotEmpty) {
          _selectedCategory = categories.first;
        }
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _availableCategories = ['食費', '交通費', '娯楽費', '日用品', 'その他'];
        _selectedCategory = '食費';
        _isLoadingCategories = false;
      });
    }
  }

  void _loadExistingBudget() {
    final budget = widget.budget!;
    _selectedCategory = budget.category;
    _limitController.text = budget.monthlyLimit.toInt().toString();
    _notesController.text = budget.notes ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.budget != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '予算編集' : '予算追加'),
        backgroundColor: Colors.green[700],
      ),
      body: _isLoadingCategories
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 対象期間表示
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.blue[700]),
                          SizedBox(width: 12),
                          Text(
                            '対象期間: ${widget.year}年${widget.month}月',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
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
                      value: _selectedCategory.isEmpty ? null : _selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _availableCategories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Row(
                            children: [
                              Text(
                                Budget(
                                  category: category,
                                  monthlyLimit: 0,
                                  year: widget.year,
                                  month: widget.month,
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'カテゴリを選択してください';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // 月間予算上限
                    Text(
                      '月間予算上限 *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _limitController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance_wallet),
                        prefixText: '¥',
                        hintText: '50000',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '予算上限を入力してください';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return '正しい金額を入力してください';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // メモ
                    Text(
                      'メモ（任意）',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                        hintText: '予算に関するメモを入力',
                      ),
                      maxLines: 3,
                    ),
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
                            onPressed: _isLoading ? null : _saveBudget,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
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

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String currentDate = DateTime.now().toIso8601String();
      final double monthlyLimit = double.parse(_limitController.text);

      Map<String, dynamic> budgetData = {
        'category': _selectedCategory,
        'monthly_limit': monthlyLimit,
        'year': widget.year,
        'month': widget.month,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'is_active': 1,
        'updated_at': currentDate,
      };

      if (widget.budget == null) {
        // 新規追加
        budgetData['created_at'] = currentDate;
        await _databaseHelper.insertBudget(budgetData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${_selectedCategory}」の予算を追加しました'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // 更新
        final updatedBudget = widget.budget!.copyWith(
          category: _selectedCategory,
          monthlyLimit: monthlyLimit,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          updatedAt: currentDate,
        );
        
        await _databaseHelper.updateBudget(updatedBudget);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${_selectedCategory}」の予算を更新しました'),
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
    _limitController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}