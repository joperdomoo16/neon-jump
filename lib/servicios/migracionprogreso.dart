import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utilidades/constantes.dart';

/// Migra el progreso guardado por versiones anteriores de la aplicación.
class MigracionProgreso {
  MigracionProgreso(this.almacen);

  final FlutterSecureStorage almacen;

  // Así se llamaban las llaves antes; hay que leerlas con ese nombre exacto
  static const llaveEstadoViejo = 'nj_estado';
  static const llaveNombreViejo = 'nj_nombre_verificado';
  static const llaveRankingViejo = 'nj_ranking';
  static const llavesFlame = [
    'highScore', 'coins', 'playerName', 'ownedSkins', 'currentSkinIndex',
    'totalDeaths', 'unlockedAchievements', 'isAudioEnabled',
  ];

  /// "monedasTotales" pasa a "Monedastotales", igual que en Aplicacion.js.
  static String capitalizar(String clave) {
    if (clave.isEmpty) return clave;
    return clave[0].toUpperCase() + clave.substring(1).toLowerCase();
  }

  static Map<String, dynamic> capitalizarMapa(Map mapa) {
    final resultado = <String, dynamic>{};
    mapa.forEach((clave, valor) {
      resultado[capitalizar(clave.toString())] = valor is Map ? capitalizarMapa(valor) : valor;
    });
    return resultado;
  }

  /// Devuelve el estado viejo ya convertido y el nombre verificado, o null si no había nada guardado.
  Future<({Map<String, dynamic> estado, String nombreVerificado})?> migrar() async {
    final estadoViejo = await almacen.read(key: llaveEstadoViejo);
    if (estadoViejo != null) {
      final estado = capitalizarMapa(jsonDecode(estadoViejo) as Map);
      // El reto guardaba el tipo de plataforma en minúscula y ahora se usa como clave
      final reto = estado['Reto'];
      if (reto is Map<String, dynamic> && reto['Clave'] is String) {
        reto['Clave'] = capitalizar(reto['Clave'] as String);
      }
      final nombre = await almacen.read(key: llaveNombreViejo) ?? '';
      await almacen.delete(key: llaveEstadoViejo);
      await almacen.delete(key: llaveNombreViejo);
      await almacen.delete(key: llaveRankingViejo);
      return (estado: estado, nombreVerificado: nombre);
    }
    return desdeVersionFlame();
  }

  Future<({Map<String, dynamic> estado, String nombreVerificado})?> desdeVersionFlame() async {
    final valores = <String, String?>{};
    for (final llave in llavesFlame) {
      valores[llave] = await almacen.read(key: llave);
    }
    if (valores.values.every((valor) => valor == null)) return null;

    int entero(String? texto) => int.tryParse(texto ?? '') ?? 0;
    final skins = (valores['ownedSkins'] ?? '0')
        .split(',')
        .map((texto) => int.tryParse(texto.trim()))
        .whereType<int>()
        .where((indice) => indice >= 0 && indice < Constantes.preciosSkins.length)
        .toSet()
        .toList();
    if (!skins.contains(0)) skins.insert(0, 0);
    var equipada = entero(valores['currentSkinIndex']);
    if (!skins.contains(equipada)) equipada = 0;
    final monedas = entero(valores['coins']);
    // Las monedas que se gastó en skins también cuentan para el total ganado
    final gastado = skins.fold<int>(0, (suma, indice) => suma + Constantes.preciosSkins[indice]);
    final caidas = entero(valores['totalDeaths']);
    final nombre = (valores['playerName'] ?? '').trim();

    final estado = <String, dynamic>{
      'Nombre': nombre,
      'Mejor': entero(valores['highScore']),
      'Monedas': monedas,
      'Monedastotales': monedas + gastado,
      'Skins': skins,
      'Equipada': equipada,
      'Partidas': caidas,
      'Caidas': caidas,
      'Logros': (valores['unlockedAchievements'] ?? '').split(',').where((logro) => logro.isNotEmpty).toList(),
      'Sonido': valores['isAudioEnabled'] != 'false',
    };
    for (final llave in llavesFlame) {
      await almacen.delete(key: llave);
    }
    return (estado: estado, nombreVerificado: nombre);
  }
}
