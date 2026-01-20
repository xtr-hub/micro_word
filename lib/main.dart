/// Flutter核心库，提供构建UI的基础组件
import 'package:flutter/material.dart';

/// 系统服务库，用于控制设备方向和UI模式
import 'package:flutter/services.dart';

/// 状态管理库Provider，用于在组件树中共享状态
import 'package:provider/provider.dart';

/// 主题提供者，用于管理应用的主题切换
import 'providers/theme_provider.dart';

/// 主页面组件，包含底部导航栏和多个子页面
import 'pages/home_page.dart';

/// 启动页组件，应用启动时显示的第一个页面
import 'pages/splash_page.dart';

/// 学习页面组件
import 'pages/study_page.dart';

/// 复习页面组件
import 'pages/review_page.dart';

/// 测试页面组件
import 'pages/test_page.dart';

/// 单词本页面组件
import 'pages/word_book_page.dart';

/// 设置页面组件
import 'pages/settings_page.dart';

/// 应用程序的入口点
///
/// Flutter应用总是从main函数开始执行
/// 该函数负责初始化应用环境并启动应用
void main() {
  /// 确保Flutter框架初始化完成
  ///
  /// 这是调用平台通道前的必要步骤，确保Flutter引擎已完全初始化
  /// 只有初始化完成后才能调用系统级API，如设置设备方向
  WidgetsFlutterBinding.ensureInitialized();

  /// 设置应用仅支持竖屏显示
  ///
  /// 使用SystemChrome类来控制设备的显示方向
  /// DeviceOrientation.portraitUp表示仅支持向上的竖屏方向
  /// 这确保应用在不同设备上都能保持一致的布局
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  /// 设置系统UI模式为沉浸式
  ///
  /// SystemUiMode.immersive模式会隐藏状态栏和导航栏
  /// 提供更沉浸式的用户体验，适合学习类应用
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  /// 运行Flutter应用
  ///
  /// runApp函数是Flutter应用的启动点，它将根组件渲染到屏幕上
  runApp(
    /// 使用ChangeNotifierProvider包装根组件
    ///
    /// Provider是Flutter中常用的状态管理库
    /// ChangeNotifierProvider用于在组件树中共享可变化的状态
    ChangeNotifierProvider(
      /// 创建ThemeProvider实例
      ///
      /// create参数接收一个函数，该函数返回要共享的状态对象
      /// 这里创建了一个ThemeProvider实例，用于管理应用主题
      create: (_) => ThemeProvider(),

      /// 根组件为WordApp
      ///
      /// WordApp是应用的核心组件，包含应用的主题和路由配置
      child: WordApp(),
    ),
  );
}

/// 微单词应用的主组件
///
/// 继承自StatelessWidget，表示该组件是无状态的
/// 负责配置应用的主题、路由和初始页面
class WordApp extends StatelessWidget {
  /// 构建组件UI
  ///
  /// BuildContext参数包含了组件在组件树中的位置信息
  /// 该方法返回一个Widget，用于描述当前组件的UI
  @override
  Widget build(BuildContext context) {
    /// 从Provider中获取ThemeProvider实例
    ///
    /// Provider.of<T>(context)用于访问祖先组件提供的状态
    /// 这里获取ThemeProvider实例，用于访问和响应主题状态变化
    final themeProvider = Provider.of<ThemeProvider>(context);

    /// 如果主题正在加载，显示加载指示器
    ///
    /// ThemeProvider在初始化时会加载保存的主题设置
    /// 在加载过程中，显示一个简单的加载界面
    if (themeProvider.isLoading) {
      return Container(
        color: Colors.white, // 背景色设为白色
        child: Center(
          /// 显示蓝色的圆形加载指示器
          ///
          /// CircularProgressIndicator是Flutter内置的加载动画组件
          child: CircularProgressIndicator(color: Colors.blue),
        ),
      );
    }

    /// MaterialApp是Flutter应用的核心组件
    ///
    /// 它提供了应用级别的配置，包括：
    /// - 主题配置（浅色/深色主题）
    /// - 路由配置
    /// - 应用标题
    /// - 初始页面
    return MaterialApp(
      /// 应用标题
      ///
      /// 该标题会显示在设备的任务管理器中
      title: '微单词',

      /// 浅色主题配置
      ///
      /// ThemeData定义了应用的视觉风格，包括颜色、字体等
      theme: ThemeData(
        primarySwatch: Colors.blue, // 主色调为蓝色
        visualDensity: VisualDensity.adaptivePlatformDensity, // 自适应不同平台的视觉密度
        brightness: Brightness.light, // 亮度为浅色
        /// 应用栏主题配置
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue, // 应用栏背景色为蓝色
          elevation: 10, // 应用栏阴影高度
          centerTitle: true, // 标题居中显示
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20), // 应用栏底部圆角
            ),
          ),
          shadowColor: Colors.transparent, // 应用栏阴影颜色
        ),
        scaffoldBackgroundColor: Colors.white, // 主页面背景色为白色
      ),

      /// 深色主题配置
      ///
      /// 与浅色主题类似，但使用深色配色方案
      /// 适合在光线较暗的环境下使用
      darkTheme: ThemeData(
        primarySwatch: Colors.blue, // 主色调仍为蓝色
        visualDensity: VisualDensity.adaptivePlatformDensity, // 自适应视觉密度
        brightness: Brightness.dark, // 亮度为深色
        /// 深色主题下的应用栏配置
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade900, // 应用栏背景色为深蓝色
          elevation: 10, // 阴影高度
          centerTitle: true, // 标题居中
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20), // 底部圆角
            ),
          ),
          shadowColor: Colors.transparent, // 阴影颜色
        ),
        scaffoldBackgroundColor: Colors.grey.shade900, // 主页面背景色为深灰色
      ),

      /// 主题模式
      ///
      /// 由ThemeProvider控制，决定使用浅色还是深色主题
      /// 可选值：ThemeMode.light（浅色）、ThemeMode.dark（深色）、ThemeMode.system（跟随系统）
      themeMode: themeProvider.themeMode,

      /// 应用启动后显示的第一个页面
      ///
      /// 这里设置为SplashPage，应用启动时会先显示启动页
      /// 启动页通常用于展示应用Logo或加载必要资源
      home: SplashPage(),

      /// 定义命名路由
      ///
      /// 路由表用于管理页面导航，通过路由名称可以跳转到对应的页面
      /// 键是路由名称，值是一个函数，返回对应的页面组件
      routes: {
        '/home': (context) => HomePage(), // 主页面路由
        '/study': (context) => StudyPage(), // 学习页面路由
        '/review': (context) => ReviewPage(), // 复习页面路由
        '/test': (context) => TestPage(), // 测试页面路由
        '/wordbook': (context) => WordBookPage(), // 单词本页面路由
        '/settings': (context) => SettingsPage(), // 设置页面路由
      },
    );
  }
}
