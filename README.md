<div align="center">
  <img src="assets/images/app_icon.svg" alt="logo" width="200" height="200">

  # 微单词

  跨平台英语单词学习应用，让背词更高效、更有趣

  <div style="display: flex; justify-content: center; gap: 12px; margin-bottom: 12px; flex-wrap: wrap;">
    <a href="LICENSE"><img src="https://img.shields.io/badge/license-Mulan%20PSL%20v2-blue.svg?style=flat&logo=github" alt="License"></a>
    <a href="#平台支持"><img src="https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-lightgrey.svg?style=flat" alt="Platform"></a>
    <a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Flutter-%E8%B7%A8%E5%B9%B3%E5%8F%B0-blue?style=flat" alt="Flutter"></a>
  </div>
</div>

## 能干什么

- **单词学习**：支持单词释义、音标、例句和掌握状态记录
- **发音辅助**：集成文本转语音能力，帮助用户练习听读
- **复习巩固**：根据学习状态筛选复习内容，强化记忆效果
- **自我测验**：支持选择题、填空题等测验方式，查看测验结果和历史记录
- **单词本管理**：支持单词增删改查、收藏、搜索、排序和多单词表管理
- **学习中心**：展示签到、连续学习天数、今日进度、学习时长和掌握统计
- **数据持久化**：使用本地数据库和跨平台存储保存单词、单词表、学习进度和设置
- **主题设置**：支持浅色、深色和跟随系统主题
- **跨平台运行**：支持 Android、iOS、Web、Windows、macOS 和 Linux

## 快速开始

### 环境要求

- **Flutter 3.x**
- **Dart 3.x**
- 平台工具：
  - Android: Android Studio / Android SDK
  - iOS: Xcode (macOS only)
  - Web: Chrome
  - Desktop: 对应平台编译器

### 运行项目

```bash
flutter pub get
flutter run
```

### 常用运行方式

```bash
# Web
flutter run -d chrome

# Android
flutter run -d android

# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

> Windows 环境运行包含插件的测试或构建时，如遇 symlink 检查，请开启 Developer Mode。

---

## 项目结构

```text
weidanci/
├── lib/
│   ├── main.dart                         # 应用入口、主题和路由配置
│   ├── models/                           # 纯数据模型
│   │   ├── word.dart                     # 单词模型
│   │   ├── word_list.dart                # 单词表模型
│   │   ├── study_progress.dart           # 学习进度模型
│   │   ├── settings.dart                 # 设置模型
│   │   ├── quiz_record.dart              # 测验记录模型
│   │   └── quiz_settings.dart            # 测验设置模型
│   ├── pages/                            # 页面组件
│   │   ├── splash_page.dart              # 启动页
│   │   ├── home_page.dart                # 主页 / 学习中心
│   │   ├── study_page.dart               # 单词学习页
│   │   ├── review_page.dart              # 复习页
│   │   ├── quiz_page.dart                # 自我测验页
│   │   ├── quiz_settings_page.dart       # 测验设置页
│   │   ├── quiz_result_page.dart         # 测验结果页
│   │   ├── quiz_history_page.dart        # 测验历史页
│   │   ├── word_book_page.dart           # 单词本页
│   │   ├── settings_page.dart            # 设置页
│   │   └── new_home_page.dart            # 备用主页组件
│   ├── providers/                        # 状态管理
│   │   ├── theme_provider.dart           # 主题状态
│   │   └── study_progress_provider.dart  # 学习进度状态
│   └── services/                         # 业务服务和数据访问
│       ├── audio_service.dart            # 发音服务
│       ├── data_manager.dart             # SQLite 数据管理
│       ├── data_consistency_service.dart # 数据一致性检查与修复
│       ├── platform_storage.dart         # 跨平台存储封装
│       ├── progress_persistence_service.dart # 学习进度持久化
│       ├── word_storage.dart             # 单词存储服务
│       └── word_list_storage.dart        # 单词表存储服务
├── test/
│   ├── models/                           # 模型和服务单元测试
│   └── pages/                            # 页面 Widget 测试
├── integration_test/
│   ├── app_smoke_test.dart               # 应用启动冒烟测试
│   └── app_flow_test.dart                # 主要用户流程集成测试
├── assets/
│   └── images/                           # 应用图标和图片资源
├── android/                              # Android 平台工程
├── ios/                                  # iOS 平台工程
├── web/                                  # Web 平台工程
├── windows/                              # Windows 平台工程
├── macos/                                # macOS 平台工程
├── linux/                                # Linux 平台工程
├── pubspec.yaml                          # 依赖与资源配置
└── analysis_options.yaml                 # Dart/Flutter 静态检查配置
```

---

## 技术栈

| 技术 | 用途 |
| --- | --- |
| Flutter | 跨平台应用框架 |
| Dart | 开发语言 |
| Provider | 全局状态管理 |
| sqflite / sqflite_common_ffi | 本地数据库与桌面测试支持 |
| shared_preferences | 轻量级本地设置存储 |
| flutter_tts | 单词发音 |
| fl_chart | 学习统计图表 |
| file_picker | 数据导入导出文件选择 |
| flutter_test / integration_test | Widget 测试和集成测试 |

---

## 平台支持

| 平台 | 学习 | 测验 | 说明 |
|------|------|------|------|
| Android | ✅ | ✅ | 完整支持 |
| iOS | ✅ | ✅ | 完整支持 |
| Web | ✅ | ✅ | 完整支持 |
| Windows | ✅ | ✅ | 完整支持 |
| macOS | ✅ | ✅ | 完整支持 |
| Linux | ✅ | ✅ | 完整支持 |

---

## 使用说明

### 学习单词

1. 进入学习页面或学习中心
2. 查看单词、音标、释义和例句
3. 根据掌握情况标记「不认识」「模糊」「认识」
4. 系统自动记录学习进度和掌握状态

### 管理单词本

1. 在单词本页面查看当前词库
2. 使用搜索和排序快速定位单词
3. 添加、编辑、删除或收藏单词
4. 通过单词表功能管理不同学习范围

### 开始测验

1. 进入测验页面
2. 可在测验设置中调整题目数量、题型等参数
3. 完成测验后查看结果
4. 在测验历史中回顾过往记录

### 学习统计

学习中心会展示：

- 今日学习进度
- 连续学习天数
- 总学习单词数
- 已掌握单词数
- 学习时长
- 签到记录

---

## 开发与测试

```bash
# 获取依赖
flutter pub get

# 静态分析
flutter analyze

# 运行全部测试
flutter test

# 运行页面渲染测试
flutter test --no-pub test/pages/page_rendering_test.dart

# 运行集成测试
flutter test integration_test/app_smoke_test.dart

# 构建 Android Debug APK
flutter build apk --debug
```

---

## 数据存储

项目的数据层集中在 `lib/services/`：

- `data_manager.dart` 负责 SQLite 数据库初始化和 CRUD 操作
- `word_storage.dart` 负责单词数据访问和默认单词初始化
- `word_list_storage.dart` 负责单词表数据访问和当前单词表管理
- `progress_persistence_service.dart` 负责学习进度自动保存
- `data_consistency_service.dart` 负责启动时的数据校验和修复
- `platform_storage.dart` 提供跨平台存储能力

---

## 维护说明

- 日志和临时 diff 文件已加入 `.gitignore`，避免再次污染仓库
- Flutter 生成目录如 `.dart_tool/`、`build/`、平台 ephemeral 文件不应提交
- Android 在 Windows 环境下已关闭 Kotlin 增量编译，以规避跨盘缓存路径问题
- 如需在全新环境中直接使用 Gradle wrapper，请确认 `android/gradlew`、`android/gradlew.bat` 和 `android/gradle/wrapper/gradle-wrapper.jar` 已按团队规范管理

---

## 许可证

本项目采用木兰宽松许可证，第 2 版（Mulan PSL v2）。

---

## 贡献

欢迎提交 Issue 和 Pull Request！

---

Made with ❤️ for English learners
