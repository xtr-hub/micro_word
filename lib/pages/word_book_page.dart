import 'package:flutter/material.dart'; // Flutter UI组件库
import '../models/word.dart'; // 单词数据模型
import '../models/word_storage.dart'; // 单词存储服务
import '../services/audio_service.dart'; // 音频播放服务

/// 单词本页面
///
/// 功能：
/// - 展示所有单词列表
/// - 支持按单词或释义搜索
/// - 支持按学习状态过滤
/// - 支持只显示收藏单词
/// - 支持多种排序方式
/// - 支持添加、编辑、删除单词
/// - 支持播放单词发音
/// - 支持切换单词收藏状态
class WordBookPage extends StatefulWidget {
  /// 创建页面状态对象
  @override
  _WordBookPageState createState() => _WordBookPageState();
}

/// WordBookPage 的状态管理类
class _WordBookPageState extends State<WordBookPage> {
  /// 所有单词列表
  late List<Word> _words;

  /// 过滤后的单词列表（根据搜索、状态过滤和收藏过滤）
  late List<Word> _filteredWords;

  /// 搜索关键词
  String _searchKeyword = '';

  /// 学习状态过滤条件（可选）
  StudyStatus? _selectedStatusFilter;

  /// 是否只显示收藏的单词
  bool _showOnlyFavorites = false;

  /// 数据加载状态
  bool _isLoading = true;

  /// 当前排序方式
  SortOption _sortOption = SortOption.word;

  /// 页面初始化时调用
  @override
  void initState() {
    super.initState();
    // 加载单词数据
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

  /// 加载单词数据
  ///
  /// 从本地存储加载所有单词，并初始化过滤和排序
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true; // 开始加载，显示加载指示器
    });

    // 从本地存储加载所有单词
    _words = await WordStorage.loadWords();
    // 初始化过滤后的单词列表为所有单词
    _filteredWords = List.from(_words);
    // 对单词列表进行排序
    _sortWords();

    setState(() {
      _isLoading = false; // 加载完成，隐藏加载指示器
    });
  }

  /// 搜索单词
  ///
  /// 根据关键词过滤单词列表
  /// 参数：
  /// - keyword: 搜索关键词
  void _searchWords(String keyword) {
    setState(() {
      _searchKeyword = keyword; // 更新搜索关键词
      _applyFilters(); // 应用过滤条件
    });
  }

  /// 应用过滤条件
  ///
  /// 根据搜索关键词、学习状态过滤和收藏过滤，更新过滤后的单词列表
  void _applyFilters() {
    // 使用where方法过滤单词列表
    _filteredWords = _words.where((word) {
      // 检查是否匹配搜索关键词（不区分大小写）
      final matchesSearch =
          word.word.toLowerCase().contains(_searchKeyword.toLowerCase()) ||
          word.meaning.toLowerCase().contains(_searchKeyword.toLowerCase());

      // 检查是否匹配学习状态过滤（如果没有设置过滤条件，则全部匹配）
      final matchesStatus =
          _selectedStatusFilter == null || word.status == _selectedStatusFilter;

      // 检查是否匹配收藏过滤（如果不是只显示收藏，则全部匹配）
      final matchesFavorite = !_showOnlyFavorites || word.isFavorite;

      // 只有同时满足所有过滤条件的单词才会被保留
      return matchesSearch && matchesStatus && matchesFavorite;
    }).toList();

    // 对过滤后的单词列表进行排序
    _sortWords();
  }

  /// 对单词列表进行排序
  ///
  /// 根据当前选择的排序方式对过滤后的单词列表进行排序
  void _sortWords() {
    switch (_sortOption) {
      case SortOption.word:
        // 按单词字母顺序排序
        _filteredWords.sort((a, b) => a.word.compareTo(b.word));
        break;
      case SortOption.lastStudyTime:
        // 按最后学习时间排序（最近学习的在前）
        _filteredWords.sort(
          (a, b) => b.lastStudyTime.compareTo(a.lastStudyTime),
        );
        break;
      case SortOption.memoryStrength:
        // 按记忆强度排序（记忆强度高的在前）
        _filteredWords.sort(
          (a, b) => b.memoryStrength.compareTo(a.memoryStrength),
        );
        break;
    }
  }

  /// 设置学习状态过滤条件
  ///
  /// 参数：
  /// - status: 要设置的学习状态过滤条件（可选）
  void _setStatusFilter(StudyStatus? status) {
    setState(() {
      _selectedStatusFilter = status; // 更新学习状态过滤条件
      _applyFilters(); // 应用过滤条件
    });
  }

  /// 设置排序方式
  ///
  /// 参数：
  /// - option: 要设置的排序方式
  void _setSortOption(SortOption? option) {
    if (option != null) {
      setState(() {
        _sortOption = option; // 更新排序方式
        _sortWords(); // 重新排序
      });
    }
  }

  /// 删除单词
  ///
  /// 弹出确认对话框，确认后删除指定ID的单词
  /// 参数：
  /// - id: 要删除的单词ID
  void _deleteWord(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除单词'),
        content: Text('确定要删除这个单词吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // 取消删除
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final currentContext = context;
              Navigator.pop(currentContext); // 关闭对话框
              // 从单词列表中移除指定ID的单词
              _words.removeWhere((word) => word.id == id);
              // 保存更新后的单词列表到本地存储
              await WordStorage.saveWords(_words);
              // 重新加载数据
              _loadData();
            },
            child: Text('删除'),
            style: TextButton.styleFrom(foregroundColor: Colors.red), // 红色文本
          ),
        ],
      ),
    );
  }

  /// 编辑单词
  ///
  /// 弹出编辑对话框，允许用户修改单词信息
  /// 参数：
  /// - word: 要编辑的单词对象
  void _editWord(Word word) {
    // 创建文本控制器，初始化值为单词的当前值
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
            // 允许内容滚动
            child: Column(
              mainAxisSize: MainAxisSize.min, // 最小化高度
              children: [
                // 英文单词输入框
                TextField(
                  controller: wordController,
                  decoration: const InputDecoration(labelText: '英文单词'),
                ),
                // 中文释义输入框
                TextField(
                  controller: meaningController,
                  decoration: const InputDecoration(labelText: '中文释义'),
                ),
                // 音标输入框
                TextField(
                  controller: phoneticController,
                  decoration: const InputDecoration(labelText: '音标'),
                ),
                // 例句输入框（支持多行输入）
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
                Navigator.pop(dialogContext); // 取消编辑
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                // 创建更新后的单词对象
                final updatedWord = Word(
                  id: word.id, // 保留原ID
                  word: wordController.text.trim(), // 英文单词
                  meaning: meaningController.text.trim(), // 中文释义
                  phonetic: phoneticController.text.trim(), // 音标
                  example: exampleController.text.trim(), // 例句
                  status: word.status, // 保留原学习状态
                  lastStudyTime: word.lastStudyTime, // 保留原学习时间
                  memoryStrength: word.memoryStrength, // 保留原记忆强度
                  isFavorite: word.isFavorite, // 保留原收藏状态
                );

                // 查找原单词在列表中的索引
                final index = _words.indexWhere((w) => w.id == word.id);
                // 先关闭对话框，再执行异步操作
                Navigator.pop(dialogContext);

                if (index != -1) {
                  // 更新单词列表
                  _words[index] = updatedWord;
                  // 保存更新后的单词列表到本地存储
                  await WordStorage.saveWords(_words);
                  // 重新加载数据
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

  /// 切换单词收藏状态
  ///
  /// 翻转单词的收藏状态并保存到本地存储
  /// 参数：
  /// - word: 要切换收藏状态的单词对象
  void _toggleFavorite(Word word) async {
    // 创建更新后的单词对象，翻转收藏状态
    final updatedWord = Word(
      id: word.id,
      word: word.word,
      meaning: word.meaning,
      phonetic: word.phonetic,
      example: word.example,
      status: word.status,
      lastStudyTime: word.lastStudyTime,
      memoryStrength: word.memoryStrength,
      isFavorite: !word.isFavorite, // 翻转收藏状态
    );

    // 查找原单词在列表中的索引
    final index = _words.indexWhere((w) => w.id == word.id);
    if (index != -1) {
      // 更新单词列表
      _words[index] = updatedWord;
      // 保存更新后的单词列表到本地存储
      await WordStorage.saveWords(_words);
      setState(() {
        _applyFilters(); // 重新应用过滤条件
      });
    }
  }

  /// 添加新单词
  ///
  /// 弹出添加对话框，允许用户输入新单词信息
  void _addNewWord() {
    // 创建文本控制器，初始值为空
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
            // 允许内容滚动
            child: Column(
              mainAxisSize: MainAxisSize.min, // 最小化高度
              children: [
                // 英文单词输入框
                TextField(
                  controller: wordController,
                  decoration: const InputDecoration(labelText: '英文单词'),
                ),
                // 中文释义输入框
                TextField(
                  controller: meaningController,
                  decoration: const InputDecoration(labelText: '中文释义'),
                ),
                // 音标输入框
                TextField(
                  controller: phoneticController,
                  decoration: const InputDecoration(labelText: '音标'),
                ),
                // 例句输入框（支持多行输入）
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
                Navigator.pop(dialogContext); // 取消添加
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                // 创建新单词对象
                final newWord = Word(
                  id: DateTime.now().millisecondsSinceEpoch, // 使用当前时间戳作为ID
                  word: wordController.text.trim(), // 英文单词
                  meaning: meaningController.text.trim(), // 中文释义
                  phonetic: phoneticController.text.trim(), // 音标
                  example: exampleController.text.trim(), // 例句
                  isFavorite: false, // 初始为未收藏
                );

                // 先关闭对话框，再执行异步操作
                Navigator.pop(dialogContext);

                // 保存新单词到本地存储
                await WordStorage.addWord(newWord);
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

  /// 构建页面UI
  @override
  Widget build(BuildContext context) {
    // 加载状态下显示加载指示器
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    // 构建完整的单词本页面
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        // 堆叠布局，用于放置浮动按钮
        children: [
          Column(
            children: [
              // 搜索栏
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: TextField(
                  onChanged: _searchWords, // 搜索关键词变化时调用
                  decoration: InputDecoration(
                    hintText: '搜索单词或释义', // 提示文本
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.blue.shade700,
                    ), // 搜索图标
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25), // 圆角
                      borderSide: BorderSide.none, // 无边框
                    ),
                    filled: true, // 填充背景
                    // 背景色：根据主题模式调整
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Color.fromRGBO(255, 255, 255, 0.9),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ), // 内边距
                    hintStyle: TextStyle(color: Colors.grey.shade400), // 提示文本样式
                  ),
                  style: TextStyle(
                    fontSize: 16, // 输入文本字体大小
                    color: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.color, // 输入文本颜色
                  ),
                ),
              ),

              // 过滤和排序选项
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Wrap(
                  spacing: 15, // 水平间距
                  runSpacing: 15, // 垂直间距
                  alignment: WrapAlignment.center, // 居中对齐
                  children: [
                    // 学习状态过滤
                    Container(
                      decoration: BoxDecoration(
                        // 背景色：根据主题模式调整
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Color.fromRGBO(255, 255, 255, 0.9),
                        borderRadius: BorderRadius.circular(20), // 圆角
                        boxShadow: [
                          // 阴影
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
                        child: DropdownButton<StudyStatus?>(
                          value: _selectedStatusFilter, // 当前选中的状态
                          hint: Text(
                            '所有状态',
                            style: TextStyle(color: Colors.grey.shade600),
                          ), // 提示文本
                          onChanged: _setStatusFilter, // 选择变化时的回调
                          items: [
                            // 全部状态选项
                            DropdownMenuItem(
                              value: null,
                              child: Text(
                                '所有状态',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                            // 各个学习状态选项
                            ...StudyStatus.values.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(
                                  _getStatusText(status), // 状态文本
                                  style: TextStyle(
                                    color: _getStatusColor(status),
                                  ), // 状态颜色
                                ),
                              );
                            }),
                          ],
                          dropdownColor: // 下拉菜单背景色
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.white,
                          underline: SizedBox(), // 移除下划线
                          icon: Icon(
                            Icons.filter_list,
                            color: Colors.blue.shade700,
                          ), // 图标
                          style: TextStyle(fontSize: 16), // 文本样式
                        ),
                      ),
                    ),

                    // 收藏过滤
                    Container(
                      decoration: BoxDecoration(
                        // 背景色：收藏状态下显示黄色，否则根据主题模式调整
                        color: _showOnlyFavorites
                            ? Colors.yellow.shade100
                            : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade800
                                  : Color.fromRGBO(255, 255, 255, 0.9)),
                        borderRadius: BorderRadius.circular(20), // 圆角
                        boxShadow: [
                          // 阴影
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
                          // 图标颜色：收藏状态下显示红色，否则显示灰色
                          color: _showOnlyFavorites
                              ? Colors.red
                              : Colors.grey.shade600,
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() {
                            _showOnlyFavorites =
                                !_showOnlyFavorites; // 翻转收藏过滤状态
                            _applyFilters(); // 应用过滤条件
                          });
                        },
                        // 提示文本：根据收藏状态显示不同文本
                        tooltip: _showOnlyFavorites ? '显示全部单词' : '只显示收藏单词',
                      ),
                    ),

                    // 排序方式
                    Container(
                      decoration: BoxDecoration(
                        // 背景色：根据主题模式调整
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Color.fromRGBO(255, 255, 255, 0.9),
                        borderRadius: BorderRadius.circular(20), // 圆角
                        boxShadow: [
                          // 阴影
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
                        child: DropdownButton<SortOption>(
                          value: _sortOption, // 当前选中的排序方式
                          onChanged: _setSortOption, // 选择变化时的回调
                          items: SortOption.values.map((option) {
                            return DropdownMenuItem(
                              value: option,
                              child: Text(
                                _getSortOptionText(option), // 排序方式文本
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            );
                          }).toList(),
                          dropdownColor: // 下拉菜单背景色
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.white,
                          underline: SizedBox(), // 移除下划线
                          icon: Icon(
                            Icons.sort,
                            color: Colors.blue.shade700,
                          ), // 图标
                          style: TextStyle(fontSize: 16), // 文本样式
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 单词列表
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredWords.length, // 列表项数量
                  padding: EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ), // 内边距
                  itemBuilder: (context, index) {
                    final word = _filteredWords[index]; // 当前单词
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 8), // 垂直间距
                      decoration: BoxDecoration(
                        // 背景色：根据主题模式调整
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.white,
                        borderRadius: BorderRadius.circular(15), // 圆角
                        boxShadow: [
                          // 阴影
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
                        ), // 内边距
                        title: Text(
                          word.word, // 单词
                          style: TextStyle(
                            fontSize: 22, // 字体大小
                            fontWeight: FontWeight.bold, // 字体粗细
                            color: Colors.blue.shade700, // 字体颜色
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
                          children: [
                            SizedBox(height: 5), // 垂直间距
                            // 中文释义
                            Text(
                              word.meaning,
                              style: TextStyle(
                                fontSize: 18, // 字体大小
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color, // 字体颜色
                              ),
                            ),
                            // 音标（如果存在）
                            if (word.phonetic != null &&
                                word.phonetic!.isNotEmpty)
                              Text(
                                word.phonetic!,
                                style: TextStyle(
                                  fontSize: 16, // 字体大小
                                  color: Colors.purple.shade500, // 字体颜色
                                  fontStyle: FontStyle.italic, // 斜体
                                ),
                              ),
                          ],
                        ),
                        trailing: Wrap(
                          spacing: 10, // 水平间距
                          alignment: WrapAlignment.end, // 右对齐
                          children: [
                            // 音频播放按钮
                            _AnimatedPlayButton(
                              onPressed: () => _speakWord(word.word),
                              size: 28,
                              tooltip: '播放发音',
                            ),
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
                              padding: EdgeInsets.zero, // 移除默认内边距
                              constraints: BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ), // 最小尺寸
                            ),
                            // 学习状态标签
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ), // 内边距
                              decoration: BoxDecoration(
                                // 背景色：状态颜色的10%透明度
                                color: Color.fromRGBO(
                                  _getStatusColor(word.status).red,
                                  _getStatusColor(word.status).green,
                                  _getStatusColor(word.status).blue,
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(20), // 圆角
                              ),
                              child: Text(
                                _getStatusText(word.status), // 状态文本
                                style: TextStyle(
                                  color: _getStatusColor(word.status), // 状态颜色
                                  fontWeight: FontWeight.bold, // 粗体
                                  fontSize: 14, // 字体大小
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _editWord(word), // 点击编辑单词
                        onLongPress: () => _deleteWord(word.id), // 长按删除单词
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // 添加单词按钮
          Positioned(
            bottom: 25, // 底部距离
            right: 25, // 右侧距离
            child: GestureDetector(
              onTap: _addNewWord, // 点击添加新单词
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300), // 动画持续时间
                width: 65, // 宽度
                height: 65, // 高度
                decoration: BoxDecoration(
                  color: Colors.blue, // 背景色
                  borderRadius: BorderRadius.circular(32.5), // 圆形
                  boxShadow: [
                    // 阴影
                    BoxShadow(
                      color: Color.fromRGBO(0, 122, 255, 0.3),
                      spreadRadius: 8,
                      blurRadius: 15,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(Icons.add, size: 28, color: Colors.white), // 加号图标
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取学习状态的中文文本
  ///
  /// 参数：
  /// - status: 学习状态枚举值
  ///
  /// 返回：学习状态的中文描述
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

  /// 获取学习状态对应的颜色
  ///
  /// 参数：
  /// - status: 学习状态枚举值
  ///
  /// 返回：对应的颜色
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

  /// 获取排序选项的中文文本
  ///
  /// 参数：
  /// - option: 排序选项枚举值
  ///
  /// 返回：排序选项的中文描述
  String _getSortOptionText(SortOption option) {
    switch (option) {
      case SortOption.word:
        return '按单词排序';
      case SortOption.lastStudyTime:
        return '按学习时间';
      case SortOption.memoryStrength:
        return '按记忆强度';
    }
  }
}

/// 排序选项枚举
///
/// 定义了三种排序方式：
enum SortOption {
  word, // 按单词字母顺序排序
  lastStudyTime, // 按最后学习时间排序
  memoryStrength, // 按记忆强度排序
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
