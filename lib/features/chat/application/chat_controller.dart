import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/llm/llm_client.dart';
import '../../../core/memory/conversation_session.dart';
import '../../../core/models/llm_config.dart';
import '../../../core/models/message.dart';
import '../../../core/rag/local_document.dart';
import '../../../core/rag/retriever.dart';
import '../../../shared/services/conversation_storage.dart';
import '../../../shared/services/local_document_storage.dart';
import '../../../shared/services/model_config_storage.dart';

typedef LlmStreamFactory = Stream<String> Function(
  LlmConfig config,
  List<Message> messages,
);

class ChatState {
  ChatState({
    required Iterable<ConversationSession> sessions,
    required this.activeSessionId,
    required this.selectedModel,
    required Map<String, LlmConfig> configs,
    Iterable<LocalDocument> documents = const <LocalDocument>[],
    this.isSending = false,
  })  : sessions = List<ConversationSession>.unmodifiable(sessions),
        configs = Map<String, LlmConfig>.unmodifiable(configs),
        documents = List<LocalDocument>.unmodifiable(documents);

  factory ChatState.initial() {
    final ConversationSession session = ConversationSession(
      id: 'default',
      title: 'Flutter 流式对话要点',
      messages: <Message>[
        const Message(
          role: MessageRole.user,
          content: '帮我写一段 Flutter 流式对话的要点',
        ),
        const Message(
          role: MessageRole.assistant,
          content:
              '好的，关键点：\n1. 用 dio 发 SSE 请求\n2. 逐 delta 更新 UI\n3. 处理跨 chunk 半行',
        ),
      ],
    );
    return ChatState(
      sessions: <ConversationSession>[session],
      activeSessionId: session.id,
      selectedModel: ChatController.models.first,
      configs: ChatController.modelConfigs,
    );
  }

  final List<ConversationSession> sessions;
  final List<LocalDocument> documents;
  final String activeSessionId;
  final String selectedModel;
  final Map<String, LlmConfig> configs;
  final bool isSending;

  LlmConfig get selectedConfig =>
      configs[selectedModel] ?? ChatController.modelConfigs[selectedModel]!;

  List<Message> get messages {
    for (final ConversationSession session in sessions) {
      if (session.id == activeSessionId) {
        return session.messages;
      }
    }
    return const <Message>[];
  }

  ChatState copyWith({
    Iterable<ConversationSession>? sessions,
    Iterable<LocalDocument>? documents,
    String? activeSessionId,
    String? selectedModel,
    Map<String, LlmConfig>? configs,
    bool? isSending,
  }) {
    return ChatState(
      sessions: sessions ?? this.sessions,
      documents: documents ?? this.documents,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      selectedModel: selectedModel ?? this.selectedModel,
      configs: configs ?? this.configs,
      isSending: isSending ?? this.isSending,
    );
  }
}

class ChatController extends StateNotifier<ChatState> {
  ChatController({
    ConversationStorage? storage,
    LocalDocumentStorage? documentStorage,
    ModelConfigStorage? configStorage,
    LlmStreamFactory? streamFactory,
  })  : _storage = storage,
        _documentStorage = documentStorage,
        _configStorage = configStorage,
        _streamFactory = streamFactory,
        super(ChatState.initial()) {
    _ready = _restore();
  }

  static const List<String> models = <String>[
    'DeepSeek-R1',
    'Qwen2.5',
    'Gemini 2.0 Flash',
  ];

  static const Map<String, LlmConfig> modelConfigs = <String, LlmConfig>{
    'DeepSeek-R1': LlmConfig.deepSeek,
    'Qwen2.5': LlmConfig.qwen,
    'Gemini 2.0 Flash': LlmConfig.gemini,
  };

  /// Keeps request bodies and local persistence bounded on every platform.
  static const int maxUserMessageLength = 8000;

  ConversationStorage? _storage;
  LocalDocumentStorage? _documentStorage;
  ModelConfigStorage? _configStorage;
  final LlmStreamFactory? _streamFactory;
  Retriever _retriever = Retriever();
  late final Future<void> _ready;

  Future<void> get ready => _ready;

  ChatState get snapshot => state;

  Future<void> _restore() async {
    try {
      final ConversationStorage storage =
          _storage ?? await ConversationStorage.create();
      final List<ConversationSession> sessions = await storage.loadSessions();
      String? selectedModel;
      Map<String, LlmConfig>? configs;
      try {
        final ModelConfigStorage configStorage =
            _configStorage ?? await ModelConfigStorage.create();
        final StoredModelSettings? settings =
            await configStorage.load(modelConfigs);
        _configStorage = configStorage;
        selectedModel = settings?.selectedModel;
        configs = settings?.configs;
      } catch (_) {
        // Keep the built-in presets when settings are unavailable or corrupt.
      }
      List<LocalDocument> documents = <LocalDocument>[];
      try {
        final LocalDocumentStorage documentStorage =
            _documentStorage ?? await LocalDocumentStorage.create();
        documents = await documentStorage.loadDocuments();
        _documentStorage = documentStorage;
      } catch (_) {
        // Keep chat usable when the platform has no local document storage.
      }
      if (!mounted) {
        return;
      }
      _storage = storage;
      _setDocuments(documents);
      if (sessions.isNotEmpty) {
        state = state.copyWith(
          sessions: sessions,
          activeSessionId: sessions.first.id,
          selectedModel: selectedModel,
          configs: configs,
        );
      } else {
        state = state.copyWith(
          selectedModel: selectedModel,
          configs: configs,
        );
        await storage.saveSessions(state.sessions);
      }
    } catch (_) {
      // Keep the local demo usable when a platform has no storage plugin.
    }
  }

  Future<void> addDocument(LocalDocument document) async {
    await _ready;
    if (!mounted) {
      return;
    }
    if (document.id.trim().isEmpty ||
        document.id.length > LocalDocument.maxIdLength ||
        document.content.trim().isEmpty ||
        document.content.length > LocalDocument.maxContentLength ||
        (document.source?.length ?? 0) > LocalDocument.maxSourceLength) {
      return;
    }
    final List<LocalDocument> documents = state.documents
        .where((LocalDocument item) => item.id != document.id)
        .toList();
    documents.insert(0, document);
    _setDocuments(documents);
    await _persist();
  }

  Future<void> deleteDocument(String documentId) async {
    await _ready;
    if (!mounted) {
      return;
    }
    final List<LocalDocument> documents = state.documents
        .where((LocalDocument document) => document.id != documentId)
        .toList();
    if (documents.length == state.documents.length) {
      return;
    }
    _setDocuments(documents);
    await _persist();
  }

  void selectModel(String model) {
    if (modelConfigs.containsKey(model) && mounted && !state.isSending) {
      state = state.copyWith(selectedModel: model);
      _persistConfigSettings();
    }
  }

  Future<void> updateModelSettings({
    required String model,
    required String apiKey,
    required double temperature,
    required String systemPrompt,
  }) async {
    await _ready;
    if (!mounted || state.isSending || !modelConfigs.containsKey(model)) {
      return;
    }
    final String normalizedApiKey = apiKey.trim();
    final String normalizedPrompt = systemPrompt.trim();
    if (normalizedApiKey.length > LlmConfig.maxApiKeyLength ||
        normalizedPrompt.length > LlmConfig.maxSystemPromptLength) {
      return;
    }
    final Map<String, LlmConfig> configs =
        Map<String, LlmConfig>.from(state.configs);
    configs[model] = (state.configs[model] ?? modelConfigs[model]!).copyWith(
      apiKey: normalizedApiKey,
      temperature: temperature.clamp(0, 2).toDouble(),
      systemPrompt: normalizedPrompt,
    );
    state = state.copyWith(
      selectedModel: model,
      configs: configs,
    );
    await _persistConfigSettings();
  }

  Future<void> createSession() async {
    await _ready;
    if (!mounted || state.isSending) {
      return;
    }
    final ConversationSession session = ConversationSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: '新会话',
      messages: const <Message>[],
    );
    state = state.copyWith(
      sessions: <ConversationSession>[session, ...state.sessions],
      activeSessionId: session.id,
    );
    await _persist();
  }

  Future<void> selectSession(String sessionId) async {
    await _ready;
    if (!mounted ||
        state.isSending ||
        !state.sessions
            .any((ConversationSession session) => session.id == sessionId)) {
      return;
    }
    state = state.copyWith(activeSessionId: sessionId);
  }

  Future<void> renameSession(String sessionId, String title) async {
    await _ready;
    if (!mounted || state.isSending) {
      return;
    }
    final String trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _updateSession(
      sessionId,
      (ConversationSession session) => session.copyWith(
        title: _limitTitle(trimmed),
      ),
    );
    await _persist();
  }

  Future<void> deleteSession(String sessionId) async {
    await _ready;
    if (!mounted || state.isSending || state.sessions.length == 1) {
      return;
    }
    final List<ConversationSession> sessions = state.sessions
        .where((ConversationSession session) => session.id != sessionId)
        .toList();
    if (sessions.length == state.sessions.length) {
      return;
    }
    final String activeSessionId = state.activeSessionId == sessionId
        ? sessions.first.id
        : state.activeSessionId;
    state = state.copyWith(
      sessions: sessions,
      activeSessionId: activeSessionId,
    );
    await _persist();
  }

  Future<void> send(String text) async {
    await _ready;
    if (!mounted || state.isSending) {
      return;
    }
    final String trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > maxUserMessageLength) {
      return;
    }

    final ConversationSession? session = _activeSession;
    if (session == null) {
      return;
    }
    final LlmConfig config = state.selectedConfig;
    final String modelName = state.selectedModel;
    final List<Message> messages = List<Message>.from(session.messages)
      ..add(Message(role: MessageRole.user, content: trimmed))
      ..add(const Message(role: MessageRole.assistant, content: ''));
    final int assistantIndex = messages.length - 1;
    _updateSession(
      session.id,
      (ConversationSession current) => current.copyWith(
        title: current.title == '新会话' ? _limitTitle(trimmed) : current.title,
        messages: messages,
      ),
    );
    state = state.copyWith(isSending: true);
    await _persist();
    if (!mounted) {
      return;
    }

    if (config.apiKey.isEmpty && _streamFactory == null) {
      _replaceMessage(
        session.id,
        assistantIndex,
        Message(
          role: MessageRole.assistant,
          content: '这是 $modelName 的本地演示回复。配置 API Key 后，这里会显示流式结果。',
        ),
      );
      state = state.copyWith(isSending: false);
      await _persist();
      return;
    }

    final List<Message> requestMessages = <Message>[
      if (config.systemPrompt.isNotEmpty)
        Message(role: MessageRole.system, content: config.systemPrompt),
      ...messages,
    ];
    final List<Message> context = _retriever.injectContext(
      List<Message>.from(requestMessages)
        ..removeAt(assistantIndex + (config.systemPrompt.isEmpty ? 0 : 1)),
      trimmed,
    );
    final buffer = StringBuffer();
    try {
      final Stream<String> stream = _streamFactory?.call(config, context) ??
          LlmClient(config: config).chatStream(context);
      await for (final String delta in stream) {
        if (!mounted) {
          return;
        }
        buffer.write(delta);
        if (buffer.length > Message.maxContentLength) {
          throw const LlmException('模型回复超过本地保存上限');
        }
        _replaceMessage(
          session.id,
          assistantIndex,
          Message(
            role: MessageRole.assistant,
            content: buffer.toString(),
          ),
        );
      }
      if (buffer.isEmpty && mounted) {
        _replaceMessage(
          session.id,
          assistantIndex,
          const Message(
            role: MessageRole.assistant,
            content: '模型没有返回文本。',
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        _replaceMessage(
          session.id,
          assistantIndex,
          Message(
            role: MessageRole.assistant,
            content: error is LlmException
                ? '请求失败：${error.message}'
                : '请求失败：模型服务暂时不可用，请稍后重试。',
          ),
        );
      }
    } finally {
      if (mounted) {
        state = state.copyWith(isSending: false);
        await _persist();
      }
    }
  }

  void _replaceMessage(String sessionId, int index, Message message) {
    if (!mounted) {
      return;
    }
    ConversationSession? session;
    for (final ConversationSession candidate in state.sessions) {
      if (candidate.id == sessionId) {
        session = candidate;
        break;
      }
    }
    if (session == null || index >= session.messages.length) {
      return;
    }
    final List<Message> messages = List<Message>.from(session.messages);
    messages[index] = message;
    _updateSession(
      session.id,
      (ConversationSession current) => current.copyWith(messages: messages),
    );
  }

  Future<void> _persist() async {
    final ConversationStorage? storage = _storage;
    final LocalDocumentStorage? documentStorage = _documentStorage;
    if (storage == null && documentStorage == null) {
      return;
    }
    try {
      if (storage != null) {
        await storage.saveSessions(state.sessions);
      }
      if (documentStorage != null) {
        await documentStorage.saveDocuments(state.documents);
      }
    } catch (_) {
      // Storage failures must not turn a successful chat request into an error.
    }
  }

  Future<void> _persistConfigSettings() async {
    final ModelConfigStorage? configStorage = _configStorage;
    if (configStorage == null) {
      return;
    }
    try {
      await configStorage.save(
        selectedModel: state.selectedModel,
        configs: state.configs,
        defaults: modelConfigs,
      );
    } catch (_) {
      // Settings failures must not block local chat usage.
    }
  }

  ConversationSession? get _activeSession {
    for (final ConversationSession session in state.sessions) {
      if (session.id == state.activeSessionId) {
        return session;
      }
    }
    return null;
  }

  void _updateSession(
    String sessionId,
    ConversationSession Function(ConversationSession session) update,
  ) {
    if (!mounted) {
      return;
    }
    final List<ConversationSession> sessions = state.sessions
        .map(
          (ConversationSession session) =>
              session.id == sessionId ? update(session) : session,
        )
        .toList();
    state = state.copyWith(sessions: sessions);
  }

  void _setDocuments(Iterable<LocalDocument> documents) {
    final List<LocalDocument> snapshot = documents.toList();
    final Retriever retriever = Retriever();
    for (final LocalDocument document in snapshot) {
      retriever.addDocument(
        document.id,
        document.content,
        source: document.source,
      );
    }
    _retriever = retriever;
    state = state.copyWith(documents: snapshot);
  }

  String _limitTitle(String title) {
    return title.length > 24 ? '${title.substring(0, 24)}…' : title;
  }
}

final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>(
  (ref) => ChatController(),
);
