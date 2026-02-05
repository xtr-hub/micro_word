
import 'package:flutter/material.dart';
import '../models/study_progress.dart';

/// 学习进度提供者类
///
/// 功能：
/// - 管理应用的学习进度全局状态
/// - 支持学习进度的更新和通知
/// - 当学习进度变化时通知所有监听的Widget
///
/// 技术说明：
/// - 继承自ChangeNotifier，实现状态通知机制
/// - 提供学习进度的getter和更新方法
/// - 实现全局刷新机制
class StudyProgressProvider extends ChangeNotifier {
  /// 私有学习进度变量
  StudyProgress? _progress;

  /// 私有加载状态变量
  bool _isLoading = true;

  /// 公共getter方法：获取当前学习进度
  StudyProgress? get progress => _progress;

  /// 公共getter方法：获取加载状态
  bool get isLoading => _isLoading;

  /// 构造函数
  StudyProgressProvider() {
    _loadProgress();
  }

  /// 加载学习进度数据
  Future<void> _loadProgress() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _progress = await StudyProgress.load();
    } catch (e) {
      print('加载学习进度数据时出错: $e');
      _progress = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 重新加载学习进度数据
  Future<void> reloadProgress() async {
    await _loadProgress();
  }

  /// 签到
  Future<bool> checkIn() async {
    if (_progress == null) return false;
    
    bool success = _progress!.checkIn();
    if (success) {
      await _loadProgress();
    }
    return success;
  }

  /// 更新学习单词数
  void updateWordsStudied(int count, bool isMastered) {
    if (_progress != null) {
      _progress!.updateWordsStudied(count, isMastered);
      notifyListeners();
    }
  }

  /// 更新复习单词数
  void updateWordsReviewed(int count) {
    if (_progress != null) {
      _progress!.updateWordsReviewed(count);
      notifyListeners();
    }
  }
}

/// 学习进度提供者的InheritedWidget实现
class StudyProgressProviderWidget extends InheritedWidget {
  final StudyProgressProvider provider;

  const StudyProgressProviderWidget({
    Key? key,
    required this.provider,
    required Widget child,
  }) : super(key: key, child: child);

  /// 静态方法：从BuildContext中获取StudyProgressProvider实例
  static StudyProgressProvider? of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<StudyProgressProviderWidget>();
    return widget?.provider;
  }

  @override
  bool updateShouldNotify(StudyProgressProviderWidget oldWidget) {
    return oldWidget.provider.progress != provider.progress;
  }
}
