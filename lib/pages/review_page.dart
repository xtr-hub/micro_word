import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/word.dart';
import '../models/word_storage.dart';
import '../models/word_list.dart';
import '../models/word_list_storage.dart';
import '../models/study_progress.dart';
import '../models/settings.dart';
import '../services/audio_service.dart';
import '../services/progress_persistence_service.dart';
import '../services/data_manager.dart';

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
  bool _isLoading = true;

  // 容器管理
  List<Word> _reviewContainer = []; // 复习容器
  List<Word> _originalContainer = []; // 原始容器（用于拼写测试）
  Map<int, int> _continuousCorrectCount = {}; // 单词ID -> 连续答对次数
  Random _random = Random();

  // 学习相关
  late StudyProgress _progress;
  late Settings _settings;

  // 当前选择的状态
  StudyStatus _selectedStatus = StudyStatus.learning;

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
    if (_reviewContainer.isEmpty) {
      // 如果容器为空，返回第一个单词作为默认值
      return _originalContainer.isNotEmpty
          ? _originalContainer.first
          : _words.isNotEmpty
          ? _words.first
          : Word(id: 0, word: 'empty', phonetic: '', meaning: '无单词');
    }
    return _reviewContainer[0];
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

  @override
  void dispose() {
    // 保存复习状态
    _saveReviewState();
    _animationController.dispose();
    super.dispose();
  }

  // 保存复习状态
  Future<void> _saveReviewState() async {
    if (_reviewContainer.isNotEmpty || _originalContainer.isNotEmpty) {
      await ProgressPersistenceService.instance.saveSessionState({
        'reviewContainer': _reviewContainer,
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

    // 尝试加载之前保存的复习状态
    final sessionState = await ProgressPersistenceService.instance
        .loadSessionState();
    bool hasSavedState = false;
    if (sessionState.containsKey('reviewContainer') &&
        sessionState['reviewContainer'] is List<Word>) {
      _reviewContainer = sessionState['reviewContainer'] as List<Word>;
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
      // 过滤出需要复习的单词（状态为 familiar 的单词）
      final reviewWords = _filteredWords
          .where((word) => word.status == StudyStatus.familiar)
          .toList();

      // 根据设置中的排序选项排序单词
      _sortWords(reviewWords);

      // 如果当前单词表中没有需要复习的单词，使用所有需要复习的单词
      final wordsToUse = reviewWords.isNotEmpty
          ? reviewWords
          : _words
                .where((word) => word.status == StudyStatus.familiar)
                .toList();

      // 初始化容器管理
      _initReviewContainer(wordsToUse);
    }

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
    if (_settings.autoPlayPronunciation && _reviewContainer.isNotEmpty) {
      _speakWord(_currentWord.word);
    }
  }

  // 初始化复习容器
  void _initReviewContainer(List<Word> wordsToUse) {
    // 清空容器
    _reviewContainer.clear();
    _originalContainer.clear();
    _continuousCorrectCount.clear();

    // 根据用户设置的复习分组大小决定容器大小
    int containerSize = _settings.reviewGroupSize;

    // 从排序后的单词列表中提取单词
    final targetWords = wordsToUse.isNotEmpty ? wordsToUse : _words;

    // 限制容器大小不超过可用单词数
    if (containerSize > targetWords.length) {
      containerSize = targetWords.length;
    }

    // 通过复习算法从单词表中筛选需要复习的单词
    for (int i = 0; i < containerSize; i++) {
      if (i < targetWords.length) {
        _reviewContainer.add(targetWords[i]);
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
    _reviewContainer.shuffle(_random);
  }

  // 随机抽取一个单词
  Word _randomlySelectWord() {
    if (_reviewContainer.isEmpty) {
      return _currentWord;
    }
    int randomIndex = _random.nextInt(_reviewContainer.length);
    return _reviewContainer[randomIndex];
  }

  // 排序单词
  void _sortWords(List<Word> words) {
    switch (_settings.sortOption) {
      case SortOption.word:
        words.sort((a, b) => a.word.compareTo(b.word));
        break;
      case SortOption.lastStudyTime:
        words.sort((a, b) => b.lastStudyTime.compareTo(a.lastStudyTime));
        break;
      case SortOption.memoryStrength:
        words.sort((a, b) => b.memoryStrength.compareTo(a.memoryStrength));
        break;
      case SortOption.shuffle:
        _shuffleWords(words);
        break;
    }
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
    // 保存单词状态到数据库
    await DataManager.instance.saveWord(_currentWord);

    // 记录复习详细信息
    bool isCorrect =
        _selectedStatus == StudyStatus.mastered ||
        _selectedStatus == StudyStatus.familiar;
    _progress.recordReview(_currentWord.id, isCorrect, _currentWord.status);

    // 保存学习进度
    _progress.updateWordsStudied(1, isCorrect);
    _progress.updateWordsReviewed(1);
    // 保存进度到数据库
    await DataManager.instance.saveStudyProgress(_progress);

    // 更新连续答对次数
    if (isCorrect) {
      // 递增连续答对次数
      int currentCount = _continuousCorrectCount[_currentWord.id] ?? 0;
      currentCount++;
      _continuousCorrectCount[_currentWord.id] = currentCount;

      // 当连续答对次数达到3时，自动将该单词从当前容器中移除
      if (currentCount >= 3) {
        _reviewContainer.remove(_currentWord);
        _masteredWords.add(_currentWord);
      }
    } else {
      // 答错时重置连续答对次数为0
      _continuousCorrectCount[_currentWord.id] = 0;
    }

    // 检查容器是否为空
    if (_reviewContainer.isEmpty) {
      // 容器为空时触发拼写测试
      _startSpellingTest();
    } else {
      // 从容器中随机抽取一个单词
      _shuffleContainer();

      // 切换到下一个单词
      setState(() {
        _selectedStatus = StudyStatus.learning;
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
    _showReviewSummary();
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
                      _buildSummaryItem(
                        '总单词数',
                        _originalContainer.length.toString(),
                      ),
                      _buildSummaryItem('掌握单词', '${_masteredWords.length}'),
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
                      Navigator.pop(context); // 返回上一页
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
                // 保存单词状态到数据库
                DataManager.instance.saveWord(_currentWord);
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    // 检查当前单词表中是否有需要复习的单词
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
                      '复习 ${_originalContainer.length - _reviewContainer.length}/${_originalContainer.length}',
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
}
