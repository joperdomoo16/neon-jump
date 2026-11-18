import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../servicios/anuncios.dart';
import '../servicios/notificaciones.dart';
import '../servicios/nube.dart';
import '../servicios/progreso.dart';
import '../servicios/soporte.dart';
import '../utilidades/constantes.dart';
import 'cuentagoogle.dart';
import 'dialogosnativos.dart';

/// Recibe los mensajes de Puente.js por el canal "Canalnativo" y le contesta.
/// Cada mensaje trae {Id, Metodo, Datos}; si el Id es mayor que cero, el juego está esperando respuesta.
class PuenteNativo {
  PuenteNativo({
    required this.web,
    required BuildContext Function() contexto,
    required this.alCambiarPantalla,
  }) : dialogos = DialogosNativos(contexto);

  final WebViewController web;
  final void Function(String pantalla) alCambiarPantalla;
  final DialogosNativos dialogos;
  late final CuentaGoogle cuenta = CuentaGoogle(dialogos);

  final progreso = Progreso();
  final nube = ServicioNube();
  final soporte = ServicioSoporte();
  final anuncios = Anuncios();
  bool? hayVibrador;
  bool? tieneAmplitud;
  bool bannerAdmob = false;
  DateTime? _ultimoSoporte;

  static final RegExp _patronCorreo = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static const Set<String> _hostsEnlaces = {
    'neon-jump-stellar.web.app',
    'khronos-co.web.app',
    'play.google.com',
  };

  Future<void> recibir(JavaScriptMessage mensaje) async {
    Map<String, dynamic> contenido;
    try {
      contenido = Map<String, dynamic>.from(jsonDecode(mensaje.message) as Map);
    } catch (error) {
      return; // si no es un mensaje del juego, se ignora
    }
    final id = (contenido['Id'] as num?)?.toInt() ?? 0;
    dynamic respuesta;
    try {
      respuesta = await atender((contenido['Metodo'] ?? '').toString(), contenido['Datos']);
    } catch (error) {
      debugPrint('Puente: falló ${contenido['Metodo']}: $error');
    }
    if (id > 0) ejecutar('Neonjump.Puente.Responder($id, ${jsonEncode(respuesta)})');
  }

  Future<dynamic> atender(String metodo, dynamic datos) async {
    switch (metodo) {
      case 'listo':
        await iniciar();
      case 'guardar':
        if (datos is Map) {
          final estado = Map<String, dynamic>.from(datos);
          progreso.guardar(estado);
          // Notificaciones solo reprograma si cambió la racha o el día
          Notificaciones().programar(
            racha: (estado['Racha'] as num?)?.toInt() ?? 1,
            ultimoDia: (estado['Ultimodia'] ?? '').toString(),
          );
        }
      case 'pantalla':
        alCambiarPantalla(datos.toString());
      case 'vibrar':
        vibrar(datos.toString());
      case 'anuncioBonificado':
        return anuncioBonificado();
      case 'intersticial':
        return anuncios.mostrarIntersticialSiToca();
      case 'abrirAnuncio':
        // El juego solo manda la clave del anuncio propio; la dirección sale de la lista fija de Constantes
        if (datos is String) {
          final direccion = Constantes.anunciosPropios[datos];
          if (direccion != null) await abrirEnlace(direccion);
        }
      case 'ranking':
        return ranking(datos is Map ? (datos['Semana'] ?? '').toString() : '');
      case 'validarNombre':
        return progreso.validarNombre((datos ?? '').toString());
      case 'vincularGoogle':
        if (datos is Map) return cuenta.vincular(Map<String, dynamic>.from(datos));
      case 'desvincularGoogle':
        return cuenta.desvincular();
      case 'enviarSoporte':
        if (datos is Map) {
          final ahora = DateTime.now();
          if (_ultimoSoporte != null && ahora.difference(_ultimoSoporte!).inSeconds < 20) {
            return {'ok': false, 'error': 'Espera unos segundos antes de enviar otra solicitud.'};
          }
          String limpio(dynamic v, int max) {
            if (v is! String) return '';
            final s = v.trim();
            return s.length <= max ? s : s.substring(0, max);
          }
          final tipo = limpio(datos['Tipo'], 12);
          final nombre = limpio(datos['Nombre'], 60);
          final correo = limpio(datos['Correo'], 100);
          final asunto = limpio(datos['Asunto'], 80);
          final descripcion = limpio(datos['Descripcion'], 500);
          if ((tipo != 'PQR' && tipo != 'Soporte') ||
              nombre.length < 3 ||
              correo.length < 6 ||
              !_patronCorreo.hasMatch(correo) ||
              asunto.length < 5 ||
              descripcion.length < 15) {
            return {'ok': false, 'error': 'Revisa los campos obligatorios e intenta de nuevo.'};
          }
          _ultimoSoporte = ahora;
          final solicitud = <String, dynamic>{
            'Tipo': tipo,
            'Nombre': nombre,
            'Correo': correo,
            'Asunto': asunto,
            'Descripcion': descripcion,
            'Jugador': limpio(datos['Jugador'], 20),
            'Version': limpio(datos['Version'], 40),
          };
          final token = await nube.autenticacion.currentUser?.getIdToken();
          if (token != null) solicitud['Token'] = token;
          return soporte.enviar(solicitud);
        }
      case 'legal':
        await legal(datos.toString());
    }
    return null;
  }

  // ---------- De Flutter hacia el juego ----------

  Future<void> ejecutar(String codigo) async {
    try {
      await web.runJavaScript(codigo);
    } catch (error) {
      debugPrint('Puente: no se pudo ejecutar en el juego: $error');
    }
  }

  void pausarJuego() => ejecutar('window.Neonjump && Neonjump.Puente && Neonjump.Puente.Pausar()');
  void alVolver() => ejecutar('window.Neonjump && Neonjump.Puente && Neonjump.Puente.Alvolver()');
  void fijarNombre(String nombre) =>
      ejecutar('window.Neonjump && Neonjump.Puente && Neonjump.Puente.Fijarnombre(${jsonEncode(nombre)})');

  /// Con el banner de AdMob cargado el juego esconde el banner propio que queda debajo; sin él, lo vuelve a mostrar.
  void fijarBannerAdmob(bool listo) {
    bannerAdmob = listo;
    ejecutar('window.Neonjump && Neonjump.Puente && Neonjump.Puente.Banneradmob($listo)');
  }

  /// Botón atrás: true si el juego se encargó (pausar, volver al menú...).
  Future<bool> atras() async {
    try {
      final resultado = await web.runJavaScriptReturningResult(
          'window.Neonjump && Neonjump.Puente ? Neonjump.Puente.Atras() : false');
      return resultado == true || resultado.toString() == 'true';
    } catch (error) {
      return false;
    }
  }

  // ---------- Lo que el juego le pide a Flutter ----------

  Future<void> iniciar() async {
    var version = '';
    try {
      final informacion = await PackageInfo.fromPlatform();
      version = 'VERSIÓN ${informacion.version}';
    } catch (error) {
      debugPrint('No se pudo leer la versión: $error');
    }
    final copia = progreso.rankingGuardado;
    final datos = {
      'Estado': progreso.estado,
      'Google': nube.googleVinculado,
      'Version': version,
      'Ranking': copia == null ? null : {'Global': copia['Global']},
    };
    await ejecutar('Neonjump.Puente.Iniciar(${jsonEncode(datos)})');
    // Si AdMob cargó el banner antes de que el juego estuviera listo, se le avisa ahora
    if (bannerAdmob) fijarBannerAdmob(true);
  }

  Future<void> vibrar(String fuerza) async {
    try {
      hayVibrador ??= await Vibration.hasVibrator();
      if (hayVibrador != true) return;
      tieneAmplitud ??= await Vibration.hasAmplitudeControl();
      final int duracion;
      final int amplitud;
      switch (fuerza) {
        case 'fuerte':
          duracion = 280;
          amplitud = 255;
        case 'medio':
          duracion = 70;
          amplitud = 235;
        default:
          duracion = 35;
          amplitud = 185;
      }
      if (tieneAmplitud == true) {
        await Vibration.vibrate(duration: duracion, amplitude: amplitud);
      } else {
        await Vibration.vibrate(duration: duracion);
      }
    } catch (error) {
      debugPrint('Vibración no disponible: $error');
    }
  }

  /// true si se ganó la recompensa de AdMob. Si AdMob no tenía anuncio contesta 'propio':
  /// el juego pone uno de sus anuncios (Khronos o MiTecho) y revive al terminarlo.
  Future<Object> anuncioBonificado() async {
    final gano = await anuncios.mostrarBonificado();
    return gano ?? 'propio';
  }

  /// Ranking global y de la semana. Sin conexión devuelve la última copia guardada.
  Future<Map<String, dynamic>?> ranking(String semana) async {
    final copia = progreso.rankingGuardado;
    List<dynamic> semanaGuardada() =>
        copia != null && copia['Semanaid'] == semana ? (copia['Semana'] as List? ?? []) : [];
    try {
      var global = await nube.rankingGlobal();
      if (global.isEmpty && copia != null) global = List<Map<String, dynamic>>.from(copia['Global'] as List? ?? []);
      List<dynamic> deLaSemana;
      try {
        deLaSemana = await nube.rankingSemana(semana);
      } catch (error) {
        deLaSemana = semanaGuardada();
      }
      final resultado = {'Global': global, 'Semana': deLaSemana, 'Semanaid': semana};
      await progreso.guardarRanking(resultado);
      return resultado;
    } catch (error) {
      debugPrint('Ranking sin conexión: $error');
      if (copia == null) return null;
      return {'Global': copia['Global'], 'Semana': semanaGuardada()};
    }
  }

  Future<void> legal(String clave) async {
    if (clave == 'privacidad') {
      if (await anuncios.requiereOpcionesPrivacidad()) {
        anuncios.mostrarOpcionesPrivacidad();
      } else {
        dialogos.aviso('En tu región no hace falta ajustar el permiso de anuncios.');
      }
      return;
    }
    final direccion = switch (clave) {
      'condiciones' => Constantes.urlCondiciones,
      'eliminar' => Constantes.urlEliminarCuenta,
      _ => Constantes.urlPolitica,
    };
    await abrirEnlace(direccion);
  }

  static Future<void> abrirEnlace(String direccion) async {
    try {
      final uri = Uri.tryParse(direccion.trim());
      if (uri == null || uri.scheme != 'https' || !_hostsEnlaces.contains(uri.host.toLowerCase())) {
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      debugPrint('No se pudo abrir el enlace externo');
    }
  }
}
