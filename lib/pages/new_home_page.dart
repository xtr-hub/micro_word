import 'package:flutter/material.dart';
import '../pages/study_page.dart';
import '../pages/word_book_page.dart';
import '../pages/settings_page.dart';

// 学习主界面，包含底部三个菜单导航
class NewHomePage extends StatefulWidget {
  @override
  _NewHomePageState createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage> {
  // 当前选中的底部导航栏索引
  // 0: 学习页面, 1: 单词本页面, 2: 设置页面
  int _selectedIndex = 0;

  // 页面控制器，用于控制 PageView 的页面切换
  final PageController _pageController = PageController();

  // 底部导航栏的选项配置 - 三个菜单
  static const List<BottomNavigationBarItem> _bottomNavItems = [
    BottomNavigationBarItem(icon: Icon(Icons.book), label: '学习'),
    BottomNavigationBarItem(icon: Icon(Icons.collections_bookmark), label: '单词本'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
  ];

  // 页面列表，按照顺序对应底部导航栏的选项
  final List<Widget> _pages = [
    StudyPage(),
    WordBookPage(),
    SettingsPage(),   
  ];

  // 底部导航栏点击事件处理函数
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        selectedItemColor: Colors.orange,
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
}