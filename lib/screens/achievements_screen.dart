import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_state.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('LOGROS', style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.amberAccent, blurRadius: 10)],
        )),
      ),
      body: Consumer<GameState>(
        builder: (context, gameState, _) {
          final achievements = gameState.achievements;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final ach = achievements[index];
              final isUnlocked = ach.isUnlocked;

              return Card(
                color: isUnlocked ? Colors.grey[900] : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isUnlocked ? Colors.amberAccent : Colors.grey[800]!,
                    width: isUnlocked ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        isUnlocked ? Icons.emoji_events : Icons.lock,
                        color: isUnlocked ? Colors.amber : Colors.grey[600],
                        size: 40,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ach.title,
                              style: TextStyle(
                                color: isUnlocked ? Colors.white : Colors.grey[500],
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ach.description,
                              style: TextStyle(
                                color: isUnlocked ? Colors.grey[300] : Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          const Icon(Icons.monetization_on, color: Colors.yellow, size: 20),
                          Text(
                            '+${ach.bonusCoins}',
                            style: TextStyle(
                              color: isUnlocked ? Colors.yellow : Colors.grey[600],
                              fontWeight: FontWeight.bold,
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
        },
      ),
    );
  }
}
