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
                        const SnackBar(content: Text('Not enough coins!')),
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
                          boxShadow: index < 6 ? [BoxShadow(color: color, blurRadius: 15)] : [],
                        ),
                        child: index >= 6
                            ? ClipOval(
                                child: Image.asset(
                                  'assets/images/skin_${['basketball', 'tennis', 'volleyball', 'soccer', 'bowling'][index - 6]}.png',
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
    
    if (skinIndex < 6) return;

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.black;

    if (skinIndex == 6) { // Basketball
      canvas.drawCircle(center, radius, linePaint);
      canvas.drawLine(Offset(radius, 0), Offset(radius, radius * 2), linePaint);
      canvas.drawLine(Offset(0, radius), Offset(radius * 2, radius), linePaint);
      
      final path = Path();
      path.moveTo(radius * 0.3, 0);
      path.quadraticBezierTo(radius * 1.5, radius, radius * 0.3, radius * 2);
      canvas.drawPath(path, linePaint);
      
      final path2 = Path();
      path2.moveTo(radius * 1.7, 0);
      path2.quadraticBezierTo(radius * 0.5, radius, radius * 1.7, radius * 2);
      canvas.drawPath(path2, linePaint);
    } 
    else if (skinIndex == 7) { // Tennis
      linePaint.color = Colors.white;
      canvas.drawCircle(center, radius, linePaint);
      
      final path = Path();
      path.moveTo(0, radius * 0.5);
      path.quadraticBezierTo(radius, radius, 0, radius * 1.5);
      canvas.drawPath(path, linePaint);
      
      final path2 = Path();
      path2.moveTo(radius * 2, radius * 0.5);
      path2.quadraticBezierTo(radius, radius, radius * 2, radius * 1.5);
      canvas.drawPath(path2, linePaint);
    }
    else if (skinIndex == 8) { // Volleyball
      linePaint.color = Colors.blueAccent;
      canvas.drawCircle(center, radius, linePaint);
      canvas.drawLine(Offset(radius * 0.5, 0), Offset(radius * 1.5, radius * 2), linePaint);
      canvas.drawLine(Offset(radius * 1.5, 0), Offset(radius * 0.5, radius * 2), linePaint);
      canvas.drawLine(Offset(0, radius), Offset(radius * 2, radius), linePaint);
    }
    else if (skinIndex == 9) { // Soccer
      final path = Path();
      double s = radius * 0.3;
      path.moveTo(radius, radius - s);
      path.lineTo(radius + s, radius - s * 0.2);
      path.lineTo(radius + s * 0.6, radius + s * 0.8);
      path.lineTo(radius - s * 0.6, radius + s * 0.8);
      path.lineTo(radius - s, radius - s * 0.2);
      path.close();
      
      final fillPaint = Paint()..color = Colors.black..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
      canvas.drawCircle(center, radius, linePaint);
      
      canvas.drawLine(Offset(radius, radius - s), Offset(radius, 0), linePaint);
      canvas.drawLine(Offset(radius + s, radius - s * 0.2), Offset(radius * 2, radius * 0.3), linePaint);
      canvas.drawLine(Offset(radius + s * 0.6, radius + s * 0.8), Offset(radius * 1.8, radius * 1.8), linePaint);
      canvas.drawLine(Offset(radius - s * 0.6, radius + s * 0.8), Offset(radius * 0.2, radius * 1.8), linePaint);
      canvas.drawLine(Offset(radius - s, radius - s * 0.2), Offset(0, radius * 0.3), linePaint);
    }
    else if (skinIndex == 10) { // Bowling
      final holePaint = Paint()..color = Colors.black54..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(radius * 0.7, radius * 0.6), radius * 0.15, holePaint);
      canvas.drawCircle(Offset(radius * 1.3, radius * 0.6), radius * 0.15, holePaint);
      canvas.drawCircle(Offset(radius, radius * 1.2), radius * 0.18, holePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
