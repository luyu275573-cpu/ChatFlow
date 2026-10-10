# ChatFlow 开发日志

> 本文件按日期追加，日期使用 Asia/Shanghai。每条记录包含任务、改动文件、验证结果、风险和 commit；计划使用 `tasks.md` 管理。
> 历史基线根据 Git 历史和本会话实际执行结果回填；未保留的早期原始日志不补造。提交前标注“随本任务提交”，提交后在后续记录提交中补入实际 SHA。

## 2026-10-11

### 任务：模型设置与运行时配置持久化

- **改动文件**：`lib/core/models/llm_config.dart`、`lib/shared/services/model_config_storage.dart`、`lib/features/chat/application/chat_controller.dart`、`lib/main.dart`、`test/shared/services/model_config_storage_test.dart`、`test/features/chat/application/chat_controller_test.dart`、`test/widget_test.dart`、`tasks.md`。
- **改动**：新增模型设置弹层，支持 DeepSeek-R1、Qwen2.5、Gemini 2.0 Flash 的运行时选择、API Key、温度和 System Prompt；Controller 统一管理配置并把 System Prompt 注入请求；新增偏好存储恢复。持久化只保存相对内置默认值的覆盖项，避免无操作时复制构建时注入的默认 Key。
- **验证结果**：`dart format` 通过；`flutter analyze` 退出码 0；`flutter test --reporter expanded` 退出码 0，共 54 项通过；`flutter build web` 退出码 0，产物目录为 `build/web/`。原始输出见 `docs/qa/2026-10-11-model-settings-*`。未运行 Android/OHOS 设备、真实供应商 API 或人工 UI 测试。
- **风险**：用户输入的 API Key 仍以 `shared_preferences` 明文保存，生产环境需服务端代理或平台安全存储；设置当前是弹层而非设计稿独立全屏页；三端 L3/L4 继续受既有签名、Gradle 和人工验收门禁限制。
- **commit**：`e61fa6b`（代码与任务状态）；记录与验证证据随本任务提交。

### 任务：代码、安全、布局和发布配置全面审查

- **改动文件**：`android/app/src/main/AndroidManifest.xml`、`lib/core/llm/llm_client.dart`、`lib/core/llm/sse_parser.dart`、`lib/features/chat/application/chat_controller.dart`、`lib/main.dart`、`lib/theme/design_tokens.dart`、消息/会话/资料模型与存储、对应测试；审查报告和证据见 `docs/qa/2026-10-11-audit-report.md` 及 `docs/qa/2026-10-11-audit-*`。
- **改动**：补上 Android release INTERNET 权限；为 LLM 请求增加超时和安全错误映射；刷新无尾部分隔行的 SSE 事件；按 session ID 回写流式消息并锁定发送中的模型；增加消息、会话和资料边界校验；聊天主页增加系统深色主题和新会话空状态。
- **验证结果**：`flutter analyze` 退出码 0；`flutter test --reporter expanded` 退出码 0，共 50 项通过；`flutter build web` 退出码 0；Android `flutter run -d emulator-5554 --debug --no-resident` 仍因 `Unable to establish loopback connection` 失败；OHOS `flutter run -d 127.0.0.1:5557 --debug --no-resident` 仍因未配置 DevEco 调试签名、未生成 signed HAP 失败；官方发布规则页面 HTTP 200。原始输出见 `docs/qa/`。
- **风险**：正式 Android/OHOS 身份、签名、隐私政策和真实设备闭环仍未验证；客户端编译时 API Key 可被提取；`shared_preferences` 明文且无 OHOS 官方实现；设置页、文生图页和逐屏设计截图仍待完成；`flutter_markdown` 已 discontinued。
- **commit**：`89f994f`（代码）；`f180f30`（边界校验回归测试和测试证据）；记录与其余审查证据随本任务提交。

### 任务：语音输入与播报适配

- **改动文件**：`lib/shared/services/voice_service.dart`、`lib/main.dart`、`android/app/src/main/AndroidManifest.xml`、`pubspec.yaml`、`pubspec.lock`、对应测试、`tasks.md`。
- **改动**：锁定 Dart 2.19 兼容的 `speech_to_text 5.6.1` 和 `flutter_tts 3.8.5`；新增语音服务适配、Android 麦克风权限、输入栏录音填词和助手气泡播报按钮。插件初始化或调用失败时返回降级结果，不阻断文字聊天。
- **验证结果**：`flutter analyze` 退出码 0；`flutter test --reporter expanded` 退出码 0，共 44 项通过；`flutter build web` 退出码 0。原始输出见 [验证索引](qa/README.md)。
- **风险**：上游两个插件均未声明 OHOS 平台，鸿蒙端只能提示不可用；Android/OHOS 真实语音仍需解决 Gradle 回环和 DevEco 签名门禁后复测；未把模拟器单测当作麦克风或扬声器验收。
- **commit**：`8b8b19d`（代码）；`5107cfe`（记录与验证证据）。

## 2026-10-10

### 任务：预设 Prompt 模板

- **改动文件**：`lib/core/models/prompt_template.dart`、`lib/main.dart`、`test/core/models/prompt_template_test.dart`、`test/widget_test.dart`、`tasks.md`。
- **改动**：增加翻译、总结、代码审查三项纯 Dart Prompt 模板；输入栏新增选择入口，选中后将指令填入输入框供用户继续编辑或直接发送。
- **验证结果**：`flutter analyze` 退出码 0；`flutter test --reporter expanded` 退出码 0，共 42 项通过；`flutter build web` 退出码 0。原始输出见 [验证索引](qa/README.md)。
- **风险**：模板当前只提供固定中文指令，没有用户自定义模板和持久化；Android Gradle loopback 与 OHOS 调试签名阻塞仍未解决。
- **commit**：`1467b52`（代码）；`8106211`（记录与验证证据）。

### 任务：RAG 应用接入与本地资料管理

- **改动文件**：`lib/core/rag/local_document.dart`、`lib/shared/services/local_document_storage.dart`、`lib/features/chat/application/chat_controller.dart`、`lib/main.dart`、对应测试、`tasks.md`。
- **改动**：增加本地资料模型和 `shared_preferences` 持久化；会话抽屉支持资料新增、删除和列表；Controller 恢复资料后重建检索器，并在真实流式请求前将命中资料插入 system 消息之后。通过可注入流工厂测试请求上下文，未改变无 API Key 时的本地演示回复。
- **验证结果**：`flutter analyze` 退出码 0；`flutter test --reporter expanded` 退出码 0，共 39 项通过；`flutter build web` 退出码 0。`flutter devices` 发现 Android `emulator-5554` 和 OHOS `127.0.0.1:5557`；Android 运行因 Gradle `Unable to establish loopback connection` 失败，OHOS 运行因未配置 DevEco 调试签名、未生成 signed HAP 失败。原始输出见 [验证索引](qa/README.md)。
- **风险**：`shared_preferences` 当前版本没有 OHOS 实现，鸿蒙端资料持久化仍需适配；检索仍是小规模关键词匹配，不支持向量语义和文件格式解析；三端 L3 需解决环境门禁后复测。
- **commit**：`6f2823d`（代码）；`624c0c7`、`21cce70`（记录与验证证据）。

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

### 历史提交逐项索引

下表拆开上述任务组中的每次提交，文件列表依据 `git log --name-only`。验证栏为已留存的会话记录范围；不代表真实供应商、设备或视觉验收通过。

| 日期 | 任务 | 改动文件 | 验证结果 | 风险/未完成 | commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-10 | 对话主页骨架 | `lib/core/models/message.dart`、`lib/main.dart`、`lib/theme/design_tokens.dart`、`test/widget_test.dart` | 见对话主页任务组；未保留早期独立原始日志 | 本地演示、设计逐屏待验收 | `23221e6` |
| 2026-10-10 | 三模型配置 | `lib/core/models/llm_config.dart`、`test/core/models/message_test.dart` | 模型配置单测；未保留独立原始日志 | 三供应商实际请求待验证 | `a9bc52c` |
| 2026-10-10 | SSE 解析 | `lib/core/llm/sse_parser.dart`、`test/core/llm/sse_parser_test.dart` | 分块解析单测；未保留独立原始日志 | 设备网络行为待验证 | `40d99f6` |
| 2026-10-10 | LLM 客户端 | `lib/core/llm/llm_client.dart`、`pubspec.yaml`、`pubspec.lock`、`test/core/llm/llm_client_test.dart` | 模拟响应客户端单测；未保留独立原始日志 | 实际 Key 和 CORS 待验证 | `acb1d76` |
| 2026-10-10 | 主页真实流式调用接口 | `lib/main.dart` | 分析、11 项测试和 Web 构建通过（会话记录） | 真实模型回复无运行证据 | `de3bd0d` |
| 2026-10-10 | 会话内存序列化 | `lib/core/models/message.dart`、`lib/core/memory/conversation_memory.dart`、`test/core/memory/conversation_memory_test.dart` | 分析、15 项测试和 Web 构建通过（会话记录） | 尚未接入存储 | `88409e9` |
| 2026-10-10 | 本地存储适配 | `lib/shared/services/conversation_storage.dart`、`pubspec.yaml`、`pubspec.lock`、`test/shared/services/conversation_storage_test.dart` | 分析和 18 项测试通过（会话记录） | OHOS 插件实现缺失 | `67d905e` |
| 2026-10-10 | 主页恢复和保存 | `lib/main.dart`、`test/widget_test.dart` | 分析、19 项测试和 Web 构建通过（会话记录） | 存储错误当前降级为本地演示 | `f976293` |
| 2026-10-10 | Riverpod Controller | `lib/features/chat/application/chat_controller.dart`、`lib/main.dart`、`pubspec.yaml`、`pubspec.lock`、`test/features/chat/application/chat_controller_test.dart` | 分析、21 项测试和 Web 构建通过（会话记录） | 三端运行待验证 | `1ba75fd` |
| 2026-10-10 | 助手 Markdown | `lib/main.dart`、`pubspec.yaml`、`pubspec.lock`、`test/widget_test.dart` | 分析、21 项测试和 Web 构建通过（会话记录） | 当前依赖版本已标记 discontinued | `f1ed3bd` |
| 2026-10-10 | 多会话管理 | `lib/core/memory/conversation_session.dart`、`lib/features/chat/application/chat_controller.dart`、`lib/shared/services/conversation_storage.dart`、`lib/main.dart` 及对应四份测试 | 分析、26 项测试和 Web 构建通过（会话记录） | Android/OHOS 运行阻塞 | `f374227` |

### 任务：建立持续开发记录

- **改动文件**：`AGENTS.md`、`PROJECT_CONTEXT.md`、`changes.md`、`tasks.md`、`docs/development-log.md`。
- **改动**：记录已实现功能、历史提交、开发命令、验收范围和阻塞项，修正过时的“默认计数器”进度描述。
- **验证结果**：对照 `git log --reverse --date=short` 和会话验证结果回填；`git diff --cached --check` 通过；基线已推送。
- **风险**：早期任务没有独立保存原始日志，已明确证据范围；自动化测试通过不代表设备、真实 API 或设计验收完成。
- **commit**：`686f7a8`。

### 任务：RAG 核心检索与上下文注入接口

- **改动文件**：`lib/core/rag/retriever.dart`、`test/core/rag/retriever_test.dart`；同步 `AGENTS.md`、`README.md`、`PROJECT_CONTEXT.md`、`changes.md`、`tasks.md`、本日志和 `docs/qa/` 验证证据。
- **改动**：增加本地文本 Unicode 分块和重叠、英文词/中文单字匹配、分数排序和数量限制；将带来源的参考资料插入原有 system 消息之后，不修改会话历史。保持纯 Dart，未新增依赖。
- **验证结果**：格式化通过；`flutter analyze` 退出码 0；`flutter test --reporter expanded` 退出码 0，共 34 项通过（RAG 8 项）；`flutter build web` 退出码 0。原始输出见 [验证索引](qa/README.md)。
- **风险**：关键词扫描适合小文本集合，无语义向量检索；英文词可能被固定长度分块截断。尚未接入 ChatController 和文档管理 UI，没有真实网络或设备运行证据。Android/OHOS 历史阻塞未在本任务复检。
- **commit**：`f1ab2a2`（`feat: 增加纯 Dart RAG 检索核心`）。

## 2026-10-09

### 任务：工程初始化和规范建立

- **改动文件**：工程骨架、`AGENTS.md`、`docs/design.html`、设计 Token、提示模板和基础配置。
- **改动**：初始化 Android/OHOS/Web 目录，写入项目技术约束、开发/设计文档和提示模板。
- **验证结果**：工程初始化提交完成。
- **风险**：当时仍为默认计数器骨架，后续需要按设计文档逐步替换。
- **commit**：`d587f63`、`ce297e4`。

| 日期 | 任务 | 改动文件 | 验证结果 | 风险 | commit |
| --- | --- | --- | --- | --- | --- |
| 2026-10-09 | 工程与设计规范初始化 | Android/OHOS/Web 骨架、`lib/main.dart`、`lib/theme/design_tokens.dart`、`AGENTS.md`、`docs/`、`pubspec.yaml`、`pubspec.lock` 等 | 已核对 Git 提交；没有保存当时的原始构建输出 | 尚为计数器骨架 | `d587f63` |
| 2026-10-09 | 首个任务提示模板 | `prompts/首个任务.md` | 已核对 Git 改动；提交说明称构建验证通过，原始日志未保留 | 不能据提交标题认定三端运行已通过 | `ce297e4` |

## 当前未完成项

- Android、OHOS 真实设备运行和截图证据；三模型实际 API Key 请求及 Web CORS 验证。
- 模型设置完整页面、文生图页面、独立流式 typing 指示器和逐屏设计复核。
- Android/OHOS 正式包名、vendor、release 签名、隐私政策及应用市场上架检查。
- 生产 API 代理/短期凭据、加密本地存储和 OHOS 语音/持久化适配。
- RAG 向量检索、文件格式解析和大规模资料索引。

## 后续记录模板

每个任务在对应日期下追加，提交后补齐实际 SHA。纯文档任务执行差异、链接和状态一致性检查；代码任务按改动执行格式化、分析和测试；涉及界面的任务还需运行截图。

```markdown
### 任务：<可验证单元名称>

- **改动文件**：<仓库相对路径>
- **改动**：<最终行为及原因>
- **验证结果**：<命令、退出码、数量和证据路径；未执行的验证明确注明>
- **风险**：<限制、未完成项、阻塞恢复条件>
- **commit**：<实际 SHA；提交前使用“随本任务提交”>
```
