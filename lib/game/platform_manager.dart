import 'package:flame/components.dart';
import 'dart:math';

import 'neon_jump_game.dart';
import 'platform.dart';
import 'coin.dart';
import '../utils/constants.dart';

class PlatformManager extends Component {
  final NeonJumpGame gameRef;
  final List<Platform> activePlatforms = [];
  final Random random = Random();

  double highestPlatformY = 0;
  
  PlatformManager({required this.gameRef});

  final Map<Type, List<Platform>> _pools = {
    NormalPlatform: [],
    MovingPlatform: [],
    FragilePlatform: [],
    SpringPlatform: [],
  };

  void spawnInitialPlatform(Vector2 position) {
    // Clear existing to pools
    for (var p in activePlatforms) {
      if (p.parent != null) p.removeFromParent();
      _pools[p.runtimeType]?.add(p);
    }
    activePlatforms.clear();

    highestPlatformY = position.y;
    final platform = _getPlatform(NormalPlatform, position);
    gameRef.world.add(platform);
    activePlatforms.add(platform);
    
    // Generate initial batch
    _generatePlatforms();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Check if we need more platforms
    // If the highest platform is lower (larger Y) than the camera top view, we need to generate more
    double cameraTopY = gameRef.camera.viewfinder.position.y - (gameRef.size.y / 2);
    if (highestPlatformY > cameraTopY - gameRef.size.y) {
      _generatePlatforms();
    }

    // Clean up platforms that are too far below
    double cameraBottomY = gameRef.camera.viewfinder.position.y + (gameRef.size.y / 2);
    activePlatforms.removeWhere((platform) {
      if (platform.position.y > cameraBottomY + 100) {
        if (platform.parent != null) platform.removeFromParent();
        _pools[platform.runtimeType]?.add(platform);
        return true;
      }
      // Also remove fragile platforms that are broken
      if (platform is FragilePlatform && platform.parent == null) {
        _pools[FragilePlatform]?.add(platform);
        return true;
      }
      return false;
    });
  }

  Platform _getPlatform(Type type, Vector2 position) {
    final pool = _pools[type];
    if (pool != null && pool.isNotEmpty) {
      final p = pool.removeLast();
      p.reset(position);
      return p;
    }
    
    // Instantiate if pool is empty
    switch (type) {
      case MovingPlatform:
        return MovingPlatform(position: position, range: gameRef.size.x * 0.4);
      case FragilePlatform:
        return FragilePlatform(position: position);
      case SpringPlatform:
        return SpringPlatform(position: position);
      case NormalPlatform:
      default:
        return NormalPlatform(position: position);
    }
  }

  void _generatePlatforms() {
    int score = gameRef.gameState.currentScore;
    
    // Difficulty logic based on score
    double currentGap = Constants.initialPlatformGapY + (score / 1000) * 50;
    if (currentGap > Constants.maxPlatformGapY) {
      currentGap = Constants.maxPlatformGapY;
    }

    double movingProb = min(0.1 + (score / 5000), 0.5);
    double fragileProb = min(0.05 + (score / 10000), 0.3);
    double springProb = 0.05;

    for (int i = 0; i < 10; i++) {
      highestPlatformY -= currentGap;
      
      // Random X position ensuring it's reachable horizontally
      double x = random.nextDouble() * (gameRef.size.x - Constants.platformWidth) + (Constants.platformWidth / 2);
      Vector2 pos = Vector2(x, highestPlatformY);
      
      Type platformType;
      double r = random.nextDouble();
      if (r < fragileProb) {
        platformType = FragilePlatform;
      } else if (r < fragileProb + movingProb) {
        platformType = MovingPlatform;
      } else if (r < fragileProb + movingProb + springProb) {
        platformType = SpringPlatform;
      } else {
        platformType = NormalPlatform;
      }
      
      Platform newPlatform = _getPlatform(platformType, pos);
      
      gameRef.world.add(newPlatform);
      activePlatforms.add(newPlatform);

      // 10% chance to spawn a coin above the platform
      if (random.nextDouble() < 0.1 && platformType != FragilePlatform) {
        final coin = Coin(position: Vector2(pos.x, pos.y - 40));
        gameRef.world.add(coin);
      }
    }
  }
}
