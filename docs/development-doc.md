# 阶段②｜「ChatFlow 跨端 AI 助手」Flutter 项目 —— 详细开发文档

> 时间区间：**2025.2 – 2025.9**
> 定位：跨端拓展 + 「AI 能力从 0 到 1」的起点。一份 Dart 代码部署到 iOS / Android / Web / 桌面，AI 核心层抽成平台无关模块，AI 能力**分阶段渐入**（先调 API，再流式，最后语音 + RAG 雏形）。

---

## 1. 项目概述

一句话：**一套代码跑通 iOS / Android / Web / 桌面的 AI 助手，从「云端 LLM 对话」起步，逐步加入流式输出、语音与 RAG，AI 核心层与 UI 解耦。**

- **框架**：Flutter 3.x（Dart 3）
- **状态管理**：Riverpod 2.x
- **网络**：dio
- **支持平台**：iOS、Android、Web、Windows/macOS/Linux

---

## 2. 选题理由

| 维度 | 说明 |
|---|---|
| 时间点契合 | 2025.2 正好是 DeepSeek-R1(1.20) 爆火期，接入大模型是当时最热的方向 |
| AI 渐入叙事 | 「先用 API → 再流式 → 再 RAG」完整呈现 AI 能力从入门到进阶的过程 |
| 架构亮点 | AI 核心层平台无关，是面试最想听的架构故事 |
| 承上启下 | 承接阶段①的原生基础，为阶段③④的鸿蒙深耕做技术迁移 |

---

## 3. 目标用户与核心场景

1. **多端统一体验**：手机、Web、桌面共享同一套会话与功能。
2. **内容创作**：文案生成、翻译、摘要、代码辅助。
3. **演示友好**：Web 版可部署成在线 Demo 给面试官试用。

---

## 4. 核心功能清单（按 AI 渐入三阶段）

### 4.1 阶段一：AI 入门（云端 LLM 调用）
- [x] 多模型接入（DeepSeek-R1 / 通义 Qwen2.5 / Gemini 2.0 Flash）
- [x] 单轮对话（发送 → 一次性返回）
- [x] 会话管理 + 本地持久化（OHOS 持久化仍待平台适配）

### 4.2 阶段二：流式体验
- [x] SSE 流式输出（逐字渲染 + Markdown）
- [x] 多会话 + 上下文管理
- [x] 预设 Prompt 模板（翻译 / 总结 / 代码审查）

### 4.3 阶段三：进阶能力
- [x] 语音输入（speech_to_text）/ 语音播报（flutter_tts）（Android/Web；OHOS 无上游实现时降级）
- [x] RAG 雏形（本地文档片段检索注入）
- [ ] 桌面端支持 + Web 部署 Demo（Web 构建已通过，桌面端未验收）

> ⚠️ 时间红线：阶段一只能用 DeepSeek-R1 / Qwen2.5 / Gemini 2.0 Flash；**Qwen3（2025.4）、Gemini 2.5（2025.3 后）只能出现在阶段三后期**。

---

## 5. 技术选型与架构

### 5.1 技术栈
| 能力 | 选型 |
|---|---|
| 状态管理 | Riverpod |
| 网络/SSE | dio（自定义 SSE 流解析） |
| Markdown | flutter_markdown |
| 语音 | speech_to_text、flutter_tts |
| 本地存储 | shared_preferences / hive / drift |

### 5.2 分层架构（AI 核心层与 UI 解耦）
```
┌───────────────────────────────────────────────┐
│  UI 层（Widget，平台相关：语音/平台能力）         │
├───────────────────────────────────────────────┤
│  表现层（Riverpod Provider / ViewModel）        │
├───────────────────────────────────────────────┤
│  ★ AI 核心层（纯 Dart，无 Flutter 依赖）★       │
│   llm / stream / rag / memory                  │
├───────────────────────────────────────────────┤
│  平台适配层（dio、shared_preferences 等）       │
└───────────────────────────────────────────────┘
```

> `core/` 目录**不 import 任何 Flutter UI 依赖**，只依赖 Dart 标准库和纯 Dart 包，可单独测试、复用、迁移。

---

## 6. 项目结构

```
chatflow/
├── lib/
│   ├── main.dart
│   ├── app/                    # router / theme
│   ├── features/
│   │   ├── chat/               # 页面 + Controller
│   │   └── settings/
│   ├── core/                   # ★ AI 核心层（纯 Dart）
│   │   ├── llm/
│   │   │   ├── llm_client.dart
│   │   │   └── sse_parser.dart
│   │   ├── rag/
│   │   │   ├── retriever.dart
│   │   │   └── embedder.dart
│   │   ├── memory/
│   │   │   └── conversation_memory.dart
│   │   └── models/
│   │       ├── message.dart
│   │       └── llm_config.dart
│   └── shared/                 # 平台适配封装
├── pubspec.yaml
└── test/                       # 重点覆盖 core/
```

---

## 7. 核心模块设计

### 7.1 数据模型（纯 Dart）
```dart
// core/models/message.dart
enum MessageRole { system, user, assistant }

class Message {
  final MessageRole role;
  final String content;
  Map<String, dynamic> toApiJson() { /* 转 OpenAI 格式 */ }
}
```

### 7.2 统一 LLM 客户端（纯 Dart，支持流式）
```dart
// core/llm/llm_client.dart
class LLMClient {
  final LLMConfig config;

  /// 流式对话：逐 token 回调
  Stream<String> chatStream(List<Message> messages) async* {
    // 用 HTTP 客户端发 SSE 请求，解析 data 行，yield 增量 token
  }

  Future<String> chat(List<Message> messages) async { /* 非流式 */ }
}
```

### 7.3 SSE 流解析
```dart
// core/llm/sse_parser.dart
class SseParser {
  final StringBuffer _buffer = StringBuffer();
  List<String> push(String chunk) {
    // Web 端可能一次拿到完整 chunk，移动端按帧分片
    // 统一按换行切分，处理跨 chunk 半行
  }
}
```

### 7.4 表现层（Riverpod）
```dart
// features/chat/application/chat_controller.dart
class ChatController extends AsyncNotifier<List<Message>> {
  Future<void> send(String text) async {
    // 1. 追加 user 消息
    // 2. 订阅 core 的 chatStream，逐 token 更新 UI
    // 3. 结束后追加完整 assistant 消息
  }
}
```

### 7.5 RAG 雏形（阶段三）
```dart
// core/rag/retriever.dart
class Retriever {
  // 本地文档切分 + 关键词/向量检索，拼接上下文注入 LLM
}
```

---

## 8. 关键难点与解决方案

| 难点 | 方案 |
|---|---|
| Web 与移动端 SSE 行为差异 | 统一封装成 `Stream`，各平台走同一套解析器 |
| 流式 UI 频繁重建 | `AsyncNotifier` + 局部刷新，避免整页 rebuild |
| API Key 安全 | 「本地配置」+「服务端中转」两种模式，发布用服务端 |
| 跨端语音差异 | 语音能力归入平台适配层，用抽象接口 + 各端实现 |
| 桌面端网络权限 | 注意 CORS / 网络权限配置 |

---

## 9. 开发里程碑

| 阶段 | 目标 | 周期 |
|---|---|---|
| M1 | 工程 + 云端 LLM 单轮对话（Android + Web） | 1 周 |
| M2 | 多模型路由 + 会话持久化 | 1 周 |
| M3 | SSE 流式输出 + Markdown | 1 周 |
| M4 | 语音 + RAG 雏形 + 桌面端 | 2 周 |

---

## 10. 测试要点

- [ ] `core/` 层纯 Dart 单元测试（SSE 解析、会话管理）
- [ ] 多平台 widget 测试
- [ ] Web 部署后真实网络请求（CORS）
- [ ] 流式输出中途断网的恢复与报错

---

## 11. 交付/发布要点

- Web 版部署成可访问链接（简历附链接，面试官可直接体验）
- Android 打包 APK / AAB
- 隐私政策 + API Key 服务端化

---

## 12. 简历亮点 + 时间锚点

> **时间区间**：2025.2 – 2025.9（AI 渐入）
> **可用模型**：DeepSeek-R1 / 通义 Qwen2.5 / Gemini 2.0 Flash（后期 Qwen3、Gemini 2.5）

**简历写法**：负责 Flutter 跨端 AI 助手开发，从云端 LLM 对话起步，逐步落地 SSE 流式输出、语音交互与 RAG 雏形，将 AI 核心层抽成平台无关的 Dart 模块，一套代码部署到 iOS / Android / Web / 桌面，核心层单元测试覆盖率 80%+。
