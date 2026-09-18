import 'package:flutter/material.dart';
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

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with SingleTickerProviderStateMixin {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  late AnimationController _logoAnimController;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _logoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameState = Provider.of<GameState>(context, listen: false);
      if (gameState.playerName.isEmpty) {
        _showNamePrompt(context, gameState);
      }
    });
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
          builder: (context, setState) {
            void checkAndSave() async {
              final trimmedName = enteredName.trim();
              if (trimmedName.isEmpty) return;

              setState(() {
                isChecking = true;
                errorMessage = null;
              });

              bool isAvailable = await gameState.isNameAvailable(trimmedName);
              
              if (!mounted) return;
              
              if (isAvailable) {
                gameState.setPlayerName(trimmedName);
                Navigator.of(context).pop();
              } else {
                setState(() {
                  isChecking = false;
                  errorMessage = 'Ese nombre ya está en uso. ¡Elige otro!';
                });
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
                          setState(() { errorMessage = null; });
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
                        setState(() {
                          isChecking = true;
                          errorMessage = null;
                        });
                        final result = await gameState.loginWithGoogle();
                        if (!mounted) return;
                        
                        if (result.hasConflict) {
                          Navigator.of(context).pop();
                          _showConflictDialog(context, gameState, result);
                        } else if (result.success) {
                          if (gameState.playerName.isEmpty) {
                            setState(() {
                              isChecking = false;
                              errorMessage = 'Sesión iniciada con Google. Ahora elige un nombre para el ranking.';
                            });
                          } else {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Progreso recuperado con éxito')),
                            );
                          }
                        } else {
                          setState(() {
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.cyanAccent, width: 2),
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Conflicto de Datos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            'Hemos encontrado otro usuario llamado "${result.cloudName}" con un SCORE de ${result.cloudScore}.\n\n¿Deseas recuperar o reemplazar por este nuevo usuario?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await gameState.resolveLoginConflict(true, result.cloudName!, result.cloudScore!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Progreso de la nube recuperado')),
                  );
                }
              },
              child: const Text('RECUPERAR', style: TextStyle(color: Colors.greenAccent)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await gameState.resolveLoginConflict(false, result.cloudName!, result.cloudScore!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nube reemplazada exitosamente')),
                  );
                }
              },
              child: const Text('REEMPLAZAR', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      }
    );
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: Constants.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
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
      body: Container(
        width: double.infinity,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Spacer(flex: 2),
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
              
              const Spacer(flex: 3),
              
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
                    const SizedBox(height: 10),
                    StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.authStateChanges(),
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        final isGoogleLinked = user?.providerData.any((p) => p.providerId == 'google.com') ?? false;
                        
                        if (isGoogleLinked) {
                          return Column(
                            children: [
                              const Text('Conectado con Google', style: TextStyle(color: Colors.greenAccent)),
                              const SizedBox(height: 5),
                              TextButton(
                                onPressed: () async {
                                  await FirebaseAuth.instance.signOut();
                                  try {
                                    await GoogleSignIn().signOut();
                                  } catch (_) {}
                                  if (mounted) {
                                    final gameState = Provider.of<GameState>(context, listen: false);
                                    await gameState.wipeLocalData();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Sesión cerrada')),
                                    );
                                    _showNamePrompt(context, gameState);
                                  }
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
                                final gameState = Provider.of<GameState>(context, listen: false);
                                final result = await gameState.loginWithGoogle();
                                if (mounted) {
                                  if (result.hasConflict) {
                                    _showConflictDialog(context, gameState, result);
                                  } else if (result.success) {
                                    if (gameState.playerName.isEmpty) {
                                      _showNamePrompt(context, gameState);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Sesión iniciada. Por favor elige un nombre para el ranking.')),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Cuenta vinculada con éxito')),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Error al iniciar sesión con Google')),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              
              const Spacer(flex: 2),
              
              // Banner Ad
              if (_isBannerAdLoaded && _bannerAd != null)
                SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                )
              else
                const SizedBox(height: 50),
            ],
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
