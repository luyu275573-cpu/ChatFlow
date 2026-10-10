# ChatFlow 全面审查报告

审查日期：2026-10-11（Asia/Shanghai）  
分支：`codex/chat-home-skeleton`  
审查范围：核心逻辑、异常路径、数据与安全、Android/OHOS 发布配置、聊天主页布局和 `docs/design.html` 对齐情况。

## 结论

代码质量门禁当前通过：`flutter analyze` 无问题，完整测试 50 项通过，`flutter build web` 通过。Android 模拟器和 OHOS 模拟器均能被 Flutter 发现，但 Android 因 Gradle loopback 连接错误无法构建，OHOS 因未配置 DevEco 调试签名无法生成 signed HAP，因此三端真实运行和发布包验收仍未通过。

发布结论为 **blocked**。仓库仍保留模板身份和签名配置，且没有隐私政策入口；这些问题不能用自动化单测替代。

## 本轮已修复

| 级别 | 问题 | 修复位置 | 结果 |
| --- | --- | --- | --- |
| P1 | Android release 主清单缺少联网权限，正式包无法访问模型服务 | `android/app/src/main/AndroidManifest.xml:5-9` | 已补 `INTERNET`，仍需 signed release 验证 |
| P1 | SSE 连接关闭时最后一条 `data:` 没有空行会丢失最后 delta | `lib/core/llm/sse_parser.dart:23`、`lib/core/llm/llm_client.dart:70` | 增加 `finish()`，新增回归测试 |
| P1 | 网络超时未设置，异常文本直接显示给用户可能泄漏 URL/供应商响应 | `lib/core/llm/llm_client.dart:19-29,147-166`、`lib/features/chat/application/chat_controller.dart:339-348` | 增加 15/15/60 秒超时和安全错误映射，异常测试确认不显示 token |
| P1 | 发送中切换模型会造成界面状态与实际请求模型不一致 | `lib/features/chat/application/chat_controller.dart:182-186,269-270` | 发送中禁止切换，回复使用发送时快照 |
| P2 | 本地会话/资料和模型回复无大小、数量边界，损坏或恶意数据可造成内存和存储压力 | `lib/core/models/message.dart:6`、`lib/core/memory/conversation_session.dart:15`、`lib/core/rag/local_document.dart:13`、两个 storage | 增加内容、消息、会话、资料上限和重复 ID 校验 |
| P2 | 聊天页始终按浅色组件绘制，系统深色模式下背景、气泡和输入栏对比度错误 | `lib/main.dart:36-68,596-783` | 增加系统跟随深色主题并复用 design tokens |
| P2 | 新会话没有空状态，用户无法判断页面是否可用 | `lib/main.dart:554-575` | 增加“开始一段新对话”空状态 |

## 未解决的安全和发布风险

| 级别 | 发现 | 证据和影响 | 建议 |
| --- | --- | --- | --- |
| 阻断上架 | Android 仍使用模板包名、debug 签名 | `android/app/build.gradle:47,60` 的 `com.example.chatflow` 和 `signingConfigs.debug` | 由项目负责人提供正式 applicationId、keystore 和 CI 签名配置；不能提交 debug key |
| 阻断上架 | OHOS 身份和签名未配置 | `ohos/AppScope/app.json5:3-4` 为 `com.example.chatflow`/`example`；`ohos/build-profile.json5:4` 的 `signingConfigs` 为空 | 在 DevEco 配置真实 bundleName/vendor 和自动或正式签名，重新生成并核验 release HAP |
| 上架前必须修复 | 应用没有应用内隐私政策入口；本地会话、资料和请求内容可能包含敏感信息 | 发布扫描报告 `PRIVACY-001`；`shared_preferences` 明文保存 | 增加隐私政策页面/链接，说明本地保存、向第三方模型发送、删除方式和保留期限 |
| 高风险 | `String.fromEnvironment` 只是编译时注入，Web/移动端包内 API Key 可被提取 | `lib/core/models/llm_config.dart:16-30` | 生产环境使用服务端代理或短期、可撤销凭据；不要把长期供应商 Key 打进公开包 |
| 高风险 | `shared_preferences` 明文存储会话、资料和请求上下文 | `lib/shared/services/conversation_storage.dart:1-105`、`lib/shared/services/local_document_storage.dart:1-88` | 若进入生产场景，使用平台安全存储/加密数据库，并提供清除入口 |
| 未验证 | OHOS 上游 `speech_to_text`/`flutter_tts` 没有 OHOS 实现；`shared_preferences` 当前锁定版本也没有 OHOS 实现 | `pubspec.yaml:37-39`，已有语音降级代码 | 增加 OHOS 原生适配或明确首发不支持语音/持久化，不能把降级当作功能通过 |
| 建议优化 | `flutter_markdown 0.6.15` 已 discontinued | `pubspec.yaml:36`、`flutter pub outdated` | 保持 Flutter 3.7.12-ohos 约束下评估 `flutter_markdown_plus` 的兼容迁移，单独验证后再升级 |

## 逻辑和数据审查

- 会话选择、删除和重命名在发送期间被 Controller 拦截；流式回写现在按发送时的 session ID 定位，避免活动会话变化导致写错消息。
- LLM 请求现在区分超时、HTTP 状态和连接失败，用户界面不会显示 Dio 原始异常或响应体。
- SSE 覆盖跨 chunk、CRLF、多行 `data:`、`[DONE]` 和无尾部分隔行；新增测试见 `test/core/llm/llm_client_test.dart` 与 `test/core/llm/sse_parser_test.dart`。
- JSON 损坏仍会被识别并降级到本地演示状态；当前不会自动备份或隔离损坏数据，生产版本应增加恢复提示和备份策略。
- RAG 仍是小规模关键词检索，中文按单字匹配会有误召回，资料内容仍可能包含提示注入；已有 system 消息明确将资料标记为不可信参考，但不能替代模型侧安全策略。
- 语音播报目前直接读取助手 Markdown 文本，代码块和链接可能被原样朗读；不影响文字聊天，但属于体验优化项。

## 页面和设计规范审查

已符合：

- 主色、背景、边框、字号、圆角和间距集中在 `lib/theme/design_tokens.dart`，聊天页不再直接写设计色值。
- 用户气泡右对齐、AI 气泡左对齐，AI 气泡使用描边和 14px 圆角；输入栏位于底部并使用安全区。
- 模型选择、会话列表、Prompt、语音输入、发送和播报按钮均有可读 tooltip/语义名称；Web 语义树已实际读出中文和主要控件。
- 空状态、错误提示、无 API Key 本地演示和插件不可用降级路径可达；系统深色主题已覆盖 AppBar、气泡、Markdown 代码块和输入栏。

仍与设计真源有差距：

- `docs/design.html` 的设置页、模型配置页和文生图页尚未实现，当前只有聊天主页、会话资料弹层和 Prompt 弹层；首发范围需要补齐页面或从商店描述中移除未实现能力。
- 设计稿要求五屏逐屏截图验收，本轮只完成 Web 构建和桌面宽度视觉检查，尚无 Android/OHOS 真机截图。
- 设计稿包含流式打字指示器，当前页面只有消息内容更新，没有独立的三点 typing 状态。
- 未声明 CJK 字体资源；Web 截图的中文字形需要在目标浏览器和真机上复核，必要时补充具备许可的 Noto Sans SC 字体资源。
- 尚未执行大字体、横屏、超长链接/代码块和系统读屏的完整矩阵测试。

## 验证证据

- [L1 分析输出](2026-10-11-audit-analyze.txt)
- [L2 完整测试输出（50 项）](2026-10-11-audit-test.txt)
- [Web 构建输出](2026-10-11-audit-web-build.txt)
- [Android 运行输出](2026-10-11-audit-android-run.txt)
- [OHOS 运行输出](2026-10-11-audit-ohos-run.txt)
- [HarmonyOS 发布静态扫描（以 `ohos/` 为工程根）](2026-10-11-audit-release-scan-ohos-root.json)

官方发布规则页面本轮在线请求均返回 HTTP 200；具体签名、隐私主体、AGC 标签、截图素材和真机行为仍没有项目证据，不能判定为已通过。
