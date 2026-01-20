import 'package:flutter/material.dart';
import '../models/study_progress.dart';
import './study_page.dart';
import './review_page.dart';
import './test_page.dart';
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
    BottomNavigationBarItem(icon: Icon(Icons.collections_bookmark), label: '单词本'),
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
    final Widget _learningCenter = Container(
      // 使用主题背景色，移除黄色主题
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.all(20),
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.blue))
              : Column(
                  children: [
                    // 顶部区域
                    Container(
                      height: 80,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 连续学习天数按钮 - 点击显示学习日历
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showCalendar = !_showCalendar;
                              });
                            },
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.9),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    spreadRadius: 5,
                                    blurRadius: 10,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${_progress.consecutiveDays}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  Text(
                                    '天',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 学习日历 - 点击连续天数按钮显示
                    if (_showCalendar)
                      _buildStudyCalendar(),

                    // 中间签到按钮
                    Expanded(
                      child: Center(
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
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _progress.isTodayCheckedIn() 
                                  ? Colors.grey.shade300 
                                  : Colors.white.withOpacity(0.95),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.3),
                                  spreadRadius: 15,
                                  blurRadius: 25,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _progress.isTodayCheckedIn() 
                                      ? Icons.check_circle 
                                      : Icons.calendar_today,
                                  size: 48,
                                  color: _progress.isTodayCheckedIn() 
                                      ? Colors.grey 
                                      : Colors.orange,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  _progress.isTodayCheckedIn() ? '已签到' : '签到',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _progress.isTodayCheckedIn() 
                                        ? Colors.grey 
                                        : Colors.orange,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  _getCurrentDate(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 底部Learn和Review按钮
                    Container(
                      height: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Learn按钮
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudyPage(),
                                ),
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
                                  // 未完成学习量，显示在左下方
                                  Align(
                                    alignment: Alignment.bottomLeft,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        bottom: 8,
                                        left: 12,
                                      ),
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
                                MaterialPageRoute(
                                  builder: (context) => ReviewPage(),
                                ),
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
                                  // 未完成复习量，显示在左下方
                                  Align(
                                    alignment: Alignment.bottomLeft,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        bottom: 8,
                                        left: 12,
                                      ),
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
                ),
        ),
      ),
    );

    // 页面列表，按照顺序对应底部导航栏的选项
    final List<Widget> _pages = [
      _learningCenter, // 学习中心页面，包含Learn和Review按钮
      TestPage(),
      WordBookPage(),
      SettingsPage(),
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

  // 构建学习日历
  Widget _buildStudyCalendar() {
    final monthNames = ['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月'];
    final weekDays = ['日', '一', '二', '三', '四', '五', '六'];
    
    // 获取当前月份的签到记录
    final checkInRecords = _progress.getCheckInRecordsForMonth(
      _selectedMonth.year, 
      _selectedMonth.month
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
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Text(
            weekDays[i],
            style: TextStyle(
              fontSize: 14,
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
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
        ),
      );
    }
    
    // 添加日期单元格
    for (var day = 1; day <= lastDay.day; day++) {
      final isCheckedIn = checkInRecords[day] ?? false;
      final isToday = DateTime.now().year == _selectedMonth.year &&
                     DateTime.now().month == _selectedMonth.month &&
                     day == DateTime.now().day;
      
      calendarDays.add(
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Container(
            width: 32,
            height: 32,
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
                fontSize: 14,
                color: isCheckedIn || isToday
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
        ),
      );
    }
    
    return Container(
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // 月份标题和切换按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                      1,
                    );
                  });
                },
              ),
              Text(
                '${_selectedMonth.year}年 ${monthNames[_selectedMonth.month - 1]}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                      1,
                    );
                  });
                },
              ),
            ],
          ),
          
          // 日历网格
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            children: calendarDays,
          ),
        ],
      ),
    );
  }
}