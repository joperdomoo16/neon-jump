# 🕹️ Neon Jump

[![Flutter](https://img.shields.io/badge/Flutter-3.2.0+-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Flame Engine](https://img.shields.io/badge/Flame-1.18.0-E65100?logo=flame&logoColor=white)](https://flame-engine.org/)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20App%20Check-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com/)
[![AdMob](https://img.shields.io/badge/Google%20AdMob-Monetization-4285F4?logo=google-ads&logoColor=white)](https://admob.google.com/)
[![Versión](https://img.shields.io/badge/Versión-1.0.14%2B17-brightgreen.svg)]()

**Neon Jump** es un juego arcade hipercasual de saltos infinitos con una llamativa estética retro neón, físicas 2D dinámicas, efectos visuales de resplandor (glow), partículas y una experiencia inmersiva optimizada para dispositivos móviles.

---

## 🚀 Características Principales

### 🎮 Jugabilidad y Físicas (Flame Engine)
* **Generación Procedural Infinita:** Las plataformas se generan dinámicamente a medida que asciendes, incrementando progresivamente la dificultad y separación vertical.
* **Control Preciso y Fluido:** Control de arrastre táctil suave (*drag-lerp*) con velocidad horizontal optimizada y soporte de respuesta inmediata al toque.
* **Seguimiento de Cámara Inteligente:** Algoritmo *lerp* independiente del framerate (soporte completo para pantallas de 60Hz, 90Hz y 120Hz) que solo avanza hacia arriba.
* **Optimizador de Memoria:** Sistema de *Object Pooling* para reciclaje y reutilización de plataformas y monedas sin sobrecargar el recolector de basura (*GC*).
* **Fondo con Efecto Parallax:** Campo de estrellas con efecto de profundidad y gradientes que cambian de color de forma dinámica según la puntuación obtenida.

### 🧱 Tipos de Plataformas
* **Normales (Rosa Neón):** Plataformas base estables para rebotar.
* **Móviles (Amarillo Neón):** Plataformas con trayectoria horizontal oscilante (ondas sinusoidales).
* **Frágiles (Rojo Neón):** Se quiebran y desaparecen inmediatamente tras ser pisadas.
* **Con Resorte (Verde Neón):** Multiplican la fuerza de impulso (*x1.6*) para impulsarte a gran altura.

### 🛍️ Tienda y Personalización (Skins)
* **Skins Neón:** Cyan, Rosa, Amarillo, Verde, Naranja y Púrpura.
* **Skins Temáticas Deportivas:** Baloncesto, Tenis, Voleibol, Fútbol y Bolos (con texturas personalizadas).
* Desbloqueables mediante monedas (*Coins*) recolectadas durante las partidas y recompensas de logros.

### 🏆 Sistema de Logros y Recompensas
* Sistema completo de objetivos desbloqueables con notificación emergente en tiempo real:
  * **Primeros Pasos:** Alcanzar 5,000 puntos.
  * **Saltador Experto:** Alcanzar 10,000 puntos.
  * **Maestro del Neón:** Alcanzar 25,000 puntos.
  * **Inmortal:** Revivir 3 veces en una sola partida.
  * **Gato de 9 Vidas:** Revivir 5 veces en una sola partida.
  * **Víctima de la Gravedad:** Acumular 10 caídas en total.
  * **A la Moda:** Desbloquear una skin en la tienda.
* Cada logro otorga monedas de bonificación de forma automática.

### 🌐 Conectividad y Clasificación Global (Firebase)
* **Google Sign-In & Auth:** Inicio de sesión seguro con vinculación de perfil de Google para no perder progreso.
* **Respaldo en la Nube:** Sincronización automática de récord (*High Score*), monedas y skins en Cloud Firestore con detección y resolución interactiva de conflictos entre datos locales y remotos.
* **Ranking Global:** Tabla de líderes mundial en tiempo real (Top 50) con validación de nombres de usuario únicos.
* **Firebase App Check:** Protección de integridad en Android (Play Integrity) y iOS (Device Check).

### 🛡️ Seguridad y Anti-Trampas
* **Ofuscación de Memoria (`ObfuscatedInt`):** Protección contra editores de memoria en tiempo de ejecución (como Cheat Engine o GameGuardian) mediante máscaras XOR dinámicas que rotan en cada escritura.
* **Detección de Speedhacks:** Análisis de velocidad de ascenso vs. tiempo transcurrido para descartar puntuaciones imposibles.
* **Almacenamiento Cifrado:** Uso de `flutter_secure_storage` para proteger las partidas guardadas en el almacenamiento interno del dispositivo.

### 💰 Monetización Responsable (Google AdMob)
* **Banners:** En la pantalla principal y en la pantalla de *Game Over*.
* **Intersticiales:** Mostrados con intervalo inteligente y límite de frecuencia para no saturar la experiencia de usuario.
* **Anuncios Bonificados (Rewarded):** Opción de revivir una vez por partida viendo un anuncio (o pagando 100 monedas).
* **Cumplimiento Familiar:** Configurado para cumplir con las políticas para familias de Google Play (`TagForChildDirectedTreatment`, calificación de contenido `G`).

### 🔊 Audio y Sensaciones Hápticas
* Efectos sonoros integrados con `FlameAudio` (rebote, resorte, moneda recogida, nuevo récord y game over).
* Vibraciones hápticas graduadas (suaves e intensas) mediante `Vibration`.
* Interruptor de audio con persistencia de configuración.

---

## 📁 Estructura del Proyecto

```text
lib/
├── firebase_options.dart      # Configuración autogenerada de Firebase
├── main.dart                  # Punto de entrada, inicialización y tema
├── game/                      # Lógica principal del motor Flame
│   ├── background.dart        # Fondo parallax de estrellas y gradientes
│   ├── coin.dart              # Componente de moneda recolectable
│   ├── neon_jump_game.dart    # Clase principal del juego Flame (ciclo, cámara, entradas)
│   ├── platform.dart          # Clases de plataformas (Normal, Moving, Fragile, Spring)
│   ├── platform_manager.dart  # Generador infinito y pooling de plataformas
│   └── player.dart            # Componente del jugador (físicas, partículas, colisiones)
├── models/
│   └── achievement.dart       # Modelo de datos para logros
├── screens/                   # Pantallas e interfaces de usuario Flutter
│   ├── achievement_overlay.dart # Notificación emergente al desbloquear logros
│   ├── achievements_screen.dart # Pantalla de lista de logros
│   ├── game_over.dart         # Pantalla de fin de partida y revivir
│   ├── game_screen.dart       # Contenedor del GameWidget y superposiciones (overlays)
│   ├── hud.dart               # Interfaz en pantalla durante la partida (score, monedas)
│   ├── main_menu.dart         # Menú de inicio, perfil, Google Sign-In y navegación
│   ├── ranking_screen.dart    # Tabla de clasificación global (Firestore)
│   └── shop_screen.dart       # Tienda de skins y selección de personajes
├── services/                  # Capa de servicios y lógica de negocio
│   ├── ads_manager.dart       # Gestión de anuncios Google Mobile Ads
│   ├── audio_manager.dart     # Efectos de audio y respuesta háptica
│   ├── firebase_service.dart  # Operaciones de Firestore, Auth y Leaderboard
│   ├── game_state.dart        # Gestor de estado global (Provider) y progreso
│   └── storage_repository.dart# Almacenamiento local seguro
└── utils/
    ├── constants.dart         # Parámetros físicos, colores neón, IDs de AdMob
    └── obfuscated_int.dart    # Estructura de entero ofuscado anti-tampering
```

---

## 🛠️ Requisitos Previos

* **Flutter SDK:** `>=3.2.0 <4.0.0` ([Instrucciones de instalación](https://docs.flutter.dev/get-started/install))
* **Dart SDK:** Incluido con Flutter.
* **Android Studio / Xcode:** Con emuladores configurados o un dispositivo físico conectado.
* **Cuenta de Firebase:** Para configurar la autenticación, base de datos Firestore y App Check.

---

## ⚙️ Instalación y Puesta en Marcha

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/joperdomoo16/neon-jump.git
   cd neon-jump
   ```

2. **Instalar dependencias:**
   ```bash
   flutter pub get
   ```

3. **Configurar Firebase:**
   * Crea un proyecto en [Firebase Console](https://console.firebase.google.com/).
   * Coloca el archivo `google-services.json` en la ruta `android/app/`.
   * Coloca el archivo `GoogleService-Info.plist` en la ruta `ios/Runner/`.
   * Habilita los siguientes servicios en la consola de Firebase:
     * **Authentication:** Proveedor *Google* y proveedor *Anónimo*.
     * **Cloud Firestore:** Base de datos en modo producción o de prueba con reglas de seguridad adecuadas.
     * **App Check:** Proveedor *Play Integrity* (Android) y *Device Check* (iOS).

4. **Ejecutar la aplicación:**
   ```bash
   flutter run
   ```

---

## 📦 Dependencias Principales

| Paquete | Versión | Propósito |
| :--- | :--- | :--- |
| [`flame`](https://pub.dev/packages/flame) | `^1.18.0` | Motor de físicas y renderizado 2D para juegos |
| [`flame_audio`](https://pub.dev/packages/flame_audio) | `^2.1.8` | Reproducción de efectos de sonido |
| [`provider`](https://pub.dev/packages/provider) | `^6.1.2` | Gestión de estado reactivo de la aplicación |
| [`firebase_core`](https://pub.dev/packages/firebase_core) | `^4.11.0` | Núcleo de servicios Firebase |
| [`cloud_firestore`](https://pub.dev/packages/cloud_firestore) | `^6.6.0` | Base de datos NoSQL para Leaderboard y respaldo |
| [`firebase_auth`](https://pub.dev/packages/firebase_auth) | `^6.5.4` | Autenticación y vinculación de cuentas |
| [`google_sign_in`](https://pub.dev/packages/google_sign_in) | `^6.2.1` | Inicio de sesión con cuentas de Google |
| [`firebase_app_check`](https://pub.dev/packages/firebase_app_check) | `^0.4.8` | Verificación de integridad de la aplicación |
| [`google_mobile_ads`](https://pub.dev/packages/google_mobile_ads) | `^9.0.0` | Monetización con Banners, Intersticiales y Rewarded Ads |
| [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) | `^10.3.1` | Almacenamiento local seguro cifrado |
| [`vibration`](https://pub.dev/packages/vibration) | `^3.2.0` | Retroalimentación háptica |
| [`google_fonts`](https://pub.dev/packages/google_fonts) | `^6.2.1` | Tipografías personalizadas |

---

## 🔒 Privacidad y Retención de Datos

* El juego cuenta con una [Política de Privacidad](POLITICA_DE_PRIVACIDAD.md) accesible públicamente.
* Se incluye una página para solicitud de supresión de datos conforme a las normativas vigentes (`public/eliminar-cuenta.html`).
* Las cuentas inactivas por más de 30 días continuos son depuradas automáticamente de los registros del ranking global.
