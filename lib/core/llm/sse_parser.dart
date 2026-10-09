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
      final String line = rawLine.endsWith('\r')
          ? rawLine.substring(0, rawLine.length - 1)
          : rawLine;

      if (line.isEmpty) {
        if (_dataLines.isNotEmpty) {
          events.add(_dataLines.join('\n'));
          _dataLines.clear();
        }
        continue;
      }

      if (line.startsWith(':') || !line.startsWith('data:')) {
        continue;
      }

      String value = line.substring('data:'.length);
      if (value.startsWith(' ')) {
        value = value.substring(1);
      }
      _dataLines.add(value);
    }
    return events;
  }

  void reset() {
    _lineBuffer.clear();
    _dataLines.clear();
  }
}
