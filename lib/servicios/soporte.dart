import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../utilidades/constantes.dart';

/// Envía las solicitudes del formulario «¿Necesitas ayuda?» (PQR o Soporte)
/// hacia la aplicación web de Google Apps Script que escribe en Google Sheets.
class ServicioSoporte {
  static const Duration _tiempoEspera = Duration(seconds: 15);
  static const Set<String> _hostsPermitidos = {
    'script.google.com',
    'script.googleusercontent.com',
  };

  static bool _esDestinoSeguro(Uri uri) =>
      uri.scheme == 'https' && _hostsPermitidos.contains(uri.host.toLowerCase());

  static bool _esRedireccion(int codigo) =>
      codigo == HttpStatus.movedPermanently ||
      codigo == HttpStatus.found ||
      codigo == HttpStatus.seeOther ||
      codigo == HttpStatus.temporaryRedirect ||
      codigo == HttpStatus.permanentRedirect;

  Future<Map<String, dynamic>> enviar(Map<String, dynamic> datos) async {
    final cliente = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final destino = Uri.parse(Constantes.urlSoporte);
      final peticion = await cliente.postUrl(destino).timeout(_tiempoEspera);
      peticion.followRedirects = false;
      peticion.headers.contentType = ContentType.json;
      peticion.add(utf8.encode(jsonEncode(datos)));

      var respuesta = await peticion.close().timeout(_tiempoEspera);
      var uriActual = destino;
      var saltos = 0;

      // Apps Script ejecuta doPost en el POST y devuelve un 302 hacia script.googleusercontent.com
      // con el JSON de respuesta. En dart:io, isRedirect es false para POST+302, por eso revisamos el código.
      while (_esRedireccion(respuesta.statusCode) && saltos < 5) {
        final siguiente = respuesta.headers.value(HttpHeaders.locationHeader);
        await respuesta.drain<void>();
        if (siguiente == null || siguiente.isEmpty) {
          return {'ok': false, 'error': 'Respuesta incompleta del servidor.'};
        }
        uriActual = uriActual.resolve(siguiente);
        if (!_esDestinoSeguro(uriActual)) {
          return {'ok': false, 'error': 'No pudimos procesar tu solicitud en este momento.'};
        }
        final seguimiento = await cliente.getUrl(uriActual).timeout(_tiempoEspera);
        seguimiento.followRedirects = false;
        respuesta = await seguimiento.close().timeout(_tiempoEspera);
        saltos++;
      }

      final texto = await respuesta.transform(utf8.decoder).join().timeout(_tiempoEspera);
      if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
        return {'ok': false, 'error': 'No pudimos registrar tu solicitud en este momento. Intenta de nuevo.'};
      }

      final decoded = jsonDecode(texto);
      if (decoded is Map<String, dynamic> && decoded['ok'] == true) {
        return {'ok': true};
      }
      return {
        'ok': false,
        'error': 'No se pudo guardar la solicitud. Verifica los datos e intenta de nuevo.',
      };
    } on TimeoutException {
      return {'ok': false, 'error': 'Tardó demasiado. Revisa tu conexión e intenta de nuevo.'};
    } on SocketException {
      return {'ok': false, 'error': 'Sin conexión a internet. Revisa tu red e intenta de nuevo.'};
    } catch (error) {
      debugPrint('Soporte: error enviando solicitud: $error');
      return {'ok': false, 'error': 'No se pudo enviar la solicitud. Intenta de nuevo.'};
    } finally {
      cliente.close(force: true);
    }
  }
}
