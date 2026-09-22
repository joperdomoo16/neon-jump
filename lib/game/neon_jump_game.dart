import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'player.dart';
import 'platform_manager.dart';
import 'background.dart';
import '../services/game_state.dart';
import '../services/audio_manager.dart';
import '../services/ads_manager.dart';

class NeonJumpGame extends FlameGame with HasCollisionDetection, DragCallbacks, TapCallbacks {
  final GameState gameState;
  late Player player;
  late PlatformManager platformManager;
  late Background background;

  double cameraMaxY = 0;
  bool isPlaying = true;
  
  // Controls - tracks the current touch X position, null if not touching
  double? _touchX;
  // Tracks which half of the screen is being held (for tap-based fallback)
  double dragDirection = 0; // -1 for left, 1 for right, 0 for neutral
  
  bool waitingForInput = true;

  NeonJumpGame({required this.gameState});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Load images
    await images.loadAll([
      'skin_soccer.png',
      'skin_tennis.png',
      'skin_basketball.png',
      'skin_volleyball.png',
      'skin_bowling.png',
    ]);
    
    // Add background
    background = Background();
    add(background);
    
    // Add player
    player = Player();
    // Start player perfectly resting on the initial platform
    player.position = Vector2(size.x / 2, size.y - 75);
    world.add(player);
    
    // Add platform manager
    platformManager = PlatformManager(gameRef: this);
    world.add(platformManager);

    // Initial platform directly under player
    platformManager.spawnInitialPlatform(Vector2(size.x / 2, size.y - 50));
    
    // Set initial camera position to center of screen
    camera.viewfinder.position = Vector2(size.x / 2, size.y / 2);
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      images.clearCache();
    } else if (state == AppLifecycleState.resumed) {
      pauseEngine(); // Keep it paused while loading
      images.loadAll([
        'skin_soccer.png',
        'skin_tennis.png',
        'skin_basketball.png',
        'skin_volleyball.png',
        'skin_bowling.png',
      ]).then((_) {
        resumeEngine();
      });
    }
  }

  @override
  void update(double dt) {
    if (!isPlaying) return;
    super.update(dt);
    
    if (waitingForInput) {
      // Game physics (player movement/gravity) are skipped in Player.update 
      // but camera follow logic still runs here to keep things centered.
    } else {
      // Horizontal movement control based on touch target
      if (_targetX != null) {
        // Smoothly lerp the player to the target X position for a buttery smooth drag
        player.position.x += (_targetX! - player.position.x) * 15 * dt;
      } else {
        player.stopHorizontal(dt);
      }
    }

    // ---- CAMERA FOLLOW LOGIC ----
    // The camera viewfinder center must track the player.
    // "Up" in Flame = smaller Y. We want the player in the lower 35% of screen,
    // so camera center Y = player.y - offset (camera looks above the player).
    
    double targetCameraY = player.position.y - size.y * 0.25;
    
    // Only move camera up (never down) — classic Doodle Jump behavior
    if (targetCameraY < camera.viewfinder.position.y) {
      // Framerate-independent lerp: smooth tracking across 60Hz, 90Hz, 120Hz displays
      double lerpFactor = 1.0 - exp(-35.0 * dt);
      double newY = camera.viewfinder.position.y + (targetCameraY - camera.viewfinder.position.y) * lerpFactor;
      
      // Safety: if player is way above camera, snap immediately
      if (player.position.y < camera.viewfinder.position.y - size.y * 0.4) {
        newY = targetCameraY;
      }
      
      camera.viewfinder.position = Vector2(size.x / 2, newY);
    }

    // Update score based on max height reached
    // Higher up means smaller Y value (since Y points down)
    double currentHeight = (size.y - player.position.y);
    if (currentHeight > cameraMaxY) {
      cameraMaxY = currentHeight;
      gameState.updateScore((cameraMaxY / 10).floor());
    }

    // Game Over condition: player falls below the screen's bottom relative to camera
    double cameraBottomY = camera.viewfinder.position.y + (size.y / 2);
    if (player.position.y > cameraBottomY + player.size.y) {
      gameOver();
    }
  }

  void gameOver() {
    isPlaying = false;
    _touchX = null;
    dragDirection = 0;
    AudioManager().playGameOver();
    gameState.setGameOver(true);
    overlays.remove('Hud');
    overlays.add('GameOver');
    AdsManager().showInterstitialAdIfAppropriate();
  }

  // --- Drag-based input handling (continuous touch) ---
  
  double _touchOffset = 0;
  double? _targetX;

  @override
  void onDragStart(DragStartEvent event) {
    if (waitingForInput) {
      waitingForInput = false;
      overlays.remove('TapToStart');
      overlays.add('Hud');
      player.jump(1.0);
    }
    
    super.onDragStart(event);
    // Calculate the difference between current player position and the touch.
    // This allows relative dragging (ball moves exactly as much as the finger).
    _touchOffset = player.position.x - event.canvasPosition.x;
    _targetX = player.position.x;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    // DragUpdateEvent only has localDelta in this Flame version
    if (_targetX != null) {
      _targetX = _targetX! + event.localDelta.x;
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _targetX = null;
    player.velocity.x = 0; // stop immediately on release
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _targetX = null;
    player.velocity.x = 0;
  }

  // --- Tap-based input as fallback ---
  @override
  void onTapDown(TapDownEvent event) {
    if (waitingForInput) {
      waitingForInput = false;
      overlays.remove('TapToStart');
      overlays.add('Hud');
      player.jump(1.0);
    }
    
    super.onTapDown(event);
    _touchOffset = player.position.x - event.canvasPosition.x;
    _targetX = player.position.x;
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    _targetX = null;
    player.velocity.x = 0;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    super.onTapCancel(event);
    _targetX = null;
    player.velocity.x = 0;
  }
  
  // Revive logic
  void revive() {
    // Reset player position to slightly above the last visible highest platform
    player.position = Vector2(size.x / 2, camera.viewfinder.position.y - 100);
    player.velocity = Vector2.zero();
    // Spawn a solid platform right under
    platformManager.spawnInitialPlatform(Vector2(size.x / 2, player.position.y + 30));
    
    isPlaying = true;
    waitingForInput = true;
    _touchX = null;
    gameState.setGameOver(false);
    gameState.incrementRevives();
    
    overlays.remove('GameOver');
    // Don't add Hud yet, wait for input
    overlays.add('TapToStart');
  }
}
