import 'package:flutter/material.dart';

import 'core/models/message.dart';
import 'theme/design_tokens.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: DesignTokens.lightBg,
        colorScheme: ColorScheme.fromSeed(seedColor: DesignTokens.primary),
        appBarTheme: const AppBarTheme(
          backgroundColor: DesignTokens.lightSurface,
          foregroundColor: DesignTokens.inkDark,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const ChatHomePage(),
    );
  }
}

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  static const List<String> _models = <String>[
    'DeepSeek-R1',
    'Qwen2.5',
    'Gemini 2.0 Flash',
  ];

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = <Message>[
    const Message(
      role: MessageRole.user,
      content: '帮我写一段 Flutter 流式对话的要点',
    ),
    const Message(
      role: MessageRole.assistant,
      content: '好的，关键点：\n1. 用 dio 发 SSE 请求\n2. 逐 delta 更新 UI\n3. 处理跨 chunk 半行',
    ),
  ];

  String _selectedModel = _models.first;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final String text = _inputController.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(Message(role: MessageRole.user, content: text));
      _messages.add(
        Message(
          role: MessageRole.assistant,
          content: '这是 $_selectedModel 的本地演示回复。接入真实模型后，这里会显示流式结果。',
        ),
      );
    });
    _inputController.clear();
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

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature将在后续阶段接入')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: '会话列表',
          onPressed: () => _showComingSoon('会话列表'),
        ),
        title: const Text(
          'ChatFlow',
          style: TextStyle(fontSize: DesignTokens.fontSizeTitle),
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            initialValue: _selectedModel,
            onSelected: (String model) {
              setState(() => _selectedModel = model);
            },
            itemBuilder: (BuildContext context) {
              return _models
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
                    _selectedModel,
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
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(DesignTokens.space3),
              itemCount: _messages.length,
              itemBuilder: (BuildContext context, int index) {
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),
          _InputBar(
            controller: _inputController,
            onSend: _sendMessage,
            onVoice: () => _showComingSoon('语音输入'),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.role == MessageRole.user;
    final Color foreground =
        isUser ? DesignTokens.lightSurface : DesignTokens.inkDark;

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
          color: isUser ? DesignTokens.userBubble : DesignTokens.aiBubbleLight,
          border: isUser ? null : Border.all(color: DesignTokens.lightBorder),
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
            Text(
              message.content,
              style: TextStyle(
                color: foreground,
                fontSize: DesignTokens.fontSizeBody,
                height: 1.5,
              ),
            ),
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
    required this.onVoice,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space2),
      decoration: const BoxDecoration(
        color: DesignTokens.lightSurface,
        border: Border(top: BorderSide(color: DesignTokens.lightBorder)),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.mic_none),
            color: DesignTokens.subText,
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
                fillColor: DesignTokens.lightBg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space3,
                  vertical: DesignTokens.space2,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                  borderSide: const BorderSide(
                    color: DesignTokens.lightBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
                  borderSide: const BorderSide(
                    color: DesignTokens.lightBorder,
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
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}
