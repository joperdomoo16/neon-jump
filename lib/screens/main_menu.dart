import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

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
              content: Column(
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
                ],
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
              const SizedBox(height: 50),
              // Logo
              AnimatedBuilder(
                animation: _logoAnimController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_logoAnimController.value * 0.1),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.5 + (_logoAnimController.value * 0.5)),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Text(
                        'NEON\nJUMP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.cyanAccent, blurRadius: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // High Score and Coins
              Consumer<GameState>(
                builder: (context, gameState, child) {
                  return Column(
                    children: [
                      Text(
                        'HIGH SCORE: ${gameState.highScore}',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.yellowAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'COINS: ${gameState.coins}',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              // Buttons
              Column(
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
                  const SizedBox(height: 15),
                  _buildButton(context, 'RANKING', Colors.amber, () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const RankingScreen()),
                    );
                  }),
                  const SizedBox(height: 15),
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
                  const SizedBox(height: 15),
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
        padding: const EdgeInsets.symmetric(vertical: 15),
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
              fontSize: 24,
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
