# Neon Jump

Juego arcade de salto vertical para Android desarrollado con Flutter y un motor web 2D ejecutado dentro de `WebView`, integrado con servicios nativos de Firebase, AdMob, almacenamiento seguro y notificaciones locales.

## Arquitectura

- **`assets/juego/`**: Lógica de simulación (`Motor.js`), escenarios y cielo dinámico (`Fondo.js`, `Cielo.js`), audio por Web Audio API (`Audio.js`), vistas de UI y puente JS-Flutter (`Puente.js`).
- **`lib/anfitrion/`**: Contenedor nativo (`pantallaapp.dart`), despacho de mensajes por JavaScriptChannel (`puentenativo.dart`), flujo de vinculación con Google (`cuentagoogle.dart`) y diálogos nativos (`dialogosnativos.dart`).
- **`lib/servicios/`**: Persistencia cifrada con `FlutterSecureStorage` (`progreso.dart`), migración de versiones anteriores (`migracionprogreso.dart`), sincronización con Firestore y Firebase Auth (`nube.dart`), gestión de consentimiento UMP y anuncios AdMob (`anuncios.dart`), envío de soporte PQR (`soporte.dart`) y recordatorios locales (`notificaciones.dart`).
- **`lib/utilidades/constantes.dart`**: Identificadores de bloques AdMob, URLs públicas, tabla de migración de skins y paleta base.

## Requisitos y ejecución

```bash
flutter pub get
flutter run
flutter build appbundle --release
```

> Para compilar en modo release es necesario configurar `android/key.properties` y `android/app/google-services.json`.
