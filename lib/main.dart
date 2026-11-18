import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'anfitrion/pantallaapp.dart';
import 'firebase_options.dart';
import 'servicios/nube.dart';
import 'servicios/progreso.dart';
import 'utilidades/constantes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // En la versión publicada no se escribe nada en la consola del celular
  if (kReleaseMode) debugPrint = (String? mensaje, {int? wrapWidth}) {};

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // App Check arranca por detrás para no demorar la apertura
  FirebaseAppCheck.instance
      .activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
      )
      .catchError((error) => debugPrint('App Check: $error'));

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // El progreso se lee antes de abrir el juego para que arranque con los datos reales
  await Progreso().cargar();
  ServicioNube().asegurarSesion();

  runApp(const NeonJumpApp());
}

class NeonJumpApp extends StatelessWidget {
  const NeonJumpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Jump',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Constantes.tinta),
      home: const PantallaApp(),
    );
  }
}
