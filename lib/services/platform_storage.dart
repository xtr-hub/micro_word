import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 跨平台存储服务
///
/// 功能：
/// - 提供跨平台的数据存储解决方案
/// - 在移动端使用文件系统存储
/// - 在Web端使用本地存储
class PlatformStorage {
  /// 保存数据到本地
  ///
  /// 参数：
  /// - key：数据键
  /// - value：数据值（JSON字符串）
  static Future<void> saveData(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$key.json');
        await file.writeAsString(value);
      } catch (e) {
        debugPrint('保存数据失败 ($key): $e');
        rethrow;
      }
    }
  }

  /// 从本地加载数据
  ///
  /// 参数：
  /// - key：数据键
  ///
  /// 返回值：
  /// - Future<String?>：数据值，如果不存在则返回null
  static Future<String?> loadData(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$key.json');
        if (!file.existsSync()) {
          return null;
        }
        return await file.readAsString();
      } catch (e) {
        debugPrint('加载数据失败 ($key): $e');
        return null;
      }
    }
  }

  /// 删除本地数据
  ///
  /// 参数：
  /// - key：数据键
  static Future<void> deleteData(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } else {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$key.json');
        if (file.existsSync()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('删除数据失败 ($key): $e');
      }
    }
  }

  /// 检查数据是否存在
  ///
  /// 参数：
  /// - key：数据键
  ///
  /// 返回值：
  /// - Future<bool>：true表示数据存在，false表示数据不存在
  static Future<bool> dataExists(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    } else {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$key.json');
        return file.existsSync();
      } catch (e) {
        debugPrint('检查数据存在失败 ($key): $e');
        return false;
      }
    }
  }

  /// 获取所有数据键（仅Web端支持）
  ///
  /// 返回值：
  /// - Future<List<String>>：所有数据键的列表
  static Future<List<String>> getAllKeys() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getKeys().toList();
    } else {
      try {
        final directory = await getApplicationDocumentsDirectory();
        if (!directory.existsSync()) {
          return [];
        }
        final files = directory.listSync();
        return files
            .whereType<File>()
            .map((file) => file.path.split(Platform.pathSeparator).last.replaceAll('.json', ''))
            .toList();
      } catch (e) {
        debugPrint('获取所有键失败: $e');
        return [];
      }
    }
  }

  /// 清除所有数据
  static Future<void> clearAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } else {
      try {
        final directory = await getApplicationDocumentsDirectory();
        if (directory.existsSync()) {
          await directory.delete(recursive: true);
        }
      } catch (e) {
        debugPrint('清除所有数据失败: $e');
      }
    }
  }

  /// 创建备份（仅移动端支持）
  ///
  /// 参数：
  /// - backupName：备份名称
  ///
  /// 返回值：
  /// - Future<bool>：true表示备份成功，false表示备份失败
  static Future<bool> createBackup(String backupName) async {
    if (kIsWeb) {
      debugPrint('Web平台不支持文件备份');
      return false;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      if (!backupDir.existsSync()) {
        await backupDir.create();
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File('${backupDir.path}/$backupName-$timestamp.json');

      final files = directory.listSync().whereType<File>();
      final Map<String, dynamic> backupData = {};

      for (var file in files) {
        if (!file.path.contains('backups')) {
          final key = file.path.split(Platform.pathSeparator).last.replaceAll('.json', '');
          final content = await file.readAsString();
          backupData[key] = json.decode(content);
        }
      }

      await backupFile.writeAsString(json.encode(backupData));
      return true;
    } catch (e) {
      debugPrint('创建备份失败: $e');
      return false;
    }
  }

  /// 恢复备份（仅移动端支持）
  ///
  /// 参数：
  /// - backupFileName：备份文件名
  ///
  /// 返回值：
  /// - Future<bool>：true表示恢复成功，false表示恢复失败
  static Future<bool> restoreBackup(String backupFileName) async {
    if (kIsWeb) {
      debugPrint('Web平台不支持文件备份');
      return false;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupFile = File('${directory.path}/backups/$backupFileName');

      if (!backupFile.existsSync()) {
        debugPrint('备份文件不存在: $backupFileName');
        return false;
      }

      final backupContent = await backupFile.readAsString();
      final backupData = json.decode(backupContent) as Map<String, dynamic>;

      for (var entry in backupData.entries) {
        await saveData(entry.key, json.encode(entry.value));
      }

      return true;
    } catch (e) {
      debugPrint('恢复备份失败: $e');
      return false;
    }
  }

  /// 获取备份列表（仅移动端支持）
  ///
  /// 返回值：
  /// - Future<List<String>>：备份文件名列表
  static Future<List<String>> getBackupList() async {
    if (kIsWeb) {
      return [];
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      if (!backupDir.existsSync()) {
        return [];
      }

      final files = backupDir.listSync().whereType<File>();
      return files.map((file) => file.path.split(Platform.pathSeparator).last).toList();
    } catch (e) {
      debugPrint('获取备份列表失败: $e');
      return [];
    }
  }

  /// 删除备份（仅移动端支持）
  ///
  /// 参数：
  /// - backupFileName：备份文件名
  static Future<void> deleteBackup(String backupFileName) async {
    if (kIsWeb) {
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupFile = File('${directory.path}/backups/$backupFileName');

      if (backupFile.existsSync()) {
        await backupFile.delete();
      }
    } catch (e) {
      debugPrint('删除备份失败: $e');
    }
  }
}
