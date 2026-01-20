# 微单词 (WeiDanCi)

<div align="center">
  <img src="assets/images/app_icon.svg" alt="微单词 Logo" width="120" height="120">
  <h2>简洁高效的单词学习应用</h2>
  <p>基于Flutter开发，支持多平台使用</p>
  
  <div style="margin: 20px 0;">
    <img src="https://img.shields.io/badge/Flutter-3.11+-blue.svg" alt="Flutter Version">
    <img src="https://img.shields.io/badge/Dart-3.1+-blue.svg" alt="Dart Version">
    <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-lightgrey.svg" alt="Supported Platforms">
    <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
  </div>
</div>

## 📱 功能特点

### 📖 核心学习功能
- **卡片式学习**：优雅的卡片界面，专注于单词学习体验
- **点击交互**：支持点击显示/隐藏释义和例句，加深记忆
- **自动发音**：单词加载和切换时自动播放音频，提升听力记忆
- **学习状态管理**：
  - 🔴 **不认识**：需要重点复习
  - 🟡 **模糊**：需要巩固
  - 🟢 **认识**：已掌握
- **智能复习算法**：基于艾宾浩斯遗忘曲线，科学调整复习频率

### 📝 多样化测试
- **选择题模式**：从4个精心设计的选项中选择正确释义
- **填空题模式**：根据释义输入正确单词，锻炼拼写能力
- **实时反馈**：即时显示答案正确与否，加深记忆印象
- **自动音频播放**：提交答案后自动播放下一个单词音频，无缝学习体验

### 📊 进度跟踪
- **可视化进度条**：直观显示学习完成度，激励持续学习
- **详细统计数据**：
  - 总学习时间
  - 已学习单词数量
  - 掌握程度分布
  - 测试准确率统计
- **学习历史记录**：完整保存所有学习和测试状态，可追溯学习轨迹

### 📚 单词本管理
- **全面单词管理**：支持查看、添加、编辑、删除单词
- **智能分类**：
  - 按学习状态筛选
  - 按字母顺序排列
  - 按添加时间排序
- **数据导入导出**：支持JSON格式的单词数据导入导出，方便数据备份和迁移

### ⚙️ 个性化设置
- **主题切换**：支持深色/浅色主题，适应不同使用场景
- **发音配置**：
  - 调整发音速度
  - 设置发音音量
  - 选择发音语言
- **学习计划**：
  - 自定义每日学习目标
  - 选择测试模式偏好
  - 设置自动播放间隔

## 🛠️ 技术栈

### 🎨 前端技术
- **Flutter 3.11+**：现代化跨平台UI框架，实现一致的用户体验
- **Dart 3.1+**：类型安全的编程语言，提供高效开发体验

### 🔄 状态管理
- **ValueNotifier/ValueListenableBuilder**：轻量级局部状态管理，性能优秀
- **Provider**：简单易用的全局状态管理方案，用于主题等全局状态

### 💾 数据存储
- **shared_preferences**：快速存储用户设置和应用配置
- **dart:io**：高效的文件系统操作，用于单词数据的持久化存储

### 🔊 音频服务
- **Text-to-Speech**：先进的文本到语音转换技术，提供自然流畅的发音
- **AudioService**：自定义音频服务，实现可靠的音频播放管理

### 📱 UI组件库
- **AnimatedContainer**：实现平滑的界面过渡动画
- **GestureDetector**：处理各种触摸交互事件
- **PageView**：实现流畅的页面切换效果
- **ValueListenableBuilder**：实现高效的局部UI更新

### 🧪 测试框架
- **Flutter Test**：单元测试和Widget测试
- **Integration Test**：集成测试，确保应用整体功能正常

## 🚀 快速开始

### 环境要求

- Flutter SDK 3.11.0+
- Dart SDK 3.1.0+
- Android Studio/Xcode（可选，用于开发）

### 安装依赖

```bash
flutter pub get
```

### 运行应用

```bash
# 运行在默认设备
flutter run

# 运行在特定设备
flutter run -d <device_id>
```

### 查看设备列表

```bash
flutter devices
```

## 🏗️ 构建应用

### 构建前准备
```bash
# 确保Flutter环境配置正确
flutter doctor

# 安装依赖
flutter pub get
```

### 📱 Android
```bash
# 构建debug版本
flutter build apk

# 构建release版本（用于发布）
flutter build apk --release

# 构建特定架构版本
flutter build apk --release --split-per-abi
```

### 🍎 iOS
```bash
# 构建debug版本
flutter build ios

# 构建release版本（需要macOS系统）
flutter build ios --release

# 构建IPA文件
flutter build ios --release --no-codesign
export PATH="$PATH:/Applications/Xcode.app/Contents/Developer/usr/bin"
xcrun xcodebuild -exportArchive -archivePath build/ios/archive/Runner.xcarchive -exportOptionsPlist exportOptions.plist -exportPath build/ios/ipa
```

### 🌐 Web
```bash
# 构建web版本
flutter build web

# 构建生产版本
flutter build web --release
```

### 💻 Desktop
```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Linux
flutter build linux
```

### 📦 构建产物位置
| 平台 | 产物路径 |
|------|----------|
| Android | `build/app/outputs/flutter-apk/` |
| iOS | `build/ios/archive/Runner.xcarchive/` |
| Web | `build/web/` |
| Windows | `build/windows/runner/Release/` |
| macOS | `build/macos/Build/Products/Release/` |
| Linux | `build/linux/x64/release/bundle/` |

## 📁 项目结构

```
weidanci/
├── assets/                      # 静态资源
│   ├── images/                  # 图片资源
│   │   ├── app_icon.svg         # 应用图标
│   │   └── app_icon.png         # 应用图标
│   └── fonts/                   # 字体资源（可选）
├── lib/                         # 源代码目录
│   ├── main.dart                # 应用入口文件
│   ├── models/                  # 数据模型
│   │   ├── word.dart            # 单词数据模型
│   │   ├── word_storage.dart    # 单词存储服务
│   │   └── study_progress.dart  # 学习进度模型
│   ├── pages/                   # 页面组件
│   │   ├── splash_page.dart     # 启动页面
│   │   ├── home_page.dart       # 首页
│   │   ├── study_page.dart      # 学习页面
│   │   ├── test_page.dart       # 测试页面
│   │   ├── word_book_page.dart  # 单词本页面
│   │   ├── settings_page.dart   # 设置页面
│   │   └── new_home_page.dart   # 新首页（备用）
│   ├── providers/               # 状态管理
│   │   └── theme_provider.dart  # 主题切换提供器
│   ├── services/                # 服务层
│   │   └── audio_service.dart   # 音频播放服务
│   ├── widgets/                 # 自定义组件（预留）
│   └── utils/                   # 工具类（预留）
├── test/                        # 测试代码
│   ├── widget_test.dart         # Widget测试
│   ├── models/                  # 模型测试
│   └── integration_test/        # 集成测试
├── android/                     # Android平台代码
├── ios/                         # iOS平台代码
├── web/                         # Web平台代码
├── windows/                     # Windows平台代码
├── macos/                       # macOS平台代码
├── linux/                       # Linux平台代码
├── pubspec.yaml                 # 项目配置文件
├── pubspec.lock                 # 依赖锁定文件
├── README.md                    # 项目说明文档
└── .gitignore                   # Git忽略文件
```

### 📁 关键目录说明
- **lib/models/**：定义应用的数据结构和业务逻辑
- **lib/pages/**：包含所有用户界面页面
- **lib/services/**：提供通用服务（如音频、网络等）
- **lib/providers/**：管理全局状态
- **assets/**：存储静态资源文件
- **test/**：包含所有测试代码

## 🎯 使用指南

### 📖 学习流程
1. **启动应用**：打开微单词应用，进入首页
2. **开始学习**：在底部导航栏点击「学习」标签
3. **查看单词**：阅读单词和音标，观察学习状态
4. **播放发音**：
   - 自动播放：单词加载完成后自动播放
   - 手动播放：点击单词或发音按钮播放
5. **显示释义**：点击单词卡片查看释义和例句
6. **标记状态**：根据掌握程度点击：
   - 🔴 **不认识**：需要重点复习
   - 🟡 **模糊**：需要巩固
   - 🟢 **认识**：已掌握
7. **下一个单词**：点击「下一个」按钮继续学习

### 📝 测试流程
1. **进入测试**：在底部导航栏点击「测试」标签
2. **选择模式**：
   - **选择题**：从4个选项中选择正确释义
   - **填空题**：根据释义输入正确单词
3. **开始作答**：
   - 选择题：点击你认为正确的选项
   - 填空题：在输入框中输入单词
4. **提交答案**：点击「提交答案」按钮
5. **查看结果**：
   - ✅ 正确：答案正确，显示绿色提示
   - ❌ 错误：答案错误，显示红色提示和正确答案
6. **继续测试**：自动进入下一题，无需手动操作

### 📚 单词本管理
1. **进入单词本**：点击底部导航栏的「单词本」标签
2. **查看单词**：浏览所有单词列表
3. **筛选单词**：根据学习状态筛选单词
4. **管理单词**：
   - **添加**：点击「+」按钮添加新单词
   - **编辑**：长按单词进行编辑
   - **删除**：滑动单词进行删除
5. **导入导出**：在设置页面进行数据管理

### ⚙️ 设置
1. **进入设置**：点击底部导航栏的「设置」标签
2. **主题设置**：切换深色/浅色主题
3. **发音设置**：调整发音速度和音量
4. **学习设置**：自定义学习计划和测试模式
5. **数据管理**：导入导出单词数据

## 📸 应用截图

<!-- 预留应用截图位置 -->
<div align="center">
  <img src="screenshots/home.png" alt="首页" width="200" style="margin: 10px;">
  <img src="screenshots/study.png" alt="学习页面" width="200" style="margin: 10px;">
  <img src="screenshots/test.png" alt="测试页面" width="200" style="margin: 10px;">
  <img src="screenshots/word_book.png" alt="单词本" width="200" style="margin: 10px;">
  <img src="screenshots/settings.png" alt="设置" width="200" style="margin: 10px;">
</div>

## 🤝 贡献指南

感谢您对微单词项目的兴趣！我们欢迎所有形式的贡献。

### 贡献流程
1. **Fork 仓库**：点击右上角Fork按钮，创建自己的仓库副本
2. **克隆仓库**：
   ```bash
   git clone https://gitee.com/xds2026/micro-words.git
   cd micro-words
   ```
3. **创建特性分支**：
   ```bash
   git checkout -b feature/AmazingFeature
   ```
4. **安装依赖**：
   ```bash
   flutter pub get
   ```
5. **开发和测试**：
   - 编写代码
   - 运行测试
   ```bash
   flutter test
   ```
6. **提交更改**：
   ```bash
   git add .
   git commit -m 'Add some AmazingFeature'
   ```
7. **推送到分支**：
   ```bash
   git push origin feature/AmazingFeature
   ```
8. **创建 Pull Request**：在Gitee上提交PR

### 贡献规范
- 遵循现有的代码风格
- 为新功能添加测试
- 更新相关文档
- 保持提交信息清晰简洁
- 一次提交只包含一个功能或修复

## ❓ 常见问题

### Q: 应用支持哪些平台？
A: 微单词基于Flutter开发，支持Android、iOS、Web和桌面平台（Windows、macOS、Linux）。

### Q: 如何添加新单词？
A: 在单词本页面点击「+」按钮，输入单词、音标、释义和例句即可。

### Q: 如何备份我的单词数据？
A: 在设置页面选择「导出数据」，将生成的JSON文件保存到安全位置。

### Q: 自动发音功能如何工作？
A: 应用使用Text-to-Speech技术，单词加载和切换时自动播放音频。

### Q: 如何切换主题？
A: 在设置页面选择「主题」选项，即可切换深色/浅色主题。

## 📧 联系方式

如有问题或建议，请通过以下方式联系：

- **项目地址**：https://gitee.com/xds2026/micro-words
- **邮箱**：your-email@example.com

## 📝 更新日志

### v1.0.2 (2026-01-20)
- ✅ 扩展默认单词列表，从10个增加到50个常用英文单词
- ✅ 优化单词数据结构，添加更多类别和丰富的例句

### v1.0.1 (2026-01-20)
- ✅ 新增例句释义功能，支持为每个例句添加中文解释
- ✅ 优化学习界面布局，增加组件间距，提升阅读体验
- ✅ 在单词本中添加和编辑单词时支持输入例句释义
- ✅ 在学习页面中显示例句的中文释义
- ✅ 自动播放例句发音功能（在自动播放设置开启时）

### v1.0.0 (2024-01-18)
- ✅ 初始版本发布
- ✅ 实现核心学习功能
- ✅ 支持选择题和填空题测试模式
- ✅ 自动音频播放功能
- ✅ 学习进度跟踪
- ✅ 单词本管理
- ✅ 主题切换功能

## 🌟 致谢

- **Flutter团队**：提供了优秀的跨平台UI框架
- **Dart社区**：丰富的开发资源和支持
- **所有贡献者**：感谢你们的支持和贡献

---

<div align="center">
  <p>❤️ 感谢使用微单词！祝您学习进步！</p>
</div>

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情
