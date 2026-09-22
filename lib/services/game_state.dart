import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/obfuscated_int.dart';
import '../models/achievement.dart';
import 'firebase_service.dart';
import 'storage_repository.dart';

class LoginResult {
  final bool success;
  final bool hasConflict;
  final String? cloudName;
  final int? cloudScore;
  final int? cloudCoins;
  
  LoginResult({
    required this.success, 
    this.hasConflict = false, 
    this.cloudName, 
    this.cloudScore,
    this.cloudCoins,
  });
}

class GameState extends ChangeNotifier {
  final _secureStorage = const FlutterSecureStorage();
  
  final ObfuscatedInt _highScore = ObfuscatedInt(0);
  final ObfuscatedInt _coins = ObfuscatedInt(0);
  final ObfuscatedInt _currentScore = ObfuscatedInt(0);
  
  List<int> _ownedSkins = [0]; // Index 0 is unlocked by default
  int _currentSkinIndex = 0;
  String _playerName = '';
  
  int _totalDeaths = 0;
  int _currentRevives = 0;
  
  final FirebaseService _firebaseService = FirebaseService();

  bool _isGameOver = false;

  Function(Achievement)? onAchievementUnlocked;

  final List<Achievement> achievements = [
    Achievement(id: 'score_5000', title: 'Primeros Pasos', description: 'Alcanza 5,000 puntos', bonusCoins: 10),
    Achievement(id: 'score_10000', title: 'Saltador Experto', description: 'Alcanza 10,000 puntos', bonusCoins: 10),
    Achievement(id: 'score_25000', title: 'Maestro del Neón', description: 'Alcanza 25,000 puntos', bonusCoins: 10),
    Achievement(id: 'revive_3', title: 'Inmortal', description: 'Revive 3 veces en una sola partida', bonusCoins: 10),
    Achievement(id: 'revive_5', title: 'Gato de 9 Vidas', description: 'Revive 5 veces en una sola partida', bonusCoins: 10),
    Achievement(id: 'die_10', title: 'Víctima de la Gravedad', description: 'Pierde 10 veces en total', bonusCoins: 10),
    Achievement(id: 'skin_1', title: 'A la Moda', description: 'Desbloquea una skin', bonusCoins: 10),
  ];

  int get highScore => _highScore.value;
  int get coins => _coins.value;
  List<int> get ownedSkins => _ownedSkins;
  int get currentSkinIndex => _currentSkinIndex;
  String get playerName => _playerName;
  
  bool get isGameOver => _isGameOver;
  int get currentScore => _currentScore.value;
  int get totalDeaths => _totalDeaths;
  int get currentRevives => _currentRevives;

  final Map<String, int> _platformBounces = {};
  Map<String, int> get platformBounces => _platformBounces;

  int _currentCoinsCollected = 0;
  int get currentCoinsCollected => _currentCoinsCollected;

  void recordBounce(String platformType) {
    if (_platformBounces.containsKey(platformType)) {
      _platformBounces[platformType] = _platformBounces[platformType]! + 1;
    } else {
      _platformBounces[platformType] = 1;
    }
    notifyListeners();
  }

  void useCoins(int amount) {
    if (_coins.value >= amount) {
      _coins.value -= amount;
      _saveCoins();
      if (_playerName.isNotEmpty) {
        _firebaseService.submitScore(_playerName, _highScore.value, coins: _coins.value);
      }
      notifyListeners();
    }
  }

  final StorageRepository _storage = StorageRepository();

  Future<void> init() async {
    final keys = [
      'highScore',
      'coins',
      'playerName',
      'ownedSkins',
      'currentSkinIndex',
      'totalDeaths',
      'unlockedAchievements'
    ];
    
    final values = await _storage.readAll(keys);

    final highScoreStr = values['highScore'];
    if (highScoreStr != null) _highScore.value = int.tryParse(highScoreStr) ?? 0;
    
    final coinsStr = values['coins'];
    if (coinsStr != null) _coins.value = int.tryParse(coinsStr) ?? 0;
    
    _playerName = values['playerName'] ?? '';
    
    final skinsString = values['ownedSkins'];
    if (skinsString != null && skinsString.isNotEmpty) {
      _ownedSkins = skinsString.split(',').map((e) => int.parse(e)).toList();
    }
    
    final skinIdxStr = values['currentSkinIndex'];
    if (skinIdxStr != null) _currentSkinIndex = int.tryParse(skinIdxStr) ?? 0;
    
    final deathsStr = values['totalDeaths'];
    if (deathsStr != null) _totalDeaths = int.tryParse(deathsStr) ?? 0;
    
    final unlockedStr = values['unlockedAchievements'];
    if (unlockedStr != null && unlockedStr.isNotEmpty) {
      final unlockedIds = unlockedStr.split(',');
      for (var ach in achievements) {
        if (unlockedIds.contains(ach.id)) {
          ach.isUnlocked = true;
        }
      }
    }
    
    notifyListeners();
  }

  void updateScore(int score) {
    _currentScore.value = score;
    if (_currentScore.value > _highScore.value) {
      _highScore.value = _currentScore.value;
    }
    _checkAchievements();
    notifyListeners();
  }

  void addCoins(int amount) {
    _coins.value += amount;
    _currentCoinsCollected += amount;
    _saveCoins();
    if (_playerName.isNotEmpty) {
      _firebaseService.submitScore(_playerName, _highScore.value, coins: _coins.value);
    }
    notifyListeners();
  }

  void unlockSkin(int skinIndex, int cost) {
    if (_coins.value >= cost && !_ownedSkins.contains(skinIndex)) {
      _coins.value -= cost;
      _ownedSkins.add(skinIndex);
      _saveCoins();
      _saveOwnedSkins();
      _checkAchievements();
      if (_playerName.isNotEmpty) {
        _firebaseService.submitScore(_playerName, _highScore.value, coins: _coins.value);
      }
      notifyListeners();
    }
  }

  void equipSkin(int skinIndex) {
    if (_ownedSkins.contains(skinIndex)) {
      _currentSkinIndex = skinIndex;
      _saveCurrentSkin();
      notifyListeners();
    }
  }
  
  Future<bool> isNameAvailable(String name) async {
    return await _firebaseService.isNameAvailable(name);
  }
  
  void setPlayerName(String name) async {
    _playerName = name;
    await _secureStorage.write(key: 'playerName', value: name);
    notifyListeners();
    _firebaseService.submitScore(name, _highScore.value, coins: _coins.value);
  }

  Future<void> wipeLocalData() async {
    _playerName = '';
    _highScore.value = 0;
    _coins.value = 0;
    _currentScore.value = 0;
    _totalDeaths = 0;
    _currentRevives = 0;
    _ownedSkins = [0];
    _currentSkinIndex = 0;
    for (var ach in achievements) {
      ach.isUnlocked = false;
    }
    await _secureStorage.deleteAll();
    notifyListeners();
  }

  Future<LoginResult> loginWithGoogle() async {
    final result = await _firebaseService.signInWithGoogle();
    if (result != null) {
      final data = await _firebaseService.getUserData();
      if (data != null) {
        final cloudScore = data['score'] as int? ?? 0;
        final cloudCoins = data['coins'] as int? ?? 0;
        final cloudName = data['playerName'] as String? ?? '';
        
        if (cloudName.isNotEmpty || cloudScore > 0 || cloudCoins > 0) {
          if (_playerName.isNotEmpty && _playerName != cloudName) {
            return LoginResult(
              success: true,
              hasConflict: true,
              cloudName: cloudName,
              cloudScore: cloudScore,
              cloudCoins: cloudCoins,
            );
          } else {
             _playerName = cloudName;
             if (cloudScore > _highScore.value) {
               _highScore.value = cloudScore;
             }
             if (cloudCoins > _coins.value) {
               _coins.value = cloudCoins;
             }
             await _saveHighScore();
             await _saveCoins();
             await _secureStorage.write(key: 'playerName', value: _playerName);
             _firebaseService.submitScore(_playerName, _highScore.value, coins: _coins.value);
             notifyListeners();
             return LoginResult(success: true, hasConflict: false);
          }
        }
      }
      
      if (_playerName.isNotEmpty) {
        _firebaseService.submitScore(_playerName, _highScore.value, coins: _coins.value);
      }
      notifyListeners();
      return LoginResult(success: true, hasConflict: false);
    }
    return LoginResult(success: false);
  }

  Future<void> resolveLoginConflict(bool recoverCloudData, String cloudName, int cloudScore, int cloudCoins) async {
    if (recoverCloudData) {
      _playerName = cloudName;
      _highScore.value = cloudScore;
      _coins.value = cloudCoins;
      await _secureStorage.write(key: 'playerName', value: cloudName);
      await _saveHighScore();
      await _saveCoins();
    } else {
      _firebaseService.submitScore(_playerName, _highScore.value, coins: _coins.value);
    }
    notifyListeners();
  }

  DateTime? _gameStartTime;

  void setGameOver(bool gameOver) {
    _isGameOver = gameOver;
    if (gameOver) {
      // Speedhack validation
      if (_gameStartTime != null) {
        final durationInSeconds = DateTime.now().difference(_gameStartTime!).inSeconds;
        // Assume maximum realistic speed is ~1000 points per second.
        // If they exceed this, do not save score.
        final maxRealisticScore = durationInSeconds * 1000;
        if (_currentScore.value > maxRealisticScore && _currentScore.value > 5000) {
          debugPrint('Speedhack detected! Score: ${_currentScore.value}, Time: $durationInSeconds sec');
          // Discard score
          _currentScore.value = 0;
        }
      }

      _totalDeaths++;
      _saveTotalDeaths();
      _checkAchievements();
      
      _saveHighScore();
      if (_playerName.isNotEmpty) {
        _firebaseService.submitScore(_playerName, _highScore.value, coins: _coins.value);
      }
    }
    notifyListeners();
  }

  void resetCurrentScore() {
    _currentScore.value = 0;
    _currentRevives = 0;
    _isGameOver = false;
    _gameStartTime = DateTime.now();
    _platformBounces.clear();
    _currentCoinsCollected = 0;
    notifyListeners();
  }
  
  void incrementRevives() {
    _currentRevives++;
    _checkAchievements();
    notifyListeners();
  }

  void _checkAchievements() {
    _evaluateAchievement('score_5000', () => currentScore >= 5000);
    _evaluateAchievement('score_10000', () => currentScore >= 10000);
    _evaluateAchievement('score_25000', () => currentScore >= 25000);
    _evaluateAchievement('revive_3', () => _currentRevives >= 3);
    _evaluateAchievement('revive_5', () => _currentRevives >= 5);
    _evaluateAchievement('die_10', () => _totalDeaths >= 10);
    _evaluateAchievement('skin_1', () => _ownedSkins.length > 1);
  }

  void _evaluateAchievement(String id, bool Function() condition) {
    final ach = achievements.firstWhere((a) => a.id == id);
    if (!ach.isUnlocked && condition()) {
      ach.isUnlocked = true;
      addCoins(ach.bonusCoins);
      _saveUnlockedAchievements();
      onAchievementUnlocked?.call(ach);
    }
  }

  Future<void> _saveHighScore() async {
    await _secureStorage.write(key: 'highScore', value: _highScore.value.toString());
  }

  Future<void> _saveCoins() async {
    await _secureStorage.write(key: 'coins', value: _coins.value.toString());
  }

  Future<void> _saveOwnedSkins() async {
    await _secureStorage.write(key: 'ownedSkins', value: _ownedSkins.join(','));
  }

  Future<void> _saveCurrentSkin() async {
    await _secureStorage.write(key: 'currentSkinIndex', value: _currentSkinIndex.toString());
  }
  
  Future<void> _saveTotalDeaths() async {
    await _secureStorage.write(key: 'totalDeaths', value: _totalDeaths.toString());
  }
  
  Future<void> _saveUnlockedAchievements() async {
    final unlockedIds = achievements.where((a) => a.isUnlocked).map((a) => a.id).join(',');
    await _secureStorage.write(key: 'unlockedAchievements', value: unlockedIds);
  }
}
