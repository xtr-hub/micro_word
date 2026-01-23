import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // 图表库，用于显示学习进度扇形图
import '../models/study_progress.dart';
import './study_page.dart';
import './review_page.dart';
import './test_page.dart';
import './test_history_page.dart';
import './word_book_page.dart';
import './settings_page.dart';

/// 应用的主界面组件
///
/// 这是一个 StatefulWidget，用于管理应用的底部导航栏和页面切换
/// 包含四个主要页面：学习、测试、单词本和设置
class HomePage extends StatefulWidget {
  /// 创建页面状态对象
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// 当前选中的底部导航栏索引
  /// 0: 学习中心, 1: 测试页面, 2: 单词本页面, 3: 设置页面
  int _selectedIndex = 0;

  /// 页面控制器，用于控制 PageView 的页面切换
  final PageController _pageController = PageController();

  /// 底部导航栏的选项配置
  static const List<BottomNavigationBarItem> _bottomNavItems = [
    BottomNavigationBarItem(icon: Icon(Icons.book), label: '学习'),
    BottomNavigationBarItem(icon: Icon(Icons.assessment), label: '测试'),
    BottomNavigationBarItem(
      icon: Icon(Icons.collections_bookmark),
      label: '单词本',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
  ];

  /// 底部导航栏点击事件处理函数
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  // 学习进度数据
  late StudyProgress _progress;
  bool _isLoading = true;
  bool _showCalendar = false;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  // 加载学习进度数据
  Future<void> _loadProgress() async {
    _progress = await StudyProgress.load();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 页面标题映射，根据当前选中的索引显示对应的标题
    final List<String> pageTitles = ['学习中心', '测试', '单词本', '设置'];

    // 学习中心页面 - 包含Learn和Review按钮
    Widget _learningCenter;
    if (_isLoading) {
      _learningCenter = Center(
        child: CircularProgressIndicator(color: Colors.blue),
      );
    } else {
      _learningCenter = Column(
        // 使用主题背景色，移除黄色主题
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 可滚动内容区域
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 顶部区域 - 今日学习进度组件
                  Container(
                    margin: EdgeInsets.only(bottom: 16),
                    child: _buildStudyProgressPieChart(),
                  ),

                  // 根据签到状态决定显示内容
                  if (!_progress.isTodayCheckedIn())
                    // 未签到时显示签到按钮
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: GestureDetector(
                        onTap: () {
                          // 使用新的签到逻辑
                          bool success = _progress.checkIn();
                          if (success) {
                            setState(() {
                              // 签到成功，刷新数据
                            });
                            // 可以添加签到成功的提示
                            print('签到成功');
                          } else {
                            // 已经签到过，添加提示
                            print('今天已经签到过了');
                          }
                        },
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.95),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
                                spreadRadius: 12,
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 40,
                                color: Colors.orange,
                              ),
                              SizedBox(height: 8),
                              Text(
                                '签到',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _getCurrentDate(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    // 使用AnimatedCrossFade实现学习记录卡片和日历之间的平滑过渡
                    AnimatedCrossFade(
                      duration: Duration(milliseconds: 300),
                      crossFadeState: _showCalendar
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showCalendar = true;
                            });
                          },
                          child: Container(
                            width: 180,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 6,
                                  offset: Offset(0, 0),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 日历图标和标题
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 24,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '学习记录',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),

                                // 连续学习天数
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '${_progress.consecutiveDays}',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '天连续学习',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      secondChild: _buildStudyCalendar(),
                    ),

                  // 学习统计卡片
                  _buildStudyStats(),
                ],
              ),
            ),
          ),

          // 底部操作按钮区域
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Learn按钮
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StudyPage()),
                    );
                  },
                  child: Container(
                    width: 150,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Color(0xFF4A90E2),
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          spreadRadius: 8,
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Learn',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // 未完成学习量，显示在右下方
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 8, right: 12),
                            child: Text(
                              // 计算未完成的学习量：每日学习目标 - 今日已学习单词数
                              '${(_progress.dailyGoal - _progress.todayWordsStudied).clamp(0, _progress.dailyGoal)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Review按钮
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReviewPage()),
                    );
                  },
                  child: Container(
                    width: 150,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Color(0xFF50C878),
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          spreadRadius: 8,
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Review',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // 未完成复习量，显示在右下方
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 8, right: 12),
                            child: Text(
                              // 计算未完成的复习量：每日复习目标 - 今日已复习单词数
                              '${(_progress.dailyReviewGoal - _progress.todayWordsReviewed).clamp(0, _progress.dailyReviewGoal)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 页面列表，按照顺序对应底部导航栏的选项
    final List<Widget> _pages = [
      _learningCenter, // 学习中心页面，包含Learn和Review按钮
      TestPage(),
      WordBookPage(),
      SettingsPage(
        onSettingsSaved: () {
          // 重新加载学习进度数据
          _loadProgress();
        },
      ),
    ];

    // 构建整个页面的UI
    return Scaffold(
      // 应用栏，显示当前页面的标题
      appBar: AppBar(
        title: Text(
          pageTitles[_selectedIndex],
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF4A90E2),
        elevation: 10,
        shadowColor: Colors.blue.withOpacity(0.3),
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          // 测试页面显示测试历史入口
          if (_selectedIndex == 1) // 测试页面的索引是1
            IconButton(
              icon: Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TestHistoryPage()),
                );
              },
              tooltip: '测试历史',
            ),
        ],
      ),

      // 页面主体部分，使用PageView实现页面切换
      body: PageView(
        controller: _pageController,
        // 页面切换时的回调函数，用于更新底部导航栏的选中状态
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        // 页面列表
        children: _pages,
      ),

      // 底部导航栏
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomNavItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 15,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 14),
      ),
    );
  }

  // 获取当前日期的格式化字符串
  String _getCurrentDate() {
    final today = DateTime.now();
    final month = today.month.toString().padLeft(2, '0');
    final day = today.day.toString().padLeft(2, '0');
    final weekday = _getWeekday(today.weekday);
    return '$month/$day $weekday';
  }

  // 获取星期几的英文缩写
  String _getWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon.';
      case DateTime.tuesday:
        return 'Tues.';
      case DateTime.wednesday:
        return 'Wed.';
      case DateTime.thursday:
        return 'Thurs.';
      case DateTime.friday:
        return 'Fri.';
      case DateTime.saturday:
        return 'Sat.';
      case DateTime.sunday:
        return 'Sun.';
      default:
        return '';
    }
  }

  // 构建学习统计卡片
  Widget _buildStudyStats() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 6,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            '学习统计',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 16),

          // 统计数据网格
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              // 总学习单词数
              _buildStatItem(
                icon: Icons.book,
                title: '总学习单词',
                value: '${_progress.totalWordsStudied}',
                color: Colors.blue,
              ),

              // 已掌握单词数
              _buildStatItem(
                icon: Icons.star,
                title: '已掌握单词',
                value: '${_progress.masteredWords}',
                color: Colors.orange,
              ),

              // 总学习时长
              _buildStatItem(
                icon: Icons.access_time,
                title: '总学习时长',
                value:
                    '${(_progress.totalStudyTime / 3600).toStringAsFixed(1)}小时',
                color: Colors.green,
              ),

              // 待复习单词数
              _buildStatItem(
                icon: Icons.refresh,
                title: '待复习单词',
                value: '${_progress.reviewWords}',
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建单个统计项
  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // 构建学习日历
  Widget _buildStudyCalendar() {
    final monthNames = [
      '一月',
      '二月',
      '三月',
      '四月',
      '五月',
      '六月',
      '七月',
      '八月',
      '九月',
      '十月',
      '十一月',
      '十二月',
    ];
    final weekDays = ['日', '一', '二', '三', '四', '五', '六'];

    // 获取当前月份的签到记录
    final checkInRecords = _progress.getCheckInRecordsForMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    // 获取月份第一天和最后一天
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    // 获取月份第一天是星期几
    final firstDayWeekday = firstDay.weekday;

    // 生成日历网格
    final calendarDays = <Widget>[];

    // 添加星期标题
    for (var i = 0; i < 7; i++) {
      calendarDays.add(
        Container(
          width: 35,
          height: 35,
          alignment: Alignment.center,
          child: Text(
            weekDays[i],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
      );
    }

    // 添加空白单元格
    for (var i = 0; i < firstDayWeekday; i++) {
      calendarDays.add(
        Container(width: 35, height: 35, alignment: Alignment.center),
      );
    }

    // 添加日期单元格
    for (var day = 1; day <= lastDay.day; day++) {
      final isCheckedIn = checkInRecords[day] ?? false;
      final isToday =
          DateTime.now().year == _selectedMonth.year &&
          DateTime.now().month == _selectedMonth.month &&
          day == DateTime.now().day;

      calendarDays.add(
        Container(
          width: 35,
          height: 35,
          alignment: Alignment.center,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCheckedIn
                  ? Colors.orange
                  : isToday
                  ? Colors.blue
                  : Colors.transparent,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 12,
                color: isCheckedIn || isToday ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 3,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 月份标题、返回按钮和切换按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 返回按钮
              IconButton(
                icon: Icon(Icons.arrow_back, size: 20, color: Colors.orange),
                onPressed: () {
                  setState(() {
                    _showCalendar = false;
                  });
                },
                padding: EdgeInsets.all(5),
                tooltip: '返回学习记录',
              ),

              // 月份标题
              Text(
                '${_selectedMonth.year}年 ${monthNames[_selectedMonth.month - 1]}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),

              // 月份切换按钮
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month - 1,
                          1,
                        );
                      });
                    },
                    padding: EdgeInsets.all(5),
                    tooltip: '上一月',
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month + 1,
                          1,
                        );
                      });
                    },
                    padding: EdgeInsets.all(5),
                    tooltip: '下一月',
                  ),
                ],
              ),
            ],
          ),

          // 日历网格
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
            children: calendarDays,
          ),
        ],
      ),
    );
  }

  // 构建今日学习进度组件 - 使用水平进度条设计
  Widget _buildStudyProgressPieChart() {
    // 计算学习进度百分比
    final studyProgress = _progress.todayWordsStudied / _progress.dailyGoal;
    final reviewProgress =
        _progress.todayWordsReviewed / _progress.dailyReviewGoal;

    // 确保进度不超过100%
    final clampedStudyProgress = studyProgress.clamp(0.0, 1.0);
    final clampedReviewProgress = reviewProgress.clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.12),
            spreadRadius: 6,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF5F5FA)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 学习进度标题
          Text(
            '今日学习进度',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 20),

          // 学习进度条
          _buildProgressBar(
            title: '学习',
            progress: clampedStudyProgress,
            current: _progress.todayWordsStudied,
            total: _progress.dailyGoal,
            color: Color(0xFF667eea),
            backgroundColor: Color(0xFFe6e9f0),
            icon: Icons.book,
          ),
          SizedBox(height: 16),

          // 复习进度条
          _buildProgressBar(
            title: '复习',
            progress: clampedReviewProgress,
            current: _progress.todayWordsReviewed,
            total: _progress.dailyReviewGoal,
            color: Color(0xFFf093fb),
            backgroundColor: Color(0xFFfce4ec),
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }

  // 构建单个进度条组件
  Widget _buildProgressBar({
    required String title,
    required double progress,
    required int current,
    required int total,
    required Color color,
    required Color backgroundColor,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和进度数字
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A5568),
                  ),
                ),
              ],
            ),
            Text(
              '$current/$total',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),

        // 进度条容器
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              // 进度条填充
              LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    width: constraints.maxWidth * progress,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // 进度百分比
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: progress > 0.5 ? Colors.white : color,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
