import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/memory/conversation_session.dart';
import 'core/models/llm_config.dart';
import 'core/models/message.dart';
import 'core/models/prompt_template.dart';
import 'core/rag/local_document.dart';
import 'features/chat/application/chat_controller.dart';
import 'shared/services/voice_service.dart';
import 'theme/design_tokens.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: _ChatFlowApp(),
    );
  }
}

class _ChatFlowApp extends StatelessWidget {
  const _ChatFlowApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatFlow',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const ChatHomePage(),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor:
          isDark ? DesignTokens.darkBg : DesignTokens.lightBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DesignTokens.primary,
        brightness: brightness,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? DesignTokens.darkSurface : DesignTokens.lightSurface,
        foregroundColor: isDark ? DesignTokens.inkLight : DesignTokens.inkDark,
        elevation: 0,
        surfaceTintColor: DesignTokens.transparent,
      ),
    );
  }
}

class ChatHomePage extends ConsumerStatefulWidget {
  const ChatHomePage({super.key});

  @override
  ConsumerState<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends ConsumerState<ChatHomePage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;

  @override
  void dispose() {
    _voiceService.stopListening();
    _voiceService.stopSpeaking();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final String text = _inputController.text;
    if (text.trim().isEmpty) {
      return;
    }
    _inputController.clear();
    await ref.read(chatControllerProvider.notifier).send(text);
  }

  Future<void> _showPrompts() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const ListTile(
                leading: Icon(Icons.auto_awesome_outlined),
                title: Text('预设 Prompt'),
                subtitle: Text('选择一个指令填入输入框'),
              ),
              ...PromptTemplate.defaults.map(
                (PromptTemplate template) => ListTile(
                  leading: const Icon(Icons.bolt_outlined),
                  title: Text(template.title),
                  subtitle: Text(template.description),
                  onTap: () {
                    _inputController.text = '${template.instruction}\n\n';
                    _inputController.selection = TextSelection.collapsed(
                      offset: _inputController.text.length,
                    );
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _voiceService.stopListening();
      if (mounted) {
        setState(() => _isListening = false);
      }
      return;
    }
    final bool started = await _voiceService.startListening(
      onText: (String text) {
        if (!mounted) {
          return;
        }
        setState(() {
          _inputController.text = text;
          _inputController.selection = TextSelection.collapsed(
            offset: text.length,
          );
        });
      },
      onListeningChanged: (bool listening) {
        if (mounted) {
          setState(() => _isListening = listening);
        }
      },
    );
    if (!started && mounted) {
      _showVoiceUnavailable('语音输入');
    }
  }

  Future<void> _speakMessage(String text) async {
    final bool started = await _voiceService.speak(text);
    if (!started && mounted) {
      _showVoiceUnavailable('语音播报');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showVoiceUnavailable(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('当前平台暂不支持$feature')),
    );
  }

  Future<void> _showSessions() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.72,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              final ChatState chatState = ref.watch(chatControllerProvider);
              final ChatController chatController =
                  ref.read(chatControllerProvider.notifier);
              return SafeArea(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.close),
                      title: const Text('会话'),
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.space3,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '最近会话',
                          style: TextStyle(color: DesignTokens.subText),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: chatState.sessions.length,
                        itemBuilder: (BuildContext context, int index) {
                          final ConversationSession session =
                              chatState.sessions[index];
                          return ListTile(
                            selected: session.id == chatState.activeSessionId,
                            leading: const Icon(Icons.chat_bubble_outline),
                            title: Text(
                              session.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () async {
                              await chatController.selectSession(session.id);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            trailing: PopupMenuButton<String>(
                              onSelected: (String action) async {
                                if (action == 'rename') {
                                  await _renameSession(session);
                                } else if (action == 'delete') {
                                  await chatController
                                      .deleteSession(session.id);
                                }
                              },
                              itemBuilder: (BuildContext context) {
                                return const <PopupMenuEntry<String>>[
                                  PopupMenuItem<String>(
                                    value: 'rename',
                                    child: Text('重命名'),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text('删除'),
                                  ),
                                ];
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.menu_book_outlined),
                      title: Text('本地资料 (${chatState.documents.length})'),
                      subtitle: const Text('用于回答时检索参考'),
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _showDocuments();
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.add,
                        color: DesignTokens.primary,
                      ),
                      title: const Text(
                        '新建会话',
                        style: TextStyle(color: DesignTokens.primary),
                      ),
                      onTap: () async {
                        await chatController.createSession();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showDocuments() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.72,
          child: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              final ChatState chatState = ref.watch(chatControllerProvider);
              final ChatController chatController =
                  ref.read(chatControllerProvider.notifier);
              return SafeArea(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.close),
                      title: const Text('本地资料'),
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.space3,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '命中资料会作为参考上下文发送给模型',
                          style: TextStyle(color: DesignTokens.subText),
                        ),
                      ),
                    ),
                    Expanded(
                      child: chatState.documents.isEmpty
                          ? const Center(child: Text('还没有本地资料'))
                          : ListView.builder(
                              itemCount: chatState.documents.length,
                              itemBuilder: (BuildContext context, int index) {
                                final LocalDocument document =
                                    chatState.documents[index];
                                return ListTile(
                                  leading:
                                      const Icon(Icons.description_outlined),
                                  title: Text(document.source ?? document.id),
                                  subtitle: Text(
                                    document.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: '删除资料',
                                    onPressed: () => chatController
                                        .deleteDocument(document.id),
                                  ),
                                );
                              },
                            ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.add,
                        color: DesignTokens.primary,
                      ),
                      title: const Text(
                        '新增本地资料',
                        style: TextStyle(color: DesignTokens.primary),
                      ),
                      onTap: _addDocument,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _addDocument() async {
    final TextEditingController idController = TextEditingController();
    final TextEditingController sourceController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    final ChatController chatController =
        ref.read(chatControllerProvider.notifier);
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('新增本地资料'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(labelText: '资料 ID'),
                ),
                TextField(
                  controller: sourceController,
                  decoration: const InputDecoration(labelText: '来源（可选）'),
                ),
                TextField(
                  controller: contentController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(labelText: '资料内容'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                final String id = idController.text.trim();
                final String content = contentController.text.trim();
                if (id.isEmpty || content.isEmpty) {
                  return;
                }
                await chatController.addDocument(
                  LocalDocument(
                    id: id,
                    content: content,
                    source: sourceController.text.trim().isEmpty
                        ? null
                        : sourceController.text.trim(),
                  ),
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    idController.dispose();
    sourceController.dispose();
    contentController.dispose();
  }

  Future<void> _renameSession(ConversationSession session) async {
    final TextEditingController controller =
        TextEditingController(text: session.title);
    final String? title = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('重命名会话'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (title != null) {
      await ref.read(chatControllerProvider.notifier).renameSession(
            session.id,
            title,
          );
    }
  }

  Future<void> _showModelSettings() async {
    final ChatController chatController =
        ref.read(chatControllerProvider.notifier);
    await chatController.ready;
    if (!mounted) {
      return;
    }
    String selectedModel = chatController.snapshot.selectedModel;
    LlmConfig selectedConfig = chatController.snapshot.selectedConfig;
    final TextEditingController apiKeyController =
        TextEditingController(text: selectedConfig.apiKey);
    final TextEditingController promptController =
        TextEditingController(text: selectedConfig.systemPrompt);
    double temperature = selectedConfig.temperature;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext sheetContext) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setSheetState) {
              final bool isDark =
                  Theme.of(context).brightness == Brightness.dark;
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    DesignTokens.space4,
                    DesignTokens.space3,
                    DesignTokens.space4,
                    DesignTokens.space3 +
                        MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          '模型设置',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: DesignTokens.space3),
                        DropdownButtonFormField<String>(
                          value: selectedModel,
                          decoration: const InputDecoration(
                            labelText: '模型',
                            border: OutlineInputBorder(),
                          ),
                          items: ChatController.models
                              .map(
                                (String model) => DropdownMenuItem<String>(
                                  value: model,
                                  child: Text(model),
                                ),
                              )
                              .toList(),
                          onChanged: (String? model) {
                            if (model == null) {
                              return;
                            }
                            setSheetState(() {
                              selectedModel = model;
                              selectedConfig =
                                  chatController.snapshot.configs[model] ??
                                      ChatController.modelConfigs[model]!;
                              apiKeyController.text = selectedConfig.apiKey;
                              promptController.text =
                                  selectedConfig.systemPrompt;
                              temperature = selectedConfig.temperature;
                            });
                          },
                        ),
                        const SizedBox(height: DesignTokens.space3),
                        Row(
                          children: <Widget>[
                            const Text('温度'),
                            const Spacer(),
                            Text(
                              temperature.toStringAsFixed(1),
                              style: const TextStyle(
                                color: DesignTokens.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: temperature,
                          min: 0,
                          max: 2,
                          divisions: 20,
                          activeColor: DesignTokens.primary,
                          label: temperature.toStringAsFixed(1),
                          onChanged: (double value) {
                            setSheetState(() => temperature = value);
                          },
                        ),
                        TextField(
                          controller: apiKeyController,
                          obscureText: true,
                          maxLength: LlmConfig.maxApiKeyLength,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'API Key',
                            hintText: '留空则不发送 Authorization',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space2),
                        TextField(
                          controller: promptController,
                          minLines: 2,
                          maxLines: 5,
                          maxLength: LlmConfig.maxSystemPromptLength,
                          decoration: const InputDecoration(
                            labelText: 'System Prompt',
                            hintText: '可选的系统级指令',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('深色模式'),
                          subtitle: Text(
                            '跟随系统',
                            style: TextStyle(
                              color: isDark
                                  ? DesignTokens.inkLight
                                  : DesignTokens.subText,
                            ),
                          ),
                          trailing: Icon(
                            Icons.brightness_auto_outlined,
                            color: isDark
                                ? DesignTokens.inkLight
                                : DesignTokens.subText,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space2),
                        Text(
                          'API Key 会保存在本机偏好设置中，生产环境建议使用服务端代理或短期凭据。',
                          style: TextStyle(
                            color: isDark
                                ? DesignTokens.inkLight
                                : DesignTokens.subText,
                            fontSize: DesignTokens.fontSizeCaption,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.space3),
                        FilledButton(
                          onPressed: () async {
                            await chatController.updateModelSettings(
                              model: selectedModel,
                              apiKey: apiKeyController.text,
                              temperature: temperature,
                              systemPrompt: promptController.text,
                            );
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                          child: const Text('保存设置'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      apiKeyController.dispose();
      promptController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ChatState chatState = ref.watch(chatControllerProvider);
    ref.listen<ChatState>(chatControllerProvider,
        (ChatState? previous, ChatState next) {
      if (previous == null ||
          previous.messages.length != next.messages.length ||
          previous.isSending != next.isSending) {
        _scrollToBottom();
      }
    });
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: '会话列表',
          onPressed: _showSessions,
        ),
        title: const Text(
          'ChatFlow',
          style: TextStyle(fontSize: DesignTokens.fontSizeTitle),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '模型设置',
            onPressed: _showModelSettings,
          ),
          PopupMenuButton<String>(
            initialValue: chatState.selectedModel,
            tooltip: '选择模型',
            onSelected: (String model) {
              ref.read(chatControllerProvider.notifier).selectModel(model);
            },
            itemBuilder: (BuildContext context) {
              return ChatController.models
                  .map(
                    (String model) => PopupMenuItem<String>(
                      value: model,
                      child: Text(model),
                    ),
                  )
                  .toList();
            },
            child: Container(
              margin: const EdgeInsets.only(right: DesignTokens.space2),
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space2,
                vertical: DesignTokens.space1,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    chatState.selectedModel,
                    style: const TextStyle(
                      color: DesignTokens.primary,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: DesignTokens.fontSizeBody,
                    color: DesignTokens.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: chatState.messages.isEmpty
                ? const Center(child: Text('开始一段新对话'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(DesignTokens.space3),
                    itemCount: chatState.messages.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _MessageBubble(
                        message: chatState.messages[index],
                        onSpeak:
                            chatState.messages[index].role == MessageRole.user
                                ? null
                                : () => _speakMessage(
                                      chatState.messages[index].content,
                                    ),
                      );
                    },
                  ),
          ),
          _InputBar(
            controller: _inputController,
            onSend: _sendMessage,
            isSending: chatState.isSending,
            onPrompt: _showPrompts,
            isListening: _isListening,
            onVoice: _toggleVoiceInput,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.onSpeak});

  final Message message;
  final VoidCallback? onSpeak;

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.role == MessageRole.user;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color foreground = isUser
        ? DesignTokens.lightSurface
        : (isDark ? DesignTokens.inkLight : DesignTokens.inkDark);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        margin: const EdgeInsets.only(bottom: DesignTokens.space2),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space3,
          vertical: DesignTokens.space2,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? DesignTokens.userBubble
              : (isDark
                  ? DesignTokens.aiBubbleDark
                  : DesignTokens.aiBubbleLight),
          border: isUser
              ? null
              : Border.all(
                  color: isDark
                      ? DesignTokens.darkBorder
                      : DesignTokens.lightBorder,
                ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(DesignTokens.radius),
            topRight: const Radius.circular(DesignTokens.radius),
            bottomLeft: Radius.circular(
              isUser ? DesignTokens.radius : DesignTokens.radiusSmall,
            ),
            bottomRight: Radius.circular(
              isUser ? DesignTokens.radiusSmall : DesignTokens.radius,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (!isUser)
              const Padding(
                padding: EdgeInsets.only(bottom: DesignTokens.space1),
                child: Text(
                  'AI',
                  style: TextStyle(
                    color: DesignTokens.accent,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (isUser)
              Text(
                message.content,
                style: TextStyle(
                  color: foreground,
                  fontSize: DesignTokens.fontSizeBody,
                  height: 1.5,
                ),
              )
            else ...<Widget>[
              MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: foreground,
                    fontSize: DesignTokens.fontSizeBody,
                    height: 1.5,
                  ),
                  code: TextStyle(
                    color: foreground,
                    fontSize: DesignTokens.fontSizeBody,
                    backgroundColor:
                        isDark ? DesignTokens.darkBg : DesignTokens.lightBg,
                  ),
                ),
              ),
              if (onSpeak != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.volume_up_outlined),
                    tooltip: '语音播报',
                    color: DesignTokens.subText,
                    onPressed: onSpeak,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.isSending,
    required this.onPrompt,
    required this.isListening,
    required this.onVoice,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;
  final VoidCallback onPrompt;
  final bool isListening;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space2),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : DesignTokens.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            color: DesignTokens.subText,
            tooltip: '预设 Prompt',
            onPressed: onPrompt,
          ),
          IconButton(
            icon: const Icon(Icons.mic_none),
            color: isListening ? DesignTokens.accent : DesignTokens.subText,
            tooltip: '语音输入',
            onPressed: onVoice,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: '输入消息…',
                filled: true,
                fillColor: isDark ? DesignTokens.darkBg : DesignTokens.lightBg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space3,
                  vertical: DesignTokens.space2,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                  borderSide: BorderSide(
                    color: isDark
                        ? DesignTokens.darkBorder
                        : DesignTokens.lightBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                  borderSide: BorderSide(
                    color: isDark
                        ? DesignTokens.darkBorder
                        : DesignTokens.lightBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                  borderSide: const BorderSide(color: DesignTokens.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.space1),
          IconButton(
            icon: const Icon(Icons.send),
            color: DesignTokens.primary,
            tooltip: '发送',
            onPressed: isSending ? null : onSend,
          ),
        ],
      ),
    );
  }
}
