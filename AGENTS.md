# AGENTS.md — ChatFlow 项目上下文（AI 编码智能体必读）

> 本文档是 Codex / Claude / DeepSeek 等智能体在本项目工作时的唯一事实来源。

## 1. 项目一句话
「ChatFlow」：Flutter 跨端 AI 助手，一份代码跑 iOS / Android / Web / 桌面（本仓库已含 android/ohos/web）。AI 能力**分阶段渐入**：先云端 LLM 对话 → 再 SSE 流式 → 再语音 + RAG 雏形。

## 2. 技术栈（锁定，不得擅自更换/升级）
- 框架：Flutter 3.7.12-ohos（鸿蒙分支，Dart 2.19.6）——**不要升级到非 ohos 版本**
- 状态管理：Riverpod 2.x
- 网络：dio（SSE 流式解析自定义实现）
- Markdown：flutter_markdown
- 语音：speech_to_text、flutter_tts
- 本地存储：shared_preferences（或 drift）
- AI 模型：DeepSeek-R1 / 通义 Qwen2.5 / Gemini 2.0 Flash（OpenAI 兼容接口）

## 3. 必读文档（本仓库 docs/）
| 文件 | 内容 |
|---|---|
| `docs/design.html` | UI 设计图（风格/配色/功能/5 屏）——**设计真源** |
| `docs/development-doc.md` | 详细开发文档 |
| `docs/agent-spec.md` | 智能体开发约束与规范 |
| `PROJECT_CONTEXT.md` | 当前实现、目录职责和已知限制 |
| `tasks.md` | 任务状态和阻塞恢复条件 |
| `docs/development-log.md` | 按日期记录改动、验证、风险和 commit |

## 4. 架构要求（重点：AI 核心层与 UI 解耦）
```
lib/
├── core/                 # ★ AI 核心层：纯 Dart，禁止 import Flutter UI
│   ├── llm/llm_client.dart、sse_parser.dart
│   ├── rag/retriever.dart
│   ├── memory/conversation_memory.dart
│   └── models/message.dart、llm_config.dart
├── features/chat/        # 表现层（Riverpod Controller + 页面）
├── shared/services/      # 平台适配层（语音等）
└── theme/design_tokens.dart
```
> 硬性要求：`core/` 目录不 import 任何 Flutter UI 依赖，只依赖 Dart 标准库和纯 Dart 包；核心层要有单元测试。

## 5. 功能需求 + 验收清单（分阶段）
### 阶段一（AI 入门）
- [x] 多模型接入（DeepSeek-R1/Qwen2.5/Gemini 2.0 Flash），可配置切换
- [x] 单轮对话 + 会话管理 + 本地持久化
### 阶段二（流式）
- [x] SSE 流式逐字渲染 + Markdown 展示
- [x] 多会话 + 上下文管理
### 阶段三（进阶）
- [ ] 语音输入/播报
- [x] RAG 雏形（本地文档片段检索注入）

### 通用验收
- [ ] 三端（Android/Web/Ohos）都能 `flutter run` 跑通
- [x] core/ 单元测试覆盖 SSE 解析 + 会话管理
- [x] API Key 走配置/环境变量，不硬编码

> 上述功能勾选代表实现和自动测试完成；真实供应商请求、三端运行及设计逐屏人工验收仍待完成。Web 已构建通过，Android/OHOS 受环境阻塞。

## 6. 设计 Token（UI 必须引用，禁止硬编码色值）
见 `lib/theme/design_tokens.dart`。关键值：主色 `#6366F1`、流式绿 `#22C55E`、
渐变紫 `#8B5CF6`、浅背景 `#F8FAFC`、深背景 `#0F172A`、圆角 14。

## 7. 编码约束（硬性规则）
1. 增量修改，禁止大文件覆盖式重写。
2. 颜色/字号/圆角引用 design_tokens，禁止硬编码。
3. 禁止擅自升级 Flutter/Dart 或新增非清单依赖。
4. 禁止硬编码 API Key，走 `--dart-define` 或本地配置文件。
5. 核心层（core/）保持纯 Dart，可单测。
6. 每任务输出：改动说明 / 涉及文件 / 验证方式 / 遗留风险。

## 8. 构建与运行命令
```bash
flutter pub get
flutter run -d chrome          # Web
flutter run -d <android-device> # Android
flutter run -d <ohos-device>    # 鸿蒙（需真机/模拟器 + hdc）
flutter test                    # 单元测试
flutter build apk --debug
```

## 9. 验收门禁
L1 `flutter analyze` 零错误 → L2 `flutter test` 通过 → L3 三端 run 通核心链路（截图）→ L4 人工 review。

## 10. 当前进度与下一步
- 已完成：对话主页、多模型配置、SSE 流式、Markdown、多会话、Riverpod 和本地持久化。
- 当前：阶段三 RAG 已完成本地资料模型、持久化、抽屉管理和聊天请求上下文注入；关键词检索及 Controller 接入通过单测。
- 下一步：语音输入/播报、Prompt 模板和三端真实运行验收；任务状态和验证证据见 `tasks.md` 与 `docs/development-log.md`。
- 每完成一个可验证单元就 git 提交。
- 每个任务开始前更新 `tasks.md`；验证后同步 `changes.md`、`PROJECT_CONTEXT.md` 与 `docs/development-log.md`，记录真实结果和 commit。
