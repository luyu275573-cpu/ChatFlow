# ChatFlow 变更摘要

## 2026-10-11

- 完成代码、安全、布局和 HarmonyOS 发布配置审查；修复 Android release INTERNET 权限缺失、SSE 尾事件丢失、LLM 超时/异常信息泄漏、发送中模型状态错配和本地数据无界增长问题。
- 聊天主页增加系统跟随深色主题、深色气泡/输入栏和新会话空状态；所有新增 UI 颜色继续引用 `design_tokens.dart`。
- 新增 6 项回归测试，完整测试达到 50 项；`flutter analyze` 和 `flutter build web` 通过。
- 留存 Android loopback、OHOS 调试签名、HarmonyOS 发布扫描、Web 构建和完整测试原始证据于 `docs/qa/2026-10-11-audit-*`；发布结论仍为 blocked。
- 审查报告见 `docs/qa/2026-10-11-audit-report.md`；未配置正式包名、vendor、签名、隐私政策和生产 API 代理。

## 2026-10-10

- 建立 `tasks.md`、`changes.md`、`PROJECT_CONTEXT.md`、`docs/development-log.md`，回填历史提交和验证范围；基线提交 `686f7a8`。
- 新增 `lib/core/rag/retriever.dart`：支持 Unicode 安全分块、重叠、英文词/中文单字匹配、排序/限量及保留系统消息的请求上下文注入。
- 新增本地资料模型与 `shared_preferences` 存储；会话抽屉支持资料新增、删除、列表，发送真实流式请求前自动注入命中资料上下文。
- 新增 8 项 RAG 测试，全量测试达到 34 项；静态分析和 Web 构建通过，证据保存在 `docs/qa/`。
- RAG 应用接入新增 5 项测试，全量测试达到 39 项；未新增依赖。Android 仍受 Gradle loopback 阻塞，OHOS 需要 DevEco 调试签名。代码提交：`6f2823d`。
- 新增纯 Dart `PromptTemplate` 和翻译/总结/代码审查三项预设；输入栏增加 Prompt 选择入口，全量测试达到 42 项，Web 构建通过。代码提交：`1467b52`。
- 新增 `VoiceService` 语音适配层，接入 `speech_to_text 5.6.1`、`flutter_tts 3.8.5`，加入 Android 麦克风权限；输入栏支持语音填词，助手消息支持播报，全量测试达到 44 项。代码提交：`8b8b19d`。
- 建立纯 Dart `core/` 层：消息模型、LLM 配置、SSE 解析器和 LLM 客户端。
- 建立聊天主页：模型切换、消息气泡、输入栏和无 API Key 时的本地演示回复。
- 增加真实 OpenAI 兼容 SSE 流式请求，API Key 通过 `String.fromEnvironment` 读取。
- 增加消息和会话 JSON 序列化、本地 `shared_preferences` 存储。
- 使用 Riverpod 管理聊天状态，并将副作用从页面移到 Controller。
- 增加 Markdown 回复渲染。
- 增加多会话创建、切换、重命名、删除和会话抽屉。
- 增加 26 项核心、服务、Controller 和 Widget 测试。
- Web 构建通过；Android Gradle loopback 和 OHOS 调试签名属于环境阻塞。

## 2026-10-09

- 初始化 Flutter / OHOS / Android / Web 工程骨架。
- 增加 `AGENTS.md`、设计文档、设计 Token 和工程提示模板。

## 当前依赖边界

- Flutter 固定为项目要求的 `3.7.12-ohos`，Dart SDK 约束为 `>=2.19.6 <3.0.0`。
- 直接依赖：`dio`、`flutter_riverpod`、`flutter_markdown`、`shared_preferences`。
- 本轮未新增 API Key、证书、签名口令或真实用户数据。
