# Neon Jump

A hyper-casual neon jumping game built with Flutter and the Flame engine.

## Features

* **Flame Engine:** Smooth 2D gameplay physics and rendering.
* **Neon Aesthetics:** Beautiful glowing graphics and visual effects.
* **Audio & Haptics:** Immersive sound effects and vibration feedback.
* **Firebase Integration:** Secure authentication (including Google Sign-In), cloud saves via Firestore, and App Check for security.
* **Monetization:** Integrated with Google Mobile Ads.

## Getting Started

### Prerequisites

* [Flutter SDK](https://flutter.dev/docs/get-started/install) (>=3.2.0 <4.0.0)
* Firebase project configuration (`google-services.json` for Android, `GoogleService-Info.plist` for iOS).

### Installation

1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Ensure your Firebase configuration files are placed in their respective platform directories.
4. Run the app using `flutter run`.

## Tech Stack

* **Framework:** [Flutter](https://flutter.dev/)
* **Game Engine:** [Flame](https://flame-engine.org/)
* **Backend:** Firebase (Auth, Firestore, App Check)
* **State Management:** Provider
