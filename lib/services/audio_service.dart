import 'package:flutter_tts/flutter_tts.dart'; // 引入Flutter TTS（文本转语音）库

/// 音频服务类
///
/// 功能：
/// - 提供文本转语音（TTS）功能，用于播放单词发音
/// - 使用单例模式实现，确保应用中只有一个TTS引擎实例
/// - 统一管理TTS引擎的初始化和配置
/// - 封装音频播放的核心逻辑
///
/// 技术说明：
/// - 基于第三方库 `flutter_tts` 实现
/// - 支持设置音量、语速、音调等参数
/// - 支持事件监听（开始播放、播放完成、播放错误）
class AudioService {
  /// 单例实例，使用静态常量确保唯一
  static final AudioService _instance = AudioService._internal();

  /// 工厂构造函数，返回单例实例
  ///
  /// 通过工厂模式，无论调用多少次AudioService()，都返回同一个实例
  factory AudioService() => _instance;

  /// Flutter TTS引擎实例
  ///
  /// late关键字表示该变量将在后续初始化，无需在声明时赋值
  late FlutterTts _flutterTts;

  /// 说话状态标志
  ///
  /// true表示正在播放音频，false表示未播放
  bool _isSpeaking = false;

  /// 私有构造函数，用于初始化单例实例
  ///
  /// 私有构造函数确保外部无法直接创建AudioService实例
  /// 只能通过工厂构造函数AudioService()获取单例
  AudioService._internal() {
    _initTTS(); // 初始化TTS引擎
  }

  /// 初始化TTS引擎
  ///
  /// 功能：
  /// - 创建FlutterTts实例
  /// - 设置TTS引擎的基本参数
  /// - 配置事件监听器
  void _initTTS() {
    // 创建FlutterTts实例
    _flutterTts = FlutterTts();

    // 设置TTS引擎的基本参数
    _flutterTts.setVolume(1.0); // 音量：0.0（静音）到1.0（最大音量）
    _flutterTts.setSpeechRate(1.0); // 语速：0.0（最慢）到1.0（正常），可超过1.0
    _flutterTts.setPitch(1.0); // 音调：0.5（低沉）到2.0（尖锐）

    // 设置语音语言为美式英语
    _flutterTts.setLanguage('en-US');

    // 设置TTS事件监听器
    // 开始播放时的回调
    _flutterTts.setStartHandler(() {
      _isSpeaking = true; // 更新说话状态为正在播放
    });

    // 播放完成时的回调
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false; // 更新说话状态为未播放
    });

    // 播放错误时的回调
    _flutterTts.setErrorHandler((message) {
      print('TTS错误: $message'); // 打印错误信息
      _isSpeaking = false; // 更新说话状态为未播放
    });
  }

  /// 播放单词发音
  ///
  /// 参数：
  /// - word: 要播放发音的单词（字符串）
  ///
  /// 功能：
  /// - 检查是否正在播放音频，如果是则先停止
  /// - 使用TTS引擎播放指定单词的发音
  ///
  /// 返回值：
  /// - Future<void>: 异步操作，无返回值
  Future<void> speak(String word) async {
    // 如果正在播放音频，先停止当前播放
    if (_isSpeaking) {
      await _flutterTts.stop();
    }

    // 使用TTS引擎播放单词发音
    await _flutterTts.speak(word);
  }

  /// 停止音频播放
  ///
  /// 功能：
  /// - 停止当前正在播放的音频
  /// - 更新说话状态为未播放
  ///
  /// 返回值：
  /// - Future<void>: 异步操作，无返回值
  Future<void> stop() async {
    // 停止TTS引擎
    await _flutterTts.stop();
    // 更新说话状态为未播放
    _isSpeaking = false;
  }
}
