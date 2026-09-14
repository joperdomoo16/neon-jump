import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

import 'neon_jump_game.dart';
import '../services/audio_manager.dart';

class Coin extends CircleComponent with HasGameRef<NeonJumpGame>, CollisionCallbacks {
  Coin({required Vector2 position}) : super(
    position: position,
    radius: 10,
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
    
    paint = Paint()
      ..color = Colors.amberAccent
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
  }

  void collect() {
    AudioManager().playCoin();
    gameRef.gameState.addCoins(1);
    removeFromParent();
  }
}
