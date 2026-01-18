import 'dart:async'; // 用于定时器功能
import 'package:flutter/material.dart'; // Flutter UI组件库
import './home_page.dart'; // 主页面组件

/// 应用启动页
///
/// 功能：
/// - 显示应用Logo和名称
/// - 2秒后自动跳转到主页面
/// - 提供良好的视觉体验
class SplashPage extends StatefulWidget {
  /// 创建页面状态对象
  @override
  _SplashPageState createState() => _SplashPageState();
}

/// SplashPage 的状态管理类
class _SplashPageState extends State<SplashPage> {
  /// 页面初始化时调用
  @override
  void initState() {
    super.initState();
    // 使用Timer定时器，延迟2秒后执行导航操作
    Timer(Duration(seconds: 2), () {
      // 导航到主页面，并替换当前页面（不再返回启动页）
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    });
  }

  /// 构建页面UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 渐变背景
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, // 渐变起始位置（顶部中心）
            end: Alignment.bottomCenter, // 渐变结束位置（底部中心）
            colors: [Colors.blue.shade100, Colors.purple.shade100], // 渐变颜色
          ),
        ),
        child: Center(
          // 垂直排列的组件
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
            children: [
              // 应用图标
              Container(
                width: 120, // 图标容器宽度
                height: 120, // 图标容器高度
                decoration: BoxDecoration(
                  color: Colors.white, // 图标背景色
                  borderRadius: BorderRadius.circular(30), // 图标圆角
                  boxShadow: [
                    // 图标阴影
                    BoxShadow(
                      color: Color.fromRGBO(0, 122, 255, 0.3), // 阴影颜色
                      spreadRadius: 15, // 阴影扩散范围
                      blurRadius: 25, // 阴影模糊程度
                      offset: Offset(0, 15), // 阴影偏移量
                    ),
                  ],
                ),
                child: Icon(
                  // 书籍图标
                  Icons.book, // 图标类型
                  size: 60, // 图标大小
                  color: Colors.blue, // 图标颜色
                ),
              ),
              SizedBox(height: 40), // 图标与应用名称间距
              // 应用名称
              Text(
                '微单词',
                style: TextStyle(
                  fontSize: 42, // 字体大小
                  fontWeight: FontWeight.bold, // 字体粗细
                  color: Colors.white, // 字体颜色
                  shadows: [
                    // 文字阴影
                    Shadow(
                      color: Color.fromRGBO(0, 122, 255, 0.3),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20), // 应用名称与标语间距
              // 应用标语
              Text(
                '轻松背单词，快乐学英语',
                style: TextStyle(
                  fontSize: 18, // 字体大小
                  color: Color.fromRGBO(255, 255, 255, 0.9), // 半透明白色
                  shadows: [
                    // 文字阴影
                    Shadow(
                      color: Color.fromRGBO(0, 122, 255, 0.3),
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 60), // 标语与加载动画间距
              // 加载动画
              Container(
                width: 60, // 动画容器宽度
                height: 60, // 动画容器高度
                child: CircularProgressIndicator(
                  // 圆形进度指示器
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ), // 进度条颜色
                  strokeWidth: 8, // 进度条宽度
                  backgroundColor: Color.fromRGBO(0, 122, 255, 0.3), // 背景色
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
