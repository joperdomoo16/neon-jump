import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import 'neon_jump_game.dart';
import 'platform.dart';
import 'coin.dart';
import '../utils/constants.dart';
import '../services/audio_manager.dart';

class Player extends CircleComponent with HasGameRef<NeonJumpGame>, CollisionCallbacks {
  Vector2 velocity = Vector2.zero();
  double _particleTimer = 0.0;
  
  Player() : super(radius: 15, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());

    // Fetch equipped skin color
    final color = Constants.neonColors[gameRef.gameState.currentSkinIndex];
    paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 10);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (gameRef.waitingForInput) return;
    
    // Apply gravity
    velocity.y += Constants.playerGravity * dt;
    
    // Update position
    position += velocity * dt;

    // Horizontal Screen Bounds (Stop at edges)
    if (position.x > gameRef.size.x - radius) {
      position.x = gameRef.size.x - radius;
      velocity.x = 0;
    } else if (position.x < radius) {
      position.x = radius;
      velocity.x = 0;
    }

    _particleTimer += dt;
    if (_particleTimer >= 0.05) {
      _particleTimer = 0.0;
      _spawnFlightParticles();
    }
  }

  void moveLeft(double dt) {
    velocity.x -= Constants.playerAcceleration * dt;
    if (velocity.x < -Constants.maxHorizontalVelocity) {
      velocity.x = -Constants.maxHorizontalVelocity;
    }
  }

  void moveRight(double dt) {
    velocity.x += Constants.playerAcceleration * dt;
    if (velocity.x > Constants.maxHorizontalVelocity) {
      velocity.x = Constants.maxHorizontalVelocity;
    }
  }

  void stopHorizontal(double dt) {
    if (velocity.x > 0) {
      velocity.x -= Constants.playerDeceleration * dt;
      if (velocity.x < 0) velocity.x = 0;
    } else if (velocity.x < 0) {
      velocity.x += Constants.playerDeceleration * dt;
      if (velocity.x > 0) velocity.x = 0;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    
    if (other is Platform && velocity.y > 0) { // Only collide when falling down
      // Check if player is above the platform
      if (position.y < other.position.y) { 
        jump(other.jumpVelocityMultiplier);
        other.onJumpedOn();
        gameRef.gameState.recordBounce(other.runtimeType.toString());
      }
    }
    
    if (other is Coin) {
      other.collect();
    }
  }

  void jump(double multiplier) {
    velocity.y = Constants.playerJumpVelocity * multiplier;
    
    // Play appropriate sound
    if (multiplier > 1.0) {
      AudioManager().playSpring();
    } else {
      AudioManager().playBounce();
    }

    _spawnBounceParticles();
  }

  void _spawnBounceParticles() {
    final random = Random();
    final color = Constants.neonColors[gameRef.gameState.currentSkinIndex];
    
    gameRef.world.add(
      ParticleSystemComponent(
        position: position.clone() + Vector2(0, radius), // Bottom of the ball
        particle: Particle.generate(
          count: 25,
          lifespan: 0.8,
          generator: (i) {
            return AcceleratedParticle(
              acceleration: Vector2(0, 150),
              speed: Vector2(
                (random.nextDouble() - 0.5) * 80, 
                -random.nextDouble() * 100 - 50
              ),
              child: ComputedParticle(
                renderer: (canvas, particle) {
                  // Light trail
                  final paint = Paint()
                    ..color = color.withOpacity(1 - particle.progress)
                    ..style = PaintingStyle.fill
                    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
                  canvas.drawCircle(Offset.zero, 4.0 * (1 - particle.progress), paint);
                  
                  // Frost sparkles (escarcha)
                  if (random.nextDouble() > 0.4) {
                    final sparklePaint = Paint()
                      ..color = Colors.white.withOpacity(1 - particle.progress)
                      ..style = PaintingStyle.fill;
                    // Draw a tiny star/sparkle
                    final sparklePath = Path();
                    double s = 2.0 * (1 - particle.progress);
                    sparklePath.moveTo(0, -s);
                    sparklePath.quadraticBezierTo(s/2, -s/2, s, 0);
                    sparklePath.quadraticBezierTo(s/2, s/2, 0, s);
                    sparklePath.quadraticBezierTo(-s/2, s/2, -s, 0);
                    sparklePath.quadraticBezierTo(-s/2, -s/2, 0, -s);
                    canvas.drawPath(sparklePath, sparklePaint);
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _spawnFlightParticles() {
    final random = Random();
    final color = Constants.neonColors[gameRef.gameState.currentSkinIndex];
    
    gameRef.world.add(
      ParticleSystemComponent(
        position: position.clone(), // Center of the ball
        particle: Particle.generate(
          count: 2, // Fewer particles for flight trail
          lifespan: 0.5,
          generator: (i) {
            return AcceleratedParticle(
              acceleration: Vector2(0, 50),
              speed: Vector2(
                (random.nextDouble() - 0.5) * 30, 
                (random.nextDouble() - 0.5) * 30 - velocity.y * 0.1 // Slight opposite direction to movement
              ),
              child: ComputedParticle(
                renderer: (canvas, particle) {
                  // Light trail
                  final paint = Paint()
                    ..color = color.withOpacity((1 - particle.progress) * 0.5)
                    ..style = PaintingStyle.fill
                    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
                  canvas.drawCircle(Offset.zero, 4.0 * (1 - particle.progress), paint);
                  
                  // Frost sparkles (escarcha)
                  if (random.nextDouble() > 0.5) {
                    final sparklePaint = Paint()
                      ..color = Colors.white.withOpacity((1 - particle.progress) * 0.8)
                      ..style = PaintingStyle.fill;
                    // Draw a tiny star/sparkle
                    final sparklePath = Path();
                    double s = 2.0 * (1 - particle.progress);
                    sparklePath.moveTo(0, -s);
                    sparklePath.quadraticBezierTo(s/2, -s/2, s, 0);
                    sparklePath.quadraticBezierTo(s/2, s/2, 0, s);
                    sparklePath.quadraticBezierTo(-s/2, s/2, -s, 0);
                    sparklePath.quadraticBezierTo(-s/2, -s/2, 0, -s);
                    canvas.drawPath(sparklePath, sparklePaint);
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
    
  @override
  void render(Canvas canvas) {
    int skinIndex = gameRef.gameState.currentSkinIndex;
    if (skinIndex < 6) {
      super.render(canvas); // Neon
    } else {
      _renderThematicSkin(canvas, skinIndex);
    }
  }

  void _renderThematicSkin(Canvas canvas, int skinIndex) {
    final center = Offset(radius, radius);
    final skinPaint = Paint()..style = PaintingStyle.fill;
    
    if (skinIndex >= 6 && skinIndex <= 10) {
      String imageName = '';
      if (skinIndex == 6) imageName = 'skin_basketball.png';
      else if (skinIndex == 7) imageName = 'skin_tennis.png';
      else if (skinIndex == 8) imageName = 'skin_volleyball.png';
      else if (skinIndex == 9) imageName = 'skin_soccer.png';
      else if (skinIndex == 10) imageName = 'skin_bowling.png';

      final sprite = Sprite(gameRef.images.fromCache(imageName));
      sprite.render(canvas, size: Vector2(radius * 2, radius * 2));
      return;
    }

    // Draw base color
    skinPaint.color = Constants.neonColors[skinIndex];
    canvas.drawCircle(center, radius, skinPaint);
  }
}
