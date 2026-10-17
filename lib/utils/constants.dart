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
    // Original Thematic (6-10)
    Colors.orange, // 6: Basketball
    Colors.lightGreenAccent, // 7: Tennis
    Colors.white, // 8: Volleyball
    Colors.white, // 9: Soccer
    Color(0xFF78909C), // 10: Bowling
    // New Creative Skins (11-21)
    Color(0xFFB388FF), // 11: 8-Ball
    Color(0xFFFF5252), // 12: Baseball
    Colors.cyanAccent, // 13: Cyber Orb
    Colors.deepOrangeAccent, // 14: Magma
    Colors.lightBlueAccent, // 15: Earth
    Colors.pinkAccent, // 16: Donut
    Colors.amberAccent, // 17: Bomb
    Colors.amber, // 18: Disco
    Color(0xFF00E5FF), // 19: Cyber Eye
    Color(0xFF76FF03), // 20: Hazard
    Color(0xFFE040FB), // 21: Galaxy
  ];

  static const List<String> skinNames = [
    'CYAN', 'PINK', 'YELLOW', 'GREEN', 'ORANGE', 'PURPLE',
    'BASKETBALL', 'TENNIS', 'VOLLEYBALL', 'SOCCER', 'BOWLING',
    '8-BALL', 'BASEBALL', 'CYBER ORB', 'MAGMA', 'EARTH',
    'DONUT', 'BOMB', 'DISCO', 'CYBER EYE', 'HAZARD', 'GALAXY',
  ];

  static const List<int> skinCosts = [
    0, 50, 100, 250, 500, 1000, // Neon
    1500, 2000, 2500, 3000, 3500, // Sports
    4000, 4500, 5000, 6000, 7000, // Creative
    8000, 9000, 10000, 12000, 15000, 20000 // Legendary
  ];

  static const List<String> thematicSkinImages = [
    'skin_basketball.png',
    'skin_tennis.png',
    'skin_volleyball.png',
    'skin_soccer.png',
    'skin_bowling.png',
    'skin_eightball.png',
    'skin_baseball.png',
    'skin_cyber.png',
    'skin_magma.png',
    'skin_earth.png',
    'skin_donut.png',
    'skin_bomb.png',
    'skin_disco.png',
    'skin_eyeball.png',
    'skin_hazard.png',
    'skin_galaxy.png',
  ];

  static const Color backgroundTop = Color(0xFF0F0C29);
  static const Color backgroundBottom = Color(0xFF302B63);

  // AdMob Test IDs (and real ones)
  static const String bannerAdUnitId = 'ca-app-pub-1945212468802352/3476895282';
  static const String interstitialAdUnitId = 'ca-app-pub-1945212468802352/9645436557';
  static const String rewardedAdUnitId = 'ca-app-pub-1945212468802352/4497051651';

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
