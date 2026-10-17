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
  final List<int>? cloudOwnedSkins;
  final int? cloudCurrentSkinIndex;
  final List<String>? cloudAchievements;
  
  LoginResult({
    required this.success, 
    this.hasConflict = false, 
    this.cloudName, 
    this.cloudScore,
    this.cloudCoins,
    this.cloudOwnedSkins,
    this.cloudCurrentSkinIndex,
    this.cloudAchievements,
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
    // Puntuaciones
    Achievement(id: 'score_1000', title: 'Calentamiento', description: 'Alcanza 1,000 puntos', bonusCoins: 5),
    Achievement(id: 'score_5000', title: 'Primeros Pasos', description: 'Alcanza 5,000 puntos', bonusCoins: 10),
    Achievement(id: 'score_10000', title: 'Saltador Experto', description: 'Alcanza 10,000 puntos', bonusCoins: 15),
    Achievement(id: 'score_15000', title: 'Velocidad Luz', description: 'Alcanza 15,000 puntos', bonusCoins: 20),
    Achievement(id: 'score_25000', title: 'Maestro del Neón', description: 'Alcanza 25,000 puntos', bonusCoins: 25),
    Achievement(id: 'score_50000', title: 'Leyenda Cibernética', description: 'Alcanza 50,000 puntos', bonusCoins: 50),
    Achievement(id: 'score_100000', title: 'Ascenso Infinito', description: 'Alcanza 100,000 puntos', bonusCoins: 100),
    
    // Monedas Acumuladas
    Achievement(id: 'coins_50', title: 'Bolsillo Lleno', description: 'Acumula 50 monedas en total', bonusCoins: 10),
    Achievement(id: 'coins_200', title: 'Tesoro Neón', description: 'Acumula 200 monedas en total', bonusCoins: 25),
    Achievement(id: 'coins_500', title: 'Magnate del Salto', description: 'Acumula 500 monedas en total', bonusCoins: 50),
    Achievement(id: 'coins_1000', title: 'Billonario Neón', description: 'Acumula 1,000 monedas en total', bonusCoins: 100),

    // Monedas en una Partida
    Achievement(id: 'match_coins_5', title: 'Recolector Astuto', description: 'Recoge 5 monedas en una sola partida', bonusCoins: 10),
    Achievement(id: 'match_coins_15', title: 'Avaro del Aire', description: 'Recoge 15 monedas en una sola partida', bonusCoins: 25),

    // Skins
    Achievement(id: 'skin_1', title: 'A la Moda', description: 'Desbloquea 2 skins', bonusCoins: 10),
    Achievement(id: 'skin_3', title: 'Pasarela de Neón', description: 'Desbloquea 3 skins', bonusCoins: 20),
    Achievement(id: 'skin_all', title: 'Colección Neón', description: 'Desbloquea 6 skins', bonusCoins: 50),
    Achievement(id: 'skin_10', title: 'Maestro del Estilo', description: 'Desbloquea 10 skins', bonusCoins: 50),
    Achievement(id: 'skin_master', title: 'Colección Legendaria', description: 'Desbloquea 20 skins', bonusCoins: 100),

    // Revives
    Achievement(id: 'revive_1', title: 'Segunda Oportunidad', description: 'Revive por primera vez', bonusCoins: 5),
    Achievement(id: 'revive_3', title: 'Inmortal', description: 'Revive 3 veces en una sola partida', bonusCoins: 15),
    Achievement(id: 'revive_5', title: 'Gato de 9 Vidas', description: 'Revive 5 veces en una sola partida', bonusCoins: 30),

    // Caídas / Muertes
    Achievement(id: 'die_1', title: 'Tropezón Inicial', description: 'Cae al vacío por primera vez', bonusCoins: 5),
    Achievement(id: 'die_10', title: 'Víctima de la Gravedad', description: 'Pierde 10 veces en total', bonusCoins: 15),
    Achievement(id: 'die_25', title: 'Persistencia Pura', description: 'Pierde 25 veces en total', bonusCoins: 25),

    // Mecánicas de Plataformas
    Achievement(id: 'bounce_spring', title: 'Super Impulso', description: 'Rebota en una plataforma resorte', bonusCoins: 10),
    Achievement(id: 'bounce_moving_5', title: 'Equilibrista', description: 'Rebota 5 veces en plataformas móviles en una partida', bonusCoins: 15),
    Achievement(id: 'bounce_fragile_5', title: 'Pisa Fuerte', description: 'Rompe 5 plataformas frágiles en una partida', bonusCoins: 15),
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
    _checkAchievements();
    notifyListeners();
  }

  void _syncToCloud() {
    if (_playerName.isNotEmpty) {
      final unlockedIds = achievements.where((a) => a.isUnlocked).map((a) => a.id).toList();
      _firebaseService.submitScore(
        _playerName,
        _highScore.value,
        coins: _coins.value,
        ownedSkins: _ownedSkins,
        currentSkinIndex: _currentSkinIndex,
        unlockedAchievements: unlockedIds,
      );
    }
  }

  void useCoins(int amount) {
    if (_coins.value >= amount) {
      _coins.value -= amount;
      _saveCoins();
      _syncToCloud();
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
    
    if (_playerName.isEmpty) {
      await restoreAnonymousUser('prueba');
    }

    notifyListeners();

    // Sincroniza en segundo plano el récord local con el ranking global.
    // Recupera a los jugadores cuyos puntajes nunca se subieron.
    _syncScoreOnStartup();
  }

  Future<void> _syncScoreOnStartup() async {
    try {
      await _firebaseService.ensureSignedIn();
      if (_playerName.isNotEmpty && (_highScore.value > 0 || _coins.value > 0 || _ownedSkins.length > 1)) {
        _syncToCloud();
      }
    } catch (e) {
      debugPrint('Error sincronizando datos al iniciar: $e');
    }
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
    _checkAchievements();
    _syncToCloud();
    notifyListeners();
  }

  void unlockSkin(int skinIndex, int cost) {
    if (_coins.value >= cost && !_ownedSkins.contains(skinIndex)) {
      _coins.value -= cost;
      _ownedSkins.add(skinIndex);
      _saveCoins();
      _saveOwnedSkins();
      _checkAchievements();
      _syncToCloud();
      notifyListeners();
    }
  }

  void equipSkin(int skinIndex) {
    if (_ownedSkins.contains(skinIndex)) {
      _currentSkinIndex = skinIndex;
      _saveCurrentSkin();
      _syncToCloud();
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
    _syncToCloud();
  }

  Future<bool> restoreAnonymousUser(String name) async {
    try {
      final data = await _firebaseService.getDataByPlayerName(name);
      if (data != null) {
        _playerName = name;
        final score = (data['score'] as num?)?.toInt() ?? 0;
        final coins = (data['coins'] as num?)?.toInt() ?? 0;
        if (score > _highScore.value) _highScore.value = score;
        if (coins > _coins.value) _coins.value = coins;

        if (data['ownedSkins'] != null) {
          final skins = List<int>.from(data['ownedSkins'].map((e) => (e as num).toInt()));
          for (final s in skins) {
            if (!_ownedSkins.contains(s)) _ownedSkins.add(s);
          }
        }
        if (data['currentSkinIndex'] != null) {
          _currentSkinIndex = (data['currentSkinIndex'] as num).toInt();
        }
        if (data['unlockedAchievements'] != null) {
          final unlocked = List<String>.from(data['unlockedAchievements']);
          for (var a in achievements) {
            if (unlocked.contains(a.id)) {
              a.isUnlocked = true;
            }
          }
        }

        await _saveHighScore();
        await _saveCoins();
        await _saveOwnedSkins();
        await _saveCurrentSkin();
        await _saveUnlockedAchievements();
        await _secureStorage.write(key: 'playerName', value: name);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error restaurando usuario anónimo $name: $e');
      return false;
    }
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
        final cloudScore = (data['score'] as num?)?.toInt() ?? 0;
        final cloudCoins = (data['coins'] as num?)?.toInt() ?? 0;
        final cloudName = data['playerName'] as String? ?? '';
        final cloudOwnedSkins = (data['ownedSkins'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ?? [0];
        final cloudCurrentSkin = (data['currentSkinIndex'] as num?)?.toInt() ?? 0;
        final cloudAchievements = (data['unlockedAchievements'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ?? [];

        final localAchievements = achievements.where((a) => a.isUnlocked).map((a) => a.id).toList();

        if (cloudName.isNotEmpty ||
            cloudScore > 0 ||
            cloudCoins > 0 ||
            cloudOwnedSkins.length > 1 ||
            cloudAchievements.isNotEmpty) {
          // ¿Hay una partida local con progreso diferente a la nube?
          final hasLocalData = _playerName.isNotEmpty ||
              _highScore.value > 0 ||
              _coins.value > 0 ||
              _ownedSkins.length > 1 ||
              localAchievements.isNotEmpty;

          final differs = _playerName != cloudName ||
              _highScore.value != cloudScore ||
              _coins.value != cloudCoins ||
              !_listsEqual(_ownedSkins, cloudOwnedSkins) ||
              !_setsEqual(localAchievements.toSet(), cloudAchievements.toSet());

          if (hasLocalData && differs) {
            // Mostrar aviso "Usuario encontrado" y dejar elegir al jugador
            return LoginResult(
              success: true,
              hasConflict: true,
              cloudName: cloudName,
              cloudScore: cloudScore,
              cloudCoins: cloudCoins,
              cloudOwnedSkins: cloudOwnedSkins,
              cloudCurrentSkinIndex: cloudCurrentSkin,
              cloudAchievements: cloudAchievements,
            );
          } else {
             // Sin partida local (o idéntica): cargar los datos de la cuenta
             _playerName = cloudName;
             _highScore.value = cloudScore;
             _coins.value = cloudCoins;
             _ownedSkins = cloudOwnedSkins.isNotEmpty ? cloudOwnedSkins : [0];
             _currentSkinIndex = cloudCurrentSkin;
             for (var ach in achievements) {
               ach.isUnlocked = cloudAchievements.contains(ach.id);
             }
             await _saveHighScore();
             await _saveCoins();
             await _saveOwnedSkins();
             await _saveCurrentSkin();
             await _saveUnlockedAchievements();
             await _secureStorage.write(key: 'playerName', value: _playerName);
             _syncToCloud();
             notifyListeners();
             return LoginResult(success: true, hasConflict: false);
          }
        }
      }
      
      _syncToCloud();
      notifyListeners();
      return LoginResult(success: true, hasConflict: false);
    }
    return LoginResult(success: false);
  }

  /// Resuelve el aviso "Usuario encontrado".
  /// - [recoverCloudData] = true  -> RETOMAR: se cargan exactamente el nombre,
  ///   récord, monedas, skins y logros que tenía la cuenta de Google.
  /// - [recoverCloudData] = false -> REEMPLAZAR: la cuenta de Google se
  ///   sobrescribe con el nombre, récord, monedas, skins y logros de la partida actual.
  Future<bool> resolveLoginConflict(
    bool recoverCloudData,
    String cloudName,
    int cloudScore,
    int cloudCoins, {
    List<int>? cloudOwnedSkins,
    int? cloudCurrentSkinIndex,
    List<String>? cloudAchievements,
  }) async {
    bool ok = true;
    if (recoverCloudData) {
      _playerName = cloudName;
      _highScore.value = cloudScore;
      _coins.value = cloudCoins;
      _ownedSkins = (cloudOwnedSkins != null && cloudOwnedSkins.isNotEmpty) ? cloudOwnedSkins : [0];
      _currentSkinIndex = cloudCurrentSkinIndex ?? 0;
      final achList = cloudAchievements ?? [];
      for (var ach in achievements) {
        ach.isUnlocked = achList.contains(ach.id);
      }
      await _secureStorage.write(key: 'playerName', value: cloudName);
      await _saveHighScore();
      await _saveCoins();
      await _saveOwnedSkins();
      await _saveCurrentSkin();
      await _saveUnlockedAchievements();
      _syncToCloud();
    } else {
      final unlockedIds = achievements.where((a) => a.isUnlocked).map((a) => a.id).toList();
      ok = await _firebaseService.overwriteUserData(
        _playerName,
        _highScore.value,
        _coins.value,
        ownedSkins: _ownedSkins,
        currentSkinIndex: _currentSkinIndex,
        unlockedAchievements: unlockedIds,
      );
    }
    notifyListeners();
    return ok;
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
      _syncToCloud();
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

  bool _isEvaluatingAchievements = false;

  void _checkAchievements() {
    if (_isEvaluatingAchievements) return;
    _isEvaluatingAchievements = true;
    try {
      // Puntuaciones
      _evaluateAchievement('score_1000', () => currentScore >= 1000);
      _evaluateAchievement('score_5000', () => currentScore >= 5000);
      _evaluateAchievement('score_10000', () => currentScore >= 10000);
      _evaluateAchievement('score_15000', () => currentScore >= 15000);
      _evaluateAchievement('score_25000', () => currentScore >= 25000);
      _evaluateAchievement('score_50000', () => currentScore >= 50000);
      _evaluateAchievement('score_100000', () => currentScore >= 100000);

      // Monedas Acumuladas
      _evaluateAchievement('coins_50', () => coins >= 50);
      _evaluateAchievement('coins_200', () => coins >= 200);
      _evaluateAchievement('coins_500', () => coins >= 500);
      _evaluateAchievement('coins_1000', () => coins >= 1000);

      // Monedas en partida actual
      _evaluateAchievement('match_coins_5', () => _currentCoinsCollected >= 5);
      _evaluateAchievement('match_coins_15', () => _currentCoinsCollected >= 15);

      // Skins
      _evaluateAchievement('skin_1', () => _ownedSkins.length >= 2);
      _evaluateAchievement('skin_3', () => _ownedSkins.length >= 3);
      _evaluateAchievement('skin_all', () => _ownedSkins.length >= 6);
      _evaluateAchievement('skin_10', () => _ownedSkins.length >= 10);
      _evaluateAchievement('skin_master', () => _ownedSkins.length >= 20);

      // Revives
      _evaluateAchievement('revive_1', () => _currentRevives >= 1);
      _evaluateAchievement('revive_3', () => _currentRevives >= 3);
      _evaluateAchievement('revive_5', () => _currentRevives >= 5);

      // Muertes totales
      _evaluateAchievement('die_1', () => _totalDeaths >= 1);
      _evaluateAchievement('die_10', () => _totalDeaths >= 10);
      _evaluateAchievement('die_25', () => _totalDeaths >= 25);

      // Rebotes en plataformas
      _evaluateAchievement('bounce_spring', () => (_platformBounces['SpringPlatform'] ?? 0) >= 1);
      _evaluateAchievement('bounce_moving_5', () => (_platformBounces['MovingPlatform'] ?? 0) >= 5);
      _evaluateAchievement('bounce_fragile_5', () => (_platformBounces['FragilePlatform'] ?? 0) >= 5);
    } finally {
      _isEvaluatingAchievements = false;
    }
  }

  void _evaluateAchievement(String id, bool Function() condition) {
    final index = achievements.indexWhere((a) => a.id == id);
    if (index != -1) {
      final ach = achievements[index];
      if (!ach.isUnlocked && condition()) {
        ach.isUnlocked = true;
        addCoins(ach.bonusCoins);
        _saveUnlockedAchievements();
        onAchievementUnlocked?.call(ach);
      }
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

  bool _listsEqual(List<int> a, List<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _setsEqual(Set<String> a, Set<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}
