# ChatFlow 验证证据

## 2026-10-11：全面审查与代码加固

对应代码提交：`89f994f`。

| 门禁 | 命令/检查 | 结果 | 原始输出 |
| --- | --- | --- | --- |
| L1 | `flutter analyze` | 退出码 0，无分析问题 | [分析输出](2026-10-11-audit-analyze.txt) |
| L2 | `flutter test --reporter expanded` | 退出码 0，50 项测试通过 | [测试输出](2026-10-11-audit-test.txt) |
| Web 构建 | `flutter build web` | 退出码 0，产物目录 `build/web/` | [构建输出](2026-10-11-audit-web-build.txt) |
| Android | `flutter run -d emulator-5554 --debug --no-resident` | 失败：Gradle `Unable to establish loopback connection` | [运行输出](2026-10-11-audit-android-run.txt) |
| OHOS | `flutter run -d 127.0.0.1:5557 --debug --no-resident` | 失败：未配置 DevEco 调试签名，未生成 signed HAP | [运行输出](2026-10-11-audit-ohos-run.txt) |
| 发布静态扫描 | `inspect-release.ps1 -ProjectRoot ohos` | blocked：模板身份、空签名配置、unsigned/debug HAP、无隐私信号 | [扫描报告](2026-10-11-audit-release-scan-ohos-root.json) |

完整结论、文件行号、设计差距和未解决风险见[审查报告](2026-10-11-audit-report.md)。

## 2026-10-10：RAG 核心接口

对应代码提交：`f1ab2a2`。

| 门禁 | 命令 | 结果 | 原始输出 |
| --- | --- | --- | --- |
| L1 | `flutter analyze` | 退出码 0，无分析问题 | [分析输出](2026-10-10-rag-analyze.txt) |
| L2 | `flutter test --reporter expanded` | 退出码 0，34 项测试通过（其中 RAG 8 项） | [测试输出](2026-10-10-rag-test.txt) |
| Web 构建 | `flutter build web` | 退出码 0，产物目录 `build/web/` | [构建输出](2026-10-10-rag-web-build.txt) |

本次没有界面改动，也没有连接设备验证。Web 构建证明当前应用仍能编译；新增 RAG 模块的行为由单元测试验证，尚未被聊天页面调用。L3 三端运行和 L4 人工复核保持待完成。

## 2026-10-10：RAG 应用接入

对应代码提交：`6f2823d`。

| 门禁 | 命令 | 结果 | 原始输出 |
| --- | --- | --- | --- |
| L1 | `flutter analyze` | 退出码 0，无分析问题 | [分析输出](2026-10-10-rag-app-analyze.txt) |
| L2 | `flutter test --reporter expanded` | 退出码 0，39 项测试通过 | [测试输出](2026-10-10-rag-app-test.txt) |
| Web 构建 | `flutter build web` | 退出码 0，产物目录 `build/web/` | [构建输出](2026-10-10-rag-app-web-build.txt) |
| Android | `flutter run -d emulator-5554 --debug --no-resident` | 失败：Gradle `Unable to establish loopback connection` | [运行输出](2026-10-10-rag-app-android-run.txt) |
| OHOS | `flutter run -d 127.0.0.1:5557 --debug --no-resident` | 失败：未配置 DevEco 调试签名，未生成 signed HAP | [运行输出](2026-10-10-rag-app-ohos-run.txt) |

本次验证覆盖本地资料新增、删除、列表、持久化及命中资料注入请求。Android/OHOS 设备均已被 Flutter 发现，但构建环境门禁仍未通过；没有把失败运行写成设备验收通过。

## 2026-10-10：预设 Prompt 模板

对应代码提交：`1467b52`。

| 门禁 | 命令 | 结果 | 原始输出 |
| --- | --- | --- | --- |
| L1 | `flutter analyze` | 退出码 0，无分析问题 | [分析输出](2026-10-10-prompt-analyze.txt) |
| L2 | `flutter test --reporter expanded` | 退出码 0，42 项测试通过 | [测试输出](2026-10-10-prompt-test.txt) |
| Web 构建 | `flutter build web` | 退出码 0，产物目录 `build/web/` | [构建输出](2026-10-10-prompt-web-build.txt) |

本次验证覆盖三项 Prompt 模板的纯 Dart 行为和输入栏选择交互；没有新增依赖，也没有改变无 API Key 时的本地演示流程。

## 2026-10-11：语音输入与播报

对应代码提交：`8b8b19d`。

| 门禁 | 命令 | 结果 | 原始输出 |
| --- | --- | --- | --- |
| L1 | `flutter analyze` | 退出码 0，无分析问题 | [分析输出](2026-10-11-voice-analyze.txt) |
| L2 | `flutter test --reporter expanded` | 退出码 0，44 项测试通过 | [测试输出](2026-10-11-voice-test.txt) |
| Web 构建 | `flutter build web` | 退出码 0，产物目录 `build/web/` | [构建输出](2026-10-11-voice-web-build.txt) |

语音服务在插件缺失或平台不支持时返回失败状态，页面显示降级提示并保留文字对话。OHOS 上游插件未声明 OHOS 平台，尚未形成鸿蒙语音能力证据。

后续证据按日期和任务命名；设备截图必须包含端别、操作和观察结果。只记录真实执行结果，不提交 API Key 或真实用户数据。

命令输出仅清理行末进度空白，结果文本保持原样，以通过仓库的差异空白检查。
