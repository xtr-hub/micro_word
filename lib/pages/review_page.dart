import 'dart:async';
import 'package:flutter/material.dart';
import '../models/word.dart';
import '../models/word_storage.dart';
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

class _ReviewPageState extends State<ReviewPage> {
  // 单词数据
  late List<Word> _words;
  int _currentIndex = 0;
  bool _isLoading = true;

  // 学习相关
  late StudyProgress _progress;
  late Settings _settings;

  // 当前选择的状态
  StudyStatus _selectedStatus = StudyStatus.learning;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 加载数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    _words = await WordStorage.loadWords();
    _progress = await StudyProgress.load();
    _settings = await Settings.load();

    // 过滤出需要复习的单词
    _words = _words
        .where((word) => word.status == StudyStatus.familiar)
        .toList();

    // 如果没有单词，使用模拟数据
    if (_words.isEmpty) {
      _words = [
        Word(
          id: 1,
          word: 'beneficial',
          phonetic: '/ˌbenɪˈfɪʃl/',
          meaning: 'adj. 有益的，有利的',
          example: 'This medicine has a beneficial effect on the patient.',
          status: StudyStatus.familiar,
        ),
      ];
    }

    setState(() {
      _isLoading = false;
    });

    // 自动播放发音
    if (_settings.autoPlayPronunciation) {
      _speakWord(_words[_currentIndex].word);
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
    _words[_currentIndex].updateStatus(_selectedStatus);

    // 保存学习进度
    _progress.updateWordsStudied(1, _selectedStatus == StudyStatus.mastered);
    _progress.updateWordsReviewed(1);
    await WordStorage.saveWords(_words);
    await _progress.save();

    // 判断是否完成了所有复习
    if (_currentIndex == _words.length - 1) {
      // 完成了所有单词的复习，显示总结
      _showReviewSummary();
    } else {
      // 切换到下一个单词
      setState(() {
        _currentIndex = _currentIndex + 1;
        _selectedStatus = StudyStatus.learning;
      });

      // 自动播放发音
      if (_settings.autoPlayPronunciation) {
        _speakWord(_words[_currentIndex].word);
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
                      _buildSummaryItem('完成复习', '${_currentIndex + 1}'),
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
          // 返回主页
          TextButton(
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
            child: Text('返回'),
          ),
          // 继续复习
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 关闭对话框
              // 重新开始复习
              _loadData();
            },
            child: Text('继续复习'),
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

    final currentWord = _words[_currentIndex];

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
                      '${_currentIndex + 1}/${_words.length}',
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
                            onTap: () => _speakWord(currentWord.word),
                            child: Text(
                              currentWord.word,
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
                            currentWord.phonetic ?? '',
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
                            onPressed: () => _speakWord(currentWord.word),
                            color: Colors.orange,
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
                () => _speakWord(_words[_currentIndex].word),
                Colors.green,
              ),

              SizedBox(height: 15),

              // 按钮2
              _buildMenuButton('收藏该单词', () {
                _words[_currentIndex].toggleFavorite();
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
    final currentWord = _words[_currentIndex];
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
}
