import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utilidades/constantes.dart';

/// Consentimiento de Google (UMP), intersticial entre partidas y anuncio bonificado para revivir.
class Anuncios {
  static final Anuncios instancia = Anuncios.interno();
  factory Anuncios() => instancia;
  Anuncios.interno();

  InterstitialAd? intersticial;
  RewardedAd? bonificado;
  bool cargandoIntersticial = false;
  bool cargandoBonificado = false;
  bool sdkListo = false;
  int partidasTerminadas = 0;
  DateTime? ultimoIntersticial;

  /// Pide el consentimiento con el formulario oficial de Google cuando la ley del país lo exige
  /// (Europa, Reino Unido, Suiza y algunos estados de EE. UU.).
  Future<void> reunirConsentimiento({VoidCallback? alTerminar}) async {
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          ConsentForm.loadAndShowConsentFormIfRequired((errorFormulario) async {
            if (errorFormulario != null) {
              debugPrint('Consentimiento: el formulario falló (${errorFormulario.errorCode})');
            }
            if (await ConsentInformation.instance.canRequestAds()) iniciarSdk();
            alTerminar?.call();
          });
        },
        (FormError error) {
          debugPrint('Consentimiento: no se pudo actualizar (${error.errorCode})');
          alTerminar?.call();
        },
      );
      // Si ya había dado permiso en otra sesión, arranco de una vez
      if (await ConsentInformation.instance.canRequestAds()) iniciarSdk();
    } catch (error) {
      debugPrint('Consentimiento: $error');
      alTerminar?.call();
    }
  }

  Future<void> iniciarSdk() async {
    if (sdkListo) return;
    sdkListo = true;
    try {
      await MobileAds.instance.initialize();
      cargarIntersticial();
      cargarBonificado();
    } catch (error) {
      debugPrint('AdMob no arrancó: $error');
    }
  }

  /// Las personas de regiones reguladas tienen que poder cambiar su consentimiento cuando quieran.
  Future<bool> requiereOpcionesPrivacidad() async {
    try {
      final estado = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      return estado == PrivacyOptionsRequirementStatus.required;
    } catch (error) {
      debugPrint('Opciones de privacidad: $error');
      return false;
    }
  }

  void mostrarOpcionesPrivacidad() {
    try {
      ConsentForm.showPrivacyOptionsForm((errorFormulario) {
        if (errorFormulario != null) debugPrint('Opciones de privacidad: ${errorFormulario.message}');
      });
    } catch (error) {
      debugPrint('Opciones de privacidad: $error');
    }
  }

  void cargarIntersticial() {
    if (!sdkListo || cargandoIntersticial || intersticial != null) return;
    cargandoIntersticial = true;
    InterstitialAd.load(
      adUnitId: Constantes.idIntersticial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (anuncio) {
          cargandoIntersticial = false;
          intersticial = anuncio;
        },
        onAdFailedToLoad: (error) {
          cargandoIntersticial = false;
          intersticial = null;
          // Si no hay anuncio, se vuelve a intentar en 30 segundos
          Future.delayed(const Duration(seconds: 30), cargarIntersticial);
        },
      ),
    );
  }

  void cargarBonificado() {
    if (!sdkListo || cargandoBonificado || bonificado != null) return;
    cargandoBonificado = true;
    RewardedAd.load(
      adUnitId: Constantes.idBonificado,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (anuncio) {
          cargandoBonificado = false;
          bonificado = anuncio;
        },
        onAdFailedToLoad: (error) {
          cargandoBonificado = false;
          bonificado = null;
          Future.delayed(const Duration(seconds: 30), cargarBonificado);
        },
      ),
    );
  }

  /// Un intersticial cada dos partidas, y nunca dos seguidos en menos de un minuto.
  /// Da true cuando tocaba anuncio pero AdMob no tenía uno listo: entonces el juego pone uno propio.
  bool mostrarIntersticialSiToca() {
    partidasTerminadas++;
    if (partidasTerminadas < 2) return false;
    final ultimo = ultimoIntersticial;
    if (ultimo != null && DateTime.now().difference(ultimo).inSeconds < 60) return false;
    ultimoIntersticial = DateTime.now();
    partidasTerminadas = 0;
    final anuncio = intersticial;
    if (anuncio == null) {
      cargarIntersticial();
      return true;
    }
    intersticial = null; // así no se muestra dos veces
    anuncio.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (cerrado) {
        cerrado.dispose();
        cargarIntersticial();
      },
      onAdFailedToShowFullScreenContent: (fallido, error) {
        fallido.dispose();
        cargarIntersticial();
      },
    );
    anuncio.show();
    return false;
  }

  /// Muestra el anuncio para revivir. Da true solo si la persona se ganó la recompensa,
  /// y responde cuando el anuncio ya se cerró, para que el juego reviva después.
  /// Da null si AdMob no tenía anuncio que mostrar: entonces el juego pone uno propio.
  Future<bool?> mostrarBonificado() {
    final anuncio = bonificado;
    if (anuncio == null) {
      cargarBonificado();
      return Future.value(null);
    }
    bonificado = null;
    final respuesta = Completer<bool?>();
    var gano = false;

    anuncio.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (cerrado) {
        cerrado.dispose();
        cargarBonificado();
        if (!respuesta.isCompleted) respuesta.complete(gano);
      },
      onAdFailedToShowFullScreenContent: (fallido, error) {
        fallido.dispose();
        cargarBonificado();
        if (!respuesta.isCompleted) respuesta.complete(null);
      },
    );
    anuncio.show(onUserEarnedReward: (mostrado, recompensa) {
      gano = true;
    });
    return respuesta.future;
  }
}
