import 'dart:async';
import 'package:flutter/material.dart';
import '../models/word.dart';
import '../models/word_storage.dart';
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

class _StudyPageState extends State<StudyPage> {
  // 单词数据
  late List<Word> _words;
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showAnswer = false;
  bool _isCorrect = false;

  // 学习相关
  late StudyProgress _progress;
  late Settings _settings;

  // 释义选项
  List<String> _meaningOptions = [];
  int _selectedOption = -1;

  // 模拟数据（实际应从单词数据中生成）
  final List<String> _fakeMeanings = [
    "adj. 好斗的，有侵略性的；进取的",
    "vt. 加重，使恶化；激怒，使恼火",
    "adj. 进步的；逐步发生的；进行式的",
    "adj. 过分的，过多的",
  ];

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

    // 如果没有单词，使用模拟数据
    if (_words.isEmpty) {
      _words = [
        Word(
          id: 1,
          word: 'aggressive',
          phonetic: '/əˈɡresɪv/',
          meaning: 'adj. 好斗的，有侵略性的；进取的',
          example: 'He has an aggressive personality.',
        ),
      ];
    }

    // 初始化释义选项
    _initMeaningOptions();

    setState(() {
      _isLoading = false;
    });

    // 自动播放发音
    if (_settings.autoPlayPronunciation) {
      _speakWord(_words[_currentIndex].word);
    }
  }

  // 初始化释义选项
  void _initMeaningOptions() {
    // 实际应用中，这里应该从单词数据中生成释义选项
    // 包括正确释义和几个干扰项
    _meaningOptions = List.from(_fakeMeanings);
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
      _isCorrect = index == 0; // 假设第一个选项是正确的
    });

    // 更新单词学习状态
    if (_isCorrect) {
      _words[_currentIndex].updateStatus(StudyStatus.familiar);
    } else {
      _words[_currentIndex].updateStatus(StudyStatus.learning);
    }
  }

  // 下一个单词
  void _nextWord() async {
    // 保存学习进度
    _progress.updateWordsStudied(1, _isCorrect);
    await WordStorage.saveWords(_words);
    await _progress.save();

    // 判断是否完成了一组学习
    if (_currentIndex == _words.length - 1) {
      // 完成了所有单词的学习，显示总结
      _showStudySummary();
    } else {
      // 切换到下一个单词
      setState(() {
        _currentIndex = _currentIndex + 1;
        _initMeaningOptions();
      });

      // 自动播放发音
      if (_settings.autoPlayPronunciation) {
        _speakWord(_words[_currentIndex].word);
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
                      _buildSummaryItem('学习完成', '${_currentIndex + 1}'),
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
          // 继续学习
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 关闭对话框
              // 重新开始学习
              setState(() {
                _currentIndex = 0;
                _initMeaningOptions();
              });
              // 自动播放发音
              if (_settings.autoPlayPronunciation) {
                _speakWord(_words[_currentIndex].word);
              }
            },
            child: Text('继续学习'),
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

    final currentWord = _words[_currentIndex];

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
                      '${_currentIndex + 1}/5',
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

                    // 释义选项
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // 提示文字
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(left: 20, bottom: 15),
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
              ),

              // 底部两个功能按钮
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
                            bool wasFavorite = _words[_currentIndex].isFavorite;
                            _words[_currentIndex].toggleFavorite();
                            WordStorage.saveWords(_words);

                            // 显示收藏状态变化的提示
                            _showFavoriteToast(!wasFavorite);
                          });
                        },
                        child: Container(
                          height: 55,
                          margin: EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: _words[_currentIndex].isFavorite
                                ? Colors.purple
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (_words[_currentIndex].isFavorite
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
                                key: ValueKey<bool>(
                                  _words[_currentIndex].isFavorite,
                                ),
                                _words[_currentIndex].isFavorite
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
    final isCorrect = index == 0;
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

  // 显示正确答案
  void _showCorrectAnswer() {
    setState(() {
      _showAnswer = true;
      _selectedOption = 0;
      _isCorrect = true;
    });
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
                () => _speakWord(_words[_currentIndex].word),
                Colors.green,
              ),

              SizedBox(height: 15),

              // 按钮3
              _buildMenuButton('收藏该单词', () {
                _words[_currentIndex].toggleFavorite();
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
}
