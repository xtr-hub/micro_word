import 'package:flutter/material.dart';
import '../pages/study_page.dart';
import '../pages/test_page.dart';
import '../pages/word_book_page.dart';
import '../pages/settings_page.dart';

/// 新的主界面组件
///
/// 采用简洁的卡片式设计风格，参考了"不背单词" app的设计
/// 特点：
/// - 顶部渐变背景
/// - 卡片式布局
/// - 响应式设计
/// - 功能入口清晰
class NewHomePage extends StatefulWidget {
  /// 创建页面状态对象
  @override
  _NewHomePageState createState() => _NewHomePageState();
}

/// NewHomePage 的状态管理类
class _NewHomePageState extends State<NewHomePage> {
  @override
  Widget build(BuildContext context) {
    // 构建整个页面UI
    return Scaffold(
      // 页面背景色，使用主题中的主色调
      backgroundColor: Theme.of(context).primaryColor,

      // SafeArea 确保内容不会被设备的状态栏或刘海遮挡
      body: SafeArea(
        // 垂直排列的布局
        child: Column(
          children: [
            // 顶部区域：包含应用标题和设置按钮
            Container(
              // 内边距设置
              padding: EdgeInsets.only(
                top: 20,
                bottom: 30,
                left: 30,
                right: 30,
              ),
              child: Row(
                // 主轴对齐方式：两端对齐
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 应用标题
                  Text(
                    '不背单词',
                    style: TextStyle(
                      fontSize: 32, // 标题字体大小
                      fontWeight: FontWeight.bold, // 标题字体粗细
                      color: Colors.white, // 标题颜色
                    ),
                  ),
                  // 设置按钮
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.white, size: 28),
                    onPressed: () {
                      // 导航到设置页面
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 学习进度卡片：显示今日学习进度
            Container(
              // 外边距设置
              margin: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              // 内边距设置
              padding: EdgeInsets.all(25),
              // 卡片装饰：半透明背景和圆角
              decoration: BoxDecoration(
                color: Color.fromRGBO(255, 255, 255, 0.2), // 半透明白色背景
                borderRadius: BorderRadius.circular(20), // 圆角半径
              ),
              child: Column(
                children: [
                  // 卡片标题
                  Text(
                    '今日学习',
                    style: TextStyle(
                      fontSize: 18, // 标题字体大小
                      color: Color.fromRGBO(255, 255, 255, 0.8), // 半透明白色
                    ),
                  ),
                  SizedBox(height: 15), // 垂直间距
                  // 学习进度数字
                  Text(
                    '0 / 20',
                    style: TextStyle(
                      fontSize: 48, // 数字字体大小
                      fontWeight: FontWeight.bold, // 数字字体粗细
                      color: Colors.white, // 数字颜色
                    ),
                  ),
                  SizedBox(height: 15), // 垂直间距
                  // 进度条
                  LinearProgressIndicator(
                    value: 0, // 当前进度值（0.0 - 1.0）
                    backgroundColor: Color.fromRGBO(
                      255,
                      255,
                      255,
                      0.3,
                    ), // 进度条背景色
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ), // 进度条颜色
                    minHeight: 8, // 进度条高度
                    borderRadius: BorderRadius.circular(4), // 进度条圆角
                  ),
                ],
              ),
            ),

            // 功能入口区域：使用Expanded填充剩余空间
            Expanded(
              child: Container(
                // 容器装饰：背景色、顶部圆角和阴影
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor, // 主体背景色
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ), // 顶部圆角
                  boxShadow: [
                    // 阴影效果
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.1), // 阴影颜色
                      spreadRadius: 10, // 阴影扩散范围
                      blurRadius: 20, // 阴影模糊程度
                      offset: Offset(0, -5), // 阴影偏移量
                    ),
                  ],
                ),

                // 可滚动内容区域
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(30), // 内边距
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // 交叉轴对齐方式：左对齐
                    mainAxisSize: MainAxisSize.min, // 主轴大小：最小化
                    children: [
                      // 功能标题
                      Text(
                        '功能',
                        style: TextStyle(
                          fontSize: 24, // 标题字体大小
                          fontWeight: FontWeight.bold, // 标题字体粗细
                          color: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.color, // 标题颜色
                        ),
                      ),
                      SizedBox(height: 20), // 垂直间距
                      // 功能卡片网格
                      GridView.builder(
                        shrinkWrap: true, // 收缩包装，适应内容大小
                        physics: NeverScrollableScrollPhysics(), // 禁用滚动
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          // 基于屏幕宽度动态调整列数：宽屏3列，窄屏2列
                          crossAxisCount:
                              MediaQuery.of(context).size.width > 600 ? 3 : 2,
                          mainAxisSpacing: 20, // 主轴方向间距
                          crossAxisSpacing: 20, // 交叉轴方向间距
                          childAspectRatio: 0.9, // 子项宽高比
                        ),
                        itemCount: 4, // 网格项数量
                        // 网格项构建器
                        itemBuilder: (context, index) {
                          // 功能卡片数据配置
                          final featureCards = [
                            {
                              'icon': Icons.book, // 图标
                              'title': '开始学习', // 标题
                              'description': '每天坚持学习20个单词', // 描述
                              'color': Colors.blue, // 主题色
                              // 点击事件：导航到学习页面
                              'onTap': () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudyPage(),
                                ),
                              ),
                            },
                            {
                              'icon': Icons.assessment, // 图标
                              'title': '自我测试', // 标题
                              'description': '检验你的学习成果', // 描述
                              'color': Colors.purple, // 主题色
                              // 点击事件：导航到测试页面
                              'onTap': () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TestPage(),
                                ),
                              ),
                            },
                            {
                              'icon': Icons.collections_bookmark, // 图标
                              'title': '我的单词本', // 标题
                              'description': '查看所有学习的单词', // 描述
                              'color': Colors.green, // 主题色
                              // 点击事件：导航到单词本页面
                              'onTap': () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WordBookPage(),
                                ),
                              ),
                            },
                            {
                              'icon': Icons.help_outline, // 图标
                              'title': '生词本', // 标题
                              'description': '重点复习难记单词', // 描述
                              'color': Colors.orange, // 主题色
                              // 点击事件：导航到单词本页面
                              'onTap': () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WordBookPage(),
                                ),
                              ),
                            },
                          ];

                          final cardData = featureCards[index]; // 获取当前索引的卡片数据

                          // 返回单个功能卡片
                          return GestureDetector(
                            onTap: cardData['onTap'] as VoidCallback, // 点击事件
                            child: Container(
                              padding: EdgeInsets.all(20), // 内边距
                              // 卡片装饰
                              decoration: BoxDecoration(
                                // 卡片背景色：根据主题模式调整
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey.shade800
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20), // 圆角半径
                                boxShadow: [
                                  // 阴影效果
                                  BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.05),
                                    spreadRadius: 3,
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start, // 左对齐
                                children: [
                                  // 图标背景
                                  Container(
                                    width: 60, // 背景宽度
                                    height: 60, // 背景高度
                                    decoration: BoxDecoration(
                                      // 背景色：使用卡片主题色的10%透明度
                                      color: Color.fromRGBO(
                                        (cardData['color'] as Color).red,
                                        (cardData['color'] as Color).green,
                                        (cardData['color'] as Color).blue,
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        15,
                                      ), // 圆角半径
                                    ),
                                    child: Icon(
                                      cardData['icon'] as IconData, // 图标
                                      size: 32, // 图标大小
                                      color: cardData['color'] as Color, // 图标颜色
                                    ),
                                  ),
                                  SizedBox(height: 15), // 垂直间距
                                  // 卡片标题
                                  Text(
                                    cardData['title'] as String, // 标题文本
                                    style: TextStyle(
                                      fontSize: 20, // 标题字体大小
                                      fontWeight: FontWeight.bold, // 标题字体粗细
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color, // 标题颜色
                                    ),
                                    maxLines: 1, // 最大行数
                                    overflow: TextOverflow.ellipsis, // 溢出处理：省略号
                                  ),
                                  SizedBox(height: 8), // 垂直间距
                                  // 卡片描述
                                  Text(
                                    cardData['description'] as String, // 描述文本
                                    style: TextStyle(
                                      fontSize: 14, // 描述字体大小
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color, // 描述颜色
                                      height: 1.4, // 行高
                                    ),
                                    maxLines: 2, // 最大行数
                                    overflow: TextOverflow.ellipsis, // 溢出处理：省略号
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 30), // 垂直间距
                      // 学习数据统计卡片
                      Container(
                        padding: EdgeInsets.all(25), // 内边距
                        decoration: BoxDecoration(
                          // 卡片背景色：根据主题模式调整
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(20), // 圆角半径
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
                          children: [
                            // 统计卡片标题
                            Text(
                              '学习数据',
                              style: TextStyle(
                                fontSize: 20, // 标题字体大小
                                fontWeight: FontWeight.bold, // 标题字体粗细
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color, // 标题颜色
                              ),
                            ),
                            SizedBox(height: 20), // 垂直间距
                            // 数据统计卡片行
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround, // 均匀分布
                              children: [
                                _buildDataCard('总单词数', '0'), // 总单词数卡片
                                _buildDataCard('已掌握', '0'), // 已掌握单词数卡片
                                _buildDataCard('连续学习', '0天'), // 连续学习天数卡片
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20), // 底部间距
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建功能卡片的辅助方法
  ///
  /// 参数：
  /// - icon: 卡片图标
  /// - title: 卡片标题
  /// - description: 卡片描述
  /// - color: 卡片主题色
  /// - onTap: 点击事件回调
  ///
  /// 返回：构建好的功能卡片Widget
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap, // 点击事件
      child: Container(
        padding: EdgeInsets.all(20), // 内边距
        decoration: BoxDecoration(
          // 卡片背景色：根据主题模式调整
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.white,
          borderRadius: BorderRadius.circular(20), // 圆角半径
          boxShadow: [
            // 阴影效果
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              spreadRadius: 3,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
          children: [
            // 图标背景
            Container(
              width: 60, // 背景宽度
              height: 60, // 背景高度
              decoration: BoxDecoration(
                // 背景色：使用主题色的10%透明度
                color: Color.fromRGBO(color.red, color.green, color.blue, 0.1),
                borderRadius: BorderRadius.circular(15), // 圆角半径
              ),
              child: Icon(
                icon, // 图标
                size: 32, // 图标大小
                color: color, // 图标颜色
              ),
            ),
            SizedBox(height: 15), // 垂直间距
            // 卡片标题
            Text(
              title,
              style: TextStyle(
                fontSize: 20, // 标题字体大小
                fontWeight: FontWeight.bold, // 标题字体粗细
                color: Theme.of(context).textTheme.bodyLarge?.color, // 标题颜色
              ),
            ),
            SizedBox(height: 8), // 垂直间距
            // 卡片描述
            Text(
              description,
              style: TextStyle(
                fontSize: 14, // 描述字体大小
                color: Theme.of(context).textTheme.bodyMedium?.color, // 描述颜色
                height: 1.4, // 行高
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建数据统计卡片的辅助方法
  ///
  /// 参数：
  /// - title: 统计项标题
  /// - value: 统计项数值
  ///
  /// 返回：构建好的数据统计卡片Widget
  Widget _buildDataCard(String title, String value) {
    return Column(
      children: [
        // 统计数值
        Text(
          value,
          style: TextStyle(
            fontSize: 28, // 数值字体大小
            fontWeight: FontWeight.bold, // 数值字体粗细
            color: Colors.blue.shade700, // 数值颜色
          ),
        ),
        SizedBox(height: 5), // 垂直间距
        // 统计标题
        Text(
          title,
          style: TextStyle(
            fontSize: 14, // 标题字体大小
            color: Theme.of(context).textTheme.bodyMedium?.color, // 标题颜色
          ),
        ),
      ],
    );
  }
}
