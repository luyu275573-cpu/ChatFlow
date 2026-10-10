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
│   ├── memory/                   # 会话实体和会话内存
│   ├── models/                   # Message、LlmConfig
│   └── rag/                      # 本地文档切分、检索和上下文注入接口
├── features/chat/application/    # Riverpod ChatController
├── shared/services/              # 平台存储等适配
└── theme/design_tokens.dart      # UI 颜色、字号、圆角和间距
```

## 当前已实现

- 三模型配置切换和可选真实 SSE 对话。
- SSE 增量渲染与助手 Markdown 展示。
- 多会话创建、选择、重命名、删除和本地持久化。
- Riverpod Controller 与 50 项自动化测试。
- `core/rag/retriever.dart`：纯 Dart 文档切分、关键词检索和上下文注入；本地资料通过 `LocalDocumentStorage` 持久化，并已接入真实流式聊天请求。
- 会话抽屉提供本地资料新增、删除和列表入口。
- 输入栏提供翻译、总结、代码审查三项预设 Prompt。
- `shared/services/voice_service.dart` 提供 `speech_to_text` 语音输入和 `flutter_tts` 语音播报适配；插件不可用时返回降级结果。
- LLM 请求具备连接/发送/接收超时、安全错误映射和 SSE 尾事件刷新；消息、会话和资料具备大小/数量边界。
- 聊天主页支持系统跟随的浅色/深色主题，空会话显示引导状态。

## 下一步与已知限制

- RAG：已完成本地资料管理、持久化、请求注入和抽屉入口；仍是关键词检索，不包含文件格式解析或向量语义检索。
- 检索以英文单词、数字和中文单字匹配，适合小规模本地文本。
- 三模型兼容请求已用模拟响应测试，尚未记录实际供应商请求成功的证据。
- 模型设置完整页面和设计稿中的文生图页面未实现；现有聊天主页已支持系统深色主题。
- 设计稿中的设置页、文生图页和独立流式 typing 指示器未实现；页面逐屏截图和大字体/横屏矩阵仍待人工验收。
- API Key 虽通过 `--dart-define` 注入，但移动端/Web 客户端凭据仍可被提取；生产环境需要服务端代理或可撤销短期凭据。
- 会话和本地资料当前由 `shared_preferences` 明文保存；OHOS 没有当前锁定版本的官方实现，平台持久化和隐私政策入口仍待补齐。
- 语音真实设备验收仍待 Android/OHOS 构建门禁恢复；OHOS 当前没有这两个上游插件的实现。

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

当前 Web 已通过构建；Android 模拟器已发现但受 Gradle loopback 错误阻塞；OHOS 模拟器已发现但 HAP 受 DevEco 调试签名配置阻塞。`shared_preferences` 当前版本没有 OHOS 实现，鸿蒙端持久化仍需专用适配或降级策略。三端 L3 和设计逐屏 L4 均未完成。

## 持续记录

- 变更摘要：[changes.md](changes.md)
- 当前任务：[tasks.md](tasks.md)
- 日期化开发日志：[docs/development-log.md](docs/development-log.md)
- 验证证据索引：[docs/qa/README.md](docs/qa/README.md)
- 每个可验证单元单独 commit，并在开发日志中记录验证命令、结果和风险。
- 约束以 `AGENTS.md` 为准；本文件提供当前实现上下文，不替代技术栈和设计规范。
