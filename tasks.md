# ChatFlow 任务清单

> 状态值：`done` 已完成并验证；`in_progress` 正在开发；`blocked` 受外部环境阻塞；`todo` 尚未开始。
> 每个可验证单元完成后单独提交，并在 `docs/development-log.md` 记录证据。

## 本轮完成与后续任务

- [done] 全面代码、安全、布局和发布配置审查；修复可在仓库内闭环的缺陷并留存验证证据（报告：`docs/qa/2026-10-11-audit-report.md`）。
- [done] 补全持续记录文件和按日期、任务、文件、验证、风险、commit 编排的开发日志。
- [done] RAG 核心单元：纯 Dart 文档切分、关键词检索、上下文注入接口及单测。
- [done] RAG 应用接入：本地文档输入/管理、ChatController 请求注入和 UI 联调。

## 阶段一：AI 入门

- [done] DeepSeek-R1、Qwen2.5、Gemini 2.0 Flash 配置切换及兼容客户端；以模拟响应验证。
- [done] OpenAI 兼容接口的单轮调用接口与本地演示回复；主页发送使用流式调用。
- [todo] 使用实际 API Key 验证三供应商网络响应及 Web CORS。
- [done] 消息 JSON 序列化与恢复。
- [done] 多会话创建、切换、重命名、删除。
- [done] `shared_preferences` 本地持久化适配。

## 阶段二：流式体验

- [done] SSE 跨 chunk 分块解析。
- [done] SSE 流式增量渲染。
- [done] Markdown 回复展示。
- [done] 多会话上下文管理。
- [done] 预设 Prompt 模板（翻译、总结、代码审查）。

## 阶段三：进阶能力

- [done] RAG 核心：文档片段检索及生成请求上下文的纯 Dart 接口。
- [done] RAG 接入聊天发送流程和本地文档管理；发送请求会注入命中资料上下文。
- [done] 语音输入（`speech_to_text`，Android/Web 适配层）。
- [done] 语音播报（`flutter_tts`，Android/Web 适配层）。

## 审查后续

- [todo] 补齐设计稿中的模型设置页和文生图页，或在首发范围中移除未实现声明。
- [todo] 增加应用内隐私政策入口，说明本地存储和第三方模型请求。
- [todo] 提供正式 Android applicationId/签名和 OHOS bundleName/vendor/签名，完成 release 包核验。
- [todo] 评估服务端代理/短期凭据，避免将长期 API Key 编译进客户端。
- [todo] 为 OHOS 适配语音和持久化插件，或明确首发降级范围。

## 验收门禁

- [done] L1：`flutter analyze` 零错误。
- [done] L2：核心层、Controller、存储和 Widget 共 50 项测试通过（2026-10-11）。
- [done] Web：`flutter build web` 通过。
- [blocked] Android：模拟器已发现，但 Gradle 报 `Unable to establish loopback connection`；恢复条件：解决本机 Java/Gradle 回环连接后重新运行 `flutter run -d emulator-5554`。
- [blocked] OHOS：模拟器已发现，但 HAP 因未配置 DevEco 调试签名而未生成；恢复条件：在 DevEco Studio 的 Signing Configs 勾选 Automatically generate signature 后重新运行 `flutter run -d 127.0.0.1:5557`。
- [todo] 三端真实设备核心链路和截图验证。
- [todo] L4 人工 UI 逐屏复核。

## 记录规则

1. 任务开始前将本项设为 `in_progress`。
2. 完成后补充验证命令、结果、风险和 commit 到 `docs/development-log.md`。
3. 外部环境阻塞必须记录恢复条件，不能写成代码已完成。
4. 提交前写日志并标记“随本任务提交”；提交后在下一次记录提交中补入实际 SHA，不猜测或伪造提交号。
