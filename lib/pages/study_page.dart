import 'dart:async'; // 计时器相关库
import 'package:flutter/material.dart'; // Flutter UI组件库
import '../models/word.dart'; // 单词数据模型
import '../models/word_storage.dart'; // 单词存储服务
import '../models/study_progress.dart'; // 学习进度模型
import '../models/settings.dart'; // 用户设置模型
import '../services/audio_service.dart'; // 音频播放服务

/// 学习页面
///
/// 功能：
/// - 显示单词卡片，包含单词、音标、释义和例句
/// - 支持播放单词发音
/// - 可点击显示/隐藏释义和例句
/// - 支持选择学习状态（不认识、模糊、认识）
/// - 自动记录学习进度
/// - 支持循环学习所有单词
class StudyPage extends StatefulWidget {
  /// 创建页面状态对象
  @override
  _StudyPageState createState() => _StudyPageState();
}

/// StudyPage 的状态管理类
class _StudyPageState extends State<StudyPage> {
  /// 所有待学习的单词列表
  late List<Word> _words;

  /// 当前正在学习的单词索引
  int _currentIndex = 0;

  /// 是否显示单词释义
  bool _showMeaning = false;

  /// 是否显示单词例句
  bool _showExample = false;

  /// 学习进度对象，用于记录和更新学习数据
  late StudyProgress _progress;

  /// 用户设置对象
  late Settings _settings;

  /// 当前选择的学习状态
  StudyStatus _selectedStatus = StudyStatus.learning;

  /// 数据加载状态
  bool _isLoading = true;

  /// 学习时长计时器
  Timer? _studyTimer;

  /// 当前学习会话开始时间
  DateTime? _sessionStartTime;

  /// 本次会话累计学习时长（秒）
  int _sessionStudyTime = 0;

  /// 页面初始化时调用
  @override
  void initState() {
    super.initState();
    // 加载单词数据和学习进度
    _loadData();
  }

  /// 当页面可见时调用
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 启动学习时长计时
    _startStudyTimer();
  }

  /// 启动学习时长计时器
  void _startStudyTimer() {
    if (_studyTimer == null || !_studyTimer!.isActive) {
      _sessionStartTime = DateTime.now();
      _sessionStudyTime = 0;

      // 每秒更新一次学习时长（不触发UI刷新）
      _studyTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        _sessionStudyTime = DateTime.now()
            .difference(_sessionStartTime!)
            .inSeconds;
      });
    }
  }

  /// 停止学习时长计时器并保存学习时长
  void _stopStudyTimer() {
    if (_studyTimer != null) {
      _studyTimer!.cancel();
      _studyTimer = null;

      // 如果学习了至少1秒，保存学习时长
      if (_sessionStudyTime > 0) {
        _progress.updateStudyTime(_sessionStudyTime);
        _sessionStudyTime = 0;
      }
    }
  }

  /// 页面销毁时调用
  @override
  void dispose() {
    // 停止计时器并保存学习时长
    _stopStudyTimer();
    super.dispose();
  }

  /// 加载单词数据和学习进度
  ///
  /// 从本地存储加载单词列表、学习进度和用户设置
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true; // 开始加载，显示加载指示器
    });

    // 从本地存储加载单词列表
    _words = await WordStorage.loadWords();
    // 从本地存储加载学习进度
    _progress = await StudyProgress.load();
    // 从本地存储加载用户设置
    _settings = await Settings.load();

    // 根据用户设置更新显示状态
    setState(() {
      _showExample = _settings.showExampleByDefault;
      _isLoading = false; // 加载完成，隐藏加载指示器
    });

    // 加载完成后根据设置自动播放当前单词的音频
    if (_words.isNotEmpty && _settings.autoPlayPronunciation) {
      _speakWord(_words[_currentIndex].word);

      // 如果例句默认显示，且例句存在，播放例句发音
      if (_showExample && _words[_currentIndex].example != null) {
        // 延迟一段时间播放例句，避免与单词发音重叠
        Future.delayed(Duration(seconds: 1), () {
          _speakWord(_words[_currentIndex].example!);
        });
      }
    }
  }

  /// 播放单词发音
  ///
  /// 使用AudioService播放指定单词的发音
  /// 参数：
  /// - word: 要播放发音的单词
  Future<void> _speakWord(String word) async {
    await AudioService().speak(word);
  }

  /// 切换显示/隐藏单词释义
  void _toggleMeaning() {
    setState(() {
      _showMeaning = !_showMeaning;
    });
  }

  /// 切换显示/隐藏单词例句
  void _toggleExample() {
    setState(() {
      _showExample = !_showExample;
    });

    // 如果例句已经显示并且自动播放发音设置开启，播放例句发音
    if (_showExample && _settings.autoPlayPronunciation) {
      final currentWord = _words[_currentIndex];
      if (currentWord.example != null) {
        _speakWord(currentWord.example!);
      }
    }
  }

  /// 处理学习状态选择
  ///
  /// 参数：
  /// - status: 选择的学习状态（不认识、模糊、认识）
  void _handleStatusSelect(StudyStatus status) {
    setState(() {
      _selectedStatus = status;
    });
  }

  /// 进入下一个单词的学习
  void _nextWord() {
    // 更新当前单词的学习状态
    _words[_currentIndex].updateStatus(_selectedStatus);

    // 更新学习进度：
    // - 学习单词数+1
    // - 如果标记为已掌握，已掌握单词数+1
    _progress.updateWordsStudied(1, _selectedStatus == StudyStatus.mastered);

    // 保存更新后的单词数据和学习进度到本地存储
    WordStorage.saveWords(_words);
    _progress.save();

    // 重置状态，准备学习下一个单词
    setState(() {
      _showMeaning = false; // 隐藏释义
      _showExample = _settings.showExampleByDefault; // 根据设置决定是否显示例句
      _selectedStatus = StudyStatus.learning; // 默认选择"不认识"状态

      // 移动到下一个单词索引，如果到达末尾则循环到开头
      _currentIndex = (_currentIndex + 1) % _words.length;
    });

    // 切换到下一个单词后根据设置自动播放音频
    if (_settings.autoPlayPronunciation) {
      _speakWord(_words[_currentIndex].word);

      // 如果例句默认显示，且例句存在，播放例句发音
      if (_showExample && _words[_currentIndex].example != null) {
        // 延迟一段时间播放例句，避免与单词发音重叠
        Future.delayed(Duration(seconds: 1), () {
          _speakWord(_words[_currentIndex].example!);
        });
      }
    }
  }

  /// 构建页面UI
  @override
  Widget build(BuildContext context) {
    // 加载状态下显示加载指示器
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.blue));
    }

    // 没有单词可学习时显示提示
    if (_words.isEmpty) {
      return Center(
        child: Text(
          '没有单词可学习，请先添加单词',
          style: TextStyle(
            fontSize: 22,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // 获取当前正在学习的单词
    final currentWord = _words[_currentIndex];

    // 构建学习页面UI
    return Padding(
      padding: const EdgeInsets.all(20.0), // 页面内边距
      child: SingleChildScrollView(
        // 可滚动容器，适应不同屏幕尺寸
        child: Column(
          mainAxisSize: MainAxisSize.min, // 垂直方向最小化
          children: [
            // 总体学习进度条
            Container(
              margin: EdgeInsets.only(bottom: 20),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _words.length, // 进度值（0.0-1.0）
                backgroundColor: Color.fromRGBO(255, 255, 255, 0.5), // 未完成部分颜色
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.blue,
                ), // 已完成部分颜色
                minHeight: 8, // 进度条高度
                borderRadius: BorderRadius.circular(4), // 进度条圆角
              ),
            ),

            // 单词进度文本（如：1/20）
            Container(
              margin: EdgeInsets.only(bottom: 20),
              child: Text(
                '${_currentIndex + 1}/${_words.length}',
                style: TextStyle(
                  fontSize: 20,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),

            // 单词卡片容器
            AnimatedContainer(
              duration: Duration(milliseconds: 300), // 动画持续时间
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25), // 卡片圆角
                // 卡片背景色：根据主题模式调整
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.white,
                boxShadow: [
                  // 卡片阴影
                  BoxShadow(
                    color: Color.fromRGBO(128, 128, 128, 0.3),
                    spreadRadius: 15,
                    blurRadius: 30,
                    offset: Offset(0, 15),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(30.0), // 卡片内边距
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 单词卡片头部（包含单词和音标）
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 25,
                      ),
                      decoration: BoxDecoration(
                        // 背景色：根据主题模式调整
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Color.fromRGBO(0, 51, 102, 0.3)
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(15), // 卡片圆角
                        border: Border.all(
                          // 卡片边框
                          // 边框颜色：根据主题模式调整
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.blue.shade800
                              : Colors.blue.shade200,
                          width: 2, // 边框宽度
                        ),
                      ),
                      child: Column(
                        children: [
                          // 单词和发音按钮
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      _speakWord(currentWord.word), // 点击单词播放发音
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: AlignmentGeometry.center,
                                    child: Text(
                                      currentWord.word, // 单词文本
                                      style: TextStyle(
                                        fontSize: 56, // 单词字体大小
                                        fontWeight: FontWeight.bold, // 单词字体粗细
                                        color: Colors.blue.shade700, // 单词颜色
                                      ),
                                      textAlign: TextAlign.center, // 居中对齐
                                      overflow: TextOverflow.visible, // 允许文本溢出
                                      softWrap: true, // 自动换行
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 15), // 单词与发音按钮间距
                              // 发音按钮
                              _AnimatedPlayButton(
                                onPressed: () => _speakWord(currentWord.word),
                                size: 32,
                              ),
                            ],
                          ),

                          // 音标（如果存在）
                          if (currentWord.phonetic != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                currentWord.phonetic!, // 音标文本
                                style: TextStyle(
                                  fontSize: 24, // 音标字体大小
                                  color: Colors.purple.shade500, // 音标颜色
                                  fontStyle: FontStyle.italic, // 斜体样式
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: 30), // 单词卡片头部与释义间距
                    // 释义区域（可点击显示/隐藏）
                    GestureDetector(
                      onTap: _toggleMeaning, // 点击切换显示/隐藏释义
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20), // 释义区域内边距
                        decoration: BoxDecoration(
                          // 背景色：根据主题模式调整
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Color.fromRGBO(0, 51, 102, 0.3)
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(15), // 圆角
                          border: Border.all(
                            // 边框
                            // 边框颜色：根据主题模式调整
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.blue.shade800
                                : Colors.blue.shade200,
                            width: 2, // 边框宽度
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '释义',
                                  style: TextStyle(
                                    fontSize: 22, // 标题字体大小
                                    fontWeight: FontWeight.bold, // 标题字体粗细
                                    color: Colors.blue.shade700, // 标题颜色
                                  ),
                                ),
                                Icon(
                                  // 箭头图标：根据是否显示释义切换
                                  _showMeaning
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: Colors.blue.shade500, // 图标颜色
                                ),
                              ],
                            ),
                            SizedBox(height: 15), // 标题与内容间距
                            // 只有在_showMeaning为true时显示释义内容
                            if (_showMeaning)
                              Text(
                                currentWord.meaning, // 单词释义
                                style: TextStyle(
                                  fontSize: 26, // 释义字体大小
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color, // 释义颜色
                                ),
                                textAlign: TextAlign.center, // 居中对齐
                              ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 20), // 释义与例句间距
                    // 例句区域（可点击显示/隐藏，仅当例句存在时显示）
                    if (currentWord.example != null)
                      GestureDetector(
                        onTap: _toggleExample, // 点击切换显示/隐藏例句
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20), // 例句区域内边距
                          decoration: BoxDecoration(
                            // 背景色：根据主题模式调整
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Color.fromRGBO(0, 102, 0, 0.3)
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(15), // 圆角
                            border: Border.all(
                              // 边框
                              // 边框颜色：根据主题模式调整
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.green.shade800
                                  : Colors.green.shade200,
                              width: 2, // 边框宽度
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '例句',
                                    style: TextStyle(
                                      fontSize: 22, // 标题字体大小
                                      fontWeight: FontWeight.bold, // 标题字体粗细
                                      color: Colors.green.shade700, // 标题颜色
                                    ),
                                  ),
                                  Icon(
                                    // 箭头图标：根据是否显示例句切换
                                    _showExample
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: Colors.green.shade500, // 图标颜色
                                  ),
                                ],
                              ),
                              SizedBox(height: 15), // 标题与内容间距
                              // 只有在_showExample为true时显示例句内容
                              if (_showExample)
                                Column(
                                  children: [
                                    Text(
                                      currentWord.example!, // 单词例句
                                      style: TextStyle(
                                        fontSize: 20, // 例句字体大小
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color, // 例句颜色
                                        fontStyle: FontStyle.italic, // 斜体样式
                                      ),
                                      textAlign: TextAlign.center, // 居中对齐
                                    ),
                                    SizedBox(height: 10), // 例句与播放按钮间距
                                    // 例句发音按钮
                                    _AnimatedPlayButton(
                                      onPressed: () =>
                                          _speakWord(currentWord.example!),
                                      size: 28,
                                      color: Colors.green,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20), // 单词卡片与状态选择间距
            // 学习状态选择标题
            Container(
              margin: EdgeInsets.only(bottom: 20),
              child: Text(
                '选择学习状态:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),

            // 学习状态选择按钮组
            Wrap(
              spacing: 15, // 水平间距
              runSpacing: 15, // 垂直间距
              alignment: WrapAlignment.center, // 居中对齐
              children: [
                // 不认识按钮
                _statusButton('不认识', Colors.red, StudyStatus.learning),
                // 模糊按钮
                _statusButton('模糊', Colors.orange, StudyStatus.familiar),
                // 认识按钮
                _statusButton('认识', Colors.green, StudyStatus.mastered),
              ],
            ),

            SizedBox(height: 30), // 状态选择与下一个按钮间距
            // 下一个单词按钮
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 300), // 按钮最大宽度
              child: GestureDetector(
                onTap: _nextWord, // 点击进入下一个单词
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300), // 动画持续时间
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 18), // 按钮内边距
                  decoration: BoxDecoration(
                    color: Colors.blue, // 按钮背景色
                    borderRadius: BorderRadius.circular(25), // 按钮圆角
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
                  child: Text(
                    '下一个', // 按钮文本
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22, // 文本字体大小
                      fontWeight: FontWeight.bold, // 文本字体粗细
                      color: Colors.white, // 文本颜色
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

  /// 构建学习状态选择按钮
  ///
  /// 参数：
  /// - text: 按钮显示文本
  /// - color: 按钮选中时的颜色
  /// - status: 按钮对应的学习状态
  ///
  /// 返回：构建好的学习状态按钮Widget
  Widget _statusButton(String text, Color color, StudyStatus status) {
    // 判断当前按钮是否被选中
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () => _handleStatusSelect(status), // 点击选择该学习状态
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300), // 动画持续时间
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15), // 按钮内边距
        constraints: BoxConstraints(minWidth: 100), // 按钮最小宽度
        decoration: BoxDecoration(
          // 按钮背景色：选中时显示主题色，未选中时显示灰色
          color: isSelected ? color : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(15), // 按钮圆角
          boxShadow: [
            // 按钮阴影：选中时阴影更明显
            BoxShadow(
              color: isSelected
                  ? Color.fromRGBO(color.red, color.green, color.blue, 0.3)
                  : Color.fromRGBO(128, 128, 128, 0.2),
              spreadRadius: isSelected ? 4 : 2,
              blurRadius: isSelected ? 12 : 6,
              offset: Offset(0, isSelected ? 8 : 3),
            ),
          ],
          border: Border.all(
            // 按钮边框：选中时显示边框
            color: isSelected
                ? Color.fromRGBO(color.red, color.green, color.blue, 0.8)
                : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
        ),
        child: Text(
          text, // 按钮文本
          style: TextStyle(
            fontSize: 16, // 文本字体大小
            fontWeight: FontWeight.bold, // 文本字体粗细
            color: isSelected
                ? Colors.white
                : Colors.black, // 文本颜色：选中时白色，未选中时黑色
          ),
          textAlign: TextAlign.center, // 文本居中对齐
        ),
      ),
    );
  }
}

/// 动画播放按钮组件
///
/// 功能：
/// - 带有按下动画效果的播放按钮
/// - 支持自定义大小、颜色和提示文本
/// - 点击时调用指定的回调函数
class _AnimatedPlayButton extends StatefulWidget {
  /// 按钮点击时的回调函数
  final VoidCallback onPressed;

  /// 按钮图标大小
  final double size;

  /// 按钮颜色
  final MaterialColor color;

  /// 按钮提示文本
  final String? tooltip;

  const _AnimatedPlayButton({
    required this.onPressed,
    this.size = 32.0,
    this.color = Colors.blue,
    this.tooltip,
  });

  /// 创建按钮状态对象
  @override
  __AnimatedPlayButtonState createState() => __AnimatedPlayButtonState();
}

/// _AnimatedPlayButton 的状态管理类
class __AnimatedPlayButtonState extends State<_AnimatedPlayButton> {
  /// 按钮缩放比例
  double _scale = 1.0;

  /// 按钮是否被按下
  bool _isPressed = false;

  /// 处理按钮按下事件
  ///
  /// 当用户按下按钮时，缩小按钮并改变样式
  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _scale = 0.85; // 缩小到85%
      _isPressed = true;
    });
  }

  /// 处理按钮抬起事件
  ///
  /// 当用户抬起按钮时，恢复按钮大小并执行回调
  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.0; // 恢复原大小
      _isPressed = false;
    });
    widget.onPressed(); // 执行按钮点击回调
  }

  /// 处理按钮取消事件
  ///
  /// 当按钮按下后取消（如手指移出按钮区域），恢复按钮大小
  void _handleTapCancel() {
    setState(() {
      _scale = 1.0; // 恢复原大小
      _isPressed = false;
    });
  }

  /// 构建按钮UI
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip ?? '播放发音', // 提示文本，默认"播放发音"
      child: GestureDetector(
        onTapDown: _handleTapDown, // 按下事件
        onTapUp: _handleTapUp, // 抬起事件
        onTapCancel: _handleTapCancel, // 取消事件
        child: AnimatedContainer(
          duration: Duration(milliseconds: 150), // 动画持续时间
          transform: Matrix4.identity()..scale(_scale), // 应用缩放变换
          transformAlignment: Alignment.center, // 变换中心点
          decoration: BoxDecoration(
            shape: BoxShape.circle, // 圆形背景
            // 背景色：按下时显示浅色，否则透明
            color: _isPressed ? widget.color.shade100 : Colors.transparent,
            boxShadow: [
              // 按下时显示阴影
              if (_isPressed)
                BoxShadow(
                  color: widget.color.shade300,
                  spreadRadius: 2,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
            ],
          ),
          padding: EdgeInsets.all(8), // 图标内边距
          child: AnimatedContainer(
            duration: Duration(milliseconds: 150), // 图标动画持续时间
            child: Icon(
              Icons.volume_up, // 音量图标
              // 图标颜色：按下时深色，否则浅色
              color: _isPressed ? widget.color.shade700 : widget.color.shade500,
              size: widget.size, // 图标大小
            ),
          ),
        ),
      ),
    );
  }
}
