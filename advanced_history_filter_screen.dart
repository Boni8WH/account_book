import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'models.dart';
import 'edit_screens.dart';

class AdvancedHistoryScreen extends StatefulWidget {
  @override
  _AdvancedHistoryScreenState createState() => _AdvancedHistoryScreenState();
}

class _AdvancedHistoryScreenState extends State<AdvancedHistoryScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  TabController? _tabController;
  
  List<Expense> _allExpenses = [];
  List<Income> _allIncomes = [];
  List<Expense> _filteredExpenses = [];
  List<Income> _filteredIncomes = [];
  
  bool _isLoading = true;
  
  // フィルター設定
  DateTimeRange? _dateRange;
  String? _selectedCategory;
  String? _selectedPaymentMethod;
  double? _minAmount;
  double? _maxAmount;
  String _sortBy = 'date_desc'; // date_desc, date_asc, amount_desc, amount_asc
  String _searchQuery = '';
  
  List<String> _categories = [];
  List<String> _paymentMethods = [];
  
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistoryData();
    _loadFilterOptions();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 支出データを取得
      List<Map<String, dynamic>> expensesList = await _databaseHelper.getExpenses();
      List<Expense> expenses = expensesList.map((map) => Expense.fromMap(map)).toList();

      // 収入データを取得
      List<Map<String, dynamic>> incomesList = await _databaseHelper.getIncomes();
      List<Income> incomes = incomesList.map((map) => Income.fromMap(map)).toList();

      setState(() {
        _allExpenses = expenses;
        _allIncomes = incomes;
        _filteredExpenses = expenses;
        _filteredIncomes = incomes;
        _isLoading = false;
      });
      
      _applyFilters();
    } catch (e) {
      print('履歴データ読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFilterOptions() async {
    try {
      // カテゴリ一覧を取得
      Set<String> categorySet = {};
      Set<String> paymentMethodSet = {};
      
      for (var expense in _allExpenses) {
        categorySet.add(expense.category);
        paymentMethodSet.add(expense.paymentMethod);
      }
      
      for (var income in _allIncomes) {
        paymentMethodSet.add(income.paymentMethod);
      }
      
      setState(() {
        _categories = categorySet.toList()..sort();
        _paymentMethods = paymentMethodSet.toList()..sort();
      });
    } catch (e) {
      print('フィルターオプション読み込みエラー: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      // 支出フィルタリング
      _filteredExpenses = _allExpenses.where((expense) {
        // 日付範囲フィルター
        if (_dateRange != null) {
          final expenseDate = DateTime.parse(expense.date);
          if (expenseDate.isBefore(_dateRange!.start) || 
              expenseDate.isAfter(_dateRange!.end.add(Duration(days: 1)))) {
            return false;
          }
        }
        
        // カテゴリフィルター
        if (_selectedCategory != null && expense.category != _selectedCategory) {
          return false;
        }
        
        // 支払い方法フィルター
        if (_selectedPaymentMethod != null && expense.paymentMethod != _selectedPaymentMethod) {
          return false;
        }
        
        // 金額範囲フィルター
        if (_minAmount != null && expense.amount < _minAmount!) {
          return false;
        }
        if (_maxAmount != null && expense.amount > _maxAmount!) {
          return false;
        }
        
        // 検索クエリフィルター
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!expense.category.toLowerCase().contains(query) &&
              !expense.paymentMethod.toLowerCase().contains(query) &&
              !(expense.memo?.toLowerCase().contains(query) ?? false)) {
            return false;
          }
        }
        
        return true;
      }).toList();
      
      // 収入フィルタリング
      _filteredIncomes = _allIncomes.where((income) {
        // 日付範囲フィルター
        if (_dateRange != null) {
          final incomeDate = DateTime.parse(income.date);
          if (incomeDate.isBefore(_dateRange!.start) || 
              incomeDate.isAfter(_dateRange!.end.add(Duration(days: 1)))) {
            return false;
          }
        }
        
        // 支払い方法フィルター
        if (_selectedPaymentMethod != null && income.paymentMethod != _selectedPaymentMethod) {
          return false;
        }
        
        // 金額範囲フィルター
        if (_minAmount != null && income.amount < _minAmount!) {
          return false;
        }
        if (_maxAmount != null && income.amount > _maxAmount!) {
          return false;
        }
        
        // 検索クエリフィルター
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!income.source.toLowerCase().contains(query) &&
              !income.paymentMethod.toLowerCase().contains(query) &&
              !(income.memo?.toLowerCase().contains(query) ?? false)) {
            return false;
          }
        }
        
        return true;
      }).toList();
      
      _applySorting();
    });
  }

  void _applySorting() {
    switch (_sortBy) {
      case 'date_desc':
        _filteredExpenses.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
        _filteredIncomes.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
        break;
      case 'date_asc':
        _filteredExpenses.sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));
        _filteredIncomes.sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));
        break;
      case 'amount_desc':
        _filteredExpenses.sort((a, b) => b.amount.compareTo(a.amount));
        _filteredIncomes.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_asc':
        _filteredExpenses.sort((a, b) => a.amount.compareTo(b.amount));
        _filteredIncomes.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }
  }

  void _clearFilters() {
    setState(() {
      _dateRange = null;
      _selectedCategory = null;
      _selectedPaymentMethod = null;
      _minAmount = null;
      _maxAmount = null;
      _searchQuery = '';
      _searchController.clear();
      _minAmountController.clear();
      _maxAmountController.clear();
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('詳細履歴'),
        backgroundColor: Colors.purple[700],
        bottom: _tabController != null ? TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.remove),
              text: '支出 (${_filteredExpenses.length})',
            ),
            Tab(
              icon: Icon(Icons.add),
              text: '収入 (${_filteredIncomes.length})',
            ),
          ],
        ) : null,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'フィルター',
          ),
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: _showSortDialog,
            tooltip: '並び替え',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadHistoryData,
            tooltip: '更新',
          ),
        ],
      ),
      body: Column(
        children: [
          // 検索バー
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.grey[100],
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'カテゴリ、支払い方法、メモで検索...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
            ),
          ),
          
          // フィルター状態表示
          if (_hasActiveFilters()) _buildActiveFiltersBar(),
          
          // メインコンテンツ
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _tabController != null ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildExpensesList(),
                      _buildIncomesList(),
                    ],
                  ) : Container(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.blue[50],
      child: Row(
        children: [
          Icon(Icons.filter_alt, color: Colors.blue[600], size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _getActiveFiltersText(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[600],
              ),
            ),
          ),
          TextButton(
            onPressed: _clearFilters,
            child: Text(
              'クリア',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _dateRange != null ||
        _selectedCategory != null ||
        _selectedPaymentMethod != null ||
        _minAmount != null ||
        _maxAmount != null ||
        _searchQuery.isNotEmpty;
  }

  String _getActiveFiltersText() {
    List<String> filters = [];
    
    if (_dateRange != null) {
      filters.add('期間指定');
    }
    if (_selectedCategory != null) {
      filters.add('カテゴリ: $_selectedCategory');
    }
    if (_selectedPaymentMethod != null) {
      filters.add('支払方法: $_selectedPaymentMethod');
    }
    if (_minAmount != null || _maxAmount != null) {
      filters.add('金額範囲');
    }
    if (_searchQuery.isNotEmpty) {
      filters.add('検索: $_searchQuery');
    }
    
    return 'フィルター適用中: ${filters.join(', ')}';
  }

  Widget _buildExpensesList() {
    if (_filteredExpenses.isEmpty) {
      return _buildEmptyState('支出データがありません', Icons.inbox);
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredExpenses.length,
      itemBuilder: (context, index) {
        Expense expense = _filteredExpenses[index];
        return _buildExpenseCard(expense);
      },
    );
  }

  Widget _buildIncomesList() {
    if (_filteredIncomes.isEmpty) {
      return _buildEmptyState('収入データがありません', Icons.inbox);
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredIncomes.length,
      itemBuilder: (context, index) {
        Income income = _filteredIncomes[index];
        return _buildIncomeCard(income);
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          if (_hasActiveFilters()) ...[
            SizedBox(height: 8),
            TextButton(
              onPressed: _clearFilters,
              child: Text('フィルターをクリア'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    DateTime date = DateTime.parse(expense.date);
    String formattedDate = '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.remove,
            color: Colors.red[600],
          ),
        ),
        title: Text(
          '¥${_formatNumber(expense.amount)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red[600],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(expense.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getCategoryColor(expense.category).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    expense.category,
                    style: TextStyle(
                      fontSize: 10,
                      color: _getCategoryColor(expense.category),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  expense.paymentMethod,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (expense.memo != null && expense.memo!.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(
                expense.memo!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: 4),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, size: 20),
              color: Colors.blue,
              onPressed: () => _editExpense(expense),
              tooltip: '編集',
            ),
            IconButton(
              icon: Icon(Icons.delete, size: 20),
              color: Colors.red,
              onPressed: () => _deleteExpense(expense),
              tooltip: '削除',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeCard(Income income) {
    DateTime date = DateTime.parse(income.date);
    String formattedDate = '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.add,
            color: Colors.green[600],
          ),
        ),
        title: Text(
          '¥${_formatNumber(income.amount)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green[600],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    income.source,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  income.paymentMethod,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (income.memo != null && income.memo!.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(
                income.memo!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: 4),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, size: 20),
              color: Colors.blue,
              onPressed: () => _editIncome(income),
              tooltip: '編集',
            ),
            IconButton(
              icon: Icon(Icons.delete, size: 20),
              color: Colors.red,
              onPressed: () => _deleteIncome(income),
              tooltip: '削除',
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('フィルター設定'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 日付範囲選択
              ListTile(
                title: Text('期間'),
                subtitle: Text(_dateRange != null 
                    ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                    : '指定なし'),
                trailing: Icon(Icons.date_range),
                onTap: _selectDateRange,
              ),
              
              // カテゴリ選択
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'カテゴリ',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<String>(value: null, child: Text('すべて')),
                  ..._categories.map((category) => DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  )).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              SizedBox(height: 12),
              
              // 支払い方法選択
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: InputDecoration(
                  labelText: '支払い方法',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<String>(value: null, child: Text('すべて')),
                  ..._paymentMethods.map((method) => DropdownMenuItem<String>(
                    value: method,
                    child: Text(method),
                  )).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value;
                  });
                },
              ),
              SizedBox(height: 12),
              
              // 金額範囲
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minAmountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '最小金額',
                        border: OutlineInputBorder(),
                        prefixText: '¥',
                      ),
                      onChanged: (value) {
                        _minAmount = double.tryParse(value);
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _maxAmountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '最大金額',
                        border: OutlineInputBorder(),
                        prefixText: '¥',
                      ),
                      onChanged: (value) {
                        _maxAmount = double.tryParse(value);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearFilters();
              Navigator.pop(context);
            },
            child: Text('クリア'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              _applyFilters();
              Navigator.pop(context);
            },
            child: Text('適用'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('並び替え'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('日付（新しい順）'),
              value: 'date_desc',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('日付（古い順）'),
              value: 'date_asc',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('金額（高い順）'),
              value: 'amount_desc',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('金額（安い順）'),
              value: 'amount_asc',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                _applyFilters();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    
    if (range != null) {
      setState(() {
        _dateRange = range;
      });
    }
  }

  // 編集・削除機能は既存のhistory_screen.dartと同じ実装を使用
  Future<void> _editExpense(Expense expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExpenseScreen(expense: expense),
      ),
    );

    if (result == true) {
      _loadHistoryData();
      _showSuccessSnackBar('支出データが更新されました');
    }
  }

  Future<void> _editIncome(Income income) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditIncomeScreen(income: income),
      ),
    );

    if (result == true) {
      _loadHistoryData();
      _showSuccessSnackBar('収入データが更新されました');
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    bool? shouldDelete = await _showDeleteConfirmDialog(
      '支出データの削除',
      '¥${_formatNumber(expense.amount)} (${expense.category})\nこのデータを削除しますか？',
    );

    if (shouldDelete == true) {
      try {
        await _databaseHelper.deleteExpense(expense.id!);
        setState(() {
          _allExpenses.removeWhere((e) => e.id == expense.id);
          _filteredExpenses.removeWhere((e) => e.id == expense.id);
        });
        _showSuccessSnackBar('支出データを削除しました');
      } catch (e) {
        _showErrorSnackBar('削除に失敗しました');
      }
    }
  }

  Future<void> _deleteIncome(Income income) async {
    bool? shouldDelete = await _showDeleteConfirmDialog(
      '収入データの削除',
      '¥${_formatNumber(income.amount)} (${income.source})\nこのデータを削除しますか？',
    );

    if (shouldDelete == true) {
      try {
        await _databaseHelper.deleteIncome(income.id!);
        setState(() {
          _allIncomes.removeWhere((i) => i.id == income.id);
          _filteredIncomes.removeWhere((i) => i.id == income.id);
        });
        _showSuccessSnackBar('収入データを削除しました');
      } catch (e) {
        _showErrorSnackBar('削除に失敗しました');
      }
    }
  }

  Future<bool?> _showDeleteConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('削除'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
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

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}