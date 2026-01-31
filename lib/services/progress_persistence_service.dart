import 'dart:async';
import 'package:flutter/material.dart';
import '../models/study_progress.dart';
import '../models/word.dart';
import '../models/word_storage.dart';

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
    final progress = await loadProgress();
    final words = await loadWords();

    return {
      'progress': progress,
      'words': words,
      'currentWordIndex': _currentWordIndex,
      'currentWordListId': _currentWordListId,
    };
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
