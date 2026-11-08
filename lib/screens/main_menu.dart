import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:in_app_update/in_app_update.dart';
import '../services/game_state.dart';
import '../services/audio_manager.dart';
import '../services/ads_manager.dart';
import '../utils/constants.dart';
import 'game_screen.dart';
import 'shop_screen.dart';
import 'achievements_screen.dart';
import 'ranking_screen.dart';
import 'dialogo_registro_nombre.dart';
import 'dialogo_conflicto_cuenta.dart';
import 'boton_neon.dart';
import 'seccion_autenticacion.dart';

/// Pantalla principal de inicio del juego, navegación, música y publicidad.
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
        _mostrarRegistroNombre(gameState);
      }
    });
  }

  void _mostrarRegistroNombre(GameState gameState) {
    mostrarDialogoRegistroNombre(
      context,
      gameState,
      onConflictoEncontrado: (resultado) {
        mostrarDialogoConflictoCuenta(context, gameState, resultado);
      },
    );
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
      debugPrint('Información de actualización en tienda: $e');
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
            debugPrint('Error al cargar banner en menú principal: ${error.message}');
            ad.dispose();
          },
        ),
      );
      _bannerAd?.load().catchError((e) {
        debugPrint('Banner load handled: $e');
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
                                blurRadius: 20 + (_logoAnimController.value * 20),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
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
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BotonNeon(
                        texto: 'PLAY',
                        color: Colors.cyanAccent,
                        alPresionar: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const GameScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      BotonNeon(
                        texto: 'RANKING',
                        color: Colors.amber,
                        alPresionar: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const RankingScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      BotonNeon(
                        texto: 'SHOP',
                        color: Colors.pinkAccent,
                        alPresionar: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ShopScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      BotonNeon(
                        texto: 'LOGROS',
                        color: Colors.purpleAccent,
                        alPresionar: () {
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
                      SeccionAutenticacion(
                        onAbrirRegistroNombre: () {
                          final gs = Provider.of<GameState>(context, listen: false);
                          _mostrarRegistroNombre(gs);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
}
