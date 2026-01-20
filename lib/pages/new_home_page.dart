
import 'package:flutter/material.dart';
import '../pages/study_page.dart';
import '../pages/test_page.dart';
import '../pages/word_book_page.dart';
import '../pages/settings_page.dart';

// 新的主界面，采用简洁的功能入口设计，参考"不背单词" app
class NewHomePage extends StatefulWidget {
  @override
  _NewHomePageState createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部区域
            Container(
              padding: EdgeInsets.only(top: 20, bottom: 30, left: 30, right: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 应用标题
                  Text(
                    '不背单词',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      
                    ),
                  ),
                  // 设置按钮
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.white, size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // 学习进度卡片
            Container(
              margin: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              padding: EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Color.fromRGBO(255, 255, 255, 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    '今日学习',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color.fromRGBO(255, 255, 255, 0.8),
                      
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    '0 / 20',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      
                    ),
                  ),
                  SizedBox(height: 15),
                  LinearProgressIndicator(
                    value: 0,
                    backgroundColor: Color.fromRGBO(255, 255, 255, 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            
            // 功能入口区域
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.1),
                      spreadRadius: 10,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ]
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 功能标题
                      Text(
                        '功能',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          
                        ),
                      ),
                      SizedBox(height: 20),
                      
                      // 功能卡片网格
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2, // 基于屏幕宽度动态调整列数
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: 0.9, // 调整宽高比以适应内容
                        ),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          // 功能卡片数据
                          final featureCards = [
                            {
                              'icon': Icons.book,
                              'title': '开始学习',
                              'description': '每天坚持学习20个单词',
                              'color': Colors.blue,
                              'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => StudyPage())),
                            },
                            {
                              'icon': Icons.assessment,
                              'title': '自我测试',
                              'description': '检验你的学习成果',
                              'color': Colors.purple,
                              'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => TestPage())),
                            },
                            {
                              'icon': Icons.collections_bookmark,
                              'title': '我的单词本',
                              'description': '查看所有学习的单词',
                              'color': Colors.green,
                              'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => WordBookPage())),
                            },
                            {
                              'icon': Icons.help_outline,
                              'title': '生词本',
                              'description': '重点复习难记单词',
                              'color': Colors.orange,
                              'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => WordBookPage())),
                            },
                          ];
                          
                          final cardData = featureCards[index];
                          
                          // 返回单个功能卡片
                          return GestureDetector(
                            onTap: cardData['onTap'] as VoidCallback,
                            child: Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.05),
                                    spreadRadius: 3,
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ]
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 图标背景
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(
                                        (cardData['color'] as Color).red,
                                        (cardData['color'] as Color).green,
                                        (cardData['color'] as Color).blue,
                                        0.1
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Icon(
                                      cardData['icon'] as IconData,
                                      size: 32,
                                      color: cardData['color'] as Color,
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  
                                  // 标题 - 添加溢出处理
                                  Text(
                                    cardData['title'] as String,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8),
                                  
                                  // 描述 - 添加溢出处理
                                  Text(
                                    cardData['description'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: 30),
                      
                      // 学习数据统计
                      Container(
                        padding: EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                '学习数据',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  
                ),
              ),
                            SizedBox(height: 20),
                            
                            // 数据统计卡片
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildDataCard('总单词数', '0'),
                                _buildDataCard('已掌握', '0'),
                                _buildDataCard('连续学习', '0天'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
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
  
  // 构建功能卡片
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              spreadRadius: 3,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图标背景
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
            color: Color.fromRGBO(color.red, color.green, color.blue, 0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            SizedBox(height: 15),
            
            // 标题
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  
                ),
              ),
              SizedBox(height: 8),
              
              // 描述
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  height: 1.4,
                  
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // 构建数据卡片
  Widget _buildDataCard(String title, String value) {
    return Column(
      children: [
        Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
              
            ),
          ),
          SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              
            ),
          ),
      ],
    );
  }
}
