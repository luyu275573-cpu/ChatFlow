# ChatFlow 变更摘要

## 2026-10-10

- 建立纯 Dart `core/` 层：消息模型、LLM 配置、SSE 解析器和 LLM 客户端。
- 建立聊天主页：模型切换、消息气泡、输入栏和无 API Key 时的本地演示回复。
- 增加真实 OpenAI 兼容 SSE 流式请求，API Key 通过 `String.fromEnvironment` 读取。
- 增加消息和会话 JSON 序列化、本地 `shared_preferences` 存储。
- 使用 Riverpod 管理聊天状态，并将副作用从页面移到 Controller。
- 增加 Markdown 回复渲染。
- 增加多会话创建、切换、重命名、删除和会话抽屉。
- 增加 26 项核心、服务、Controller 和 Widget 测试。
- Web 构建通过；Android Gradle loopback 和 OHOS 无设备属于环境阻塞。

## 2026-10-09

- 初始化 Flutter / OHOS / Android / Web 工程骨架。
- 增加 `AGENTS.md`、设计文档、设计 Token 和工程提示模板。

## 当前依赖边界

- Flutter 固定为项目要求的 `3.7.12-ohos`，Dart SDK 约束为 `>=2.19.6 <3.0.0`。
- 直接依赖：`dio`、`flutter_riverpod`、`flutter_markdown`、`shared_preferences`。
- 没有提交 API Key、证书、签名口令或用户数据。
