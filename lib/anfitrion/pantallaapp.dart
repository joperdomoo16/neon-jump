import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../servicios/anuncios.dart';
import '../servicios/progreso.dart';
import '../utilidades/constantes.dart';
import 'puentenativo.dart';

/// La única pantalla de la app: el juego (assets/juego) corre en un WebView a pantalla completa.
/// Flutter solo pone encima lo que tiene que ser nativo: el banner de AdMob y los diálogos.
class PantallaApp extends StatefulWidget {
  const PantallaApp({super.key});

  @override
  State<PantallaApp> createState() => EstadoPantallaApp();
}

class EstadoPantallaApp extends State<PantallaApp> with WidgetsBindingObserver {
  // Medidas del escenario del juego (Base.css) y del hueco del banner en el menú (Pantallamenu.js)
  static const double anchoEscenario = 390, altoEscenario = 844;
  static const double bannerIzquierda = 35, bannerAbajo = 12, bannerAncho = 320, bannerAlto = 50;
  // Dirección desde donde Android sirve el juego empaquetado
  static const String carpetaJuego = 'file:///android_asset/flutter_assets/assets/juego/';

  late final WebViewController web;
  late final PuenteNativo puente;
  BannerAd? banner;
  bool bannerListo = false;
  String pantalla = 'Menu';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    web = WebViewController();
    puente = PuenteNativo(
      web: web,
      contexto: () => context,
      alCambiarPantalla: (nueva) {
        if (mounted && nueva != pantalla) setState(() => pantalla = nueva);
      },
    );
    Progreso().alCambiarNombre = puente.fijarNombre;

    web
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Constantes.tinta)
      ..addJavaScriptChannel('Canalnativo', onMessageReceived: puente.recibir)
      ..setNavigationDelegate(NavigationDelegate(
        // El WebView solo puede mostrar el juego empaquetado. Así ninguna otra página llega a tener
        // el canal con Flutter; los enlaces https se abren por fuera en el navegador.
        onNavigationRequest: (pedido) {
          final urlMinuscula = pedido.url.toLowerCase();
          if (urlMinuscula.contains('..') || urlMinuscula.contains('%2e')) {
            return NavigationDecision.prevent;
          }
          if (pedido.url == 'about:blank' || pedido.url.startsWith(carpetaJuego)) {
            return NavigationDecision.navigate;
          }
          final direccion = Uri.tryParse(pedido.url);
          if (direccion != null && direccion.scheme == 'https') PuenteNativo.abrirEnlace(pedido.url);
          return NavigationDecision.prevent;
        },
      ));

    final plataforma = web.platform;
    if (plataforma is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(kDebugMode);
      plataforma.setTextZoom(100); // que el tamaño de letra del sistema no desarme el diseño
      plataforma.setMediaPlaybackRequiresUserGesture(false);
      plataforma.setOverScrollMode(WebViewOverScrollMode.never);
    }
    web.loadFlutterAsset('assets/juego/index.html');

    Anuncios().reunirConsentimiento(alTerminar: () {
      if (mounted) cargarBanner();
    });
    cargarBanner();
    buscarActualizacion();
  }

  Future<void> cargarBanner() async {
    if (banner != null) return;
    try {
      if (!await ConsentInformation.instance.canRequestAds() || !mounted || banner != null) return;
      banner = BannerAd(
        adUnitId: Constantes.idBanner,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (cargado) {
            if (mounted) setState(() => bannerListo = true);
            puente.fijarBannerAdmob(true);
          },
          onAdFailedToLoad: (fallido, error) {
            debugPrint('Banner no disponible: ${error.message}');
            // Sin banner de AdMob el menú muestra el banner propio que hay en el hueco
            banner = null;
            puente.fijarBannerAdmob(false);
            if (mounted && bannerListo) setState(() => bannerListo = false);
            fallido.dispose();
            // Se vuelve a pedir en un minuto: cuando AdMob vuelva a tener anuncios, aparece solo
            Future.delayed(const Duration(minutes: 1), () {
              if (mounted) cargarBanner();
            });
          },
        ),
      );
      await banner!.load();
    } catch (error) {
      debugPrint('Banner no disponible: $error');
    }
  }

  // Si hay versión nueva en Play, se actualiza de una vez
  Future<void> buscarActualizacion() async {
    try {
      final informacion = await InAppUpdate.checkForUpdate();
      if (informacion.updateAvailability == UpdateAvailability.updateAvailable && informacion.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      } else if (informacion.updateAvailability == UpdateAvailability.developerTriggeredUpdateInProgress) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (error) {
      debugPrint('Actualización en tienda: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        puente.pausarJuego();
        Progreso().vaciar();
      case AppLifecycleState.resumed:
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        puente.alVolver();
      case AppLifecycleState.detached:
        Progreso().vaciar();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    banner?.dispose();
    super.dispose();
  }

  /// Pone el banner real centrado sobre el hueco "BANNER ADMOB · 320 × 50" del menú,
  /// con la misma escala que le aplica Base.css al escenario.
  Widget? bannerEncima(Size vista) {
    final anuncio = banner;
    if (!bannerListo || anuncio == null || pantalla != 'Menu') return null;
    final escala = min(min(vista.width / anchoEscenario, vista.height / altoEscenario), 1.6);
    final izquierda = (vista.width - anchoEscenario * escala) / 2;
    final arriba = (vista.height - altoEscenario * escala) / 2;
    final ancho = anuncio.size.width.toDouble(), alto = anuncio.size.height.toDouble();
    final centroX = izquierda + (bannerIzquierda + bannerAncho / 2) * escala;
    final centroY = arriba + (altoEscenario - bannerAbajo - bannerAlto / 2) * escala;
    return Positioned(
      left: centroX - ancho / 2,
      top: centroY - alto / 2,
      width: ancho,
      height: alto,
      child: AdWidget(ad: anuncio),
    );
  }

  @override
  Widget build(BuildContext context) {
    // El mismo fondo de Base.css: #16132E en celulares y #0E0C22 en pantallas anchas
    final fondo = MediaQuery.sizeOf(context).width > 500 ? const Color(0xFF0E0C22) : Constantes.tinta;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (yaSalio, resultado) async {
        if (yaSalio) return;
        if (!await puente.atras()) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: fondo,
        resizeToAvoidBottomInset: false,
        body: LayoutBuilder(builder: (contexto, caja) {
          final anuncio = bannerEncima(caja.biggest);
          return Stack(children: [
            Positioned.fill(child: WebViewWidget(controller: web)),
            if (anuncio != null) anuncio,
          ]);
        }),
      ),
    );
  }
}
