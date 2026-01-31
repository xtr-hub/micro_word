import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../models/word_list.dart';
import '../models/word_list_storage.dart';
import '../models/word.dart';
import '../models/word_storage.dart';
import '../models/test_settings.dart';
import './test_page.dart';

/// 测试参数设置页面
///
/// 功能：
/// - 允许用户设置测试单词数量
/// - 允许用户选择测试范围（单词表）
/// - 支持上传自定义单词表文件
/// - 提供参数验证机制
class TestSettingsPage extends StatefulWidget {
  @override
  _TestSettingsPageState createState() => _TestSettingsPageState();
}

class _TestSettingsPageState extends State<TestSettingsPage> {
  /// 测试单词数量
  int _testWordCount = 10;

  /// 输入的测试单词数量文本
  TextEditingController _wordCountController = TextEditingController(
    text: '10',
  );

  /// 可用的单词表列表
  List<WordList> _wordLists = [];

  /// 选中的单词表
  WordList? _selectedWordList;

  /// 自定义单词表文件路径
  String? _customWordListPath;

  /// 数据加载状态
  bool _isLoading = true;

  /// 错误信息
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWordLists();
  }

  /// 加载单词表列表和测试设置
  Future<void> _loadWordLists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final wordLists = await WordListStorage.loadWordLists();

      // 加载测试设置
      final testSettings = await TestSettingsStorage.loadTestSettings();

      setState(() {
        _wordLists = wordLists;

        // 设置测试单词数量
        _testWordCount = testSettings.testWordCount;
        _wordCountController.text = testSettings.testWordCount.toString();

        // 设置自定义单词表路径
        _customWordListPath = testSettings.customWordListPath;

        // 选择单词表
        if (testSettings.selectedWordListId != null && wordLists.isNotEmpty) {
          _selectedWordList = wordLists.firstWhere(
            (list) => list.id == testSettings.selectedWordListId,
            orElse: () => wordLists.firstWhere(
              (list) => list.isCurrent,
              orElse: () => wordLists[0],
            ),
          );
        } else if (wordLists.isNotEmpty) {
          _selectedWordList = wordLists.firstWhere(
            (list) => list.isCurrent,
            orElse: () => wordLists[0],
          );
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载数据失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 验证测试单词数量
  Future<bool> _validateWordCount() async {
    try {
      final count = int.parse(_wordCountController.text);
      if (count <= 0) {
        setState(() {
          _errorMessage = '测试单词数量必须为正整数';
        });
        return false;
      }

      if (_selectedWordList != null) {
        final words = await _getWordsFromSelectedList();
        if (count > words.length) {
          setState(() {
            _errorMessage = '测试单词数量不能超过所选单词表的总单词数 (${words.length})';
          });
          return false;
        }
      }

      setState(() {
        _testWordCount = count;
        _errorMessage = null;
      });
      return true;
    } catch (e) {
      setState(() {
        _errorMessage = '请输入有效的数字';
      });
      return false;
    }
  }

  /// 从选中的单词表中获取单词列表
  Future<List<Word>> _getWordsFromSelectedList() async {
    final allWords = await WordStorage.loadWords();
    if (_selectedWordList != null) {
      return allWords
          .where((word) => _selectedWordList!.wordIds.contains(word.id))
          .toList();
    }
    return [];
  }

  /// 上传自定义单词表文件
  Future<void> _uploadCustomWordList() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: '选择单词表文件',
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _customWordListPath = result.files.single.path!;
          _selectedWordList = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '上传文件失败: $e';
      });
    }
  }

  /// 保存测试设置
  void _saveSettings() async {
    final isValid = await _validateWordCount();
    if (!isValid) return;

    if (_selectedWordList == null && _customWordListPath == null) {
      setState(() {
        _errorMessage = '请选择测试范围或上传自定义单词表';
      });
      return;
    }

    // 创建测试设置对象
    final testSettings = TestSettings(
      testWordCount: _testWordCount,
      customWordListPath: _customWordListPath,
    );

    // 保存测试设置
    final saveSuccess = await TestSettingsStorage.saveTestSettings(
      testSettings,
      _selectedWordList,
    );

    if (!saveSuccess) {
      setState(() {
        _errorMessage = '保存设置失败，请重试';
      });
      return;
    }

    // 显示保存成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('设置保存成功'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // 导航回测试页面，并传递更新后的测试参数
    final returnData = {
      'testWordCount': _testWordCount,
      'selectedWordList': _selectedWordList,
      'customWordListPath': _customWordListPath,
    };
    debugPrint('TestSettingsPage: 返回设置数据: $returnData');
    Navigator.pop(context, returnData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('测试设置'), backgroundColor: Colors.blue),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.blue))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 测试单词数量设置
                  _buildWordCountSetting(),
                  SizedBox(height: 30),

                  // 测试范围设置
                  _buildTestRangeSetting(),
                  SizedBox(height: 30),

                  // 错误信息显示
                  if (_errorMessage != null)
                    Container(
                      padding: EdgeInsets.all(15),
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),

                  // 保存设置按钮
                  _buildSaveSettingsButton(),
                ],
              ),
            ),
    );
  }

  /// 构建测试单词数量设置
  Widget _buildWordCountSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '测试单词数量',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _wordCountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '请输入测试单词数量',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              if (_errorMessage != null) {
                setState(() {
                  _errorMessage = null;
                });
              }
            },
          ),
        ),
        if (_selectedWordList != null)
          FutureBuilder<List<Word>>(
            future: _getWordsFromSelectedList(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '所选单词表共有 ${snapshot.data!.length} 个单词',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                );
              }
              return SizedBox();
            },
          ),
      ],
    );
  }

  /// 构建测试范围设置
  Widget _buildTestRangeSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '测试范围',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        SizedBox(height: 10),

        // 单词表选择
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<WordList>(
            value: _selectedWordList,
            hint: Text('请选择单词表'),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
            ),
            items: _wordLists.map((wordList) {
              return DropdownMenuItem<WordList>(
                value: wordList,
                child: Text(wordList.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedWordList = value;
                _customWordListPath = null;
                _errorMessage = null;
              });
            },
          ),
        ),
        SizedBox(height: 20),

        // 上传自定义单词表
        Text(
          '或上传自定义单词表',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
        SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _uploadCustomWordList,
          icon: Icon(Icons.upload_file),
          label: Text('上传单词表文件'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        if (_customWordListPath != null)
          Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              '已选择文件: ${_customWordListPath!.split('/').last}',
              style: TextStyle(fontSize: 14, color: Colors.green),
            ),
          ),
      ],
    );
  }

  /// 构建保存设置按钮
  Widget _buildSaveSettingsButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _saveSettings,
        child: Text(
          '保存设置',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
        ),
      ),
    );
  }
}
