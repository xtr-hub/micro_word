import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/word_storage.dart';
import '../models/word_list.dart';
import '../services/word_list_storage.dart';
import '../models/study_progress.dart';
import '../models/settings.dart';
import '../services/audio_service.dart';
import '../services/progress_persistence_service.dart';
import '../services/data_manager.dart';

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
  bool _isLoading = true;
  bool _showAnswer = false;
  bool _isCorrect = false;

  // 容器管理
  List<Word> _studyContainer = []; // 学习容器
  List<Word> _originalContainer = []; // 原始容器（用于拼写测试）
  Map<int, int> _continuousCorrectCount = {}; // 单词ID -> 连续答对次数
  Random _random = Random();

  // 学习相关
  late StudyProgress _progress;
  late Settings _settings;

  // 释义选项
  List<String> _meaningOptions = [];
  int _selectedOption = -1;
  int _correctAnswerIndex = 0;

  // 拼写测试相关
  bool _isSpellingTest = false;
  String _spellingInput = '';
  int _spellingTestIndex = 0;
  bool _showCorrectSpelling = false;

  // 学习小结相关
  List<Word> _masteredWords = [];

  // 乱序单词ID顺序
  List<int>? _shuffledWordIds;
  // 乱序状态是否已生成
  bool _isShuffleGenerated = false;

  // 获取当前单词
  Word get _currentWord {
    if (_studyContainer.isEmpty) {
      // 如果容器为空，返回第一个单词作为默认值
      return _words.isNotEmpty
          ? _words.first
          : Word(id: 0, word: 'empty', phonetic: '', meaning: '无单词');
    }
    return _studyContainer[0];
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

  @override
  void dispose() {
    // 保存学习状态
    _saveStudyState();
    _animationController.dispose();
    super.dispose();
  }

  // 保存学习状态
  Future<void> _saveStudyState() async {
    if (_studyContainer.isNotEmpty || _originalContainer.isNotEmpty) {
      await ProgressPersistenceService.instance.saveSessionState({
        'studyContainer': _studyContainer,
        'originalContainer': _originalContainer,
        'continuousCorrectCount': _continuousCorrectCount,
        'masteredWords': _masteredWords,
        'isShuffleGenerated': _isShuffleGenerated,
        'shuffledWordIds': _shuffledWordIds,
      });
    }
  }

  // 加载数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // 初始化DataManager
    await DataManager.instance.initialize();

    // 使用DataManager加载数据
    _words = await DataManager.instance.getAllWords();
    _progress = await DataManager.instance.getStudyProgress();
    _settings = await Settings.load();
    _currentWordList =
        await DataManager.instance.getCurrentWordList() ??
        WordList(id: 1, name: '默认单词表', isCurrent: true);

    // 过滤出当前单词表中的单词
    _filteredWords = _words
        .where((word) => _currentWordList.wordIds.contains(word.id))
        .toList();

    // 根据单词表中的顺序排序单词（确保学习界面严格按照单词表顺序）
    _filteredWords.sort((a, b) {
      final indexA = _currentWordList.wordIds.indexOf(a.id);
      final indexB = _currentWordList.wordIds.indexOf(b.id);
      return indexA.compareTo(indexB);
    });

    // 根据设置中的排序选项排序单词（仅对非新单词生效）
    _sortWords();

    // 尝试加载之前保存的学习状态
    final sessionState = await ProgressPersistenceService.instance
        .loadSessionState();
    bool hasSavedState = false;
    if (sessionState.containsKey('studyContainer') &&
        sessionState['studyContainer'] is List<Word>) {
      _studyContainer = sessionState['studyContainer'] as List<Word>;
      _originalContainer = sessionState['originalContainer'] as List<Word>;
      _continuousCorrectCount =
          sessionState['continuousCorrectCount'] as Map<int, int>;
      _masteredWords = sessionState['masteredWords'] as List<Word>;
      _isShuffleGenerated = sessionState['isShuffleGenerated'] as bool ?? false;
      _shuffledWordIds = sessionState['shuffledWordIds'] as List<int>?;
      hasSavedState = true;
    }

    // 如果没有保存的状态，初始化容器管理
    if (!hasSavedState) {
      // 初始化容器管理
      _initStudyContainer();
    }

    // 初始化释义选项
    _initMeaningOptions();

    setState(() {
      _isLoading = false;
    });

    // 自动播放发音
    if (_settings.autoPlayPronunciation && _studyContainer.isNotEmpty) {
      _speakWord(_currentWord.word);
    }
  }

  // 初始化学习容器
  void _initStudyContainer() {
    // 清空容器
    _studyContainer.clear();
    _originalContainer.clear();
    _continuousCorrectCount.clear();

    // 根据用户设置的学习分组大小决定容器大小
    int containerSize = _settings.studyGroupSize;

    // 从排序后的单词列表中提取单词
    final targetWords = _filteredWords.isNotEmpty ? _filteredWords : _words;

    // 限制容器大小不超过可用单词数
    if (containerSize > targetWords.length) {
      containerSize = targetWords.length;
    }

    // 按照用户指定的学习顺序从单词表中提取单词
    for (int i = 0; i < containerSize; i++) {
      if (i < targetWords.length) {
        _studyContainer.add(targetWords[i]);
        _originalContainer.add(targetWords[i]);
        // 初始化连续答对次数为0
        _continuousCorrectCount[targetWords[i].id] = 0;
      }
    }

    // 随机打乱容器中的单词顺序，确保抽取的随机性
    _shuffleContainer();
  }

  // 打乱容器中的单词顺序
  void _shuffleContainer() {
    _studyContainer.shuffle(_random);
  }

  // 排序单词
  void _sortWords() {
    // 分离新单词和已学习单词
    final newWords = _filteredWords
        .where((word) => word.status == StudyStatus.newWord)
        .toList();
    final learnedWords = _filteredWords
        .where((word) => word.status != StudyStatus.newWord)
        .toList();

    // 新单词严格按照单词表顺序
    newWords.sort((a, b) {
      final indexA = _currentWordList.wordIds.indexOf(a.id);
      final indexB = _currentWordList.wordIds.indexOf(b.id);
      return indexA.compareTo(indexB);
    });

    // 已学习单词根据用户设置排序
    switch (_settings.sortOption) {
      case SortOption.word:
        learnedWords.sort((a, b) => a.word.compareTo(b.word));
        break;
      case SortOption.lastStudyTime:
        learnedWords.sort((a, b) => b.lastStudyTime.compareTo(a.lastStudyTime));
        break;
      case SortOption.memoryStrength:
        learnedWords.sort(
          (a, b) => b.memoryStrength.compareTo(a.memoryStrength),
        );
        break;
      case SortOption.shuffle:
        _shuffleWords(learnedWords);
        break;
    }

    // 合并新单词和已学习单词，新单词在前
    _filteredWords = [...newWords, ...learnedWords];
  }

  // 乱序排序单词
  void _shuffleWords(List<Word> words) {
    // 如果还没有生成乱序顺序，生成一个
    if (!_isShuffleGenerated) {
      // 获取当前单词表中的单词ID
      final wordIds = words.map((word) => word.id).toList();
      // 打乱顺序
      wordIds.shuffle();
      // 保存乱序顺序
      _shuffledWordIds = wordIds;
      _isShuffleGenerated = true;
    }

    // 如果已经有乱序顺序，根据该顺序排序
    if (_shuffledWordIds != null) {
      words.sort((a, b) {
        final indexA = _shuffledWordIds!.indexOf(a.id);
        final indexB = _shuffledWordIds!.indexOf(b.id);
        return indexA.compareTo(indexB);
      });
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
      _isAnimating = true; // 开始动画
    });

    // 启动动画，无论选择正确还是错误的答案
    _startAnimation();

    // 更新单词学习状态和连续答对次数
    if (_isCorrect) {
      _currentWord.updateStatus(StudyStatus.familiar);
      // 保存单词状态到数据库
      DataManager.instance.saveWord(_currentWord);
      // 递增连续答对次数
      int currentCount = _continuousCorrectCount[_currentWord.id] ?? 0;
      currentCount++;
      _continuousCorrectCount[_currentWord.id] = currentCount;

      // 当连续答对次数达到3时，自动将该单词从当前容器中移除
      if (currentCount >= 3) {
        _studyContainer.remove(_currentWord);
        _masteredWords.add(_currentWord);
      }
    } else {
      _currentWord.updateStatus(StudyStatus.learning);
      // 保存单词状态到数据库
      DataManager.instance.saveWord(_currentWord);
      // 答错时重置连续答对次数为0
      _continuousCorrectCount[_currentWord.id] = 0;
    }
  }

  // 启动动画
  void _startAnimation() {
    _animationController.forward();
  }

  // 显示正确答案
  void _showCorrectAnswer() {
    setState(() {
      _showAnswer = true;
      _isCorrect = false;
      _selectedOption = _correctAnswerIndex; // 设置选中选项为正确答案
      _isAnimating = true; // 开始动画
    });

    // 启动动画
    _startAnimation();
  }

  // 下一个单词
  void _nextWord() async {
    // 记录学习详细信息
    _progress.recordStudy(_currentWord.id, _isCorrect, _currentWord.status);

    // 保存学习进度
    _progress.updateWordsStudied(1, _isCorrect);
    // 保存进度到数据库
    await DataManager.instance.saveStudyProgress(_progress);

    // 检查容器是否为空
    if (_studyContainer.isEmpty) {
      // 容器为空时触发拼写测试
      _startSpellingTest();
    } else {
      // 从容器中随机抽取一个单词
      _shuffleContainer();

      // 切换到下一个单词
      setState(() {
        _initMeaningOptions();
        _isAnimating = false; // 重置动画状态
        _animationController.reset(); // 重置动画控制器
      });

      // 自动播放发音
      if (_settings.autoPlayPronunciation) {
        _speakWord(_currentWord.word);
      }
    }
  }

  // 开始拼写测试
  void _startSpellingTest() {
    setState(() {
      _isSpellingTest = true;
      _spellingTestIndex = 0;
      _spellingInput = '';
      _showCorrectSpelling = false;
    });
  }

  // 下一个拼写测试单词
  void _nextSpellingTestWord() {
    setState(() {
      _spellingTestIndex++;
      _spellingInput = '';
      _showCorrectSpelling = false;

      // 检查是否完成所有拼写测试
      if (_spellingTestIndex >= _originalContainer.length) {
        _endSpellingTest();
      }
    });
  }

  // 结束拼写测试
  void _endSpellingTest() {
    setState(() {
      _isSpellingTest = false;
    });

    // 显示学习小结
    _showStudySummary();
  }

  // 检查拼写
  void _checkSpelling() {
    if (_spellingTestIndex < _originalContainer.length) {
      final currentTestWord = _originalContainer[_spellingTestIndex];
      if (_spellingInput.toLowerCase() == currentTestWord.word.toLowerCase()) {
        // 拼写正确，进入下一个单词
        _nextSpellingTestWord();
      } else {
        // 拼写错误，显示正确拼写，然后要求用户重新拼写
        setState(() {
          _showCorrectSpelling = true;
          // 重置输入，让用户重新拼写
          _spellingInput = '';
        });
      }
    }
  }

  // 显示学习小结
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
                      _buildSummaryItem(
                        '总单词数',
                        _originalContainer.length.toString(),
                      ),
                      _buildSummaryItem('掌握单词', '${_masteredWords.length}'),
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
            // 单词表格
            Container(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('单词')),
                    DataColumn(label: Text('音标')),
                    DataColumn(label: Text('释义')),
                    DataColumn(label: Text('掌握情况')),
                    DataColumn(label: Text('下次复习')),
                  ],
                  rows: _originalContainer.map((word) {
                    bool isMastered = _masteredWords.contains(word);
                    String reviewTime = _calculateReviewTime(word);
                    return DataRow(
                      cells: [
                        DataCell(Text(word.word)),
                        DataCell(Text(word.phonetic ?? '')),
                        DataCell(Text(word.meaning)),
                        DataCell(Text(isMastered ? '已掌握' : '学习中')),
                        DataCell(Text(reviewTime)),
                      ],
                    );
                  }).toList(),
                ),
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
                      Navigator.pop(context); // 返回上一页
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
                      // 重新初始化容器
                      _initStudyContainer();
                      setState(() {
                        _initMeaningOptions();
                      });
                      // 自动播放发音
                      if (_settings.autoPlayPronunciation &&
                          _studyContainer.isNotEmpty) {
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

  // 计算单词的下次复习时间
  String _calculateReviewTime(Word word) {
    if (word.status == StudyStatus.mastered) {
      // 已掌握的单词，3天后复习
      return '3天后';
    } else if (word.status == StudyStatus.familiar) {
      // 熟悉的单词，1天后复习
      return '1天后';
    } else {
      // 学习中的单词，今天复习
      return '今天';
    }
  }

  // 显示收藏状态变化的提示
  void _showFavoriteToast(bool isFavorite) {
    // 这里可以实现一个简单的Toast提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorite ? '已添加到收藏' : '已从收藏中移除'),
        duration: Duration(seconds: 1),
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
                '学习选项',
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
                Colors.blue,
              ),

              SizedBox(height: 15),

              // 按钮2
              _buildMenuButton('收藏该单词', () {
                setState(() {
                  _currentWord.toggleFavorite();
                  // 保存单词状态到数据库
                  DataManager.instance.saveWord(_currentWord);
                  _showFavoriteToast(_currentWord.isFavorite);
                });
                Navigator.pop(context);
              }, Colors.purple),

              SizedBox(height: 15),

              // 按钮3
              _buildMenuButton('查看详细释义', () {
                _showWordDetails();
                Navigator.pop(context);
              }, Colors.green),

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    // 检查当前单词表是否为空
    if (_originalContainer.isEmpty) {
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

    // 拼写测试界面
    if (_isSpellingTest) {
      if (_spellingTestIndex >= _originalContainer.length) {
        // 拼写测试完成，显示学习小结
        _endSpellingTest();
        return Container();
      }

      final currentTestWord = _originalContainer[_spellingTestIndex];

      return Scaffold(
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
                          setState(() {
                            _isSpellingTest = false;
                          });
                        },
                      ),

                      // 进度指示器
                      Text(
                        '拼写测试 ${_spellingTestIndex + 1}/${_originalContainer.length}',
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

                // 拼写测试内容
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 单词释义
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          children: [
                            Text(
                              '请拼写以下单词:',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              currentTestWord.meaning,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 40),

                            // 发音按钮
                            IconButton(
                              icon: Icon(Icons.volume_up, size: 40),
                              onPressed: () => _speakWord(currentTestWord.word),
                              color: Colors.orange,
                            ),
                            SizedBox(height: 40),

                            // 正确拼写提示
                            if (_showCorrectSpelling)
                              Container(
                                padding: EdgeInsets.all(15),
                                margin: EdgeInsets.symmetric(horizontal: 40),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '正确拼写: ${currentTestWord.word}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            SizedBox(height: 20),

                            // 拼写输入框
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: TextField(
                                onChanged: (value) {
                                  setState(() {
                                    _spellingInput = value;
                                  });
                                },
                                onSubmitted: (value) {
                                  _checkSpelling();
                                },
                                decoration: InputDecoration(
                                  hintText: '请输入单词拼写',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                ),
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                            SizedBox(height: 30),

                            // 检查按钮
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _checkSpelling,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 15),
                                ),
                                child: Text(
                                  '检查拼写',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
              ],
            ),
          ),
        ),
      );
    }

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
                      '学习 ${_originalContainer.length - _studyContainer.length}/${_originalContainer.length}',
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

              // 单词进度信息
              Container(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '连续答对: ${_continuousCorrectCount[_currentWord.id] ?? 0}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '还需答对: ${3 - (_continuousCorrectCount[_currentWord.id] ?? 0)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
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
                            // 保存单词状态到数据库
                            DataManager.instance.saveWord(_currentWord);

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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '例句',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              _currentWord.example!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                                fontStyle: FontStyle.italic,
                              ),
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
}
