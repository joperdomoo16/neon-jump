import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/obfuscated_int.dart';
import '../models/achievement.dart';
import 'firebase_service.dart';
import '../utils/constants.dart';

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
      notifyListeners();
    }
  }

  Future<void> init() async {
    final highScoreStr = await _secureStorage.read(key: 'highScore');
    if (highScoreStr != null) _highScore.value = int.tryParse(highScoreStr) ?? 0;
    
    final coinsStr = await _secureStorage.read(key: 'coins');
    if (coinsStr != null) _coins.value = int.tryParse(coinsStr) ?? 0;
    
    _playerName = await _secureStorage.read(key: 'playerName') ?? '';
    
    final skinsString = await _secureStorage.read(key: 'ownedSkins');
    if (skinsString != null && skinsString.isNotEmpty) {
      _ownedSkins = skinsString.split(',').map((e) => int.parse(e)).toList();
    }
    
    final skinIdxStr = await _secureStorage.read(key: 'currentSkinIndex');
    if (skinIdxStr != null) _currentSkinIndex = int.tryParse(skinIdxStr) ?? 0;
    
    final deathsStr = await _secureStorage.read(key: 'totalDeaths');
    if (deathsStr != null) _totalDeaths = int.tryParse(deathsStr) ?? 0;
    
    final unlockedStr = await _secureStorage.read(key: 'unlockedAchievements');
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
    notifyListeners();
  }

  void unlockSkin(int skinIndex, int cost) {
    if (_coins.value >= cost && !_ownedSkins.contains(skinIndex)) {
      _coins.value -= cost;
      _ownedSkins.add(skinIndex);
      _saveCoins();
      _saveOwnedSkins();
      _checkAchievements();
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
    _firebaseService.submitScore(name, _highScore.value);
  }

  void setGameOver(bool gameOver) {
    _isGameOver = gameOver;
    if (gameOver) {
      _totalDeaths++;
      _saveTotalDeaths();
      _checkAchievements();
      
      _saveHighScore();
      if (_playerName.isNotEmpty) {
        _firebaseService.submitScore(_playerName, _highScore.value);
      }
    }
    notifyListeners();
  }

  void resetCurrentScore() {
    _currentScore.value = 0;
    _currentRevives = 0;
    _isGameOver = false;
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
