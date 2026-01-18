/// Material Design主题相关组件，提供主题相关的类和方法
import 'package:flutter/material.dart';

/// SharedPreferences库，用于本地存储主题设置
import 'package:shared_preferences/shared_preferences.dart';

/// 主题提供者类
///
/// 功能：
/// - 管理应用的主题状态
/// - 支持浅色、深色和系统主题模式
/// - 持久化保存主题设置到本地
/// - 当主题变化时通知所有监听的Widget
///
/// 技术说明：
/// - 继承自ChangeNotifier，实现状态通知机制
/// - 使用SharedPreferences进行本地数据存储
/// - 提供主题模式的getter和更新方法
class ThemeProvider extends ChangeNotifier {
  /// 私有主题模式变量
  ///
  /// 初始值为浅色主题
  ThemeMode _themeMode = ThemeMode.light;

  /// 私有加载状态变量
  ///
  /// - true：正在加载主题设置
  /// - false：主题设置已加载完成
  /// 初始值为true，因为构造函数会调用_loadTheme方法
  bool _isLoading = true;

  /// 公共getter方法：获取当前主题模式
  ///
  /// 允许外部Widget访问当前主题模式
  /// 返回值：ThemeMode枚举值（light、dark、system）
  ThemeMode get themeMode => _themeMode;

  /// 公共getter方法：获取加载状态
  ///
  /// 允许外部Widget判断主题是否正在加载
  /// 返回值：bool类型，true表示正在加载，false表示加载完成
  bool get isLoading => _isLoading;

  /// 构造函数
  ///
  /// 在创建ThemeProvider实例时自动调用_loadTheme方法加载主题
  /// 确保应用启动时能恢复上次保存的主题设置
  ThemeProvider() {
    _loadTheme();
  }

  /// 私有方法：从本地存储加载主题设置
  ///
  /// 功能：
  /// - 从SharedPreferences中读取保存的主题设置
  /// - 解析主题模式字符串为ThemeMode枚举值
  /// - 处理加载失败的情况
  /// - 通知监听者主题已加载完成
  ///
  /// 返回值：
  /// - Future<void>：异步操作，无返回值
  Future<void> _loadTheme() async {
    try {
      /// 获取SharedPreferences实例
      ///
      /// SharedPreferences是Flutter中常用的本地存储解决方案
      /// 用于保存简单的键值对数据
      final prefs = await SharedPreferences.getInstance();

      /// 从本地存储获取主题模式字符串
      ///
      /// 键名：'themeMode'，默认值为'light'
      /// 如果本地没有保存过主题设置，使用默认值
      final themeModeStr = prefs.getString('themeMode') ?? 'light';

      /// 将字符串转换为ThemeMode枚举值
      _themeMode = _getThemeModeFromString(themeModeStr);
    } catch (e) {
      /// 如果加载失败，默认使用浅色主题
      ///
      /// 可能的失败原因：SharedPreferences初始化失败、数据格式错误等
      _themeMode = ThemeMode.light;
    } finally {
      /// 无论成功与否，都将加载状态设为false
      _isLoading = false;

      /// 通知所有监听该状态的Widget
      ///
      /// notifyListeners()会触发所有监听该ChangeNotifier的Widget重新构建
      /// 这是ChangeNotifier的核心方法，实现了状态变化的通知机制
      notifyListeners();
    }
  }

  /// 私有方法：将主题设置保存到本地存储
  ///
  /// 功能：
  /// - 将ThemeMode枚举值转换为字符串
  /// - 使用SharedPreferences保存主题设置
  /// - 处理保存失败的情况
  ///
  /// 参数：
  /// - themeMode：要保存的主题模式
  ///
  /// 返回值：
  /// - Future<void>：异步操作，无返回值
  Future<void> _saveTheme(ThemeMode themeMode) async {
    try {
      /// 获取SharedPreferences实例
      final prefs = await SharedPreferences.getInstance();

      /// 将ThemeMode枚举值转换为字符串，并保存到本地存储
      await prefs.setString('themeMode', _getThemeModeString(themeMode));
    } catch (e) {
      /// 如果保存失败，打印错误信息
      ///
      /// 在实际应用中，可能需要更完善的错误处理
      print('保存主题设置失败: $e');
    }
  }

  /// 公共方法：更新主题模式
  ///
  /// 功能：
  /// - 更新内部主题模式变量
  /// - 将新的主题模式保存到本地存储
  /// - 通知所有监听的Widget主题已更新
  ///
  /// 参数：
  /// - themeMode：新的主题模式
  void updateTheme(ThemeMode themeMode) {
    /// 更新内部主题模式变量
    _themeMode = themeMode;

    /// 将新的主题模式保存到本地存储
    _saveTheme(themeMode);

    /// 通知所有监听该状态的Widget，主题已更新
    notifyListeners();
  }

  /// 私有方法：将字符串转换为ThemeMode枚举值
  ///
  /// 参数：
  /// - mode：主题模式字符串（'light'、'dark'、'system'）
  ///
  /// 返回值：
  /// - ThemeMode枚举值
  ThemeMode _getThemeModeFromString(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light; // 浅色主题
      case 'dark':
        return ThemeMode.dark; // 深色主题
      case 'system':
        return ThemeMode.system; // 跟随系统主题
      default:
        return ThemeMode.light; // 默认浅色主题
    }
  }

  /// 私有方法：将ThemeMode枚举值转换为字符串
  ///
  /// 参数：
  /// - mode：ThemeMode枚举值
  ///
  /// 返回值：
  /// - 主题模式字符串（'light'、'dark'、'system'）
  String _getThemeModeString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light'; // 浅色主题对应的字符串
      case ThemeMode.dark:
        return 'dark'; // 深色主题对应的字符串
      case ThemeMode.system:
        return 'system'; // 系统主题对应的字符串
      default:
        return 'light'; // 默认返回浅色主题字符串
    }
  }
}

/// 主题提供者的InheritedWidget实现
///
/// 功能：
/// - 在Widget树中高效共享ThemeProvider实例
/// - 提供便捷的方法访问主题状态
/// - 优化Widget树的重建性能
///
/// 技术说明：
/// - 继承自InheritedWidget，实现跨Widget树的数据共享
/// - 提供静态of方法，方便Widget访问主题状态
/// - 实现updateShouldNotify方法，优化重建性能
class ThemeProviderWidget extends InheritedWidget {
  /// 保存ThemeProvider实例的引用
  final ThemeProvider provider;

  /// 构造函数
  ///
  /// 参数：
  /// - provider：ThemeProvider实例
  /// - child：子Widget
  const ThemeProviderWidget({
    Key? key,
    required this.provider,
    required Widget child,
  }) : super(key: key, child: child);

  /// 静态方法：从BuildContext中获取ThemeProvider实例
  ///
  /// 功能：
  /// - 提供便捷的方式访问主题状态
  /// - 允许Widget树中的任何Widget获取ThemeProvider实例
  ///
  /// 参数：
  /// - context：BuildContext，用于查找Widget树
  ///
  /// 返回值：
  /// - ThemeProvider实例，如果找不到则返回null
  static ThemeProvider? of(BuildContext context) {
    /// 从BuildContext中查找最近的ThemeProviderWidget
    ///
    /// dependOnInheritedWidgetOfExactType方法会：
    /// 1. 查找指定类型的最近的InheritedWidget
    /// 2. 建立依赖关系，当InheritedWidget更新时，当前Widget会重新构建
    final widget = context
        .dependOnInheritedWidgetOfExactType<ThemeProviderWidget>();

    /// 返回ThemeProvider实例，如果找不到则返回null
    return widget?.provider;
  }

  /// 重写方法：决定是否通知子Widget更新
  ///
  /// 功能：
  /// - 当ThemeProviderWidget更新时，判断是否需要通知所有依赖它的子Widget
  /// - 优化性能，避免不必要的Widget重建
  ///
  /// 参数：
  /// - oldWidget：旧的ThemeProviderWidget实例
  ///
  /// 返回值：
  /// - bool类型，true表示需要通知子Widget，false表示不需要
  @override
  bool updateShouldNotify(ThemeProviderWidget oldWidget) {
    /// 如果旧的ThemeProvider和新的ThemeProvider的主题模式不同，返回true
    /// 否则返回false，避免不必要的Widget重建
    return oldWidget.provider.themeMode != provider.themeMode;
  }
}
