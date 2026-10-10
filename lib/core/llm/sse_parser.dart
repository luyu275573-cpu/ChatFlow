/// Collects complete Server-Sent Events from arbitrarily split HTTP chunks.
class SseParser {
  final StringBuffer _lineBuffer = StringBuffer();
  final List<String> _dataLines = <String>[];

  List<String> push(String chunk) {
    _lineBuffer.write(chunk);
    final List<String> lines = _lineBuffer.toString().split('\n');
    _lineBuffer
      ..clear()
      ..write(lines.removeLast());

    final List<String> events = <String>[];
    for (final String rawLine in lines) {
      _consumeLine(rawLine, events);
    }
    return events;
  }

  /// Flushes the final line/event when a response ends without a trailing
  /// blank line. Some OpenAI-compatible gateways close the connection right
  /// after the last `data:` line, which otherwise drops the last delta.
  List<String> finish() {
    final List<String> events = <String>[];
    if (_lineBuffer.isNotEmpty) {
      final String line = _lineBuffer.toString();
      _lineBuffer.clear();
      _consumeLine(line, events);
    }
    if (_dataLines.isNotEmpty) {
      events.add(_dataLines.join('\n'));
      _dataLines.clear();
    }
    return events;
  }

  void reset() {
    _lineBuffer.clear();
    _dataLines.clear();
  }

  void _consumeLine(String rawLine, List<String> events) {
    final String line = rawLine.endsWith('\r')
        ? rawLine.substring(0, rawLine.length - 1)
        : rawLine;

    if (line.isEmpty) {
      if (_dataLines.isNotEmpty) {
        events.add(_dataLines.join('\n'));
        _dataLines.clear();
      }
      return;
    }

    if (line.startsWith(':') || !line.startsWith('data:')) {
      return;
    }

    String value = line.substring('data:'.length);
    if (value.startsWith(' ')) {
      value = value.substring(1);
    }
    _dataLines.add(value);
  }
}
