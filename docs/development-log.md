# ChatFlow 开发日志

> 本文件按日期追加。每条记录只写已发生的任务、文件、验证证据、风险和 commit；计划使用 `tasks.md` 管理。

## 2026-10-10

### 任务：对话主页和多模型基础

- **改动文件**：`lib/main.dart`、`lib/theme/design_tokens.dart`、`lib/core/models/message.dart`、`lib/core/models/llm_config.dart`、相关测试。
- **改动**：建立设计 Token、对话主页、三模型配置、消息模型和本地演示回复。
- **验证结果**：`flutter analyze` 通过；Widget 和模型测试通过。
- **风险**：真实设备运行尚未完成；API Key 必须通过运行参数提供。
- **commit**：`23221e6`、`a9bc52c`。

### 任务：SSE 解析与 LLM 客户端

- **改动文件**：`lib/core/llm/sse_parser.dart`、`lib/core/llm/llm_client.dart`、`pubspec.yaml`、相关测试。
- **改动**：支持跨 chunk 半行、多行 `data:`、`[DONE]`，并接入 OpenAI 兼容非流式和流式请求。
- **验证结果**：SSE 和客户端测试通过；核心层未引入 Flutter UI 依赖。
- **风险**：不同供应商错误响应结构可能需要后续补充；Web 真实网络请求仍受 CORS 和 Key 配置影响。
- **commit**：`40d99f6`、`acb1d76`、`de3bd0d`。

### 任务：会话内存和本地持久化

- **改动文件**：`lib/core/memory/conversation_memory.dart`、`lib/core/models/message.dart`、`lib/shared/services/conversation_storage.dart`、相关测试。
- **改动**：增加消息 JSON 往返、只读会话快照、`shared_preferences` 保存/读取/清空和损坏数据检查。
- **验证结果**：分析通过；核心和存储测试通过。
- **风险**：当前 `shared_preferences` 官方包未声明 OHOS 平台，OHOS 需要专用适配或降级策略。
- **commit**：`88409e9`、`67d905e`、`f976293`。

### 任务：Riverpod 状态层和 Markdown

- **改动文件**：`lib/features/chat/application/chat_controller.dart`、`lib/main.dart`、`pubspec.yaml`、相关测试。
- **改动**：将发送、流式更新、模型切换和持久化从页面移入 Controller；助手回复使用 Markdown 渲染。
- **验证结果**：`flutter analyze` 通过；全量测试达到 21 项；`flutter build web` 退出码 0。
- **风险**：`flutter_markdown 0.6.15` 已标记 discontinued，但当前项目规范仍要求 `flutter_markdown`；暂不升级依赖。
- **commit**：`1ba75fd`、`f1ed3bd`。

### 任务：多会话和会话抽屉

- **改动文件**：`lib/core/memory/conversation_session.dart`、`lib/shared/services/conversation_storage.dart`、`lib/features/chat/application/chat_controller.dart`、`lib/main.dart`、相关测试。
- **改动**：增加会话实体、旧单会话数据兼容、会话列表持久化、新建/选择/重命名/删除和设计稿侧边栏。
- **验证结果**：`flutter analyze` 通过；全量测试达到 26 项；`flutter build web` 退出码 0。
- **风险**：Android 当前构建遇到 `java.io.IOException: Unable to establish loopback connection`；OHOS `hdc list targets` 返回 `[Empty]`，没有完成三端运行验收。
- **commit**：`f374227`。

## 2026-10-09

### 任务：工程初始化和规范建立

- **改动文件**：工程骨架、`AGENTS.md`、`docs/design.html`、设计 Token、提示模板和基础配置。
- **验证结果**：工程初始化提交完成。
- **风险**：当时仍为默认计数器骨架，后续需要按设计文档逐步替换。
- **commit**：`d587f63`、`ce297e4`。

## 当前未完成项

- 阶段三语音输入、语音播报和 RAG 雏形。
- Prompt 模板。
- Android、OHOS 真实设备运行和截图证据。
- 发布签名、隐私政策及应用市场上架检查。
