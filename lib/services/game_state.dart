import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/obfuscated_int.dart';
import '../models/achievement.dart';
import '../models/resultado_login.dart';
import 'firebase_service.dart';
import 'storage_repository.dart';
import 'gestor_logros.dart';

export '../models/resultado_login.dart';

/// Administrador central del estado reactivo del juego, datos del jugador y sincronización.
class GameState extends ChangeNotifier {
  final _secureStorage = const FlutterSecureStorage();
  final StorageRepository _storage = StorageRepository();
  final FirebaseService _firebaseService = FirebaseService();
  final GestorLogros _gestorLogros = GestorLogros();

  final ObfuscatedInt _highScore = ObfuscatedInt(0);
  final ObfuscatedInt _coins = ObfuscatedInt(0);
  final ObfuscatedInt _currentScore = ObfuscatedInt(0);

  List<int> _ownedSkins = [0];
  int _currentSkinIndex = 0;
  String _playerName = '';

  int _totalDeaths = 0;
  int _currentRevives = 0;
  int _currentCoinsCollected = 0;
  bool _isGameOver = false;
  DateTime? _gameStartTime;
  final Map<String, int> _platformBounces = {};

  List<Achievement> get achievements => _gestorLogros.listaLogros;
  Function(Achievement)? get onAchievementUnlocked => _gestorLogros.onAchievementUnlocked;
  set onAchievementUnlocked(Function(Achievement)? callback) {
    _gestorLogros.onAchievementUnlocked = callback;
  }

  int get highScore => _highScore.value;
  int get coins => _coins.value;
  List<int> get ownedSkins => _ownedSkins;
  int get currentSkinIndex => _currentSkinIndex;
  String get playerName => _playerName;
  bool get isGameOver => _isGameOver;
  int get currentScore => _currentScore.value;
  int get totalDeaths => _totalDeaths;
  int get currentRevives => _currentRevives;
  int get currentCoinsCollected => _currentCoinsCollected;
  Map<String, int> get platformBounces => _platformBounces;

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
      _gestorLogros.cargarDesbloqueados(unlockedStr.split(','));
    }

    notifyListeners();
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

  void recordBounce(String platformType) {
    _platformBounces[platformType] = (_platformBounces[platformType] ?? 0) + 1;
    _verificarLogros();
    notifyListeners();
  }

  void _syncToCloud() {
    if (_playerName.isNotEmpty) {
      _firebaseService.submitScore(
        _playerName,
        _highScore.value,
        coins: _coins.value,
        ownedSkins: _ownedSkins,
        currentSkinIndex: _currentSkinIndex,
        unlockedAchievements: _gestorLogros.idsDesbloqueados,
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

  void updateScore(int score) {
    _currentScore.value = score;
    if (_currentScore.value > _highScore.value) {
      _highScore.value = _currentScore.value;
    }
    _verificarLogros();
    notifyListeners();
  }

  void addCoins(int amount) {
    _coins.value += amount;
    _currentCoinsCollected += amount;
    _saveCoins();
    _verificarLogros();
    _syncToCloud();
    notifyListeners();
  }

  void unlockSkin(int skinIndex, int cost) {
    if (_coins.value >= cost && !_ownedSkins.contains(skinIndex)) {
      _coins.value -= cost;
      _ownedSkins.add(skinIndex);
      _saveCoins();
      _saveOwnedSkins();
      _verificarLogros();
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
          _gestorLogros.cargarDesbloqueados(List<String>.from(data['unlockedAchievements']));
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
    _gestorLogros.reiniciar();
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

        final localAchievements = _gestorLogros.idsDesbloqueados;

        if (cloudName.isNotEmpty ||
            cloudScore > 0 ||
            cloudCoins > 0 ||
            cloudOwnedSkins.length > 1 ||
            cloudAchievements.isNotEmpty) {
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
            _playerName = cloudName;
            _highScore.value = cloudScore;
            _coins.value = cloudCoins;
            _ownedSkins = cloudOwnedSkins.isNotEmpty ? cloudOwnedSkins : [0];
            _currentSkinIndex = cloudCurrentSkin;
            _gestorLogros.cargarDesbloqueados(cloudAchievements);

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
      _gestorLogros.reiniciar();
      _gestorLogros.cargarDesbloqueados(cloudAchievements ?? []);

      await _secureStorage.write(key: 'playerName', value: cloudName);
      await _saveHighScore();
      await _saveCoins();
      await _saveOwnedSkins();
      await _saveCurrentSkin();
      await _saveUnlockedAchievements();
      _syncToCloud();
    } else {
      ok = await _firebaseService.overwriteUserData(
        _playerName,
        _highScore.value,
        _coins.value,
        ownedSkins: _ownedSkins,
        currentSkinIndex: _currentSkinIndex,
        unlockedAchievements: _gestorLogros.idsDesbloqueados,
      );
    }
    notifyListeners();
    return ok;
  }

  void setGameOver(bool gameOver) {
    _isGameOver = gameOver;
    if (gameOver) {
      if (_gameStartTime != null) {
        final durationInSeconds = DateTime.now().difference(_gameStartTime!).inSeconds;
        final maxRealisticScore = durationInSeconds * 1000;
        if (_currentScore.value > maxRealisticScore && _currentScore.value > 5000) {
          debugPrint('Puntaje irreal detectado: ${_currentScore.value} en $durationInSeconds seg');
          _currentScore.value = 0;
        }
      }

      _totalDeaths++;
      _saveTotalDeaths();
      _verificarLogros();
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
    _verificarLogros();
    notifyListeners();
  }

  void _verificarLogros() {
    _gestorLogros.evaluarMetas(
      puntajeActual: currentScore,
      totalMonedas: coins,
      monedasPartida: _currentCoinsCollected,
      cantidadSkins: _ownedSkins.length,
      revividasPartida: _currentRevives,
      muertesTotales: _totalDeaths,
      rebotesPlataforma: _platformBounces,
      onPremio: (bonus) => addCoins(bonus),
      onGuardar: () => _saveUnlockedAchievements(),
    );
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
    await _secureStorage.write(key: 'unlockedAchievements', value: _gestorLogros.idsDesbloqueados.join(','));
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
