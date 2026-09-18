import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import '../utils/constants.dart';
import 'neon_jump_game.dart';

abstract class Platform extends PositionComponent with CollisionCallbacks, HasGameRef<NeonJumpGame> {
  final double jumpVelocityMultiplier;
  
  Platform({
    required Vector2 position, 
    this.jumpVelocityMultiplier = 1.0,
  }) : super(
    position: position,
    size: Vector2(Constants.platformWidth, Constants.platformHeight),
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  void reset(Vector2 newPosition) {
    position.setFrom(newPosition);
  }

  void onJumpedOn() {} // Hook for subclasses (e.g. Fragile platform)
  
  Color getDynamicColor(Color baseColor) {
    if (!isMounted) return baseColor;
    try {
      int level = gameRef.gameState.currentScore ~/ 700;
      if (level == 0) return baseColor;
      
      HSLColor hsl = HSLColor.fromColor(baseColor);
      double newHue = (hsl.hue + (level * 60.0)) % 360.0;
      return hsl.withHue(newHue).toColor();
    } catch (e) {
      return baseColor;
    }
  }
}

class NormalPlatform extends Platform {
  NormalPlatform({required super.position});

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()
      ..color = getDynamicColor(Colors.pinkAccent)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 5);
    
    // Draw rounded rectangle for platform
    final rect = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(10));
    canvas.drawRRect(rect, paint);
  }
}

class MovingPlatform extends Platform {
  double _time = 0;
  final double speed;
  final double range;
  double initialX;

  MovingPlatform({required super.position, this.speed = 2.0, this.range = 100.0}) 
    : initialX = position.x;

  @override
  void reset(Vector2 newPosition) {
    super.reset(newPosition);
    initialX = newPosition.x;
    _time = 0;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()
      ..color = getDynamicColor(Colors.yellowAccent)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 5);
    
    final rect = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(10));
    canvas.drawRRect(rect, paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    // Simple math for sine wave centered at initialX:
    position.x = initialX + range * sin(_time * speed);
  }
}

class FragilePlatform extends Platform {
  bool _isBroken = false;

  FragilePlatform({required super.position});

  @override
  void reset(Vector2 newPosition) {
    super.reset(newPosition);
    _isBroken = false;
  }

  @override
  void render(Canvas canvas) {
    if (_isBroken) return;
    super.render(canvas);
    final paint = Paint()
      ..color = getDynamicColor(Colors.redAccent)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
    
    final rect = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(10));
    canvas.drawRRect(rect, paint);
  }

  @override
  void onJumpedOn() {
    _isBroken = true;
    removeFromParent();
    // TODO: Add breaking particles
  }
}

class SpringPlatform extends Platform {
  SpringPlatform({required super.position}) : super(jumpVelocityMultiplier: 1.6);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()
      ..color = getDynamicColor(Colors.greenAccent)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8);
    
    final rect = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(10));
    canvas.drawRRect(rect, paint);
    
    // Draw spring indicator (simple lines)
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    canvas.drawLine(Offset(size.x/2 - 10, size.y/2), Offset(size.x/2 + 10, size.y/2), linePaint);
    canvas.drawLine(Offset(size.x/2 - 10, size.y/2 - 5), Offset(size.x/2 + 10, size.y/2 - 5), linePaint);
  }
}
