import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // 图表库，用于显示学习数据图表
import 'package:provider/provider.dart'; // 状态管理库，用于主题切换
import '../models/study_progress.dart'; // 学习进度模型
import '../models/settings.dart'; // 用户设置模型
import '../models/word_storage.dart'; // 单词存储服务
import '../providers/theme_provider.dart'; // 主题状态管理

/// 设置页面
///
/// 包含以下功能模块：
/// - 学习目标设置（每天学习单词数）
/// - 界面设置（主题模式）
/// - 学习设置（自动播放发音、默认显示例句）
/// - 学习统计数据
/// - 学习数据分析（饼图和柱状图）
class SettingsPage extends StatefulWidget {
  /// 设置保存成功回调函数
  final Function? onSettingsSaved;

  /// 创建页面状态对象
  const SettingsPage({Key? key, this.onSettingsSaved}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

/// SettingsPage 的状态管理类
class _SettingsPageState extends State<SettingsPage> {
  /// 学习进度对象，用于存储和显示学习数据
  late StudyProgress _progress;

  /// 用户设置对象
  late Settings _settings;

  /// 每天学习目标单词数
  int _dailyGoal = 20;

  /// 每天复习目标单词数
  int _dailyReviewGoal = 50;

  /// 主题模式（浅色、深色或跟随系统）
  late ThemeMode _themeMode;

  /// 是否自动播放单词发音
  bool _autoPlayPronunciation = true;

  /// 是否默认显示例句
  bool _showExampleByDefault = false;

  /// 当前发音类型
  PronunciationType _pronunciationType = PronunciationType.american;

  /// 学习分组大小
  int _studyGroupSize = 5;

  /// 复习分组大小
  int _reviewGroupSize = 20;

  /// 排序选项
  SortOption _sortOption = SortOption.word;

  /// 数据加载状态
  bool _isLoading = true;

  /// 页面初始化时调用
  @override
  void initState() {
    super.initState();
    // 初始化数据：加载学习进度和设置
    _loadData();
  }

  /// 当依赖的Provider发生变化时调用
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 从Provider获取当前主题模式
    final themeProvider = Provider.of<ThemeProvider>(context);
    setState(() {
      _themeMode = themeProvider.themeMode;
    });
  }

  /// 加载设置数据
  ///
  /// 从本地存储加载学习进度和设置信息
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true; // 开始加载，显示加载指示器
    });

    // 加载学习进度数据
    _progress = await StudyProgress.load();
    _dailyGoal = _progress.dailyGoal; // 设置每天学习目标
    _dailyReviewGoal = _progress.dailyReviewGoal; // 设置每天复习目标

    // 加载用户设置
    _settings = await Settings.load();
    _autoPlayPronunciation = _settings.autoPlayPronunciation;
    _showExampleByDefault = _settings.showExampleByDefault;
    _pronunciationType = _settings.pronunciationType;
    _studyGroupSize = _settings.studyGroupSize;
    _reviewGroupSize = _settings.reviewGroupSize;
    _sortOption = _settings.sortOption;

    setState(() {
      _isLoading = false; // 加载完成，隐藏加载指示器
    });
  }

  /// 更新每天学习目标
  ///
  /// 参数：
  /// - value: 新的每天学习目标单词数
  void _updateDailyGoal(double value) {
    setState(() {
      _dailyGoal = value.toInt(); // 更新目标值
    });
  }

  /// 更新每天复习目标
  ///
  /// 参数：
  /// - value: 新的每天复习目标单词数
  void _updateDailyReviewGoal(double value) {
    setState(() {
      _dailyReviewGoal = value.toInt(); // 更新目标值
    });
  }

  /// 保存设置
  ///
  /// 将当前设置保存到本地存储
  void _saveSettings() {
    _progress.dailyGoal = _dailyGoal; // 更新学习进度中的每日学习目标
    _progress.dailyReviewGoal = _dailyReviewGoal; // 更新学习进度中的每日复习目标
    _progress.save(); // 保存学习进度

    // 更新分组策略设置
    _settings.studyGroupSize = _studyGroupSize;
    _settings.reviewGroupSize = _reviewGroupSize;
    _settings.save(); // 保存用户设置

    // 通知主页更新数据
    if (widget.onSettingsSaved != null) {
      widget.onSettingsSaved!();
    }

    // 显示保存成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('设置已保存'), duration: Duration(seconds: 2)),
    );
  }

  /// 重置为默认单词
  ///
  /// 将当前单词数据重置为50个默认单词
  void _resetToDefaultWords() async {
    // 显示确认对话框
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('确认重置'),
          content: Text('确定要将所有单词数据重置为50个默认单词吗？此操作不可撤销！'),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // 关闭对话框
              },
            ),
            TextButton(
              child: Text('重置'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red, // 重置按钮文字颜色
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // 关闭对话框

                try {
                  // 保存当前上下文用于异步操作
                  final scaffoldContext = ScaffoldMessenger.of(context).context;

                  // 调用WordStorage的重置方法
                  await WordStorage.resetToDefaultWords();

                  // 显示重置成功提示
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(
                      content: Text('已成功重置为50个默认单词'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  // 保存当前上下文用于异步操作
                  final scaffoldContext = ScaffoldMessenger.of(context).context;

                  // 显示重置失败提示
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(
                      content: Text('重置失败：$e'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// 切换主题模式
  ///
  /// 参数：
  /// - mode: 新的主题模式
  void _toggleThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode; // 更新本地状态
    });

    // 调用Provider更新全局主题
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.updateTheme(mode);
  }

  /// 切换自动播放发音设置
  ///
  /// 参数：
  /// - value: 是否自动播放发音
  void _toggleAutoPlayPronunciation(bool value) {
    setState(() {
      _autoPlayPronunciation = value;
      _settings.autoPlayPronunciation = value;
    });
  }

  /// 切换默认显示例句设置
  ///
  /// 参数：
  /// - value: 是否默认显示例句
  void _toggleShowExampleByDefault(bool value) {
    setState(() {
      _showExampleByDefault = value;
      _settings.showExampleByDefault = value;
    });
  }

  /// 切换发音类型
  ///
  /// 参数：
  /// - type: 要切换到的发音类型
  void _togglePronunciationType(PronunciationType type) {
    setState(() {
      _pronunciationType = type;
      _settings.pronunciationType = type;
    });
  }

  /// 切换排序选项
  ///
  /// 参数：
  /// - option: 要切换到的排序选项
  void _toggleSortOption(SortOption option) {
    setState(() {
      _sortOption = option;
      _settings.sortOption = option;
    });
  }

  /// 构建页面UI
  @override
  Widget build(BuildContext context) {
    // 加载状态下显示加载指示器
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    // 构建完整的设置页面
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(20.0), // 页面内边距
        child: ListView(
          // 可滚动列表，用于容纳所有设置项
          children: [
            // 学习目标设置
            _buildSettingSection('学习目标', [
              // 每天学习单词数设置
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                title: Text(
                  '每天学习单词数',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                subtitle: Text(
                  '$_dailyGoal个单词/天', // 显示当前目标值
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              // 滑动条，用于调整每天学习单词数
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Slider(
                  value: _dailyGoal.toDouble(), // 当前值
                  min: 5, // 最小值
                  max: 100, // 最大值
                  divisions: 19, // 刻度数
                  label: '$_dailyGoal', // 滑动时显示的标签
                  onChanged: _updateDailyGoal, // 滑动时的回调函数
                  activeColor: Colors.blue, // 已选择部分颜色
                  inactiveColor: Colors.grey.shade300, // 未选择部分颜色
                  thumbColor: Colors.blue, // 滑块颜色
                ),
              ),
              SizedBox(height: 10),
              // 每天复习单词数设置
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                title: Text(
                  '每天复习单词数',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                subtitle: Text(
                  '$_dailyReviewGoal个单词/天', // 显示当前目标值
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              // 滑动条，用于调整每天复习单词数
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Slider(
                  value: _dailyReviewGoal.toDouble(), // 当前值
                  min: 5, // 最小值
                  max: 200, // 最大值
                  divisions: 39, // 刻度数
                  label: '$_dailyReviewGoal', // 滑动时显示的标签
                  onChanged: _updateDailyReviewGoal, // 滑动时的回调函数
                  activeColor: Colors.green, // 已选择部分颜色
                  inactiveColor: Colors.grey.shade300, // 未选择部分颜色
                  thumbColor: Colors.green, // 滑块颜色
                ),
              ),
            ]),

            SizedBox(height: 25), // 垂直间距
            // 界面设置
            _buildSettingSection('界面设置', [
              // 主题模式设置
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                title: Text(
                  '主题模式',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                trailing: Container(
                  // 下拉选择框容器
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButton<ThemeMode>(
                    value: _themeMode, // 当前选中的主题模式
                    onChanged: (mode) => _toggleThemeMode(mode!), // 选择变化时的回调
                    items: ThemeMode.values.map((mode) {
                      // 主题模式选项
                      return DropdownMenuItem(
                        value: mode,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            _getThemeModeText(mode), // 显示主题模式文本
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    underline: SizedBox(), // 移除下拉框下划线
                    icon: Icon(
                      // 下拉箭头
                      Icons.arrow_drop_down,
                      color: Colors.blue.shade700,
                    ),
                    dropdownColor: // 下拉菜单背景色
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.white,
                    menuMaxHeight: 200, // 下拉菜单最大高度
                    style: TextStyle(
                      // 下拉菜单项样式
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    borderRadius: BorderRadius.circular(15), // 下拉菜单圆角
                  ),
                ),
              ),
            ]),

            SizedBox(height: 25), // 垂直间距
            // 学习设置
            _buildSettingSection('学习设置', [
              // 自动播放发音开关
              SwitchListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                title: Text(
                  '自动播放发音',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                value: _autoPlayPronunciation, // 当前开关状态
                onChanged: _toggleAutoPlayPronunciation, // 开关变化时的回调
                activeThumbColor: Colors.blue, // 开关激活时的滑块颜色
                inactiveThumbColor: Colors.grey.shade400, // 开关未激活时的滑块颜色
              ),

              // 默认显示例句开关
              SwitchListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                title: Text(
                  '默认显示例句',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                value: _showExampleByDefault, // 当前开关状态
                onChanged: _toggleShowExampleByDefault, // 开关变化时的回调
                activeThumbColor: Colors.blue, // 开关激活时的滑块颜色
                inactiveThumbColor: Colors.grey.shade400, // 开关未激活时的滑块颜色
              ),

              // 发音类型选择
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                title: Text(
                  '发音类型',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                trailing: Container(
                  // 下拉选择框容器
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButton<PronunciationType>(
                    value: _pronunciationType, // 当前选中的发音类型
                    onChanged: (type) =>
                        _togglePronunciationType(type!), // 选择变化时的回调
                    items: PronunciationType.values.map((type) {
                      // 发音类型选项
                      return DropdownMenuItem(
                        value: type,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            _getPronunciationTypeText(type), // 显示发音类型文本
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color, // 字体颜色
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    underline: SizedBox(), // 移除下拉框下划线
                    icon: Icon(
                      // 下拉箭头
                      Icons.arrow_drop_down,
                      color: Colors.blue.shade700,
                    ),
                    dropdownColor: // 下拉菜单背景色
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.white,
                    menuMaxHeight: 200, // 下拉菜单最大高度
                    style: TextStyle(
                      // 下拉菜单项样式
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    borderRadius: BorderRadius.circular(15), // 下拉菜单圆角
                  ),
                ),
              ),

              SizedBox(height: 10),

              // 排序选项选择
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                title: Text(
                  '单词排序方式',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                trailing: Container(
                  // 下拉选择框容器
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButton<SortOption>(
                    value: _sortOption, // 当前选中的排序选项
                    onChanged: (option) =>
                        _toggleSortOption(option!), // 选择变化时的回调
                    items: SortOption.values.map((option) {
                      // 排序选项
                      return DropdownMenuItem(
                        value: option,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            _getSortOptionText(option), // 显示排序选项文本
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color, // 字体颜色
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    underline: SizedBox(), // 移除下拉框下划线
                    icon: Icon(
                      // 下拉箭头
                      Icons.arrow_drop_down,
                      color: Colors.blue.shade700,
                    ),
                    dropdownColor: // 下拉菜单背景色
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.white,
                    menuMaxHeight: 200, // 下拉菜单最大高度
                    style: TextStyle(
                      // 下拉菜单项样式
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    borderRadius: BorderRadius.circular(15), // 下拉菜单圆角
                  ),
                ),
              ),

              SizedBox(height: 10),

              // 分组策略设置
              _buildSettingSection('分组策略', [
                // 学习分组大小设置
                ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  title: Text(
                    '学习分组大小',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    '$_studyGroupSize个单词/组', // 显示当前学习分组大小
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                // 数字输入框，用于调整学习分组大小
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: TextEditingController(text: '$_studyGroupSize'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      int? size = int.tryParse(value);
                      if (size != null && size >= 1 && size <= 50) {
                        setState(() {
                          _studyGroupSize = size;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: '每组单词数',
                      hintText: '1-50',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // 复习分组大小设置
                ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  title: Text(
                    '复习分组大小',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    '$_reviewGroupSize个单词/组', // 显示当前复习分组大小
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                // 数字输入框，用于调整复习分组大小
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: TextEditingController(
                      text: '$_reviewGroupSize',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      int? size = int.tryParse(value);
                      if (size != null && size >= 1 && size <= 50) {
                        setState(() {
                          _reviewGroupSize = size;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: '每组单词数',
                      hintText: '1-50',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                ),
                // 添加垂直间距，确保输入框与组件底部之间有足够的留白空间
                SizedBox(height: 20),
              ]),
            ]),

            SizedBox(height: 25), // 垂直间距
            // 学习统计
            _buildSettingSection('学习统计', [
              _buildStatisticItem('总学习单词数', '${_progress.totalWordsStudied}'),
              _buildStatisticItem('已掌握单词数', '${_progress.masteredWords}'),
              _buildStatisticItem('连续学习天数', '${_progress.consecutiveDays}'),
              _buildStatisticItem(
                '总学习时长',
                '${_formatStudyTime(_progress.totalStudyTime)}',
              ),
              _buildStatisticItem(
                '今日学习单词数',
                '${_progress.todayWordsStudied}/${_progress.dailyGoal}',
              ),
              _buildStatisticItem(
                '今日学习时长',
                '${_formatStudyTime(_progress.todayStudyTime)}',
              ),
            ]),

            SizedBox(height: 25), // 垂直间距
            // 学习数据分析
            _buildSettingSection('学习数据分析', [
              // 学习进度饼图
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      '学习进度',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        // 饼图组件，用于显示已掌握和学习中单词的比例
                        PieChartData(
                          sections: [
                            // 饼图的各个部分
                            PieChartSectionData(
                              color: Colors.blue, // 已掌握部分颜色
                              value: _progress.masteredWords
                                  .toDouble(), // 已掌握单词数
                              title: '已掌握', // 部分标题
                              radius: 60, // 部分半径
                              titleStyle: TextStyle(
                                // 标题样式
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              color: Colors.grey.shade300, // 学习中部分颜色
                              value: // 学习中单词数
                                  (_progress.totalWordsStudied -
                                          _progress.masteredWords)
                                      .toDouble(),
                              title: '学习中', // 部分标题
                              radius: 60, // 部分半径
                              titleStyle: TextStyle(
                                // 标题样式
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                          sectionsSpace: 2, // 各部分之间的间距
                          centerSpaceRadius: 80, // 中心空白区域半径
                          pieTouchData: PieTouchData(enabled: true), // 启用触摸交互
                          borderData: FlBorderData(show: false), // 不显示边框
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20), // 垂直间距
              // 今日学习数据 - 3个小卡片设计
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      '今日学习数据',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 15),
                    // 卡片容器：使用Row实现水平布局，确保卡片在同一行
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 卡片1：今日已学习单词数
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 7.5),
                            child: _buildDataCard(
                              context: context,
                              title: '今日已学',
                              value: '${_progress.todayWordsStudied}',
                              unit: '个单词',
                              color: Colors.blue,
                              icon: Icons.book,
                            ),
                          ),
                        ),
                        // 卡片2：今日目标单词数
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 7.5),
                            child: _buildDataCard(
                              context: context,
                              title: '今日目标',
                              value: '${_progress.dailyGoal}',
                              unit: '个单词',
                              color: Colors.green,
                              icon: Icons.flag,
                            ),
                          ),
                        ),
                        // 卡片3：目标达成率
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 7.5),
                            child: _buildDataCard(
                              context: context,
                              title: '达成率',
                              value:
                                  '${((_progress.todayWordsStudied / (_progress.dailyGoal > 0 ? _progress.dailyGoal : 1)) * 100).toInt()}',
                              unit: '%',
                              color: Colors.orange,
                              icon: Icons.trending_up,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]),

            SizedBox(height: 40), // 垂直间距
            // 重置为默认单词按钮
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 300), // 按钮最大宽度
              child: GestureDetector(
                onTap: _resetToDefaultWords, // 点击重置为默认单词
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300), // 动画持续时间
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 20), // 按钮内边距
                  decoration: BoxDecoration(
                    color: Colors.red, // 按钮背景色
                    borderRadius: BorderRadius.circular(30), // 按钮圆角
                    boxShadow: [
                      // 按钮阴影
                      BoxShadow(
                        color: Color.fromRGBO(255, 0, 0, 0.3),
                        spreadRadius: 5,
                        blurRadius: 15,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '重置为50个默认单词',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20), // 垂直间距
            // 保存设置按钮
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 300), // 按钮最大宽度
              child: GestureDetector(
                onTap: _saveSettings, // 点击保存设置
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300), // 动画持续时间
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 20), // 按钮内边距
                  decoration: BoxDecoration(
                    color: Colors.blue, // 按钮背景色
                    borderRadius: BorderRadius.circular(30), // 按钮圆角
                    boxShadow: [
                      // 按钮阴影
                      BoxShadow(
                        color: Color.fromRGBO(0, 122, 255, 0.3),
                        spreadRadius: 5,
                        blurRadius: 15,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '保存设置',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20), // 底部间距
          ],
        ),
      ),
    );
  }

  /// 构建设置分组的辅助方法
  ///
  /// 参数：
  /// - title: 分组标题
  /// - children: 分组内的设置项
  ///
  /// 返回：构建好的设置分组Widget
  Widget _buildSettingSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
      children: [
        Padding(
          padding: EdgeInsets.only(left: 15),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        SizedBox(height: 15), // 标题与内容间距
        Container(
          decoration: BoxDecoration(
            // 卡片背景色：根据主题模式调整
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.white,
            borderRadius: BorderRadius.circular(20), // 卡片圆角
            boxShadow: [
              // 卡片阴影
              BoxShadow(
                color: Color.fromRGBO(128, 128, 128, 0.2),
                spreadRadius: 5,
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(children: children), // 分组内的设置项
        ),
      ],
    );
  }

  /// 构建统计项的辅助方法
  ///
  /// 参数：
  /// - label: 统计项标签
  /// - value: 统计项数值
  ///
  /// 返回：构建好的统计项Widget
  Widget _buildStatisticItem(String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      trailing: Container(
        // 数值显示容器
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          // 背景色：根据主题模式调整
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.blue.shade900.withOpacity(0.3)
              : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(25), // 容器圆角
        ),
        child: Text(
          value, // 统计数值
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            // 文字颜色：根据主题模式调整
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.blue.shade400
                : Colors.blue.shade700,
          ),
        ),
      ),
    );
  }

  /// 获取主题模式的中文文本
  ///
  /// 参数：
  /// - mode: 主题模式枚举值
  ///
  /// 返回：主题模式的中文描述
  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  /// 获取发音类型的中文文本
  ///
  /// 参数：
  /// - type: 发音类型枚举值
  ///
  /// 返回：发音类型的中文描述
  String _getPronunciationTypeText(PronunciationType type) {
    switch (type) {
      case PronunciationType.american:
        return '美式发音';
      case PronunciationType.british:
        return '英式发音';
    }
  }

  ///
  /// 获取排序选项的中文描述
  ///
  /// 参数：
  /// - option: 排序选项枚举值
  ///
  /// 返回：排序选项的中文描述
  String _getSortOptionText(SortOption option) {
    switch (option) {
      case SortOption.word:
        return '按单词排序';
      case SortOption.lastStudyTime:
        return '按学习时间';
      case SortOption.memoryStrength:
        return '按记忆强度';
      case SortOption.shuffle:
        return '乱序学习';
    }
  }

  /// 构建数据卡片
  ///
  /// 创建一个美观的小卡片，用于显示学习数据
  ///
  /// 参数：
  /// - context: 上下文
  /// - title: 卡片标题
  /// - value: 卡片数值
  /// - unit: 数值单位
  /// - color: 卡片主题色
  /// - icon: 卡片图标
  ///
  /// 返回：构建好的数据卡片Widget
  Widget _buildDataCard({
    required BuildContext context,
    required String title,
    required String value,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        // 卡片背景色：根据主题模式调整
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.white,
        borderRadius: BorderRadius.circular(15), // 卡片圆角
        boxShadow: [
          // 卡片阴影
          BoxShadow(
            color: Color.fromRGBO(128, 128, 128, 0.2),
            spreadRadius: 3,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 图标
          Icon(icon, color: color, size: 24),
          SizedBox(height: 10),
          // 标题
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 5),
          // 数值
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          // 单位
          Text(
            unit,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  /// 格式化学习时长
  ///
  /// 将秒数转换为易读的格式：
  /// - 超过1小时：显示小时和分钟
  /// - 超过1分钟：显示分钟和秒
  /// - 否则：显示秒
  ///
  /// 参数：
  /// - seconds: 学习时长（秒）
  ///
  /// 返回：格式化后的学习时长字符串
  String _formatStudyTime(int seconds) {
    final hours = seconds ~/ 3600; // 小时数
    final minutes = (seconds % 3600) ~/ 60; // 分钟数
    final remainingSeconds = seconds % 60; // 剩余秒数

    if (hours > 0) {
      return '${hours}小时${minutes}分钟';
    } else if (minutes > 0) {
      return '${minutes}分钟${remainingSeconds}秒';
    } else {
      return '${remainingSeconds}秒';
    }
  }
}
