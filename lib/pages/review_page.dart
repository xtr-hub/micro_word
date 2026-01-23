import 'dart:async';
import 'package:flutter/material.dart';
import '../models/word.dart';
import '../models/word_storage.dart';
import '../models/word_list.dart';
import '../models/word_list_storage.dart';
import '../models/study_progress.dart';
import '../models/settings.dart';
import '../services/audio_service.dart';

/// 复习页面 - 符合设计图要求
///
/// 功能：
/// - 黄色渐变背景
/// - 简洁的单词卡片，包含单词、音标
/// - 底部三个状态按钮：不认识、模糊、认识
/// - 发音播放
/// - 学习进度跟踪
class ReviewPage extends StatefulWidget {
  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage>
    with SingleTickerProviderStateMixin {
  // 单词数据
  late List<Word> _words;
  late WordList _currentWordList;
  late List<Word> _filteredWords;
  late List<List<Word>> _wordGroups; // 分组后的单词列表
  int _currentGroup = 0; // 当前分组索引
  int _currentIndexInGroup = 0; // 当前在分组中的索引
  bool _isLoading = true;

  // 分组学习统计
  late DateTime _groupStartTime; // 当前分组的开始时间
  int _groupCorrectCount = 0; // 当前分组的正确答案数量

  // 学习相关
  late StudyProgress _progress;
  late Settings _settings;

  // 当前选择的状态
  StudyStatus _selectedStatus = StudyStatus.learning;

  // 获取当前单词
  Word get _currentWord {
    return _wordGroups[_currentGroup][_currentIndexInGroup];
  }

  // 例句显示相关
  bool _showExample = false;
  bool _isToggling = false; // 动画触发保护标志
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadData();

    // 初始化动画控制器
    _animationController = AnimationController(
      duration: Duration(milliseconds: 400), // 稍微延长动画时间，使其更流畅
      vsync: this,
    );

    // 初始化动画
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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

    // 过滤出需要复习的单词（状态为 familiar 的单词）
    final reviewWords = _filteredWords
        .where((word) => word.status == StudyStatus.familiar)
        .toList();

    // 如果当前单词表中没有需要复习的单词，使用所有需要复习的单词
    final wordsToUse = reviewWords.isNotEmpty
        ? reviewWords
        : _words.where((word) => word.status == StudyStatus.familiar).toList();

    // 如果没有需要复习的单词，使用模拟数据
    if (wordsToUse.isEmpty) {
      _words = [
        Word(
          id: 1,
          word: 'beneficial',
          phonetic: '/ˌbenɪˈfɪʃl/',
          meaning: 'adj. 有益的，有利的',
          example: 'This medicine has a beneficial effect on the patient.',
          status: StudyStatus.familiar,
        ),
        Word(
          id: 2,
          word: 'confident',
          phonetic: '/ˈkɒnfɪdənt/',
          meaning: 'adj. 自信的，确信的',
          example: 'She is confident of winning the race.',
          status: StudyStatus.familiar,
        ),
        Word(
          id: 3,
          word: 'dependent',
          phonetic: '/dɪˈpendənt/',
          meaning: 'adj. 依赖的，依靠的',
          example: 'The child is dependent on his parents.',
          status: StudyStatus.familiar,
        ),
        Word(
          id: 4,
          word: 'efficient',
          phonetic: '/ɪˈfɪʃnt/',
          meaning: 'adj. 效率高的，有能力的',
          example: 'The new machine is more efficient than the old one.',
          status: StudyStatus.familiar,
        ),
        Word(
          id: 5,
          word: 'aggressive',
          phonetic: '/əˈɡresɪv/',
          meaning: 'adj. 好斗的，有侵略性的；进取的',
          example: 'He has an aggressive personality.',
          status: StudyStatus.familiar,
        ),
      ];
      _filteredWords = _words;
    }

    // 实现分组逻辑
    _wordGroups = [];
    int groupSize = _settings.reviewGroupSize;
    final targetWords = wordsToUse.isNotEmpty ? wordsToUse : _words;
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

    setState(() {
      _isLoading = false;
      _showExample = _settings.showExampleByDefault;
    });

    // 如果默认显示例句，延迟设置动画控制器为完成状态，避免初始渲染时的计算压力
    if (_settings.showExampleByDefault) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animationController.value = 1.0;
      });
    }

    // 自动播放发音
    if (_settings.autoPlayPronunciation &&
        _wordGroups.isNotEmpty &&
        _wordGroups[_currentGroup].isNotEmpty) {
      _speakWord(_currentWord.word);
    }
  }

  // 播放单词发音
  Future<void> _speakWord(String word) async {
    await AudioService().speak(word);
  }

  // 选择学习状态
  void _selectStatus(StudyStatus status) {
    setState(() {
      _selectedStatus = status;
    });
  }

  // 下一个单词
  void _nextWord() async {
    // 更新当前单词的学习状态
    _currentWord.updateStatus(_selectedStatus);

    // 保存学习进度
    bool isCorrect = _selectedStatus == StudyStatus.mastered;
    _progress.updateWordsStudied(1, isCorrect);
    _progress.updateWordsReviewed(1);
    await WordStorage.saveWords(_words);
    await _progress.save();

    // 更新分组正确计数
    if (isCorrect) {
      _groupCorrectCount++;
    }

    // 检查是否达成今日学习任务
    bool isTaskCompleted = _progress.todayWordsStudied >= _progress.dailyGoal;

    // 判断是否完成了当前分组
    if (_currentIndexInGroup == _wordGroups[_currentGroup].length - 1) {
      // 检查是否完成了所有分组
      bool isAllGroupsCompleted = _currentGroup == _wordGroups.length - 1;

      // 如果达成今日学习任务或完成了所有分组，优先显示复习完成界面
      if (isTaskCompleted || isAllGroupsCompleted) {
        _showReviewSummary();
      } else {
        // 否则显示分组完成提示
        _showGroupCompletion();
      }
    } else {
      // 切换到当前分组的下一个单词
      setState(() {
        _currentIndexInGroup = _currentIndexInGroup + 1;
        _selectedStatus = StudyStatus.learning;
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
              color: Colors.green,
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
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    '第 ${_currentGroup + 1} 组复习已完成！',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
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
                      backgroundColor: Colors.green,
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

  // 进入下一组复习
  void _nextGroup() {
    // 判断是否完成了所有分组
    if (_currentGroup == _wordGroups.length - 1) {
      // 完成了所有分组，显示复习总结
      _showReviewSummary();
    } else {
      // 进入下一组
      setState(() {
        _currentGroup = _currentGroup + 1;
        _currentIndexInGroup = 0;
        _groupStartTime = DateTime.now();
        _groupCorrectCount = 0;
        _selectedStatus = StudyStatus.learning;
      });

      // 自动播放发音
      if (_settings.autoPlayPronunciation) {
        _speakWord(_currentWord.word);
      }
    }
  }

  // 显示复习总结
  void _showReviewSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Text(
            '复习完成',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 20),
            // 复习成果
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    '本次复习成果',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSummaryItem('总复习数', _words.length.toString()),
                      _buildSummaryItem(
                        '完成复习',
                        '${_progress.todayWordsReviewed}',
                      ),
                      _buildSummaryItem(
                        '今日目标',
                        '${_progress.todayWordsReviewed}/${_progress.dailyReviewGoal}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // 复习建议
            Text(
              '恭喜你完成了本次复习！',
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
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                ),
              ),

              // 继续复习
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {
                      Navigator.pop(context); // 关闭对话框
                      // 重新开始复习
                      _loadData();
                    },
                    child: Text(
                      '继续复习',
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
            color: Colors.green,
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

    // 检查当前单词表中是否有需要复习的单词
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
                    '当前单词表中没有需要复习的单词',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '"${_currentWordList.name}" 中没有已熟悉的单词',
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
              // 顶部区域
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

              // 单词卡片
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                            onPressed: () => _speakWord(_currentWord.word),
                            color: Colors.orange,
                          ),

                          SizedBox(height: 20),

                          // 例句显示区域
                          if (_currentWord.example != null &&
                              _currentWord.example!.isNotEmpty &&
                              _showExample)
                            GestureDetector(
                              onTap: _toggleExample,
                              child: RepaintBoundary(
                                child: AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _opacityAnimation.value,
                                      child: Transform.scale(
                                        scale: _scaleAnimation.value,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.95),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.1),
                                          spreadRadius: 2,
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          '例句',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _currentWord.example!,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.green,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // 显示/隐藏例句按钮
                          if (_currentWord.example != null &&
                              _currentWord.example!.isNotEmpty)
                            GestureDetector(
                              onTap: _toggleExample,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.05),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _showExample ? '隐藏例句' : '显示例句',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: 40),

                    // 提示文字
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        '瞬间想起词义，选「认识」\n思考后想起词义，选「模糊」',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 底部状态按钮
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 状态选择提示
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 20, bottom: 20),
                        child: Text(
                          '选择学习状态',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),

                    // 三个状态按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 不认识按钮
                        Expanded(
                          child: _buildStatusButton(
                            '不认识',
                            Colors.red,
                            StudyStatus.learning,
                          ),
                        ),

                        SizedBox(width: 15),

                        // 模糊按钮
                        Expanded(
                          child: _buildStatusButton(
                            '模糊',
                            Colors.orange,
                            StudyStatus.familiar,
                          ),
                        ),

                        SizedBox(width: 15),

                        // 认识按钮
                        Expanded(
                          child: _buildStatusButton(
                            '认识',
                            Colors.green,
                            StudyStatus.mastered,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // 下一个按钮
                    GestureDetector(
                      onTap: _nextWord,
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              spreadRadius: 5,
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '下一个',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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

  // 构建状态按钮
  Widget _buildStatusButton(String text, Color color, StudyStatus status) {
    final isSelected = _selectedStatus == status;

    return GestureDetector(
      onTap: () => _selectStatus(status),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              spreadRadius: 5,
              blurRadius: 15,
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
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
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
                '复习选项',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              SizedBox(height: 20),

              // 按钮1
              _buildMenuButton(
                '再听一遍发音',
                () => _speakWord(_currentWord.word),
                Colors.green,
              ),

              SizedBox(height: 15),

              // 按钮2
              _buildMenuButton('收藏该单词', () {
                _currentWord.toggleFavorite();
                WordStorage.saveWords(_words);
                Navigator.pop(context);
              }, Colors.purple),

              SizedBox(height: 15),

              // 按钮3
              _buildMenuButton('查看详细释义', () {
                _showWordDetails();
                Navigator.pop(context);
              }, Colors.blue),

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

  // 显示单词详细信息
  void _showWordDetails() {
    // 这里可以实现显示单词详细信息的功能
    // 例如显示释义、例句、相关词组等
    final currentWord = _currentWord;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentWord.word),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentWord.phonetic ?? '',
              style: TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 15),
            Text(currentWord.meaning, style: TextStyle(fontSize: 16)),
            SizedBox(height: 15),
            if (currentWord.example != null && currentWord.example!.isNotEmpty)
              Text(
                '例句: ${currentWord.example}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }

  // 切换例句显示状态
  void _toggleExample() {
    // 检查动画控制器是否正在运行或正在切换状态，如果是，则不执行任何操作
    if (_animationController.isAnimating || _isToggling) {
      return;
    }

    _isToggling = true;

    if (_showExample) {
      // 隐藏例句
      _animationController.reverse().then((_) {
        setState(() {
          _showExample = false;
        });
        _isToggling = false;
      });
    } else {
      // 显示例句
      setState(() {
        _showExample = true;
      });
      _animationController.forward().then((_) {
        _isToggling = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
