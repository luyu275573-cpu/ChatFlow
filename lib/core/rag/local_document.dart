/// A user-provided document kept in the local RAG library.
class LocalDocument {
  const LocalDocument({
    required this.id,
    required this.content,
    this.source,
  });

  final String id;
  final String content;
  final String? source;

  static const int maxIdLength = 200;
  static const int maxSourceLength = 500;
  static const int maxContentLength = 100000;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'content': content,
      if (source != null) 'source': source,
    };
  }

  factory LocalDocument.fromJson(Map<String, dynamic> json) {
    final Object? idValue = json['id'];
    final Object? contentValue = json['content'];
    final Object? sourceValue = json['source'];
    if (idValue is! String ||
        idValue.trim().isEmpty ||
        idValue.length > maxIdLength ||
        contentValue is! String ||
        contentValue.trim().isEmpty ||
        contentValue.length > maxContentLength ||
        (sourceValue is String && sourceValue.length > maxSourceLength) ||
        (sourceValue != null && sourceValue is! String)) {
      throw const FormatException('本地资料必须包含有效的 id 和 content');
    }
    return LocalDocument(
      id: idValue,
      content: contentValue,
      source: sourceValue as String?,
    );
  }
}
