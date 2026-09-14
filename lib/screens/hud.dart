import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/game_state.dart';

class Hud extends StatelessWidget {
  const Hud({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score
                Text(
                  '${gameState.currentScore}',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.cyanAccent, blurRadius: 10),
                    ],
                  ),
                ),
                // Coins
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amberAccent, size: 30),
                    const SizedBox(width: 8),
                    Text(
                      '${gameState.coins}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Colors.amberAccent, blurRadius: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
