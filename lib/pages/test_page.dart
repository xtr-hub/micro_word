import 'package:flutter/material.dart'; // Flutter UI组件库
import '../models/word.dart'; // 单词数据模型
import '../models/word_storage.dart'; // 单词存储服务
import '../models/study_progress.dart'; // 学习进度模型
import '../services/audio_service.dart'; // 音频播放服务

/// 测试页面
///
/// 功能：
/// - 支持两种测试模式：选择题和填空题
/// - 随机生成10个单词进行测试
/// - 支持播放单词发音
/// - 实时统计测试结果
/// - 测试完成后显示详细结果
/// - 根据测试结果更新单词学习状态
class TestPage extends StatefulWidget {
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

  /// 当前测试的单词列表（随机选择10个）
  late List<Word> _testWords;

  /// 当前测试的单词索引
  int _currentIndex = 0;

  /// 用户选择的答案
  //String? _selectedAnswer;
  ValueNotifier<String?> _selectedAnswer = ValueNotifier<String?>(null);

  /// 测试结果统计
  int _correctCount = 0; // 正确数量
  int _wrongCount = 0; // 错误数量

  /// 是否显示测试结果
  bool _showResult = false;

  /// 数据加载状态
  bool _isLoading = true;

  /// 学习进度对象
  late StudyProgress _progress;

  /// 页面初始化时调用
  @override
  void initState() {
    super.initState();
    // 注册应用生命周期观察者
    WidgetsBinding.instance.addObserver(this);
    // 加载单词数据和学习进度
    _loadData();
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

  /// 监听应用生命周期变化
  ///
  /// 当页面可见性发生变化时，停止或恢复音频播放
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 当页面不可见时，停止音频播放
    if (state == AppLifecycleState.paused) {
      _stopAudio();
    }
  }

  /// 加载单词数据和学习进度
  ///
  /// 从本地存储加载单词列表和学习进度信息
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true; // 开始加载，显示加载指示器
    });

    // 从本地存储加载单词列表
    _words = await WordStorage.loadWords();
    // 从本地存储加载学习进度
    _progress = await StudyProgress.load();
    // 生成测试单词列表
    _generateTestWords();

    setState(() {
      _isLoading = false; // 加载完成，隐藏加载指示器
    });

    // 数据加载完成后，自动播放当前单词的音频
    if (_testWords.isNotEmpty) {
      _speakWord(_testWords[_currentIndex].word);
    }
  }

  /// 生成测试单词列表
  ///
  /// 从所有单词中随机选择10个作为测试单词
  void _generateTestWords() {
    _testWords = [];
    // 创建单词列表的副本，避免修改原始列表
    final availableWords = List.from(_words);

    // 随机选择10个单词，直到选满或没有更多单词
    while (_testWords.length < 10 && availableWords.isNotEmpty) {
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
  void _submitAnswer() {
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
      } else {
        // 测试完成，显示结果
        _showResult = true;
      }
    });

    // 如果还有下一个单词，自动播放音频
    if (_currentIndex < _testWords.length) {
      _speakWord(_testWords[_currentIndex].word);
    }

    // 保存更新后的单词数据到本地存储
    WordStorage.saveWords(_words);

    // 更新学习进度
    bool isMastered = currentWord.status == StudyStatus.mastered;
    _progress.updateWordsStudied(1, isMastered);
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
    final availableWords = List.from(_words); // 创建单词列表副本

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
      children: options.map((option) {
        return ValueListenableBuilder<String?>(
          valueListenable: _selectedAnswer,
          builder: (context, selectedAnswer, child) {
            // 判断当前选项是否被选中
            final isSelected = selectedAnswer == option;
            return GestureDetector(
              onTap: () => _handleAnswerSelect(option), // 点击选择该选项
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200), // 动画持续时间
                margin: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 20,
                ), // 选项间距
                padding: EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 18,
                ), // 选项内边距
                decoration: BoxDecoration(
                  // 选项背景色：选中时显示蓝色，否则根据主题模式调整
                  color: isSelected
                      ? Colors.blue
                      : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.white),
                  borderRadius: BorderRadius.circular(25), // 选项圆角
                  boxShadow: [
                    // 选项阴影
                    BoxShadow(
                      color: isSelected
                          ? Color.fromRGBO(0, 122, 255, 0.3)
                          : Color.fromRGBO(128, 128, 128, 0.2),
                      spreadRadius: isSelected ? 4 : 3,
                      blurRadius: isSelected ? 12 : 8,
                      offset: Offset(0, isSelected ? 8 : 5),
                    ),
                  ],
                  border: Border.all(
                    // 选项边框：选中时显示蓝色边框
                    color: isSelected
                        ? Colors.blue.shade400
                        : Colors.transparent,
                    width: isSelected ? 3 : 0,
                  ),
                ),
                child: Text(
                  option, // 选项文本
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20, // 文本字体大小
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal, // 选中时加粗
                    color: isSelected
                        ? Colors.white
                        : Colors.blue.shade700, // 文本颜色
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
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

/// 测试模式枚举
///
/// 定义了两种测试模式：
enum TestMode {
  multipleChoice, // 选择题模式
  blankFill, // 填空题模式
}
