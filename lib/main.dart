import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'services/game_state.dart';
import 'services/ads_manager.dart';
import 'services/audio_manager.dart';
import 'screens/main_menu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
  );
  
  // Set preferred orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Hide system overlays for full screen experience
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final gameState = GameState();
  await gameState.init();

  if (!kIsWeb) {
    await AdsManager().init();
  }
  await AudioManager().init();

  runApp(
    ChangeNotifierProvider.value(
      value: gameState,
      child: const NeonJumpApp(),
    ),
  );
}

class NeonJumpApp extends StatelessWidget {
  const NeonJumpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Jump',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        // Will apply neon specific fonts in the widgets directly
      ),
      home: const MainMenuScreen(),
    );
  }
}
