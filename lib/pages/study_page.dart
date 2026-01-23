import 'dart:async';
import 'package:flutter/material.dart';
import '../models/word.dart';
import '../models/word_storage.dart';
import '../models/word_list.dart';
import '../models/word_list_storage.dart';
import '../models/study_progress.dart';
import '../models/settings.dart';
import '../services/audio_service.dart';

/// 学习页面 - 符合设计图要求
///
/// 功能：
/// - 黄色渐变背景
/// - 简洁的单词卡片，包含单词、音标
/// - 释义选择功能
/// - 发音播放
/// - 学习进度跟踪
class StudyPage extends StatefulWidget {
  @override
  _StudyPageState createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage>
    with SingleTickerProviderStateMixin {
  // 单词数据
  late List<Word> _words;
  late WordList _currentWordList;
  late List<Word> _filteredWords;
  late List<List<Word>> _wordGroups; // 分组后的单词列表
  int _currentGroup = 0; // 当前分组索引
  int _currentIndexInGroup = 0; // 当前在分组中的索引
  bool _isLoading = true;
  bool _showAnswer = false;
  bool _isCorrect = false;

  // 分组学习统计
  late DateTime _groupStartTime; // 当前分组的开始时间
  int _groupCorrectCount = 0; // 当前分组的正确答案数量

  // 学习相关
  late StudyProgress _progress;
  late Settings _settings;

  // 释义选项
  List<String> _meaningOptions = [];
  int _selectedOption = -1;
  int _correctAnswerIndex = 0;

  // 获取当前单词
  Word get _currentWord {
    return _wordGroups[_currentGroup][_currentIndexInGroup];
  }

  // 动画相关
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _exampleOpacityAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _loadData();

    // 初始化动画控制器
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    // 初始化高度动画
    _heightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 初始化例句透明度动画
    _exampleOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  // 加载数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // 并行加载数据
    final wordsFuture = WordStorage.loadWords();
    final progressFuture = StudyProgress.load();
    final settingsFuture = Settings.load();
    final currentWordListFuture = WordListStorage.getCurrentWordList();

    final results = await Future.wait([
      wordsFuture,
      progressFuture,
      settingsFuture,
      currentWordListFuture,
    ]);
    _words = results[0] as List<Word>;
    _progress = results[1] as StudyProgress;
    _settings = results[2] as Settings;
    _currentWordList = results[3] as WordList;

    // 过滤出当前单词表中的单词
    _filteredWords = _words
        .where((word) => _currentWordList.wordIds.contains(word.id))
        .toList();

    // 如果当前单词表中没有单词，使用所有单词
    final wordsToUse = _filteredWords.isNotEmpty ? _filteredWords : _words;

    // 如果没有单词，使用模拟数据
    if (wordsToUse.isEmpty) {
      _words = [
        Word(
          id: 1,
          word: 'aggressive',
          phonetic: '/əˈɡresɪv/',
          meaning: 'adj. 好斗的，有侵略性的；进取的',
          example: 'He has an aggressive personality.',
        ),
        Word(
          id: 2,
          word: 'beneficial',
          phonetic: '/ˌbenɪˈfɪʃl/',
          meaning: 'adj. 有益的，有利的',
          example: 'This medicine has a beneficial effect on the patient.',
        ),
        Word(
          id: 3,
          word: 'confident',
          phonetic: '/ˈkɒnfɪdənt/',
          meaning: 'adj. 自信的，确信的',
          example: 'She is confident of winning the race.',
        ),
        Word(
          id: 4,
          word: 'dependent',
          phonetic: '/dɪˈpendənt/',
          meaning: 'adj. 依赖的，依靠的',
          example: 'The child is dependent on his parents.',
        ),
        Word(
          id: 5,
          word: 'efficient',
          phonetic: '/ɪˈfɪʃnt/',
          meaning: 'adj. 效率高的，有能力的',
          example: 'The new machine is more efficient than the old one.',
        ),
      ];
      _filteredWords = _words;
    }

    // 实现分组逻辑
    _wordGroups = [];
    int groupSize = _settings.studyGroupSize;
    final targetWords = _filteredWords.isNotEmpty ? _filteredWords : _words;
    for (int i = 0; i < targetWords.length; i += groupSize) {
      int end = i + groupSize;
      if (end > targetWords.length) {
        end = targetWords.length;
      }
      _wordGroups.add(targetWords.sublist(i, end));
    }

    // 初始化分组索引
    _currentGroup = 0;
    _currentIndexInGroup = 0;
    _groupStartTime = DateTime.now();
    _groupCorrectCount = 0;

    // 初始化释义选项
    _initMeaningOptions();

    setState(() {
      _isLoading = false;
    });

    // 自动播放发音
    if (_settings.autoPlayPronunciation &&
        _wordGroups.isNotEmpty &&
        _wordGroups[_currentGroup].isNotEmpty) {
      _speakWord(_currentWord.word);
    }
  }

  // 初始化释义选项
  void _initMeaningOptions() {
    // 从单词数据中生成释义选项
    // 包括正确释义和几个干扰项
    _meaningOptions = [];

    // 添加当前单词的正确释义
    final currentWord = _currentWord;
    _meaningOptions.add(currentWord.meaning);

    // 从当前单词表的其他单词中添加干扰项
    final otherWords = _filteredWords.isNotEmpty ? _filteredWords : _words;
    final availableDistractors = otherWords
        .where((word) => word.id != currentWord.id)
        .toList();

    // 随机选择几个干扰项（最多3个）
    final distractorCount = 3;
    for (
      int i = 0;
      i < distractorCount && i < availableDistractors.length;
      i++
    ) {
      _meaningOptions.add(availableDistractors[i].meaning);
    }

    // 如果干扰项不足，添加一些默认干扰项
    while (_meaningOptions.length < 4) {
      _meaningOptions.add('adj. 示例释义');
    }

    // 随机打乱选项顺序
    _meaningOptions.shuffle();

    // 记录正确答案的索引
    _correctAnswerIndex = _meaningOptions.indexOf(currentWord.meaning);

    _selectedOption = -1;
    _showAnswer = false;
    _isCorrect = false;
  }

  // 播放单词发音
  Future<void> _speakWord(String word) async {
    await AudioService().speak(word);
  }

  // 选择释义选项
  void _selectMeaning(int index) {
    if (_showAnswer) return;

    setState(() {
      _selectedOption = index;
      _showAnswer = true;
      _isCorrect = index == _correctAnswerIndex; // 使用正确答案索引判断
    });

    // 启动动画，无论选择正确还是错误的答案
    _startAnimation();

    // 更新单词学习状态
    if (_isCorrect) {
      _currentWord.updateStatus(StudyStatus.familiar);
      _groupCorrectCount++;
    } else {
      _currentWord.updateStatus(StudyStatus.learning);
    }
  }

  // 下一个单词
  void _nextWord() async {
    // 保存学习进度
    _progress.updateWordsStudied(1, _isCorrect);
    await WordStorage.saveWords(_words);
    await _progress.save();

    // 检查是否达成今日学习任务
    bool isTaskCompleted = _progress.todayWordsStudied >= _progress.dailyGoal;

    // 判断是否完成了当前分组
    if (_currentIndexInGroup == _wordGroups[_currentGroup].length - 1) {
      // 检查是否完成了所有分组
      bool isAllGroupsCompleted = _currentGroup == _wordGroups.length - 1;

      // 如果达成今日学习任务或完成了所有分组，优先显示学习完成界面
      if (isTaskCompleted || isAllGroupsCompleted) {
        _showStudySummary();
      } else {
        // 否则显示分组完成提示
        _showGroupCompletion();
      }
    } else {
      // 切换到当前分组的下一个单词
      setState(() {
        _currentIndexInGroup = _currentIndexInGroup + 1;
        _initMeaningOptions();
        _isAnimating = false;
      });

      // 自动播放发音
      if (_settings.autoPlayPronunciation) {
        _speakWord(_currentWord.word);
      }
    }
  }

  // 显示分组完成提示
  void _showGroupCompletion() {
    // 计算分组学习统计数据
    int groupSize = _wordGroups[_currentGroup].length;
    double accuracy = groupSize > 0
        ? (_groupCorrectCount / groupSize) * 100
        : 0;
    int groupTime = DateTime.now().difference(_groupStartTime).inSeconds;

    // 显示分组完成提示对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Text(
            '分组完成',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 20),
            // 分组信息
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    '第 ${_currentGroup + 1} 组学习已完成！',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSummaryItem(
                        '正确率',
                        '${accuracy.toStringAsFixed(1)}%',
                      ),
                      _buildSummaryItem('用时', '${groupTime}秒'),
                      _buildSummaryItem(
                        '正确',
                        '$_groupCorrectCount / $groupSize',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // 学习建议
            Text(
              '继续保持，加油！',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          // 使用Row和Expanded实现按钮对称分布
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 返回主页
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      '返回主页',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
              // 继续下一组
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _nextGroup();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      '继续下一组',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  // 进入下一组学习
  void _nextGroup() {
    // 判断是否完成了所有分组
    if (_currentGroup == _wordGroups.length - 1) {
      // 完成了所有分组，显示学习总结
      _showStudySummary();
    } else {
      // 进入下一组
      setState(() {
        _currentGroup = _currentGroup + 1;
        _currentIndexInGroup = 0;
        _groupStartTime = DateTime.now();
        _groupCorrectCount = 0;
        _initMeaningOptions();
        _isAnimating = false;
      });

      // 自动播放发音
      if (_settings.autoPlayPronunciation) {
        _speakWord(_currentWord.word);
      }
    }
  }

  // 显示学习总结
  void _showStudySummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Text(
            '学习完成',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 20),
            // 学习成果
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    '本次学习成果',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSummaryItem('总单词数', _words.length.toString()),
                      _buildSummaryItem(
                        '学习完成',
                        '${_progress.todayWordsStudied}',
                      ),
                      _buildSummaryItem(
                        '今日目标',
                        '${_progress.todayWordsStudied}/${_progress.dailyGoal}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // 学习建议
            Text(
              '恭喜你完成了本次学习！',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          // 使用Row和Expanded实现按钮对称分布
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 返回主页
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.grey.shade100,
                    ),
                    onPressed: () {
                      Navigator.pop(context); // 关闭对话框
                      // 判断是否可以返回（通过导航栈）
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context); // 返回上一页
                      } else {
                        // 如果无法返回，说明是在PageView中，什么都不做
                        // 继续留在当前页面
                      }
                    },
                    child: Text(
                      '返回',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                ),
              ),

              // 继续学习
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () {
                      Navigator.pop(context); // 关闭对话框
                      // 重新开始学习
                      setState(() {
                        _currentGroup = 0;
                        _currentIndexInGroup = 0;
                        _groupStartTime = DateTime.now();
                        _groupCorrectCount = 0;
                        _initMeaningOptions();
                      });
                      // 自动播放发音
                      if (_settings.autoPlayPronunciation) {
                        _speakWord(_currentWord.word);
                      }
                    },
                    child: Text(
                      '继续学习',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建总结项
  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    // 检查当前单词表是否为空
    if (_wordGroups.isEmpty ||
        (_wordGroups.length == 1 && _wordGroups[0].isEmpty)) {
      return Scaffold(
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book, size: 80, color: Colors.grey.shade300),
                  SizedBox(height: 20),
                  Text(
                    '当前单词表中没有单词',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '请先添加单词到 "${_currentWordList.name}"',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      '返回单词本',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 不再需要 currentWord 变量，直接使用 _currentWord getter 方法

    return Scaffold(
      // 使用主题背景色，移除黄色渐变
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              // 顶部进度条
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 返回按钮
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),

                    // 进度指示器
                    Text(
                      '第 ${_currentGroup + 1} 组 ${_currentIndexInGroup + 1}/${_wordGroups[_currentGroup].length}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    // 更多选项
                    IconButton(
                      icon: Icon(Icons.more_vert, color: Colors.black),
                      onPressed: _showBottomMenu,
                    ),
                  ],
                ),
              ),

              // 单词卡片和释义选项 - 可滚动区域
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 单词卡片
                      Column(
                        children: [
                          // 单词和音标
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40),
                            child: Column(
                              children: [
                                // 单词
                                GestureDetector(
                                  onTap: () => _speakWord(_currentWord.word),
                                  child: Text(
                                    _currentWord.word,
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),

                                SizedBox(height: 10),

                                // 音标
                                Text(
                                  _currentWord.phonetic ?? '',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),

                                SizedBox(height: 10),

                                // 发音按钮
                                IconButton(
                                  icon: Icon(Icons.volume_up, size: 32),
                                  onPressed: () =>
                                      _speakWord(_currentWord.word),
                                  color: Colors.orange,
                                ),

                                SizedBox(height: 20),
                              ],
                            ),
                          ),

                          SizedBox(height: 40),

                          // 释义选项
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                // 提示文字
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: 20,
                                      bottom: 15,
                                    ),
                                    child: Text(
                                      '先回想词义再选择，想不起来「看答案」',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ),

                                // 释义选项列表
                                for (int i = 0; i < _meaningOptions.length; i++)
                                  _buildMeaningOption(i, _meaningOptions[i]),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 底部两个功能按钮 - 固定在屏幕下方
              Container(
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 按钮1：查看答案/下一个单词
                    Expanded(
                      child: GestureDetector(
                        onTap: _showAnswer ? _nextWord : _showCorrectAnswer,
                        child: Container(
                          height: 55,
                          margin: EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: _showAnswer ? Colors.blue : Colors.orange,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: _showAnswer
                                    ? Colors.blue.withOpacity(0.3)
                                    : Colors.orange.withOpacity(0.3),
                                spreadRadius: 5,
                                blurRadius: 15,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _showAnswer ? '下一个' : '答案',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 按钮2：收藏按钮
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            bool wasFavorite = _currentWord.isFavorite;
                            _currentWord.toggleFavorite();
                            WordStorage.saveWords(_words);

                            // 显示收藏状态变化的提示
                            _showFavoriteToast(!wasFavorite);
                          });
                        },
                        child: Container(
                          height: 55,
                          margin: EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: _currentWord.isFavorite
                                ? Colors.purple
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (_currentWord.isFavorite
                                            ? Colors.purple
                                            : Colors.grey.shade400)
                                        .withOpacity(0.3),
                                spreadRadius: 5,
                                blurRadius: 15,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child: Icon(
                                key: ValueKey<bool>(_currentWord.isFavorite),
                                _currentWord.isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建释义选项
  Widget _buildMeaningOption(int index, String meaning) {
    final isSelected = index == _selectedOption;
    final isCorrect = index == _correctAnswerIndex;
    final showResult = _showAnswer;

    Color bgColor = Colors.white;
    Color textColor = Colors.black;
    Color borderColor = Colors.grey.shade200;

    if (showResult) {
      if (isCorrect) {
        bgColor = Colors.green.shade100;
        borderColor = Colors.green;
      } else if (isSelected) {
        bgColor = Colors.red.shade100;
        borderColor = Colors.red;
      }
    } else if (isSelected) {
      bgColor = Colors.blue.shade50;
      borderColor = Colors.blue;
    }

    if (isCorrect && showResult && _isAnimating) {
      return AnimatedBuilder(
        animation: _heightAnimation,
        builder: (context, child) {
          return GestureDetector(
            onTap: () => _selectMeaning(index),
            child: Container(
              margin: EdgeInsets.only(bottom: 15),
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15 + (_heightAnimation.value * 25),
              ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 选项标记
                      Container(
                        width: 24,
                        height: 24,
                        margin: EdgeInsets.only(right: 15),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: showResult && isCorrect
                              ? Colors.green
                              : showResult && isSelected
                              ? Colors.red
                              : isSelected
                              ? Colors.blue
                              : Colors.grey.shade300,
                        ),
                        child: showResult && isCorrect
                            ? Icon(Icons.check, size: 16, color: Colors.white)
                            : SizedBox(),
                      ),

                      // 释义文本
                      Expanded(
                        child: Text(
                          meaning,
                          style: TextStyle(fontSize: 18, color: textColor),
                        ),
                      ),
                    ],
                  ),
                  // 例句显示区域
                  if (isCorrect &&
                      _heightAnimation.value > 0.3 &&
                      _currentWord.example != null &&
                      _currentWord.example!.isNotEmpty)
                    Opacity(
                      opacity: _exampleOpacityAnimation.value,
                      child: Container(
                        margin: EdgeInsets.only(top: 15),
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '例句',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _currentWord.example!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      return GestureDetector(
        onTap: () => _selectMeaning(index),
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
                  color: showResult && isCorrect
                      ? Colors.green
                      : showResult && isSelected
                      ? Colors.red
                      : isSelected
                      ? Colors.blue
                      : Colors.grey.shade300,
                ),
                child: showResult && isCorrect
                    ? Icon(Icons.check, size: 16, color: Colors.white)
                    : SizedBox(),
              ),

              // 释义文本
              Expanded(
                child: Text(
                  meaning,
                  style: TextStyle(fontSize: 18, color: textColor),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // 启动动画
  void _startAnimation() {
    _animationController.reset();
    _animationController.forward();
    setState(() {
      _isAnimating = true;
    });
  }

  // 显示正确答案
  void _showCorrectAnswer() {
    setState(() {
      _showAnswer = true;
      _selectedOption = _correctAnswerIndex;
      _isCorrect = true;
    });

    // 启动动画
    _startAnimation();
  }

  // 显示底部上拉菜单
  void _showBottomMenu() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 菜单标题
              Text(
                _showAnswer ? '选择操作' : '学习选项',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              SizedBox(height: 20),

              // 按钮1
              _buildMenuButton(
                _showAnswer ? '下一个单词' : '查看答案',
                _showAnswer ? _nextWord : _showCorrectAnswer,
                _showAnswer ? Colors.blue : Colors.orange,
              ),

              SizedBox(height: 15),

              // 按钮2
              _buildMenuButton(
                '再听一遍发音',
                () => _speakWord(_currentWord.word),
                Colors.green,
              ),

              SizedBox(height: 15),

              // 按钮3
              _buildMenuButton('收藏该单词', () {
                _currentWord.toggleFavorite();
                WordStorage.saveWords(_words);
                Navigator.pop(context);
              }, Colors.purple),

              SizedBox(height: 20),

              // 取消按钮
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // 构建菜单按钮
  Widget _buildMenuButton(String text, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: () {
        onTap();
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              spreadRadius: 3,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // 显示收藏状态变化的提示
  void _showFavoriteToast(bool isFavorite) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100,
        left: 0,
        right: 0,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    isFavorite ? '已收藏' : '已取消收藏',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // 2秒后移除提示
    Future.delayed(Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
