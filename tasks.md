# ChatFlow 任务清单

> 状态值：`done` 已完成并验证；`in_progress` 正在开发；`blocked` 受外部环境阻塞；`todo` 尚未开始。
> 每个可验证单元完成后单独提交，并在 `docs/development-log.md` 记录证据。

## 当前任务

- [in_progress] 阶段三 RAG 雏形：本地文档切分、关键词检索、上下文注入接口。

## 阶段一：AI 入门

- [done] DeepSeek-R1、Qwen2.5、Gemini 2.0 Flash 配置切换。
- [done] OpenAI 兼容接口的单轮对话与本地演示回复。
- [done] 消息 JSON 序列化与恢复。
- [done] 多会话创建、切换、重命名、删除。
- [done] `shared_preferences` 本地持久化适配。

## 阶段二：流式体验

- [done] SSE 跨 chunk 分块解析。
- [done] SSE 流式增量渲染。
- [done] Markdown 回复展示。
- [done] 多会话上下文管理。
- [todo] 预设 Prompt 模板（翻译、总结、代码审查）。

## 阶段三：进阶能力

- [in_progress] RAG 雏形（本地文档片段检索注入）。
- [todo] 语音输入（`speech_to_text`）。
- [todo] 语音播报（`flutter_tts`）。

## 验收门禁

- [done] L1：`flutter analyze` 零错误。
- [done] L2：核心层、Controller、存储和 Widget 测试通过。
- [done] Web：`flutter build web` 通过。
- [blocked] Android：模拟器曾连接，但 Gradle daemon 报 `Unable to establish loopback connection`。
- [blocked] OHOS：`hdc list targets` 返回 `[Empty]`，当前没有可用设备目标。
- [todo] 三端真实设备核心链路和截图验证。
- [todo] L4 人工 UI 逐屏复核。

## 记录规则

1. 任务开始前将本项设为 `in_progress`。
2. 完成后补充验证命令、结果、风险和 commit 到 `docs/development-log.md`。
3. 外部环境阻塞必须记录恢复条件，不能写成代码已完成。
