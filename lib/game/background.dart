import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'neon_jump_game.dart';
import '../utils/constants.dart';

class Background extends Component with HasGameRef<NeonJumpGame> {
  final Random random = Random();
  late List<Star> stars;
  int _currentPaletteIndex = 0;
  
  // Base background colors
  Color topColor = Constants.backgroundTop;
  Color bottomColor = Constants.backgroundBottom;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Generate some stars for parallax
    stars = List.generate(50, (index) {
      return Star(
        position: Vector2(random.nextDouble() * gameRef.size.x, random.nextDouble() * gameRef.size.y),
        size: random.nextDouble() * 3 + 1,
        parallaxFactor: random.nextDouble() * 0.5 + 0.1,
      );
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Determine palette based on score (change every 500 points)
    int score = gameRef.gameState.currentScore;
    int paletteIndex = (score ~/ 500) % Constants.neonColors.length;
    
    if (paletteIndex != _currentPaletteIndex) {
      _currentPaletteIndex = paletteIndex;
      _gradientPaint = null; // Invalidate cached shader if colors change
    }
  }

  Paint? _gradientPaint;
  Rect? _cachedRect;
  final Paint _starPaint = Paint()..color = Colors.white.withOpacity(0.5);

  @override
  void render(Canvas canvas) {
    if (_cachedRect == null || _cachedRect!.width != gameRef.size.x || _cachedRect!.height != gameRef.size.y || _gradientPaint == null) {
      _cachedRect = Rect.fromLTWH(0, 0, gameRef.size.x, gameRef.size.y);
      _gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, bottomColor],
        ).createShader(_cachedRect!);
    }
      
    canvas.drawRect(_cachedRect!, _gradientPaint!);

    // Draw stars with parallax wrap
    final cameraTopLeft = gameRef.camera.viewfinder.position - gameRef.size / 2;

    for (var star in stars) {
      // Parallax effect: stars move slower than the camera
      // Their apparent position wraps around the screen
      double relativeY = (star.position.y - cameraTopLeft.y * star.parallaxFactor) % gameRef.size.y;
      if (relativeY < 0) relativeY += gameRef.size.y;
      
      canvas.drawCircle(
        Offset(star.position.x, relativeY), 
        star.size, 
        _starPaint
      );
    }
  }
}

class Star {
  final Vector2 position;
  final double size;
  final double parallaxFactor;

  Star({required this.position, required this.size, required this.parallaxFactor});
}
