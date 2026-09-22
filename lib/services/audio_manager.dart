import 'package:flame_audio/flame_audio.dart';
import 'package:vibration/vibration.dart';
import 'storage_repository.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final StorageRepository _storage = StorageRepository();
  bool _isAudioEnabled = true;
  bool _audioFilesAvailable = true;

  Future<void> init() async {
    final savedAudio = await _storage.readBool('isAudioEnabled');
    if (savedAudio != null) {
      _isAudioEnabled = savedAudio;
    }

    // Try to preload — if files don't exist, disable audio gracefully
    try {
      await FlameAudio.audioCache.loadAll([
        'bounce.wav',
        'spring.wav',
        'coin.wav',
        'game_over.wav',
        'new_record.wav',
      ]);
    } catch (e) {
      _audioFilesAvailable = false;
      // Audio files not found — the app will run silently without crashing
    }
  }

  void toggleAudio() {
    _isAudioEnabled = !_isAudioEnabled;
    _storage.saveBool('isAudioEnabled', _isAudioEnabled);
  }

  bool get isAudioEnabled => _isAudioEnabled;

  void playBounce() {
    if (_isAudioEnabled && _audioFilesAvailable) {
      try {
        FlameAudio.play('bounce.wav');
      } catch (_) {}
    }
  }

  void playSpring() {
    if (_isAudioEnabled && _audioFilesAvailable) {
      try {
        FlameAudio.play('spring.wav');
      } catch (_) {}
    }
    _lightVibrate();
  }

  void playCoin() {
    if (_isAudioEnabled && _audioFilesAvailable) {
      try {
        FlameAudio.play('coin.wav');
      } catch (_) {}
    }
  }

  void playGameOver() {
    if (_isAudioEnabled && _audioFilesAvailable) {
      try {
        FlameAudio.play('game_over.wav');
      } catch (_) {}
    }
    _heavyVibrate();
  }

  void playNewRecord() {
    if (_isAudioEnabled && _audioFilesAvailable) {
      try {
        FlameAudio.play('new_record.wav');
      } catch (_) {}
    }
    _lightVibrate();
  }

  Future<void> _lightVibrate() async {
    try {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 50, amplitude: 50);
      }
    } catch (_) {}
  }

  Future<void> _heavyVibrate() async {
    try {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 300, amplitude: 255);
      }
    } catch (_) {}
  }
}
