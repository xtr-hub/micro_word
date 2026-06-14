# 贡献指南

感谢你关注并参与微单词项目。本文档说明项目的贡献流程、代码规范、测试要求和提交流程，帮助协作者保持一致的开发方式。

## 参与方式

欢迎通过以下方式参与项目：

- 提交 Issue：反馈 Bug、提出功能建议或改进意见
- 提交 Pull Request：修复问题、完善功能、优化文档或补充测试
- 完善文档：改进 README、使用说明、开发说明和注释
- 补充测试：增加单元测试、Widget 测试或集成测试

## 开发环境

建议使用以下环境：

- Flutter SDK 3.x
- Dart SDK 3.x
- Android Studio 或 VS Code
- Android SDK / 浏览器 / 桌面平台运行环境

初始化项目：

```bash
flutter pub get
```

运行项目：

```bash
flutter run
```

常用平台示例：

```bash
flutter run -d chrome
flutter run -d android
flutter run -d windows
```

Windows 环境运行包含插件的测试或构建时，如遇 symlink 检查，请开启 Developer Mode。

## 分支规范

建议从主开发分支创建功能分支：

```bash
git checkout debug-branch
git pull
git checkout -b feat/your-feature-name
```

分支命名建议：

| 类型 | 示例 | 用途 |
| --- | --- | --- |
| `feat/*` | `feat/word-list-filter` | 新功能 |
| `fix/*` | `fix/quiz-result-score` | Bug 修复 |
| `docs/*` | `docs/update-readme` | 文档更新 |
| `test/*` | `test/add-quiz-tests` | 测试补充 |
| `refactor/*` | `refactor/storage-service` | 重构 |
| `chore/*` | `chore/cleanup-logs` | 构建、配置、清理等维护工作 |

## 提交规范

提交信息建议使用简洁明确的中文或英文描述，说明本次提交的主要目的。

推荐格式：

```text
<类型>: <简要说明>
```

示例：

```text
feat: 添加单词表筛选功能
fix: 修复测验结果得分显示错误
docs: 更新贡献指南
test: 补充页面渲染测试
refactor: 整理单词存储服务
chore: 清理临时日志文件
```

提交前请确认 Git 用户信息正确：

```bash
git config user.name
git config user.email
```

## 代码规范

### Dart / Flutter 规范

- 遵循项目已有代码风格
- 提交前运行格式化：

```bash
dart format lib test integration_test
```

- 尽量保持 Widget、模型和服务职责清晰：
  - `lib/models/`：数据模型
  - `lib/pages/`：页面组件
  - `lib/providers/`：状态管理
  - `lib/services/`：业务服务、存储和数据访问
- 业务测验功能使用 `quiz` 命名，避免和自动化测试目录 `test/` 混淆
- 新增公共方法或复杂逻辑时，请补充必要注释
- 避免提交无关格式化或大范围无意义改动

### 文件和目录规范

请不要提交以下生成文件或本地环境文件：

- `.dart_tool/`
- `build/`
- `.idea/`
- `.vscode/`
- `*.iml`
- 平台 ephemeral 文件
- 本地日志、临时 diff、运行输出文件

如需调整 `.gitignore`，请确保不会误忽略必要源码、测试或配置文件。

## 测试要求

提交前建议至少运行以下检查：

```bash
flutter analyze
flutter test
```

针对页面或局部功能，可运行指定测试：

```bash
flutter test --no-pub test/pages/page_rendering_test.dart
flutter test --no-pub test/pages/quiz_page_test.dart
```

构建 Android Debug 包：

```bash
flutter build apk --debug
```

如果修改了集成流程，可运行：

```bash
flutter test integration_test/app_smoke_test.dart
flutter test integration_test/app_flow_test.dart
```

如测试无法在当前环境运行，请在 Pull Request 中说明原因、已验证的替代命令和相关输出。

## Pull Request 流程

提交 Pull Request 前，请确认：

- 代码已格式化
- 相关测试已运行或说明未运行原因
- 没有提交本地生成文件、日志文件或临时文件
- 文档已随功能变化同步更新
- 变更范围聚焦，避免混入无关修改
- UI 或交互变化尽量附上截图或说明

Pull Request 描述建议包含：

```md
## 变更内容

- 

## 验证方式

- [ ] flutter analyze
- [ ] flutter test
- [ ] flutter build apk --debug

## 备注

- 
```

## Issue 反馈规范

提交 Bug 反馈时，建议包含：

- 问题描述
- 复现步骤
- 期望结果
- 实际结果
- 运行平台和 Flutter 版本
- 相关日志或截图

提交功能建议时，建议包含：

- 使用场景
- 期望行为
- 可能的交互方式
- 是否愿意提交实现

## 数据和兼容性注意事项

项目包含本地数据存储和学习进度持久化逻辑。修改以下内容时请特别注意兼容性：

- `lib/services/data_manager.dart`
- `lib/services/word_storage.dart`
- `lib/services/word_list_storage.dart`
- `lib/services/progress_persistence_service.dart`
- `lib/models/study_progress.dart`
- `lib/models/quiz_record.dart`
- `lib/models/quiz_settings.dart`

如需修改本地存储 key、数据库结构或数据模型字段，请说明迁移策略，避免破坏已有用户数据。

## 许可证

贡献代码即表示你同意你的贡献以本项目许可证发布。

本项目采用木兰宽松许可证，第 2 版（Mulan PSL v2）。
