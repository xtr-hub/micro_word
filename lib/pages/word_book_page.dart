import 'package:flutter/material.dart';
import '../models/word.dart';
import '../models/word_storage.dart';
import '../models/word_list.dart';
import '../models/word_list_storage.dart';
import '../models/settings.dart';

// 单词本页面
class WordBookPage extends StatefulWidget {
  @override
  _WordBookPageState createState() => _WordBookPageState();
}

class _WordBookPageState extends State<WordBookPage> {
  // 单词列表
  late List<Word> _words;
  // 过滤后的单词列表
  late List<Word> _filteredWords;
  // 单词表列表
  late List<WordList> _wordLists;
  // 当前单词表
  late WordList _currentWordList;
  // 搜索关键词
  String _searchKeyword = '';
  // 学习状态过滤
  StudyStatus? _selectedStatusFilter;
  // 是否只显示收藏单词
  bool _showOnlyFavorites = false;
  // 是否加载中
  bool _isLoading = true;
  // 排序方式
  SortOption _sortOption = SortOption.word;
  // 乱序单词ID顺序
  List<int>? _shuffledWordIds;
  // 乱序状态是否已生成
  bool _isShuffleGenerated = false;
  // 设置
  late Settings _settings;

  @override
  void initState() {
    super.initState();
    // 初始化数据
    _loadData();
  }

  // 加载单词和单词表数据
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      // 重置乱序状态，因为单词数据可能发生变化
      _shuffledWordIds = null;
      _isShuffleGenerated = false;
    });

    // 并行加载单词和单词表数据
    final wordsFuture = WordStorage.loadWords();
    final wordListsFuture = WordListStorage.loadWordLists();
    final settingsFuture = Settings.load();

    final results = await Future.wait([
      wordsFuture,
      wordListsFuture,
      settingsFuture,
    ]);
    _words = results[0] as List<Word>;
    _wordLists = results[1] as List<WordList>;
    _settings = results[2] as Settings;

    // 从设置中读取排序选项
    _sortOption = _settings.sortOption;

    // 找到当前单词表
    _currentWordList = _wordLists.firstWhere(
      (wordList) => wordList.isCurrent,
      orElse: () => _wordLists.isNotEmpty
          ? _wordLists[0]
          : WordList(
              id: DateTime.now().millisecondsSinceEpoch,
              name: '默认单词表',
              isCurrent: true,
            ),
    );

    // 应用过滤条件
    _applyFilters();

    setState(() {
      _isLoading = false;
    });
  }

  // 搜索单词
  void _searchWords(String keyword) {
    setState(() {
      _searchKeyword = keyword;
      _applyFilters();
    });
  }

  // 应用过滤条件
  void _applyFilters() {
    _filteredWords = _words.where((word) {
      // 检查单词是否在当前单词表中
      final inCurrentWordList = _currentWordList.wordIds.contains(word.id);

      final matchesSearch =
          word.word.toLowerCase().contains(_searchKeyword.toLowerCase()) ||
          word.meaning.toLowerCase().contains(_searchKeyword.toLowerCase());

      final matchesStatus =
          _selectedStatusFilter == null || word.status == _selectedStatusFilter;

      final matchesFavorite = !_showOnlyFavorites || word.isFavorite;

      return inCurrentWordList &&
          matchesSearch &&
          matchesStatus &&
          matchesFavorite;
    }).toList();

    _sortWords();
  }

  // 排序单词
  void _sortWords() {
    switch (_sortOption) {
      case SortOption.word:
        _filteredWords.sort((a, b) => a.word.compareTo(b.word));
        break;
      case SortOption.lastStudyTime:
        _filteredWords.sort(
          (a, b) => b.lastStudyTime.compareTo(a.lastStudyTime),
        );
        break;
      case SortOption.memoryStrength:
        _filteredWords.sort(
          (a, b) => b.memoryStrength.compareTo(a.memoryStrength),
        );
        break;
      case SortOption.shuffle:
        _shuffleWords();
        break;
    }
  }

  // 乱序排序单词
  void _shuffleWords() {
    // 如果还没有生成乱序顺序，生成一个
    if (!_isShuffleGenerated) {
      // 获取当前单词表中的单词ID
      final wordIds = _filteredWords.map((word) => word.id).toList();
      // 打乱顺序
      wordIds.shuffle();
      // 保存乱序顺序
      _shuffledWordIds = wordIds;
      _isShuffleGenerated = true;
    }

    // 如果已经有乱序顺序，根据该顺序排序
    if (_shuffledWordIds != null) {
      _filteredWords.sort((a, b) {
        final indexA = _shuffledWordIds!.indexOf(a.id);
        final indexB = _shuffledWordIds!.indexOf(b.id);
        return indexA.compareTo(indexB);
      });
    }
  }

  // 切换单词表
  Future<void> _switchWordList(WordList wordList) async {
    // 更新单词表的当前状态
    for (final wl in _wordLists) {
      wl.isCurrent = wl.id == wordList.id;
    }

    // 保存更新后的单词表列表
    await WordListStorage.saveWordLists(_wordLists);

    // 更新当前单词表并重新加载数据
    setState(() {
      _currentWordList = wordList;
      // 重置乱序状态，因为不同单词表的乱序顺序应该不同
      _shuffledWordIds = null;
      _isShuffleGenerated = false;
    });

    // 重新应用过滤条件
    _applyFilters();
  }

  // 创建新单词表
  Future<void> _createWordList() async {
    // 显示输入对话框，让用户输入新单词表的名称
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        String? name;
        return AlertDialog(
          title: Text('创建新单词表'),
          content: TextField(
            onChanged: (value) => name = value,
            decoration: InputDecoration(labelText: '单词表名称'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, name),
              child: Text('创建'),
            ),
          ],
        );
      },
    );

    // 如果用户输入了名称且名称不为空
    if (newName != null && newName.trim().isNotEmpty) {
      // 创建新单词表
      final newWordList = WordList(
        id: DateTime.now().millisecondsSinceEpoch,
        name: newName.trim(),
        isCurrent: true, // 新单词表设为当前学习内容
      );

      // 添加新单词表
      await WordListStorage.addWordList(newWordList);

      // 重新加载数据
      await _loadData();
    }
  }

  // 编辑单词表
  Future<void> _editWordList(WordList wordList) async {
    // 显示输入对话框，让用户输入新的单词表名称
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        String? name = wordList.name;
        return AlertDialog(
          title: Text('编辑单词表'),
          content: TextField(
            onChanged: (value) => name = value,
            decoration: InputDecoration(labelText: '单词表名称'),
            controller: TextEditingController(text: wordList.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, name),
              child: Text('保存'),
            ),
          ],
        );
      },
    );

    // 如果用户输入了名称且名称不为空
    if (newName != null && newName.trim().isNotEmpty) {
      // 创建更新后的单词表
      final updatedWordList = WordList(
        id: wordList.id,
        name: newName.trim(),
        createdAt: wordList.createdAt,
        wordIds: wordList.wordIds,
        isCurrent: wordList.isCurrent,
      );

      // 更新单词表
      await WordListStorage.updateWordList(updatedWordList);

      // 重新加载数据
      await _loadData();
    }
  }

  // 删除单词表
  Future<void> _deleteWordList(WordList wordList) async {
    // 显示确认对话框
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('删除单词表'),
          content: Text('确定要删除单词表 "${wordList.name}" 吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('删除'),
            ),
          ],
        );
      },
    );

    // 如果用户确认删除
    if (confirm == true) {
      // 删除单词表
      await WordListStorage.deleteWordList(wordList.id);

      // 重新加载数据
      await _loadData();
    }
  }

  // 向单词表添加单词
  Future<void> _addWordToWordList(Word word) async {
    // 显示单词表选择对话框
    final selectedWordList = await showDialog<WordList>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('添加到单词表'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _wordLists.length,
              itemBuilder: (context, index) {
                final wl = _wordLists[index];
                final isAdded = wl.wordIds.contains(word.id);
                return ListTile(
                  title: Text(wl.name),
                  trailing: isAdded ? Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(context, wl),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
          ],
        );
      },
    );

    // 如果用户选择了单词表
    if (selectedWordList != null) {
      // 向单词表添加单词
      selectedWordList.addWord(word.id);

      // 更新单词表
      await WordListStorage.updateWordList(selectedWordList);

      // 重新加载数据
      await _loadData();
    }
  }

  // 从单词表移除单词
  Future<void> _removeWordFromWordList(Word word) async {
    // 从当前单词表移除单词
    _currentWordList.removeWord(word.id);

    // 更新单词表
    await WordListStorage.updateWordList(_currentWordList);

    // 重新加载数据
    await _loadData();
  }

  // 设置学习状态过滤
  void _setStatusFilter(StudyStatus? status) {
    setState(() {
      _selectedStatusFilter = status;
      _applyFilters();
    });
  }

  // 设置排序方式
  void _setSortOption(SortOption? option) async {
    if (option != null) {
      setState(() {
        _sortOption = option;
        _sortWords();
      });

      // 保存排序选项到设置
      _settings.sortOption = option;
      await _settings.save();
    }
  }

  // 删除单词
  void _deleteWord(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除单词'),
        content: Text('确定要删除这个单词吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final currentContext = context;
              Navigator.pop(currentContext);
              _words.removeWhere((word) => word.id == id);
              await WordStorage.saveWords(_words);
              _loadData();
            },
            child: Text('删除'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  // 编辑单词
  void _editWord(Word word) {
    final TextEditingController wordController = TextEditingController(
      text: word.word,
    );
    final TextEditingController meaningController = TextEditingController(
      text: word.meaning,
    );
    final TextEditingController phoneticController = TextEditingController(
      text: word.phonetic,
    );
    final TextEditingController exampleController = TextEditingController(
      text: word.example,
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('编辑单词'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: wordController,
                  decoration: const InputDecoration(labelText: '英文单词'),
                ),
                TextField(
                  controller: meaningController,
                  decoration: const InputDecoration(labelText: '中文释义'),
                ),
                TextField(
                  controller: phoneticController,
                  decoration: const InputDecoration(labelText: '音标'),
                ),
                TextField(
                  controller: exampleController,
                  decoration: const InputDecoration(labelText: '例句'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final updatedWord = Word(
                  id: word.id,
                  word: wordController.text.trim(),
                  meaning: meaningController.text.trim(),
                  phonetic: phoneticController.text.trim(),
                  example: exampleController.text.trim(),
                  status: word.status,
                  lastStudyTime: word.lastStudyTime,
                  memoryStrength: word.memoryStrength,
                  isFavorite: word.isFavorite,
                );

                final index = _words.indexWhere((w) => w.id == word.id);
                // 先关闭对话框，再执行异步操作
                Navigator.pop(dialogContext);

                if (index != -1) {
                  _words[index] = updatedWord;
                  await WordStorage.saveWords(_words);
                  _loadData();
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  // 切换单词收藏状态
  void _toggleFavorite(Word word) async {
    final updatedWord = Word(
      id: word.id,
      word: word.word,
      meaning: word.meaning,
      phonetic: word.phonetic,
      example: word.example,
      status: word.status,
      lastStudyTime: word.lastStudyTime,
      memoryStrength: word.memoryStrength,
      isFavorite: !word.isFavorite,
    );

    final index = _words.indexWhere((w) => w.id == word.id);
    if (index != -1) {
      _words[index] = updatedWord;
      await WordStorage.saveWords(_words);
      setState(() {
        _applyFilters();
      });
    }
  }

  // 添加新单词
  void _addNewWord() {
    final TextEditingController wordController = TextEditingController();
    final TextEditingController meaningController = TextEditingController();
    final TextEditingController phoneticController = TextEditingController();
    final TextEditingController exampleController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('添加新单词'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: wordController,
                  decoration: const InputDecoration(labelText: '英文单词'),
                ),
                TextField(
                  controller: meaningController,
                  decoration: const InputDecoration(labelText: '中文释义'),
                ),
                TextField(
                  controller: phoneticController,
                  decoration: const InputDecoration(labelText: '音标'),
                ),
                TextField(
                  controller: exampleController,
                  decoration: const InputDecoration(labelText: '例句'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final newWord = Word(
                  id: DateTime.now().millisecondsSinceEpoch,
                  word: wordController.text.trim(),
                  meaning: meaningController.text.trim(),
                  phonetic: phoneticController.text.trim(),
                  example: exampleController.text.trim(),
                  isFavorite: false,
                );

                // 先关闭对话框，再执行异步操作
                Navigator.pop(dialogContext);

                // 添加单词到存储
                await WordStorage.addWord(newWord);

                // 将新单词添加到当前单词表
                _currentWordList.addWord(newWord.id);
                await WordListStorage.updateWordList(_currentWordList);

                // 重新加载数据
                _loadData();
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              // 单词表管理
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Color.fromRGBO(255, 255, 255, 0.9),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(128, 128, 128, 0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: DropdownButton<WordList>(
                      value: _currentWordList,
                      hint: Text('选择单词表'),
                      onChanged: (selectedWordList) {
                        if (selectedWordList != null) {
                          _switchWordList(selectedWordList);
                        } else {
                          // 创建新单词表
                          _createWordList();
                        }
                      },
                      items: [
                        ..._wordLists.map((wordList) {
                          return DropdownMenuItem(
                            value: wordList,
                            child: Text(wordList.name),
                          );
                        }),
                        // 添加创建新单词表的选项
                        DropdownMenuItem(value: null, child: Text('+ 创建新单词表')),
                      ],
                      dropdownColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade800
                          : Colors.white,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.blue.shade700,
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      isExpanded: true,
                      underline: Container(),
                      onTap: () {
                        // 这里可以添加一些逻辑，比如刷新单词表列表
                      },
                    ),
                  ),
                ),
              ),

              // 搜索栏
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: TextField(
                  onChanged: _searchWords,
                  decoration: InputDecoration(
                    hintText: '搜索单词或释义',
                    prefixIcon: Icon(Icons.search, color: Colors.blue.shade700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Color.fromRGBO(255, 255, 255, 0.9),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),

              // 过滤和排序选项
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  alignment: WrapAlignment.center,
                  children: [
                    // 学习状态过滤
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Color.fromRGBO(255, 255, 255, 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(128, 128, 128, 0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: SizedBox(
                          width: 120,
                          child: DropdownButtonFormField<StudyStatus?>(
                            value: _selectedStatusFilter,
                            hint: Text(
                              '所有状态',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            onChanged: _setStatusFilter,
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text(
                                  '所有状态',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                              ...StudyStatus.values.map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(
                                    _getStatusText(status),
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                    ),
                                  ),
                                );
                              }),
                            ],
                            dropdownColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.white,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                            icon: Icon(
                              Icons.filter_list,
                              color: Colors.blue.shade700,
                            ),
                            style: TextStyle(fontSize: 14),
                            isExpanded: false,
                          ),
                        ),
                      ),
                    ),

                    // 收藏过滤
                    Container(
                      decoration: BoxDecoration(
                        color: _showOnlyFavorites
                            ? Colors.yellow.shade100
                            : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade800
                                  : Color.fromRGBO(255, 255, 255, 0.9)),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(128, 128, 128, 0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.favorite,
                          color: _showOnlyFavorites
                              ? Colors.red
                              : Colors.grey.shade600,
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() {
                            _showOnlyFavorites = !_showOnlyFavorites;
                            _applyFilters();
                          });
                        },
                        tooltip: _showOnlyFavorites ? '显示全部单词' : '只显示收藏单词',
                      ),
                    ),

                    // 排序方式
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Color.fromRGBO(255, 255, 255, 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(128, 128, 128, 0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: SizedBox(
                          width: 120,
                          child: DropdownButtonFormField<SortOption>(
                            value: _sortOption,
                            onChanged: _setSortOption,
                            items: SortOption.values.map((option) {
                              return DropdownMenuItem(
                                value: option,
                                child: Text(
                                  _getSortOptionText(option),
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              );
                            }).toList(),
                            dropdownColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.white,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                            icon: Icon(Icons.sort, color: Colors.blue.shade700),
                            style: TextStyle(fontSize: 14),
                            isExpanded: false,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 单词列表
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredWords.length,
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  itemBuilder: (context, index) {
                    final word = _filteredWords[index];
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.white,
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
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        title: Text(
                          word.word,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 5),
                            Text(
                              word.meaning,
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                              ),
                            ),
                            if (word.phonetic != null &&
                                word.phonetic!.isNotEmpty)
                              Text(
                                word.phonetic!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.purple.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 收藏按钮
                            IconButton(
                              icon: Icon(
                                word.isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: word.isFavorite
                                    ? Colors.red
                                    : Colors.grey.shade400,
                                size: 28,
                              ),
                              onPressed: () => _toggleFavorite(word),
                              tooltip: word.isFavorite ? '取消收藏' : '收藏单词',
                            ),
                            SizedBox(width: 10),
                            // 单词表操作按钮
                            IconButton(
                              icon: Icon(
                                Icons.list,
                                color: Colors.blue.shade700,
                                size: 24,
                              ),
                              onPressed: () {
                                // 显示单词表操作菜单
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) {
                                    return Container(
                                      padding: EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            leading: Icon(Icons.add),
                                            title: Text('添加到其他单词表'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _addWordToWordList(word);
                                            },
                                          ),
                                          ListTile(
                                            leading: Icon(Icons.remove),
                                            title: Text('从当前单词表移除'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _removeWordFromWordList(word);
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              tooltip: '单词表操作',
                            ),
                            SizedBox(width: 10),
                            // 学习状态
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(
                                  _getStatusColor(word.status).red,
                                  _getStatusColor(word.status).green,
                                  _getStatusColor(word.status).blue,
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getStatusText(word.status),
                                style: TextStyle(
                                  color: _getStatusColor(word.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _editWord(word),
                        onLongPress: () => _deleteWord(word.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // 添加单词按钮
          Positioned(
            bottom: 25,
            right: 25,
            child: GestureDetector(
              onTap: _addNewWord,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(32.5),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 122, 255, 0.3),
                      spreadRadius: 8,
                      blurRadius: 15,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(Icons.add, size: 28, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 获取学习状态文本
  String _getStatusText(StudyStatus status) {
    switch (status) {
      case StudyStatus.newWord:
        return '新单词';
      case StudyStatus.learning:
        return '学习中';
      case StudyStatus.familiar:
        return '熟悉';
      case StudyStatus.mastered:
        return '已掌握';
      case StudyStatus.reviewed:
        return '已复习';
    }
  }

  // 获取学习状态颜色
  Color _getStatusColor(StudyStatus status) {
    switch (status) {
      case StudyStatus.newWord:
        return Colors.grey;
      case StudyStatus.learning:
        return Colors.red;
      case StudyStatus.familiar:
        return Colors.orange;
      case StudyStatus.mastered:
        return Colors.green;
      case StudyStatus.reviewed:
        return Colors.blue;
    }
  }

  // 获取排序选项文本
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
}
