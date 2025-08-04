import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kakeibo_app/chart_data_service.dart';

class DynamicPieChart extends StatefulWidget {
  const DynamicPieChart({Key? key}) : super(key: key);  // keyパラメータを追加

  @override
  DynamicPieChartState createState() => DynamicPieChartState();  // アンダースコアを削除
}

class DynamicPieChartState extends State<DynamicPieChart> {  // アンダースコアを削除
  final ChartDataService _chartDataService = ChartDataService();
  Map<String, double> _categoryData = {};
  Map<String, double> _percentages = {};
  bool _isLoading = true;
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, double> categoryTotals = await _chartDataService.getExpensesByCategory();
      Map<String, double> percentages = _chartDataService.calculatePercentages(categoryTotals);

      setState(() {
        _categoryData = categoryTotals;
        _percentages = percentages;
        _hasData = categoryTotals.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      print('円グラフデータ読み込みエラー: $e');
      setState(() {
        _isLoading = false;
        _hasData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: 200,
        height: 200,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasData) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart,
                size: 50,
                color: Colors.grey[400],
              ),
              SizedBox(height: 10),
              Text(
                '支出データなし',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // 円グラフ
        Container(
          width: 200,
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 25,
              sections: _buildPieChartSections(),
            ),
          ),
        ),
        SizedBox(height: 20),
        
        // 凡例
        _buildLegend(),
      ],
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    Map<String, dynamic> colorMap = _chartDataService.getCategoryColors();
    List<PieChartSectionData> sections = [];

    _categoryData.forEach((category, amount) {
      double percentage = _percentages[category] ?? 0;
      Color sectionColor = Color(colorMap[category]?['color'] ?? 0xFF9E9E9E);

      sections.add(
        PieChartSectionData(
          color: sectionColor,
          value: percentage,
          title: '${percentage.toInt()}%',
          radius: 80,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });

    return sections;
  }

  Widget _buildLegend() {
    Map<String, dynamic> colorMap = _chartDataService.getCategoryColors();
    
    return Column(
      children: _categoryData.entries.map((entry) {
        String category = entry.key;
        double amount = entry.value;
        double percentage = _percentages[category] ?? 0;
        
        Color itemColor = Color(colorMap[category]?['color'] ?? 0xFF9E9E9E);
        String icon = colorMap[category]?['icon'] ?? '💰';

        return Container(
          margin: EdgeInsets.symmetric(vertical: 4),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: itemColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: itemColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: itemColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                icon,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '¥${_chartDataService.formatNumber(amount)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: itemColor,
                    ),
                  ),
                  Text(
                    '${percentage.toInt()}%',
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
      }).toList(),
    );
  }
}
