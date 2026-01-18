import 'package:flutter/material.dart';

// 导入应用的主要页面组件
import 'study_page.dart'; // 学习页面
import 'test_page.dart'; // 测试页面
import 'word_book_page.dart'; // 单词本页面
import 'settings_page.dart'; // 设置页面

/// 应用的主界面组件
///
/// 这是一个 StatefulWidget，用于管理应用的底部导航栏和页面切换
/// 包含四个主要页面：学习、测试、单词本和设置
class HomePage extends StatefulWidget {
  /// 创建页面状态对象
  @override
  _HomePageState createState() => _HomePageState();
}

/// HomePage 的状态管理类
///
/// 负责处理底部导航栏的点击事件和页面切换逻辑
class _HomePageState extends State<HomePage> {
  /// 当前选中的底部导航栏索引
  /// 0: 学习页面, 1: 测试页面, 2: 单词本页面, 3: 设置页面
  int _selectedIndex = 0;

  /// 页面控制器，用于控制 PageView 的页面切换
  /// PageController 允许我们以编程方式切换页面
  final PageController _pageController = PageController();

  /// 底部导航栏的选项配置
  /// 每个选项包含一个图标和一个标签
  static const List<BottomNavigationBarItem> _bottomNavItems = [
    BottomNavigationBarItem(icon: Icon(Icons.book), label: '学习'), // 学习页面选项
    BottomNavigationBarItem(
      icon: Icon(Icons.assessment),
      label: '测试',
    ), // 测试页面选项
    BottomNavigationBarItem(icon: Icon(Icons.list), label: '单词本'), // 单词本页面选项
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'), // 设置页面选项
  ];

  /// 底部导航栏点击事件处理函数
  ///
  /// 当用户点击底部导航栏的某个选项时，会调用此函数
  /// 参数：
  /// - index: 被点击的选项索引
  void _onItemTapped(int index) {
    setState(() {
      // 更新当前选中的索引，这会触发UI重新构建
      _selectedIndex = index;
      // 使用页面控制器跳转到对应的页面
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 页面标题映射，根据当前选中的索引显示对应的标题
    final List<String> pageTitles = ['学习', '测试', '单词本', '设置'];

    // 构建整个页面的UI
    return Scaffold(
      // 页面背景色，使用主题中的主色调
      backgroundColor: Theme.of(context).primaryColor,

      // 应用栏，显示当前页面的标题
      appBar: AppBar(
        title: Text(
          pageTitles[_selectedIndex], // 根据当前索引显示对应标题
          style: TextStyle(
            fontSize: 24, // 标题字体大小
            fontWeight: FontWeight.bold, // 标题字体粗细
            color: Colors.white, // 标题颜色
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor, // 应用栏背景色
        elevation: 0, // 移除应用栏阴影
        shadowColor: Colors.transparent, // 阴影颜色设为透明
        centerTitle: true, // 标题居中显示
        shape: RoundedRectangleBorder(
          // 应用栏底部圆角设计
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),

      // 页面主体部分，使用PageView实现页面切换
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor, // 主体背景色
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // 顶部圆角
        ),
        child: PageView(
          controller: _pageController, // 关联页面控制器
          // 页面切换时的回调函数，用于更新底部导航栏的选中状态
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index; // 更新选中索引
            });
          },
          // 页面列表，按照顺序对应底部导航栏的选项
          children: [StudyPage(), TestPage(), WordBookPage(), SettingsPage()],
        ),
      ),

      // 底部导航栏
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomNavItems, // 导航栏选项配置
        currentIndex: _selectedIndex, // 当前选中的索引
        selectedItemColor: Colors.blue, // 选中项的颜色
        unselectedItemColor: Colors.grey, // 未选中项的颜色
        onTap: _onItemTapped, // 点击事件处理函数
        backgroundColor: Colors.white, // 导航栏背景色
        elevation: 15, // 导航栏阴影高度
        type: BottomNavigationBarType.fixed, // 导航栏类型为固定
        selectedLabelStyle: TextStyle(
          // 选中标签的样式
          fontWeight: FontWeight.bold, // 选中标签字体加粗
          fontSize: 14, // 选中标签字体大小
        ),
        unselectedLabelStyle: TextStyle(fontSize: 14), // 未选中标签的样式
      ),
    );
  }
}
