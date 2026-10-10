# ChatFlow 项目上下文

## 项目定位

ChatFlow 是一个 Flutter 跨端 AI 助手，按“云端模型 → SSE 流式 → 语音与 RAG”逐阶段实现。设计真源是 [docs/design.html](docs/design.html)，详细开发约束见 [AGENTS.md](AGENTS.md)、[docs/development-doc.md](docs/development-doc.md) 和 [docs/agent-spec.md](docs/agent-spec.md)。

## 固定技术栈

- Flutter `3.7.12-ohos`，Dart `2.19.6`，不升级到非 OHOS 分支。
- Riverpod 2.x、Dio、自定义 SSE 解析、`flutter_markdown`、`shared_preferences`。
- 模型：DeepSeek-R1、Qwen2.5、Gemini 2.0 Flash。
- API Key 仅通过 `--dart-define` 对应的环境常量读取。

## 目录职责

```text
lib/
├── core/                         # 纯 Dart，禁止 Flutter UI import
│   ├── llm/                      # LLM 客户端和 SSE 解析
│   ├── memory/                   # 消息、会话和会话内存
│   └── models/                   # Message、LlmConfig
├── features/chat/application/    # Riverpod ChatController
├── shared/services/              # 平台存储等适配
└── theme/design_tokens.dart      # UI 颜色、字号、圆角和间距
```

## 当前已实现

- 三模型配置切换和可选真实 SSE 对话。
- SSE 增量渲染与助手 Markdown 展示。
- 多会话创建、选择、重命名、删除和本地持久化。
- Riverpod Controller 与 26 项自动化测试。

## 开发命令

```powershell
flutter pub get
flutter analyze
flutter test
flutter build web
flutter run -d chrome
flutter run -d <android-device>
flutter run -d <ohos-device>
```

## 验收门禁

1. L1：`flutter analyze` 无错误。
2. L2：`flutter test` 全部通过。
3. L3：Android、Web、OHOS 核心链路运行并留存证据。
4. L4：对照 `docs/design.html` 人工 review。

当前 Web 已通过构建；Android 受 Gradle loopback 错误阻塞；OHOS 因 `hdc list targets` 无设备阻塞。不要把环境阻塞写成代码完成。

## 持续记录

- 变更摘要：[changes.md](changes.md)
- 当前任务：[tasks.md](tasks.md)
- 日期化开发日志：[docs/development-log.md](docs/development-log.md)
- 每个可验证单元单独 commit，并在开发日志中记录验证命令、结果和风险。
