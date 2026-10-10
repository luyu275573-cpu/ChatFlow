import 'package:flutter_test/flutter_test.dart';

import 'package:chatflow/shared/services/voice_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('falls back cleanly when speech plugins are unavailable', () async {
    final service = VoiceService();

    expect(await service.startListening(onText: (_) {}), isFalse);
    expect(await service.speak('测试'), isFalse);
    await service.stopListening();
    await service.stopSpeaking();
  });
}
