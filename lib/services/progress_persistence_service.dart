import 'dart:async';
import 'package:flutter/material.dart';
import '../models/study_progress.dart';
import '../models/word.dart';
import '../services/word_storage.dart';
import './data_manager.dart';

class ProgressPersistenceService {
  static ProgressPersistenceService? _instance;
  static ProgressPersistenceService get instance =>
      _instance ??= ProgressPersistenceService._();

  ProgressPersistenceService._();

  Timer? _autoSaveTimer;
  StudyProgress? _cachedProgress;
  List<Word>? _cachedWords;
  int? _currentWordIndex;
  String? _currentWordListId;

  static const int _autoSaveIntervalSeconds = 30;

  void initialize() {
    _startAutoSave();
    _setupLifecycleListener();
  }

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(
      Duration(seconds: _autoSaveIntervalSeconds),
      (_) => _autoSave(),
    );
  }

  void _autoSave() async {
    try {
      if (_cachedProgress != null) {
        await _cachedProgress!.save();
      }
      if (_cachedWords != null) {
        await WordStorage.saveWords(_cachedWords!);
      }
    } catch (e) {
      debugPrint('自动保存失败: $e');
    }
  }

  void _setupLifecycleListener() {
    WidgetsBinding.instance.addObserver(_LifecycleObserver(this));
  }

  Future<void> saveProgress({
    StudyProgress? progress,
    List<Word>? words,
    int? currentWordIndex,
    String? currentWordListId,
  }) async {
    if (progress != null) {
      _cachedProgress = progress;
      await progress.save();
    }
    if (words != null) {
      _cachedWords = words;
      await WordStorage.saveWords(words);
    }
    if (currentWordIndex != null) {
      _currentWordIndex = currentWordIndex;
    }
    if (currentWordListId != null) {
      _currentWordListId = currentWordListId;
    }
  }

  Future<StudyProgress> loadProgress() async {
    if (_cachedProgress == null) {
      _cachedProgress = await StudyProgress.load();
    }
    return _cachedProgress!;
  }

  Future<List<Word>> loadWords() async {
    if (_cachedWords == null) {
      _cachedWords = await WordStorage.loadWords();
    }
    return _cachedWords!;
  }

  Future<Map<String, dynamic>> loadSessionState() async {
    try {
      /// 使用DataManager加载数据
      await DataManager.instance.initialize();
      final words = await DataManager.instance.getAllWords();
      final progress = await DataManager.instance.getStudyProgress();

      return {
        'progress': progress,
        'words': words,
        'currentWordIndex': _currentWordIndex,
        'currentWordListId': _currentWordListId,
        'studyContainer': [],
        'originalContainer': [],
        'continuousCorrectCount': {},
        'masteredWords': [],
        'isShuffleGenerated': false,
        'shuffledWordIds': null,
        'reviewContainer': [],
      };
    } catch (e) {
      debugPrint('加载会话状态失败: $e');

      /// 失败时使用原有方式加载
      final progress = await loadProgress();
      final words = await loadWords();

      return {
        'progress': progress,
        'words': words,
        'currentWordIndex': _currentWordIndex,
        'currentWordListId': _currentWordListId,
        'studyContainer': [],
        'originalContainer': [],
        'continuousCorrectCount': {},
        'masteredWords': [],
        'isShuffleGenerated': false,
        'shuffledWordIds': null,
        'reviewContainer': [],
      };
    }
  }

  Future<void> saveSessionState(Map<String, dynamic> state) async {
    try {
      /// 使用DataManager保存数据
      await DataManager.instance.initialize();

      // 保存会话状态
      if (state.containsKey('progress') && state['progress'] is StudyProgress) {
        await DataManager.instance.saveStudyProgress(state['progress']);
      }
      if (state.containsKey('words') && state['words'] is List<Word>) {
        await DataManager.instance.saveWords(state['words']);
      }
      if (state.containsKey('currentWordIndex')) {
        _currentWordIndex = state['currentWordIndex'];
      }
      if (state.containsKey('currentWordListId')) {
        _currentWordListId = state['currentWordListId'];
      }
    } catch (e) {
      debugPrint('保存会话状态失败: $e');

      /// 失败时使用原有方式保存
      if (state.containsKey('progress') && state['progress'] is StudyProgress) {
        await saveProgress(progress: state['progress']);
      }
      if (state.containsKey('words') && state['words'] is List<Word>) {
        await saveProgress(words: state['words']);
      }
    }
  }

  void updateCurrentWordIndex(int index) {
    _currentWordIndex = index;
  }

  void updateCurrentWordListId(String id) {
    _currentWordListId = id;
  }

  Future<void> saveBeforeExit() async {
    try {
      if (_cachedProgress != null) {
        _cachedProgress!.recordAppCloseTime(DateTime.now());
      }
      _autoSave();
    } catch (e) {
      debugPrint('退出前保存失败: $e');
    }
  }

  void dispose() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }
}

class _LifecycleObserver with WidgetsBindingObserver {
  final ProgressPersistenceService _service;

  _LifecycleObserver(this._service);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _service.saveBeforeExit();
        break;
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
        break;
    }
  }
}
