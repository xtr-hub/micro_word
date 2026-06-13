import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/word.dart';
import '../models/word_list.dart';
import '../models/study_progress.dart';

class DataManager {
  static DataManager? _instance;
  static DataManager get instance => _instance ??= DataManager._();

  late Database _database;
  bool _isInitialized = false;

  DataManager._();

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 打开数据库
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'wei_dan_ci.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        // 创建单词表
        db.execute('''
          CREATE TABLE IF NOT EXISTS words (
            id INTEGER PRIMARY KEY,
            word TEXT NOT NULL,
            phonetic TEXT,
            meaning TEXT NOT NULL,
            example TEXT,
            exampleMeaning TEXT,
            status INTEGER DEFAULT 0
          )
        ''');

        // 创建单词表表
        db.execute('''
          CREATE TABLE IF NOT EXISTS word_lists (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            isCurrent INTEGER DEFAULT 0
          )
        ''');

        // 创建单词表-单词关联表
        db.execute('''
          CREATE TABLE IF NOT EXISTS word_list_words (
            wordListId INTEGER,
            wordId INTEGER,
            position INTEGER,
            PRIMARY KEY (wordListId, wordId),
            FOREIGN KEY (wordListId) REFERENCES word_lists (id),
            FOREIGN KEY (wordId) REFERENCES words (id)
          )
        ''');

        // 创建学习进度表
        db.execute('''
          CREATE TABLE IF NOT EXISTS study_progress (
            id INTEGER PRIMARY KEY,
            totalWordsStudied INTEGER DEFAULT 0,
            masteredWords INTEGER DEFAULT 0,
            consecutiveDays INTEGER DEFAULT 0,
            totalStudyTime INTEGER DEFAULT 0,
            dailyGoal INTEGER DEFAULT 10,
            lastStudyDate INTEGER DEFAULT 0
          )
        ''');

        // 插入默认学习进度
        db.execute('''
          INSERT INTO study_progress (id, totalWordsStudied, masteredWords, consecutiveDays, totalStudyTime, dailyGoal, lastStudyDate)
          VALUES (1, 0, 0, 0, 0, 10, 0)
        ''');
      },
    );

    _isInitialized = true;
    debugPrint('数据库初始化完成');
  }

  // 单词相关操作
  Future<List<Word>> getAllWords() async {
    await initialize();
    final List<Map<String, dynamic>> maps = await _database.query('words');
    return List.generate(maps.length, (i) {
      return Word(
        id: maps[i]['id'],
        word: maps[i]['word'],
        phonetic: maps[i]['phonetic'],
        meaning: maps[i]['meaning'],
        example: maps[i]['example'],
        exampleMeaning: maps[i]['exampleMeaning'],
        status: StudyStatus.values[maps[i]['status']],
      );
    });
  }

  Future<Word?> getWordById(int id) async {
    await initialize();
    final List<Map<String, dynamic>> maps = await _database.query(
      'words',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Word(
        id: maps[0]['id'],
        word: maps[0]['word'],
        phonetic: maps[0]['phonetic'],
        meaning: maps[0]['meaning'],
        example: maps[0]['example'],
        exampleMeaning: maps[0]['exampleMeaning'],
        status: StudyStatus.values[maps[0]['status']],
      );
    }
    return null;
  }

  Future<void> saveWord(Word word) async {
    await initialize();
    await _database.insert('words', {
      'id': word.id,
      'word': word.word,
      'phonetic': word.phonetic,
      'meaning': word.meaning,
      'example': word.example,
      'exampleMeaning': word.exampleMeaning,
      'status': word.status.index,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateWordStatus(int wordId, StudyStatus status) async {
    await initialize();
    await _database.update(
      'words',
      {'status': status.index},
      where: 'id = ?',
      whereArgs: [wordId],
    );
  }

  Future<void> saveWords(List<Word> words) async {
    await initialize();
    final batch = _database.batch();
    for (final word in words) {
      batch.insert('words', {
        'id': word.id,
        'word': word.word,
        'phonetic': word.phonetic,
        'meaning': word.meaning,
        'example': word.example,
        'exampleMeaning': word.exampleMeaning,
        'status': word.status.index,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  // 单词表相关操作
  Future<List<WordList>> getAllWordLists() async {
    await initialize();
    final List<Map<String, dynamic>> maps = await _database.query('word_lists');
    final wordLists = <WordList>[];
    for (final map in maps) {
      final wordList = WordList(
        id: map['id'],
        name: map['name'],
        isCurrent: map['isCurrent'] == 1,
      );
      // 加载单词ID
      final wordIds = await getWordIdsForWordList(map['id']);
      wordList.wordIds = wordIds;
      wordLists.add(wordList);
    }
    return wordLists;
  }

  Future<List<int>> getWordIdsForWordList(int wordListId) async {
    await initialize();
    final List<Map<String, dynamic>> maps = await _database.query(
      'word_list_words',
      where: 'wordListId = ?',
      orderBy: 'position',
    );
    return List.generate(maps.length, (i) => maps[i]['wordId']);
  }

  Future<WordList?> getCurrentWordList() async {
    await initialize();
    final List<Map<String, dynamic>> maps = await _database.query(
      'word_lists',
      where: 'isCurrent = 1',
    );
    if (maps.isNotEmpty) {
      final wordList = WordList(
        id: maps[0]['id'],
        name: maps[0]['name'],
        isCurrent: true,
      );
      // 加载单词ID
      final wordIds = await getWordIdsForWordList(maps[0]['id']);
      wordList.wordIds = wordIds;
      return wordList;
    }
    // 如果没有当前单词表，返回第一个
    final allLists = await getAllWordLists();
    return allLists.isNotEmpty ? allLists[0] : null;
  }

  Future<void> saveWordList(WordList wordList) async {
    await initialize();
    // 开始事务
    await _database.transaction((txn) async {
      // 保存单词表
      await txn.insert('word_lists', {
        'id': wordList.id,
        'name': wordList.name,
        'isCurrent': wordList.isCurrent ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // 如果是当前单词表，将其他设置为非当前
      if (wordList.isCurrent) {
        await txn.update(
          'word_lists',
          {'isCurrent': 0},
          where: 'id != ?',
          whereArgs: [wordList.id],
        );
      }

      // 删除旧的关联
      await txn.delete(
        'word_list_words',
        where: 'wordListId = ?',
        whereArgs: [wordList.id],
      );

      // 保存新的关联
      for (int i = 0; i < wordList.wordIds.length; i++) {
        await txn.insert('word_list_words', {
          'wordListId': wordList.id,
          'wordId': wordList.wordIds[i],
          'position': i,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // 学习进度相关操作
  Future<StudyProgress> getStudyProgress() async {
    await initialize();
    final List<Map<String, dynamic>> maps = await _database.query(
      'study_progress',
    );
    if (maps.isNotEmpty) {
      return StudyProgress(
        totalWordsStudied: maps[0]['totalWordsStudied'],
        masteredWords: maps[0]['masteredWords'],
        consecutiveDays: maps[0]['consecutiveDays'],
        lastStudyDate: DateTime.fromMillisecondsSinceEpoch(
          maps[0]['lastStudyDate'],
        ),
      );
    }
    return StudyProgress();
  }

  Future<void> saveStudyProgress(StudyProgress progress) async {
    await initialize();
    await _database.update('study_progress', {
      'totalWordsStudied': progress.totalWordsStudied,
      'masteredWords': progress.masteredWords,
      'consecutiveDays': progress.consecutiveDays,
      'totalStudyTime': progress.totalStudyTime,
      'dailyGoal': progress.dailyGoal,
      'lastStudyDate': progress.lastStudyDate.millisecondsSinceEpoch,
    }, where: 'id = 1');
  }

  // 清理方法
  Future<void> close() async {
    if (_isInitialized) {
      await _database.close();
      _isInitialized = false;
    }
  }

  // 重置数据库
  Future<void> resetDatabase() async {
    await close();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'wei_dan_ci.db');
    if (await File(path).exists()) {
      await File(path).delete();
    }
    _instance = null;
    await initialize();
  }
}
