import 'package:flutter/material.dart';

class Constants {
  // Palettes for the Neon Glow
  static const List<Color> neonColors = [
    Colors.cyanAccent,
    Colors.pinkAccent,
    Colors.yellowAccent,
    Colors.greenAccent,
    Colors.deepOrangeAccent,
    Colors.purpleAccent,
    Colors.orange, // 6: Basketball
    Colors.lightGreenAccent, // 7: Tennis
    Colors.white, // 8: Volleyball
    Colors.white, // 9: Soccer
    Colors.black87, // 10: Bowling
  ];

  static const List<String> skinNames = [
    'CYAN', 'PINK', 'YELLOW', 'GREEN', 'ORANGE', 'PURPLE',
    'BASKETBALL', 'TENNIS', 'VOLLEYBALL', 'SOCCER', 'BOWLING'
  ];

  static const List<int> skinCosts = [
    0, 50, 100, 250, 500, 1000, // Neon
    2000, 2500, 3000, 4000, 5000 // Thematic
  ];

  static const Color backgroundTop = Color(0xFF0F0C29);
  static const Color backgroundBottom = Color(0xFF302B63);

  // AdMob Test IDs (and real ones)
  static const String bannerAdUnitId = 'ca-app-pub-1945212468802352/1717282635';
  static const String interstitialAdUnitId = 'ca-app-pub-1945212468802352/4862320720';
  static const String rewardedAdUnitId = 'ca-app-pub-1945212468802352/7153442145';

  // Game Physics
  static const double playerGravity = 1200.0;
  static const double playerJumpVelocity = -800.0;
  static const double playerSpringVelocity = -1200.0;
  static const double playerHorizontalSpeed = 400.0;
  static const double playerAcceleration = 2000.0;
  static const double playerDeceleration = 1500.0;
  static const double maxHorizontalVelocity = 500.0;

  // Platform generation
  static const double initialPlatformGapY = 100.0;
  static const double maxPlatformGapY = 250.0;
  static const double platformWidth = 100.0;
  static const double platformHeight = 20.0;
}
