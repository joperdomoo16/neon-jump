import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:provider/provider.dart';

import '../game/neon_jump_game.dart';
import '../services/game_state.dart';
import 'hud.dart';
import 'game_over.dart';
import 'achievement_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late NeonJumpGame _game;

  @override
  void initState() {
    super.initState();
    final gameState = Provider.of<GameState>(context, listen: false);
    gameState.resetCurrentScore();
    _game = NeonJumpGame(gameState: gameState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async {
          // Confirm exit if needed, for now just allow
          return true;
        },
        child: Stack(
          children: [
            GameWidget(
              game: _game,
              overlayBuilderMap: {
                'Hud': (BuildContext context, NeonJumpGame game) {
                  return const Hud();
                },
                'GameOver': (BuildContext context, NeonJumpGame game) {
                  return GameOver(game: game);
                },
                'TapToStart': (BuildContext context, NeonJumpGame game) {
                  return IgnorePointer(
                    child: Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Text(
                          'TAP TO CONTINUE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 10)],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              },
              initialActiveOverlays: const ['TapToStart'],
            ),
            const AchievementOverlay(),
          ],
        ),
      ),
    );
  }
}
