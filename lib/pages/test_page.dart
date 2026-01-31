import 'dart:async'; // 计时器相关库
import 'dart:io'; // 文件操作库
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Flutter UI组件库
import '../models/word.dart'; // 单词数据模型
import '../models/word_storage.dart'; // 单词存储服务
import '../models/word_list.dart'; // 单词表数据模型
import '../models/word_list_storage.dart'; // 单词表存储服务
import '../models/study_progress.dart'; // 学习进度模型
import '../models/settings.dart'; // 用户设置模型
import '../models/test_record.dart'; // 测试记录模型
import '../models/test_settings.dart'; // 测试设置模型
import '../services/audio_service.dart'; // 音频播放服务
import './test_result_page.dart'; // 测试结果页面
import './test_history_page.dart'; // 测试历史页面

/// 测试页面
///
/// 功能：
/// - 支持两种测试模式：选择题和填空题
/// - 随机生成指定数量的单词进行测试
/// - 支持播放单词发音
/// - 实时统计测试结果
/// - 测试完成后显示详细结果
/// - 测试完成后显示详细结果
/// - 根据测试结果更新单词学习状态
class TestPage extends StatefulWidget {
  /// 测试单词数量
  final int testWordCount;

  /// 选中的单词表
  final WordList? selectedWordList;

  /// 自定义单词表文件路径
  final String? customWordListPath;

  /// 构造函数
  const TestPage({
    Key? key,
    this.testWordCount = 10,
    this.selectedWordList,
    this.customWordListPath,
  }) : super(key: key);

  /// 创建页面状态对象
  @override
  _TestPageState createState() => _TestPageState();
}

/// TestPage 的状态管理类
class _TestPageState extends State<TestPage> with WidgetsBindingObserver {
  /// 当前测试模式
  TestMode _testMode = TestMode.multipleChoice;

  /// 所有单词列表
  late List<Word> _words;

  /// 当前单词表
  late WordList _currentWordList;

  /// 过滤后的单词列表（当前单词表中的单词）
  late List<Word> _filteredWords;

  /// 当前测试的单词列表（随机选择10个）
  late List<Word> _testWords;

  /// 当前测试的单词索引
  int _currentIndex = 0;

  /// 用户选择的答案
  //String? _selectedAnswer;
  ValueNotifier<String?> _selectedAnswer = ValueNotifier<String?>(null);

  /// 存储每个测试题的用户答案
  Map<int, String?> _userAnswers = {};

  /// 填空题输入框控制器
  late TextEditingController _blankFillController;

  /// 测试结果统计
  int _correctCount = 0; // 正确数量
  int _wrongCount = 0; // 错误数量

  /// 是否显示测试结果
  bool _showResult = false;

  /// 数据加载状态
  bool _isLoading = true;

  /// 学习进度对象
  late StudyProgress _progress;

  /// 用户设置对象
  late Settings _settings;

  /// 测试设置对象
  late TestSettings _testSettings;

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
    // 注册应用生命周期观察者
    WidgetsBinding.instance.addObserver(this);
    // 初始化填空题输入框控制器
    _blankFillController = TextEditingController();
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

  /// 监听应用生命周期变化
  ///
  /// 当页面可见性发生变化时，停止或恢复音频播放和学习计时
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 当页面不可见时，停止音频播放和学习计时
    if (state == AppLifecycleState.paused) {
      _stopAudio();
      _stopStudyTimer();
    }
    // 当页面重新可见时，恢复学习计时
    else if (state == AppLifecycleState.resumed) {
      _startStudyTimer();
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

  /// 停止音频播放
  ///
  /// 调用AudioService的stop方法停止当前正在播放的音频
  Future<void> _stopAudio() async {
    await AudioService().stop();
  }

  /// 页面销毁时调用
  @override
  void dispose() {
    // 停止计时器并保存学习时长
    _stopStudyTimer();
    // 移除应用生命周期观察者
    WidgetsBinding.instance.removeObserver(this);
    // 释放填空题输入框控制器
    _blankFillController.dispose();
    super.dispose();
  }

  /// 当widget的参数发生变化时调用
  @override
  void didUpdateWidget(TestPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('TestPage: didUpdateWidget被调用');
    debugPrint(
      'TestPage: 旧参数 - testWordCount: ${oldWidget.testWordCount}, selectedWordList: ${oldWidget.selectedWordList}, customWordListPath: ${oldWidget.customWordListPath}',
    );
    debugPrint(
      'TestPage: 新参数 - testWordCount: ${widget.testWordCount}, selectedWordList: ${widget.selectedWordList}, customWordListPath: ${widget.customWordListPath}',
    );

    // 检查widget的参数是否发生变化
    if (oldWidget.testWordCount != widget.testWordCount ||
        oldWidget.selectedWordList != widget.selectedWordList ||
        oldWidget.customWordListPath != widget.customWordListPath) {
      debugPrint('TestPage: 参数发生变化，重新加载数据');
      // 参数发生变化，重新加载数据
      _loadData();
    }
  }

  /// 加载单词数据和学习进度
  ///
  /// 从本地存储加载单词列表、学习进度和用户设置
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true; // 开始加载，显示加载指示器
    });

    // 并行加载数据
    final wordsFuture = WordStorage.loadWords();
    final progressFuture = StudyProgress.load();
    final settingsFuture = Settings.load();
    final currentWordListFuture = WordListStorage.getCurrentWordList();
    final wordListsFuture = WordListStorage.loadWordLists();

    // 加载测试设置
    final testSettingsFuture = TestSettingsStorage.loadTestSettings();

    final results = await Future.wait([
      wordsFuture,
      progressFuture,
      settingsFuture,
      currentWordListFuture,
      wordListsFuture,
      testSettingsFuture,
    ]);

    _words = results[0] as List<Word>;
    _progress = results[1] as StudyProgress;
    _settings = results[2] as Settings;
    _currentWordList = results[3] as WordList;
    final wordLists = results[4] as List<WordList>;
    _testSettings = results[5] as TestSettings;

    // 根据传入的参数或保存的测试设置加载相应的单词
    if (widget.customWordListPath != null) {
      // 从自定义单词表文件加载单词
      try {
        final file = File(widget.customWordListPath!);
        final content = await file.readAsString();
        final customWords = WordStorage.parseWordsFromJson(content);
        _filteredWords = customWords;
      } catch (e) {
        debugPrint('加载自定义单词表失败: $e');
        // 如果加载失败，使用默认单词表
        _filteredWords = _words
            .where((word) => _currentWordList.wordIds.contains(word.id))
            .toList();
      }
    } else if (widget.selectedWordList != null) {
      // 从选中的单词表加载单词
      _filteredWords = _words
          .where((word) => widget.selectedWordList!.wordIds.contains(word.id))
          .toList();
    } else if (_testSettings.customWordListPath != null) {
      // 从保存的自定义单词表路径加载单词
      try {
        final file = File(_testSettings.customWordListPath!);
        final content = await file.readAsString();
        final customWords = WordStorage.parseWordsFromJson(content);
        _filteredWords = customWords;
      } catch (e) {
        debugPrint('加载保存的自定义单词表失败: $e');
        // 如果加载失败，使用默认单词表
        _filteredWords = _words
            .where((word) => _currentWordList.wordIds.contains(word.id))
            .toList();
      }
    } else if (_testSettings.selectedWordListId != null &&
        wordLists.isNotEmpty) {
      // 从保存的选中单词表加载单词
      final selectedWordList = wordLists.firstWhere(
        (list) => list.id == _testSettings.selectedWordListId,
        orElse: () => _currentWordList,
      );
      _filteredWords = _words
          .where((word) => selectedWordList.wordIds.contains(word.id))
          .toList();
    } else {
      // 从当前单词表加载单词
      _filteredWords = _words
          .where((word) => _currentWordList.wordIds.contains(word.id))
          .toList();
    }

    // 生成测试单词列表
    _generateTestWords();

    setState(() {
      _isLoading = false; // 加载完成，隐藏加载指示器
    });

    // 数据加载完成后，根据设置自动播放当前单词的音频
    if (_testWords.isNotEmpty && _settings.autoPlayPronunciation) {
      _speakWord(_testWords[_currentIndex].word);
    }
  }

  /// 生成测试单词列表
  ///
  /// 从当前单词表中随机选择指定数量的单词作为测试单词
  void _generateTestWords() {
    _testWords = [];
    // 创建过滤后的单词列表的副本，避免修改原始列表
    final availableWords = List.from(_filteredWords);

    // 确定测试单词数量：优先使用传入的参数
    final testCount = widget.testWordCount;

    // 随机选择指定数量的单词，直到选满或没有更多单词
    while (_testWords.length < testCount && availableWords.isNotEmpty) {
      // 使用当前时间的毫秒数作为随机数种子，选择一个随机索引
      final randomIndex =
          DateTime.now().millisecondsSinceEpoch % availableWords.length;
      // 从可用单词列表中移除并获取该单词
      final word = availableWords.removeAt(randomIndex);
      // 添加到测试单词列表
      _testWords.add(word);
    }
  }

  /// 开始新的测试
  ///
  /// 重置测试状态，生成新的测试单词列表
  void _startNewTest() {
    setState(() {
      _currentIndex = 0; // 重置当前测试索引
      _correctCount = 0; // 重置正确计数
      _wrongCount = 0; // 重置错误计数
      _showResult = false; // 隐藏测试结果
      _selectedAnswer.value = null; // 清空选中答案
      _userAnswers = {}; // 清空用户答案映射
      _generateTestWords(); // 生成新的测试单词列表
    });
  }

  /// 处理答案选择
  ///
  /// 当用户选择答案时，更新选中的答案
  /// 参数：
  /// - answer: 用户选择的答案
  void _handleAnswerSelect(String answer) {
    _selectedAnswer.value = answer;
  }

  /// 提交答案
  ///
  /// 检查用户答案是否正确，更新测试结果，并移动到下一个测试题
  void _submitAnswer() async {
    // 如果没有选择答案，直接返回
    if (_selectedAnswer.value == null) return;

    // 获取当前测试的单词
    final currentWord = _testWords[_currentIndex];
    bool isCorrect = false;

    // 根据测试模式检查答案是否正确
    if (_testMode == TestMode.multipleChoice) {
      // 选择题：检查选择的释义是否正确
      isCorrect = _selectedAnswer.value == currentWord.meaning;
    } else if (_testMode == TestMode.blankFill) {
      // 填空题：检查输入的单词是否正确（忽略大小写和前后空格）
      isCorrect =
          _selectedAnswer.value?.trim().toLowerCase() ==
          currentWord.word.toLowerCase();
    }

    // 存储当前测试题的用户答案
    _userAnswers[_currentIndex] = _selectedAnswer.value;

    setState(() {
      if (isCorrect) {
        _correctCount++; // 正确数量加1
        // 回答正确，将单词状态更新为"模糊"（熟悉）
        currentWord.updateStatus(StudyStatus.familiar);
      } else {
        _wrongCount++; // 错误数量加1
        // 回答错误，如果单词状态不是"新单词"，则将其状态更新为"学习中"（不认识）
        if (currentWord.status != StudyStatus.newWord) {
          currentWord.updateStatus(StudyStatus.learning);
        }
      }

      // 检查是否还有下一个测试题
      if (_currentIndex < _testWords.length - 1) {
        // 移动到下一个测试题
        _currentIndex++;
        _selectedAnswer.value = null; // 清空选中答案
        // 如果是填空题，清空输入框内容
        if (_testMode == TestMode.blankFill) {
          _blankFillController.clear();
        }
      } else {
        // 测试完成，生成测试记录
        _generateTestRecord();
      }
    });

    // 如果还有下一个单词，根据设置自动播放音频
    if (_currentIndex < _testWords.length && _settings.autoPlayPronunciation) {
      _speakWord(_testWords[_currentIndex].word);
    }

    // 保存更新后的单词数据到本地存储
    WordStorage.saveWords(_words);

    // 更新学习进度
    bool isMastered = currentWord.status == StudyStatus.mastered;
    _progress.updateWordsStudied(1, isMastered);
  }

  /// 生成测试记录
  void _generateTestRecord() async {
    // 停止学习时长计时器并计算测试时长
    _stopStudyTimer();
    final testDuration = _sessionStudyTime;

    // 计算测试总题数和得分
    final total = _correctCount + _wrongCount;
    final score = total > 0 ? (_correctCount / total * 100).toInt() : 0;

    // 生成题目记录
    final questions = <TestQuestion>[];
    for (int i = 0; i < _testWords.length; i++) {
      final word = _testWords[i];
      final userAnswer = _userAnswers[i]; // 从映射中获取用户答案
      TestQuestion question;
      if (_testMode == TestMode.multipleChoice) {
        // 选择题
        final options = _generateOptions(word.meaning);
        bool isCorrect = userAnswer == word.meaning;
        question = TestQuestion(
          id: '${i}_${DateTime.now().millisecondsSinceEpoch}',
          mode: TestMode.multipleChoice,
          question: word.word,
          userAnswer: userAnswer,
          correctAnswer: word.meaning,
          status: userAnswer != null
              ? (isCorrect ? QuestionStatus.correct : QuestionStatus.wrong)
              : QuestionStatus.unattempted,
          options: options,
        );
      } else {
        // 填空题
        bool isCorrect =
            userAnswer?.trim().toLowerCase() == word.word.toLowerCase();
        question = TestQuestion(
          id: '${i}_${DateTime.now().millisecondsSinceEpoch}',
          mode: TestMode.blankFill,
          question: word.meaning,
          userAnswer: userAnswer,
          correctAnswer: word.word,
          status: userAnswer != null
              ? (isCorrect ? QuestionStatus.correct : QuestionStatus.wrong)
              : QuestionStatus.unattempted,
        );
      }
      questions.add(question);
    }

    // 生成测试记录
    final testRecord = TestRecord(
      testTime: DateTime.now(),
      testDuration: testDuration,
      totalQuestions: total,
      correctQuestions: _correctCount,
      score: score,
      testMode: _testMode,
      testWordCount: _testWords.length,
      testRange: '随机测试',
      questions: questions,
    );

    // 保存测试记录
    await TestRecordStorage.addRecord(testRecord);

    // 跳转到测试结果页面
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TestResultPage(testRecord: testRecord),
      ),
    );
  }

  /// 生成选择题选项
  ///
  /// 为选择题生成4个选项，包含1个正确答案和3个错误答案
  /// 参数：
  /// - correctAnswer: 正确答案
  ///
  /// 返回：包含4个选项的列表，已打乱顺序
  List<String> _generateOptions(String correctAnswer) {
    final options = [correctAnswer]; // 先添加正确答案
    final availableWords = List.from(_filteredWords); // 从当前单词表中选择选项

    // 随机选择3个错误选项
    while (options.length < 4 && availableWords.isNotEmpty) {
      // 使用当前时间的毫秒数作为随机数种子，选择一个随机索引
      final randomIndex =
          DateTime.now().millisecondsSinceEpoch % availableWords.length;
      final word = availableWords.removeAt(randomIndex);

      // 确保错误选项不与正确答案重复，且不重复添加
      if (word.meaning != correctAnswer && !options.contains(word.meaning)) {
        options.add(word.meaning);
      }
    }

    // 如果当前单词表中的单词不够，从所有单词中补充
    if (options.length < 4) {
      final allAvailableWords = List.from(_words);
      while (options.length < 4 && allAvailableWords.isNotEmpty) {
        final randomIndex =
            DateTime.now().millisecondsSinceEpoch % allAvailableWords.length;
        final word = allAvailableWords.removeAt(randomIndex);

        if (word.meaning != correctAnswer && !options.contains(word.meaning)) {
          options.add(word.meaning);
        }
      }
    }

    // 打乱选项顺序
    options.shuffle();
    return options;
  }

  /// 构建页面UI
  @override
  Widget build(BuildContext context) {
    // 加载状态下显示加载指示器
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.blue));
    }

    // 没有单词可测试时显示提示
    if (_words.isEmpty) {
      return Center(
        child: Text(
          '没有单词可测试，请先添加单词',
          style: TextStyle(
            fontSize: 22,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // 当前单词表中没有单词时显示提示
    if (_filteredWords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '当前单词表中没有单词',
              style: TextStyle(
                fontSize: 22,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              '请先添加单词到 "${_currentWordList.name}"',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      );
    }

    // 构建测试页面UI
    return Padding(
      padding: const EdgeInsets.all(20.0), // 页面内边距
      child: SingleChildScrollView(
        // 可滚动容器，适应不同屏幕尺寸
        child: Column(
          mainAxisSize: MainAxisSize.min, // 垂直方向最小化
          children: [
            // 测试模式选择
            Container(
              margin: EdgeInsets.only(bottom: 30),
              child: Wrap(
                spacing: 30, // 水平间距
                runSpacing: 20, // 垂直间距
                alignment: WrapAlignment.center, // 居中对齐
                children: [
                  // 选择题按钮
                  _testModeButton('选择题', TestMode.multipleChoice),
                  // 填空题按钮
                  _testModeButton('填空题', TestMode.blankFill),
                ],
              ),
            ),

            // 根据是否显示结果，切换显示测试屏幕或结果屏幕
            _showResult ? _buildResultScreen() : _buildTestScreen(),
          ],
        ),
      ),
    );
  }

  /// 构建测试模式选择按钮
  ///
  /// 参数：
  /// - text: 按钮显示文本
  /// - mode: 按钮对应的测试模式
  ///
  /// 返回：构建好的测试模式按钮Widget
  Widget _testModeButton(String text, TestMode mode) {
    // 判断当前按钮是否被选中
    final isSelected = _testMode == mode;
    // 判断当前是否为深色模式
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        setState(() {
          _testMode = mode; // 更新测试模式
          _startNewTest(); // 开始新的测试
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300), // 动画持续时间
        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 16), // 按钮内边距
        constraints: BoxConstraints(minWidth: 100), // 按钮最小宽度
        decoration: BoxDecoration(
          // 按钮背景色：选中时显示蓝色，否则根据主题模式调整
          color: isSelected
              ? Colors.blue
              : isDarkMode
              ? Colors.grey.shade800
              : Colors.white,
          borderRadius: BorderRadius.circular(30), // 按钮圆角
          boxShadow: [
            // 按钮阴影
            BoxShadow(
              color: isSelected
                  ? Color.fromRGBO(0, 122, 255, 0.3)
                  : Color.fromRGBO(128, 128, 128, 0.2),
              spreadRadius: isSelected ? 5 : 3,
              blurRadius: isSelected ? 15 : 8,
              offset: Offset(0, isSelected ? 10 : 5),
            ),
          ],
        ),
        child: Text(
          text, // 按钮文本
          style: TextStyle(
            fontSize: 17, // 文本字体大小
            fontWeight: FontWeight.bold, // 文本字体粗细
            color: isSelected ? Colors.white : Colors.blue.shade700, // 文本颜色
          ),
          textAlign: TextAlign.center, // 文本居中对齐
        ),
      ),
    );
  }

  /// 构建测试屏幕
  ///
  /// 显示当前测试题、选项或输入框，以及提交按钮
  Widget _buildTestScreen() {
    // 没有足够的单词进行测试时显示提示
    if (_testWords.isEmpty) {
      return Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(128, 128, 128, 0.2),
                spreadRadius: 3,
                blurRadius: 8,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            '没有足够的单词进行测试',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // 获取当前测试的单词
    final currentWord = _testWords[_currentIndex];
    // 构建测试屏幕UI
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 测试进度
        Container(
          margin: EdgeInsets.only(bottom: 20),
          child: Text(
            '${_currentIndex + 1}/${_testWords.length}', // 显示当前进度（如：1/10）
            style: TextStyle(
              fontSize: 24,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),

        // 单词卡片
        Container(
          margin: EdgeInsets.only(bottom: 30),
          padding: EdgeInsets.all(30), // 卡片内边距
          decoration: BoxDecoration(
            // 卡片背景色：根据主题模式调整
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.white,
            borderRadius: BorderRadius.circular(20), // 卡片圆角
            boxShadow: [
              // 卡片阴影
              BoxShadow(
                color: Color.fromRGBO(128, 128, 128, 0.3),
                spreadRadius: 10,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  // 根据测试模式显示不同内容
                  // 选择题：显示单词
                  // 填空题：显示释义
                  _testMode == TestMode.multipleChoice
                      ? currentWord.word
                      : currentWord.meaning,
                  style: TextStyle(
                    fontSize: 42, // 字体大小
                    fontWeight: FontWeight.bold, // 字体粗细
                    color: Colors.blue.shade700, // 字体颜色
                  ),
                  textAlign: TextAlign.center, // 居中对齐
                  overflow: TextOverflow.visible, // 允许文本溢出
                ),
              ),
              SizedBox(width: 15), // 单词与发音按钮间距
              // 音频播放按钮
              if (_testMode == TestMode.multipleChoice ||
                  _testMode == TestMode.blankFill) // 两种模式都显示播放按钮
                _AnimatedPlayButton(
                  onPressed: () => _speakWord(currentWord.word),
                  size: 36,
                ),
            ],
          ),
        ),

        // 根据测试模式显示不同的测试内容
        if (_testMode == TestMode.multipleChoice)
          // 选择题：显示选项
          _buildMultipleChoiceOptions(currentWord)
        else
          // 填空题：显示输入框
          _buildBlankFillInput(currentWord),

        SizedBox(height: 40), // 测试内容与提交按钮间距
        // 提交答案按钮
        ValueListenableBuilder<String?>(
          valueListenable: _selectedAnswer,
          builder: (context, selectedAnswer, child) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 300), // 按钮最大宽度
              child: GestureDetector(
                // 只有选择了答案才能点击提交
                onTap: selectedAnswer != null ? _submitAnswer : null,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200), // 动画持续时间
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 18), // 按钮内边距
                  decoration: BoxDecoration(
                    // 按钮背景色：选择答案后显示蓝色，否则显示灰色
                    color: selectedAnswer != null
                        ? Colors.blue
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(30), // 按钮圆角
                    boxShadow: selectedAnswer != null
                        ? [
                            // 选择答案后显示阴影
                            BoxShadow(
                              color: Color.fromRGBO(0, 122, 255, 0.3),
                              spreadRadius: 5,
                              blurRadius: 15,
                              offset: Offset(0, 10),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    '提交答案', // 按钮文本
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22, // 文本字体大小
                      fontWeight: FontWeight.bold, // 文本字体粗细
                      color: Colors.white, // 文本颜色
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// 构建选择题选项
  ///
  /// 为选择题显示4个选项，用户可以点击选择
  /// 参数：
  /// - word: 当前测试的单词
  Widget _buildMultipleChoiceOptions(Word word) {
    // 生成选择题选项
    final options = _generateOptions(word.meaning);

    // 构建选项列表
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 提示文字
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 20, bottom: 15),
            child: Text(
              '请选择正确的释义',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
        ),
        // 选项列表
        for (int i = 0; i < options.length; i++)
          _buildMeaningOption(i, options[i], word.meaning),
      ],
    );
  }

  /// 构建释义选项
  Widget _buildMeaningOption(int index, String meaning, String correctMeaning) {
    return ValueListenableBuilder<String?>(
      valueListenable: _selectedAnswer,
      builder: (context, selectedAnswer, child) {
        final isSelected = selectedAnswer == meaning;
        final isCorrect = meaning == correctMeaning;

        Color bgColor = Colors.white;
        Color textColor = Colors.black;
        Color borderColor = Colors.grey.shade200;

        if (isSelected) {
          bgColor = Colors.blue.shade50;
          borderColor = Colors.blue;
        }

        return GestureDetector(
          onTap: () => _handleAnswerSelect(meaning),
          child: Container(
            margin: EdgeInsets.only(bottom: 15),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 3,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // 选项标记
                Container(
                  width: 24,
                  height: 24,
                  margin: EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 16, color: Colors.white)
                      : SizedBox(),
                ),

                // 选项文本
                Expanded(
                  child: Text(
                    meaning,
                    style: TextStyle(fontSize: 18, color: textColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建填空题输入框
  ///
  /// 为填空题显示文本输入框，用户可以输入答案
  /// 参数：
  /// - word: 当前测试的单词
  Widget _buildBlankFillInput(Word word) {
    return SizedBox(
      height: 80, // 输入框高度
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 40), // 输入框外边距
        child: TextField(
          controller: _blankFillController, // 使用输入框控制器
          onChanged: (value) => _handleAnswerSelect(value), // 输入变化时更新选中答案
          decoration: InputDecoration(
            hintText: '请输入对应的英文单词', // 提示文本
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30), // 输入框圆角
              borderSide: BorderSide.none, // 隐藏边框
            ),
            filled: true, // 填充背景
            fillColor: Colors.white, // 背景色
            contentPadding: EdgeInsets.symmetric(
              horizontal: 30,
              vertical: 20,
            ), // 内边距
            hintStyle: TextStyle(
              fontSize: 20,
              color: Colors.grey.shade400,
            ), // 提示文本样式
            suffixIcon: Icon(Icons.edit, color: Colors.blue.shade500), // 后缀图标
          ),
          textAlign: TextAlign.center, // 文本居中对齐
          style: TextStyle(
            fontSize: 28, // 输入文本字体大小
            fontWeight: FontWeight.bold, // 输入文本字体粗细
            color: Colors.blue.shade700, // 输入文本颜色
          ),
          autofocus: true, // 自动获取焦点
        ),
      ),
    );
  }

  /// 构建测试结果屏幕
  ///
  /// 显示测试完成后的详细结果，包括正确数量、错误数量和准确率
  Widget _buildResultScreen() {
    // 计算测试总题数和准确率
    final total = _correctCount + _wrongCount;
    final accuracy = total > 0 ? (_correctCount / total * 100).toInt() : 0;

    // 构建结果屏幕UI
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 结果标题
        Container(
          margin: EdgeInsets.only(bottom: 30),
          padding: EdgeInsets.all(30), // 标题容器内边距
          decoration: BoxDecoration(
            // 容器背景色：根据主题模式调整
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.white,
            borderRadius: BorderRadius.circular(20), // 容器圆角
            boxShadow: [
              // 容器阴影
              BoxShadow(
                color: Color.fromRGBO(128, 128, 128, 0.3),
                spreadRadius: 10,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Text(
            '测试完成！', // 结果标题
            style: TextStyle(
              fontSize: 42, // 标题字体大小
              fontWeight: FontWeight.bold, // 标题字体粗细
              color: Colors.blue, // 标题颜色
            ),
          ),
        ),

        SizedBox(height: 40), // 标题与结果数据间距
        // 结果标题
        Text(
          '测试结果',
          style: TextStyle(
            fontSize: 28, // 标题字体大小
            fontWeight: FontWeight.bold, // 标题字体粗细
            color: Colors.grey.shade700, // 标题颜色
          ),
        ),

        SizedBox(height: 30), // 标题与结果数据间距
        // 结果数据
        Wrap(
          spacing: 20, // 水平间距
          runSpacing: 20, // 垂直间距
          alignment: WrapAlignment.center, // 居中对齐
          children: [
            // 正确数量
            _resultItem('正确', _correctCount, Colors.green),
            // 错误数量
            _resultItem('错误', _wrongCount, Colors.red),
            // 准确率
            _resultItem('准确率', '$accuracy%', Colors.blue),
          ],
        ),

        SizedBox(height: 50), // 结果数据与再测一次按钮间距
        // 再测一次按钮
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 300), // 按钮最大宽度
          child: GestureDetector(
            onTap: _startNewTest, // 点击开始新的测试
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300), // 动画持续时间
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20), // 按钮内边距
              decoration: BoxDecoration(
                color: Colors.blue, // 按钮背景色
                borderRadius: BorderRadius.circular(35), // 按钮圆角
                boxShadow: [
                  // 按钮阴影
                  BoxShadow(
                    color: Color.fromRGBO(0, 122, 255, 0.3),
                    spreadRadius: 5,
                    blurRadius: 20,
                    offset: Offset(0, 15),
                  ),
                ],
              ),
              child: Text(
                '再测一次', // 按钮文本
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24, // 文本字体大小
                  fontWeight: FontWeight.bold, // 文本字体粗细
                  color: Colors.white, // 文本颜色
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 20), // 底部间距
      ],
    );
  }

  /// 构建结果项
  ///
  /// 显示测试结果的单个数据项
  /// 参数：
  /// - label: 数据项标签（如：正确、错误、准确率）
  /// - value: 数据项值（如：5、3、60%）
  /// - color: 数据项颜色
  ///
  /// 返回：构建好的结果项Widget
  Widget _resultItem(String label, dynamic value, Color color) {
    return Container(
      padding: EdgeInsets.all(25), // 结果项内边距
      decoration: BoxDecoration(
        // 结果项背景色：根据主题模式调整
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.white,
        borderRadius: BorderRadius.circular(15), // 结果项圆角
        boxShadow: [
          // 结果项阴影
          BoxShadow(
            color: Color.fromRGBO(128, 128, 128, 0.2),
            spreadRadius: 5,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 标签
          Text(
            label,
            style: TextStyle(
              fontSize: 20, // 标签字体大小
              color: Colors.grey.shade600, // 标签颜色
              fontWeight: FontWeight.bold, // 标签字体粗细
            ),
          ),
          SizedBox(height: 15), // 标签与值间距
          // 值
          Text(
            value.toString(), // 将值转换为字符串
            style: TextStyle(
              fontSize: 36, // 值字体大小
              fontWeight: FontWeight.bold, // 值字体粗细
              color: color, // 值颜色
            ),
          ),
        ],
      ),
    );
  }
}

/// 动画播放按钮组件
///
/// 功能：
/// - 带有按下动画效果的播放按钮
/// - 支持自定义大小和提示文本
/// - 点击时调用指定的回调函数
class _AnimatedPlayButton extends StatefulWidget {
  /// 按钮点击时的回调函数
  final VoidCallback onPressed;

  /// 按钮图标大小
  final double size;

  /// 按钮提示文本
  final String? tooltip;

  const _AnimatedPlayButton({
    required this.onPressed,
    this.size = 32.0,
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
            // 背景色：按下时显示浅蓝色，否则透明
            color: _isPressed ? Colors.blue.shade100 : Colors.transparent,
            boxShadow: [
              // 按下时显示阴影
              if (_isPressed)
                BoxShadow(
                  color: Colors.blue.shade300,
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
              // 图标颜色：按下时深蓝色，否则浅蓝色
              color: _isPressed ? Colors.blue.shade700 : Colors.blue.shade500,
              size: widget.size, // 图标大小
            ),
          ),
        ),
      ),
    );
  }
}
