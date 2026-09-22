import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../game/neon_jump_game.dart';
import '../services/game_state.dart';
import '../services/ads_manager.dart';
import '../utils/constants.dart';
import 'game_screen.dart';
class GameOver extends StatefulWidget {
  final NeonJumpGame game;
  const GameOver({super.key, required this.game});

  @override
  State<GameOver> createState() => _GameOverState();
}

class _GameOverState extends State<GameOver> {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  bool _hasRevived = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context, listen: true);

    return Container(
      width: double.infinity,
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Text(
              'GAME OVER',
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(color: Colors.pinkAccent, blurRadius: 20),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'SCORE: ${gameState.currentScore}',
              style: const TextStyle(
                fontSize: 30,
                color: Colors.cyanAccent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'COINS COLLECTED: ${gameState.currentCoinsCollected}',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.amberAccent,
              ),
            ),
            const SizedBox(height: 20),
            
            // Block bounce summary
            if (gameState.platformBounces.isNotEmpty) ...[
              const Text(
                'BLOCKS BOUNCED:',
                style: TextStyle(fontSize: 18, color: Colors.yellowAccent),
              ),
              const SizedBox(height: 5),
              ...gameState.platformBounces.entries.map((e) {
                String name = e.key.replaceAll('Platform', '');
                return Text(
                  '$name: ${e.value}',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                );
              }),
            ],
            const SizedBox(height: 40),
            
            if (!_hasRevived) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildButton(
                    context, 
                    'REVIVE (AD)', 
                    Colors.greenAccent, 
                    () {
                      AdsManager().showRewardedAd(
                        onReward: () {
                          setState(() {
                            _hasRevived = true;
                          });
                          widget.game.revive();
                        },
                      );
                    },
                    width: 160,
                    fontSize: 16,
                  ),
                  const SizedBox(width: 15),
                  _buildButton(
                    context, 
                    'REVIVE (100 🪙)', 
                    gameState.coins >= 100 ? Colors.amber : Colors.grey, 
                    () {
                      if (gameState.coins >= 100) {
                        gameState.useCoins(100);
                        setState(() {
                          _hasRevived = true;
                        });
                        widget.game.revive();
                      }
                    },
                    width: 160,
                    fontSize: 16,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
              
            _buildButton(
              context, 
              'RETRY', 
              Colors.cyanAccent, 
              () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const GameScreen()),
                );
              },
            ),
            
            const SizedBox(height: 20),
            _buildButton(
              context, 
              'MENU', 
              Colors.pinkAccent, 
              () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),

            const Spacer(),
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
    );
  }

  Widget _buildButton(BuildContext context, String text, Color color, VoidCallback onPressed, {double width = 200, double fontSize = 20}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: color, blurRadius: 10)],
            ),
          ),
        ),
      ),
    );
  }
}
