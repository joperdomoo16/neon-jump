import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/game_state.dart';
import '../utils/constants.dart';
import 'game_screen.dart';
import 'shop_screen.dart';
import 'achievements_screen.dart';
import 'ranking_screen.dart';
import 'package:in_app_update/in_app_update.dart';
import '../services/audio_manager.dart';
import '../services/ads_manager.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with SingleTickerProviderStateMixin {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  late AnimationController _logoAnimController;
  bool _showPrivacyOptionsButton = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _checkForAppUpdate();
    _logoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initConsentAndAds();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameState = Provider.of<GameState>(context, listen: false);
      if (gameState.playerName.isEmpty) {
        _showNamePrompt(context, gameState);
      }
    });
  }

  Future<void> _checkForAppUpdate() async {
    if (kIsWeb) return;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        }
      } else if (info.updateAvailability == UpdateAvailability.developerTriggeredUpdateInProgress) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      debugPrint('ℹ️ [InAppUpdate] Verificación de actualización en Play Store: $e');
    }
  }

  void _initConsentAndAds() {
    AdsManager().gatherConsent(onConsentComplete: () {
      if (mounted) {
        _checkPrivacyOptions();
        _loadBannerAd();
      }
    });
    _checkPrivacyOptions();
    _loadBannerAd();
  }

  Future<void> _checkPrivacyOptions() async {
    final isRequired = await AdsManager().isPrivacyOptionsRequired();
    if (mounted && _showPrivacyOptionsButton != isRequired) {
      setState(() {
        _showPrivacyOptionsButton = isRequired;
      });
    }
  }

  void _showNamePrompt(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String enteredName = '';
        bool isChecking = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            void checkAndSave() async {
              final trimmedName = enteredName.trim();
              if (trimmedName.isEmpty) return;

              setDialogState(() {
                isChecking = true;
                errorMessage = null;
              });

              bool isAvailable = await gameState.isNameAvailable(trimmedName);
              
              if (!mounted || !dialogCtx.mounted) return;
              
              if (isAvailable) {
                gameState.setPlayerName(trimmedName);
                Navigator.of(dialogCtx).pop();
              } else {
                final recovered = await gameState.restoreAnonymousUser(trimmedName);
                if (!mounted || !dialogCtx.mounted) return;
                if (recovered) {
                  Navigator.of(dialogCtx).pop();
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('¡Bienvenido de vuelta, $trimmedName! Progreso recuperado.'),
                    ),
                  );
                } else {
                  setDialogState(() {
                    isChecking = false;
                    errorMessage = 'Ese nombre ya está en uso. ¡Elige otro!';
                  });
                }
              }
            }

            return AlertDialog(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.cyanAccent, width: 2),
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text('Bienvenido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Ingresa tu nombre para el Ranking Global:', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 15),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Tu nombre',
                        hintStyle: const TextStyle(color: Colors.white30),
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
                        errorText: errorMessage,
                      ),
                      onChanged: (val) {
                        enteredName = val;
                        if (errorMessage != null) {
                          setDialogState(() { errorMessage = null; });
                        }
                      },
                      onSubmitted: (val) {
                        if (!isChecking) checkAndSave();
                      },
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      '¿Ya habías jugado? Recupera tu progreso',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      icon: const Icon(Icons.login, color: Colors.white),
                      label: const Text('GOOGLE LOGIN', style: TextStyle(color: Colors.white)),
                      onPressed: () async {
                        if (isChecking) return;
                        setDialogState(() {
                          isChecking = true;
                          errorMessage = null;
                        });
                        final messenger = ScaffoldMessenger.of(this.context);
                        final result = await gameState.loginWithGoogle();
                        if (!mounted || !dialogCtx.mounted) return;
                        
                        if (result.hasConflict) {
                          Navigator.of(dialogCtx).pop();
                          _showConflictDialog(this.context, gameState, result);
                        } else if (result.success) {
                          if (gameState.playerName.isEmpty) {
                            setDialogState(() {
                              isChecking = false;
                              errorMessage = 'Sesión iniciada con Google. Ahora elige un nombre para el ranking.';
                            });
                          } else {
                            Navigator.of(dialogCtx).pop();
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Progreso recuperado con éxito')),
                            );
                          }
                        } else {
                          setDialogState(() {
                            isChecking = false;
                            errorMessage = 'Error al conectar con Google';
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                isChecking 
                  ? const CircularProgressIndicator(color: Colors.pinkAccent)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                      onPressed: checkAndSave,
                      child: const Text('GUARDAR', style: TextStyle(color: Colors.white)),
                    ),
              ],
            );
          }
        );
      },
    );
  }

  void _showConflictDialog(BuildContext context, GameState gameState, LoginResult result) {
    final cloudName = result.cloudName ?? '';
    final cloudScore = result.cloudScore ?? 0;
    final cloudCoins = result.cloudCoins ?? 0;
    final cloudSkins = result.cloudOwnedSkins ?? [0];
    final cloudCurrentSkin = result.cloudCurrentSkinIndex ?? 0;
    final cloudAchievements = result.cloudAchievements ?? [];
    final localAchievementsCount = gameState.achievements.where((a) => a.isUnlocked).length;
    // Usamos el ScaffoldMessenger de la pantalla (no el del diálogo, que se cierra)
    final messenger = ScaffoldMessenger.of(this.context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.cyanAccent, width: 2),
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.person_search, color: Colors.cyanAccent),
              SizedBox(width: 8),
              Expanded(
                child: Text('¡Usuario encontrado!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Esta cuenta de Google ya tiene datos guardados:',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 10),
                _buildDataCard(
                  label: 'CUENTA DE GOOGLE',
                  color: Colors.cyanAccent,
                  name: cloudName,
                  score: cloudScore,
                  coins: cloudCoins,
                  skinsCount: cloudSkins.length,
                  achievementsCount: cloudAchievements.length,
                ),
                const SizedBox(height: 10),
                _buildDataCard(
                  label: 'PARTIDA ACTUAL',
                  color: Colors.pinkAccent,
                  name: gameState.playerName,
                  score: gameState.highScore,
                  coins: gameState.coins,
                  skinsCount: gameState.ownedSkins.length,
                  achievementsCount: localAchievementsCount,
                ),
                const SizedBox(height: 14),
                const Text(
                  '¿Deseas retomar los datos que ya tenías o reemplazarlos por los de la partida actual?',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await gameState.resolveLoginConflict(
                  true,
                  cloudName,
                  cloudScore,
                  cloudCoins,
                  cloudOwnedSkins: cloudSkins,
                  cloudCurrentSkinIndex: cloudCurrentSkin,
                  cloudAchievements: cloudAchievements,
                );
                messenger.showSnackBar(
                  SnackBar(content: Text('¡Bienvenido de vuelta, $cloudName! Datos recuperados')),
                );
              },
              child: const Text('RETOMAR', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: dialogContext,
                  builder: (c) => AlertDialog(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.redAccent, width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    title: const Text('¿Reemplazar datos?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    content: Text(
                      'Se borrarán definitivamente los datos de "$cloudName" ($cloudScore pts, $cloudCoins monedas, ${cloudSkins.length} skins, ${cloudAchievements.length} logros) y se guardará la partida actual en tu cuenta de Google.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(c).pop(false),
                        child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(c).pop(true),
                        child: const Text('REEMPLAZAR', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
                if (confirm != true) return;
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                final ok = await gameState.resolveLoginConflict(
                  false,
                  cloudName,
                  cloudScore,
                  cloudCoins,
                );
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Datos reemplazados por la partida actual'
                        : 'No se pudo reemplazar. Revisa tu conexión e inténtalo de nuevo'),
                  ),
                );
              },
              child: const Text('REEMPLAZAR', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
    );
  }

  Widget _buildDataCard({
    required String label,
    required Color color,
    required String name,
    required int score,
    required int coins,
    required int skinsCount,
    required int achievementsCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(
            name.isEmpty ? '(sin nombre)' : name,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.yellowAccent, size: 18),
              const SizedBox(width: 4),
              Text('Récord: $score', style: const TextStyle(color: Colors.yellowAccent)),
              const SizedBox(width: 16),
              const Icon(Icons.monetization_on, color: Colors.amberAccent, size: 18),
              const SizedBox(width: 4),
              Text('$coins', style: const TextStyle(color: Colors.amberAccent)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.palette, color: Colors.pinkAccent, size: 18),
              const SizedBox(width: 4),
              Text('Skins: $skinsCount', style: const TextStyle(color: Colors.white70)),
              const SizedBox(width: 16),
              const Icon(Icons.military_tech, color: Colors.cyanAccent, size: 18),
              const SizedBox(width: 4),
              Text('Logros: $achievementsCount', style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  void _loadBannerAd() async {
    if (kIsWeb) return;
    if (_isBannerAdLoaded || _bannerAd != null) return;
    try {
      if (!await ConsentInformation.instance.canRequestAds()) return;
      if (!mounted) return;

      _bannerAd = BannerAd(
        adUnitId: Constants.bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) {
              setState(() {
                _isBannerAdLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('⚠️ [AdMob] Error al cargar banner en MainMenu: ${error.message} (Código: ${error.code})');
            ad.dispose();
          },
        ),
      );
      _bannerAd?.load().catchError((e) {
        debugPrint('⚠️ [AdMob] Banner load handled: $e');
      });
    } catch (e) {
      debugPrint('AdMob banner unavailable: $e');
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _logoAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: SizedBox.expand(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F0C29),
                Color(0xFF302B63),
                Color(0xFF7A1C77),
                Color(0xFFD6226B),
                Color(0xFFF16529),
              ],
              stops: [0.0, 0.3, 0.6, 0.8, 1.0],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(
                          AudioManager().isAudioEnabled ? Icons.volume_up : Icons.volume_off,
                          color: AudioManager().isAudioEnabled ? Colors.cyanAccent : Colors.grey,
                          size: 32,
                          shadows: AudioManager().isAudioEnabled
                              ? const [Shadow(color: Colors.cyanAccent, blurRadius: 10)]
                              : null,
                        ),
                        onPressed: () {
                          setState(() {
                            AudioManager().toggleAudio();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Logo
              AnimatedBuilder(
                animation: _logoAnimController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_logoAnimController.value * 0.1),
                    child: Text(
                      'NEON\nJUMP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 45,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.cyanAccent, 
                            blurRadius: 20 + (_logoAnimController.value * 20)
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              
              // High Score and Coins
              Consumer<GameState>(
                builder: (context, gameState, child) {
                  return Column(
                    children: [
                      Text(
                        'HIGH SCORE: ${gameState.highScore}',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.yellowAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'COINS: ${gameState.coins}',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (gameState.playerName.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Bienvenido ${gameState.playerName}',
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.cyanAccent, blurRadius: 15),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 25),
              
              // Buttons
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    _buildButton(
                      context, 
                      'PLAY', 
                      Colors.cyanAccent, 
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const GameScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildButton(context, 'RANKING', Colors.amber, () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const RankingScreen()),
                      );
                    }),
                    const SizedBox(height: 10),
                    _buildButton(
                      context, 
                      'SHOP', 
                      Colors.pinkAccent, 
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ShopScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildButton(
                      context, 
                      'LOGROS', 
                      Colors.purpleAccent, 
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AchievementsScreen()),
                        );
                      },
                    ),
                    if (_showPrivacyOptionsButton) ...[
                      const SizedBox(height: 6),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                        icon: const Icon(Icons.privacy_tip_outlined, size: 16, color: Colors.cyanAccent),
                        label: const Text(
                          'Opciones de privacidad',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        onPressed: () {
                          AdsManager().showPrivacyOptionsForm(onDismissed: (_) {
                            _checkPrivacyOptions();
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 10),
                    StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.authStateChanges(),
                      builder: (streamCtx, snapshot) {
                        final user = snapshot.data;
                        final isGoogleLinked = user?.providerData.any((p) => p.providerId == 'google.com') ?? false;
                        
                        if (isGoogleLinked) {
                          return Column(
                            children: [
                              const Text('Conectado con Google', style: TextStyle(color: Colors.greenAccent)),
                              const SizedBox(height: 5),
                              TextButton(
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final gameState = Provider.of<GameState>(context, listen: false);
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogCtx) => AlertDialog(
                                      backgroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        side: const BorderSide(color: Colors.redAccent, width: 2),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      content: const Text(
                                        '¿Estás seguro de que deseas cerrar sesión? Tus datos locales se reiniciarán en este dispositivo.',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(dialogCtx).pop(false),
                                          child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(dialogCtx).pop(true),
                                          child: const Text('CERRAR SESIÓN', style: TextStyle(color: Colors.redAccent)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm != true) return;

                                  await FirebaseAuth.instance.signOut();
                                  try {
                                    await GoogleSignIn().signOut();
                                  } catch (_) {}
                                  if (!mounted || !context.mounted) return;
                                  await gameState.wipeLocalData();
                                  if (!mounted || !context.mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Sesión cerrada')),
                                  );
                                  _showNamePrompt(context, gameState);
                                },
                                child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
                              ),
                              const SizedBox(height: 15),
                            ],
                          );
                        }
                        
                        return Column(
                          children: [
                            const Text(
                              '¡Guarda tu progreso!',
                              style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _buildButton(
                              context, 
                              'GOOGLE LOGIN', 
                              Colors.blueAccent, 
                              () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final gameState = Provider.of<GameState>(context, listen: false);
                                final result = await gameState.loginWithGoogle();
                                if (!mounted || !context.mounted) return;
                                if (result.hasConflict) {
                                  _showConflictDialog(context, gameState, result);
                                } else if (result.success) {
                                  if (gameState.playerName.isEmpty) {
                                    _showNamePrompt(context, gameState);
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('Sesión iniciada. Por favor elige un nombre para el ranking.')),
                                    );
                                  } else {
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('Cuenta vinculada con éxito')),
                                    );
                                  }
                                } else {
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Error al iniciar sesión con Google')),
                                  );
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              
                const SizedBox(height: 20),
                
                // Banner Ad
                if (_isBannerAdLoaded && _bannerAd != null)
                  SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  )
                else
                  const SizedBox(height: 50),
                SizedBox(height: MediaQuery.paddingOf(context).bottom + 12),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildButton(BuildContext context, String text, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(color: color, blurRadius: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
