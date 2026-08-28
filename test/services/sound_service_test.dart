import 'package:flutter_test/flutter_test.dart';

import 'package:ddx_focus/services/sound_service.dart';

class _FakePlayer implements AlarmPlayer {
  final List<String> played = [];
  int stopCount = 0;
  bool throwOnPlay = false;

  @override
  Future<void> play(String assetPath) async {
    if (throwOnPlay) throw Exception('no audio device');
    played.add(assetPath);
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }
}

void main() {
  group('SoundService', () {
    test(
      'playFocus and playRest hand the correct asset to the player',
      () async {
        final fake = _FakePlayer();
        final service = SoundService.withPlayer(fake);

        await service.playFocus();
        await service.playRest();

        expect(fake.played, ['sounds/FocusAlarm.mp3', 'sounds/RestAlarm.mp3']);
      },
    );

    test('stop forwards to the player', () async {
      final fake = _FakePlayer();
      final service = SoundService.withPlayer(fake);

      await service.stop();

      expect(fake.stopCount, 1);
    });

    test('player errors are swallowed and do not propagate', () async {
      final fake = _FakePlayer()..throwOnPlay = true;
      final service = SoundService.withPlayer(fake);

      await service.playFocus();
      await service.playRest();
      await service.stop();
    });
  });
}
