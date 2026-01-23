import 'package:flutter/material.dart';
import '../models/test_record.dart';
import './test_result_page.dart';

/// 测试历史页面组件
///
/// 展示用户的测试历史记录，包括：
/// - 历史记录列表（按时间倒序排列）
/// - 历史记录筛选功能
/// - 点击查看历史测试结果详情
class TestHistoryPage extends StatefulWidget {
  /// 创建测试历史页面状态对象
  const TestHistoryPage({Key? key}) : super(key: key);

  @override
  _TestHistoryPageState createState() => _TestHistoryPageState();
}

class _TestHistoryPageState extends State<TestHistoryPage> {
  /// 测试记录列表
  late List<TestRecord> _testRecords;

  /// 加载状态
  bool _isLoading = true;

  /// 筛选条件
  String? _selectedDateRange;
  String? _selectedScoreRange;

  @override
  void initState() {
    super.initState();
    _loadTestRecords();
  }

  /// 加载测试记录
  Future<void> _loadTestRecords() async {
    setState(() {
      _isLoading = true;
    });

    // 从本地存储加载测试记录
    _testRecords = await TestRecordStorage.loadRecords();

    setState(() {
      _isLoading = false;
    });
  }

  /// 筛选测试记录
  List<TestRecord> _filterRecords() {
    var filtered = List<TestRecord>.from(_testRecords);

    // 按日期范围筛选
    if (_selectedDateRange != null) {
      // 这里可以根据实际需求实现日期范围筛选逻辑
    }

    // 按得分范围筛选
    if (_selectedScoreRange != null) {
      // 这里可以根据实际需求实现得分范围筛选逻辑
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('测试历史'),
        actions: [
          // 刷新按钮
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadTestRecords,
            tooltip: '刷新记录',
          ),

          // 筛选按钮
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // 这里可以实现筛选对话框
              _showFilterDialog();
            },
            tooltip: '筛选记录',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Builder(
              builder: (context) {
                // 筛选后的测试记录
                final filteredRecords = _filterRecords();

                return filteredRecords.isEmpty
                    ? Center(
                        child: Text(
                          '暂无测试记录',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = filteredRecords[index];
                          return _buildTestRecordItem(record);
                        },
                      );
              },
            ),
    );
  }

  /// 构建测试记录项
  Widget _buildTestRecordItem(TestRecord record) {
    // 计算测试日期
    final testDate = record.testTime;
    final now = DateTime.now();
    final isToday =
        testDate.year == now.year &&
        testDate.month == now.month &&
        testDate.day == now.day;
    final isYesterday =
        testDate.year == now.year &&
        testDate.month == now.month &&
        testDate.day == now.day - 1;

    String dateText;
    if (isToday) {
      dateText =
          '今天 ${testDate.hour.toString().padLeft(2, '0')}:${testDate.minute.toString().padLeft(2, '0')}';
    } else if (isYesterday) {
      dateText =
          '昨天 ${testDate.hour.toString().padLeft(2, '0')}:${testDate.minute.toString().padLeft(2, '0')}';
    } else {
      dateText =
          '${testDate.year}-${testDate.month.toString().padLeft(2, '0')}-${testDate.day.toString().padLeft(2, '0')}';
    }

    return GestureDetector(
      onTap: () {
        // 点击查看测试结果详情
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TestResultPage(testRecord: record),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 测试日期和模式
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateText,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                Text(
                  record.testMode == TestMode.multipleChoice ? '选择题' : '填空题',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),

            // 测试范围
            Text(
              '测试范围: ${record.testRange}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            SizedBox(height: 10),

            // 测试数据
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${record.totalQuestions} 题',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                Text(
                  '得分: ${record.score}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: record.score >= 80
                        ? Colors.green
                        : record.score >= 60
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
                Text(
                  '用时: ${record.formattedDuration}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),

            SizedBox(height: 10),

            // 点击查看提示
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '点击查看详情',
                style: TextStyle(fontSize: 12, color: Colors.blue.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示筛选对话框
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('筛选记录'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 日期范围筛选
              DropdownButtonFormField<String>(
                value: _selectedDateRange,
                hint: Text('选择日期范围'),
                items: [
                  DropdownMenuItem(value: 'today', child: Text('今天')),
                  DropdownMenuItem(value: 'week', child: Text('本周')),
                  DropdownMenuItem(value: 'month', child: Text('本月')),
                  DropdownMenuItem(value: 'all', child: Text('全部')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDateRange = value;
                  });
                },
              ),
              SizedBox(height: 15),

              // 得分范围筛选
              DropdownButtonFormField<String>(
                value: _selectedScoreRange,
                hint: Text('选择得分范围'),
                items: [
                  DropdownMenuItem(
                    value: 'excellent',
                    child: Text('优秀 (80-100)'),
                  ),
                  DropdownMenuItem(value: 'good', child: Text('良好 (60-79)')),
                  DropdownMenuItem(value: 'poor', child: Text('待提高 (0-59)')),
                  DropdownMenuItem(value: 'all', child: Text('全部')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedScoreRange = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedDateRange = null;
                  _selectedScoreRange = null;
                });
                Navigator.of(context).pop();
              },
              child: Text('重置'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
