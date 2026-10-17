import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/game_state.dart';
import '../utils/constants.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> skins = List.generate(
      Constants.neonColors.length,
      (i) => {
        'color': Constants.neonColors[i],
        'cost': Constants.skinCosts[i],
        'name': Constants.skinNames[i]
      }
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'SHOP',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.pinkAccent, blurRadius: 10)],
          ),
        ),
        actions: [
          Consumer<GameState>(
            builder: (context, gameState, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amberAccent),
                    const SizedBox(width: 5),
                    Text(
                      '${gameState.coins}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: Consumer<GameState>(
        builder: (context, gameState, child) {
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.88,
            ),
            itemCount: skins.length,
            itemBuilder: (context, index) {
              final skin = skins[index];
              final isOwned = gameState.ownedSkins.contains(index);
              final isEquipped = gameState.currentSkinIndex == index;
              final color = skin['color'] as Color;

              return GestureDetector(
                onTap: () {
                  if (isOwned) {
                    gameState.equipSkin(index);
                  } else {
                    if (gameState.coins >= skin['cost']) {
                      gameState.unlockSkin(index, skin['cost']);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('¡Monedas insuficientes!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(
                      color: isEquipped ? Colors.white : color.withOpacity(0.5),
                      width: isEquipped ? 3 : 1,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: isEquipped
                        ? [BoxShadow(color: color, blurRadius: 10)]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(isEquipped ? 0.8 : 0.3),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: index >= 6
                            ? ClipOval(
                                child: Image.asset(
                                  'assets/images/${Constants.thematicSkinImages[index - 6]}',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : CustomPaint(
                                painter: SkinPreviewPainter(index, color),
                              ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        skin['name'], 
                        style: TextStyle(
                          color: color, 
                          fontWeight: FontWeight.bold,
                          fontSize: 12
                        )
                      ),
                      const SizedBox(height: 5),
                      if (isEquipped)
                        const Text('EQUIPPED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))
                      else if (isOwned)
                        const Text('OWNED', style: TextStyle(color: Colors.white54, fontSize: 12))
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.amberAccent, size: 16),
                            const SizedBox(width: 5),
                            Text('${skin['cost']}', style: const TextStyle(color: Colors.white, fontSize: 12)),
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

class SkinPreviewPainter extends CustomPainter {
  final int skinIndex;
  final Color baseColor;

  SkinPreviewPainter(this.skinIndex, this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    double radius = size.width / 2;
    final center = Offset(radius, radius);
    final skinPaint = Paint()..style = PaintingStyle.fill;
    
    skinPaint.color = baseColor;
    canvas.drawCircle(center, radius, skinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
