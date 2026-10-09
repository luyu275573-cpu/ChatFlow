import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/models/message.dart';
import 'features/chat/application/chat_controller.dart';
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

class ChatHomePage extends ConsumerStatefulWidget {
  const ChatHomePage({super.key});

  @override
  ConsumerState<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends ConsumerState<ChatHomePage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final String text = _inputController.text;
    if (text.isEmpty) {
      return;
    }
    _inputController.clear();
    await ref.read(chatControllerProvider.notifier).send(text);
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

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature将在后续阶段接入')),
    );
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
          onPressed: () => _showComingSoon('会话列表'),
        ),
        title: const Text(
          'ChatFlow',
          style: TextStyle(fontSize: DesignTokens.fontSizeTitle),
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            initialValue: chatState.selectedModel,
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
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(DesignTokens.space3),
              itemCount: chatState.messages.length,
              itemBuilder: (BuildContext context, int index) {
                return _MessageBubble(message: chatState.messages[index]);
              },
            ),
          ),
          _InputBar(
            controller: _inputController,
            onSend: _sendMessage,
            isSending: chatState.isSending,
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
            if (isUser)
              Text(
                message.content,
                style: TextStyle(
                  color: foreground,
                  fontSize: DesignTokens.fontSizeBody,
                  height: 1.5,
                ),
              )
            else
              MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: foreground,
                    fontSize: DesignTokens.fontSizeBody,
                    height: 1.5,
                  ),
                  code: const TextStyle(
                    color: DesignTokens.inkDark,
                    fontSize: DesignTokens.fontSizeBody,
                    backgroundColor: DesignTokens.lightBg,
                  ),
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
    required this.isSending,
    required this.onVoice,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;
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
            onPressed: isSending ? null : onSend,
          ),
        ],
      ),
    );
  }
}
