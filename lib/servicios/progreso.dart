import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utilidades/constantes.dart';
import 'migracionprogreso.dart';
import 'nube.dart';

/// Progreso del jugador. Es el mismo objeto de estado que maneja Aplicacion.js: se guarda cifrado
/// en el celular y lo importante (récord, monedas, skins, logros, racha) se respalda en Firebase.
class Progreso {
  static final Progreso instancia = Progreso.interno();
  factory Progreso() => instancia;
  Progreso.interno();

  static const llaveEstado = 'Estadojugador';
  static const llaveNombre = 'Nombreverificado';
  static const llaveRanking = 'Rankingguardado';
  static final RegExp nombreAutomatico = RegExp(r'^Jugador_\d{5}$');
  static const int tamanoMaximo = 64000;

  final almacen = const FlutterSecureStorage();
  final nube = ServicioNube();

  /// Estado completo con las claves de Aplicacion.js (Nombre, Mejor, Monedas...).
  Map<String, dynamic>? estado;

  /// El último nombre que se comprobó que nadie más tiene en el ranking.
  String nombreVerificado = '';

  /// Copia del ranking para mostrarlo sin conexión.
  Map<String, dynamic>? rankingGuardado;

  /// Se llama cuando toca cambiar un nombre automático que ya estaba tomado.
  void Function(String nombre)? alCambiarNombre;

  Timer? relojGuardar;
  Timer? relojNube;
  String ultimaSubida = '';
  String ultimaSemana = '';
  bool subiendo = false;

  Future<void> cargar() async {
    try {
      final guardado = await almacen.read(key: llaveEstado);
      if (guardado != null) {
        estado = Map<String, dynamic>.from(jsonDecode(guardado) as Map);
        nombreVerificado = await almacen.read(key: llaveNombre) ?? '';
      } else {
        final migrado = await MigracionProgreso(almacen).migrar();
        if (migrado != null) {
          estado = migrado.estado;
          nombreVerificado = migrado.nombreVerificado;
        }
      }
      final ranking = await almacen.read(key: llaveRanking);
      if (ranking != null) rankingGuardado = Map<String, dynamic>.from(jsonDecode(ranking) as Map);
    } catch (error) {
      debugPrint('No se pudo leer el progreso: $error');
    }
    estado ??= {};
    // Sin nombre no sale en el ranking, así que se le pone uno mientras elige el suyo
    if ((estado!['Nombre'] ?? '').toString().trim().isEmpty) {
      estado!['Nombre'] = nombreAleatorio();
    }
    await escribir();
  }

  static String nombreAleatorio() => 'Jugador_${10000 + Random.secure().nextInt(90000)}';

  /// Validación en segunda capa (nativa) con listas blancas y rangos antes de guardar o subir.
  static Map<String, dynamic> sanearEstado(Map<String, dynamic> crudo) {
    int entero(dynamic valor, int min, int max, int defecto) {
      if (valor is num && valor.isFinite) return valor.toInt().clamp(min, max);
      final parsed = int.tryParse(valor?.toString() ?? '');
      return parsed != null ? parsed.clamp(min, max) : defecto;
    }

    String texto(dynamic valor, int maxLargo) {
      if (valor is! String) return '';
      final limpio = valor.trim();
      return limpio.length <= maxLargo ? limpio : limpio.substring(0, maxLargo);
    }

    final totalSkins = Constantes.preciosSkins.length;
    final skinsCrudas = crudo['Skins'] is List ? crudo['Skins'] as List : const [0];
    final skins = skinsCrudas
        .map((s) => entero(s, -1, totalSkins, -1))
        .where((s) => s >= 0 && s < totalSkins)
        .toSet()
        .toList();
    if (!skins.contains(0)) skins.insert(0, 0);
    final equipada = entero(crudo['Equipada'], 0, totalSkins - 1, 0);

    final logrosCrudos = crudo['Logros'] is List ? crudo['Logros'] as List : const [];
    final patronLogro = RegExp(r'^[a-z0-9_]{3,30}$');
    final logros = logrosCrudos
        .whereType<String>()
        .where((id) => patronLogro.hasMatch(id))
        .toSet()
        .take(50)
        .toList();

    final nombreCrudo = texto(crudo['Nombre'], 20);
    final nombreSeguro = (ServicioNube.esNombreSeguro(nombreCrudo) || nombreAutomatico.hasMatch(nombreCrudo))
        ? nombreCrudo
        : '';

    final ultimoDia = texto(crudo['Ultimodia'], 10);
    final semana = texto(crudo['Semana'], 10);

    final resultado = <String, dynamic>{
      'Nombre': nombreSeguro,
      'Mejor': entero(crudo['Mejor'], 0, 500000, 0),
      'Monedas': entero(crudo['Monedas'], 0, 1000000, 0),
      'Monedastotales': entero(crudo['Monedastotales'], 0, 100000000, 0),
      'Skins': skins,
      'Equipada': skins.contains(equipada) ? equipada : 0,
      'Partidas': entero(crudo['Partidas'], 0, 10000000, 0),
      'Caidas': entero(crudo['Caidas'], 0, 10000000, 0),
      'Revivestotales': entero(crudo['Revivestotales'], 0, 10000000, 0),
      'Revividasmax': entero(crudo['Revividasmax'], 0, 1000, 0),
      'Mejormonedaspartida': entero(crudo['Mejormonedaspartida'], 0, 100000, 0),
      'Resortetotal': entero(crudo['Resortetotal'], 0, 10000000, 0),
      'Movilmax': entero(crudo['Movilmax'], 0, 100000, 0),
      'Fragilmax': entero(crudo['Fragilmax'], 0, 100000, 0),
      'Segundosjugados': entero(crudo['Segundosjugados'], 0, 1000000000, 0),
      'Racha': entero(crudo['Racha'], 1, 50000, 1),
      'Logros': logros,
      'Sonido': crudo['Sonido'] != false && crudo['Sonido'] != 'false',
      'Musica': crudo['Musica'] != false && crudo['Musica'] != 'false',
      'Vibracion': crudo['Vibracion'] != false && crudo['Vibracion'] != 'false',
      'Sensibilidad': entero(crudo['Sensibilidad'], 0, 100, 70),
      'Tiendacat': const {'neon', 'deportes', 'creativas', 'legendarias'}.contains(crudo['Tiendacat'])
          ? crudo['Tiendacat']
          : 'neon',
      'Tiendasel': entero(crudo['Tiendasel'], 0, totalSkins - 1, 0),
      'Rankingtab': crudo['Rankingtab'] == 'semana' ? 'semana' : 'global',
      'Ultimodia': RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(ultimoDia) ? ultimoDia : '',
      'Semana': RegExp(r'^\d{4}-W\d{2}$').hasMatch(semana) ? semana : '',
      'Mejorsemana': entero(crudo['Mejorsemana'], 0, 500000, 0),
    };
    if (crudo['Reto'] is Map) {
      final reto = crudo['Reto'] as Map;
      final clave = texto(reto['Clave'], 12);
      final dia = texto(reto['Dia'], 10);
      if (const {'Movil', 'Fragil', 'Resorte'}.contains(clave) && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dia)) {
        resultado['Reto'] = {
          'Clave': clave,
          'Dia': dia,
          'Progreso': entero(reto['Progreso'], 0, 8, 0),
          'Hecho': reto['Hecho'] == true,
        };
      }
    }
    return resultado;
  }

  /// Llega desde el juego cada vez que cambia algo; se sanea en capa nativa, se escribe y se sube con un poco de espera.
  void guardar(Map<String, dynamic> nuevo) {
    // El estado del juego pesa unos 2 KB; algo muchísimo más grande no es del juego y no se guarda
    if (jsonEncode(nuevo).length > tamanoMaximo) {
      debugPrint('Se descartó un estado demasiado grande');
      return;
    }
    estado = sanearEstado(nuevo);
    relojGuardar?.cancel();
    relojGuardar = Timer(const Duration(milliseconds: 100), escribir);
    relojNube?.cancel();
    relojNube = Timer(const Duration(seconds: 3), subirNube);
  }

  /// Guarda ya lo que esté pendiente (la app se va a segundo plano o se cierra la sesión).
  Future<void> vaciar() async {
    if (relojGuardar?.isActive ?? false) {
      relojGuardar!.cancel();
      await escribir();
    }
    if (relojNube?.isActive ?? false) {
      relojNube!.cancel();
      await subirNube();
    }
  }

  Future<void> escribir() async {
    try {
      await almacen.write(key: llaveEstado, value: jsonEncode(estado ?? {}));
      await almacen.write(key: llaveNombre, value: nombreVerificado);
    } catch (error) {
      debugPrint('No se pudo guardar el progreso: $error');
    }
  }

  Future<void> guardarRanking(Map<String, dynamic> ranking) async {
    rankingGuardado = ranking;
    try {
      await almacen.write(key: llaveRanking, value: jsonEncode(ranking));
    } catch (error) {
      debugPrint('No se pudo guardar el ranking: $error');
    }
  }

  /// Sube el progreso y el récord de la semana. Solo sube si el nombre es válido y es suyo.
  Future<void> subirNube() async {
    final actual = estado;
    if (actual == null || subiendo) return;
    subiendo = true;
    try {
      final nombre = (actual['Nombre'] ?? '').toString().trim();
      if (!await asegurarNombre(nombre)) return;

      final progreso = ProgresoNube.desdeEstado(actual);
      // Si nada cambió desde la última vez, no hay para qué escribir otra vez
      final firma = jsonEncode([nombre, progreso.mejor, progreso.monedas, progreso.skins, progreso.skinEquipada,
        progreso.logros, progreso.racha, progreso.ultimoDia]);
      if (firma != ultimaSubida) {
        await nube.enviarPuntaje(nombre, progreso);
        ultimaSubida = firma;
      }

      final semana = (actual['Semana'] ?? '').toString();
      final mejorSemana = (actual['Mejorsemana'] as num?)?.toInt() ?? 0;
      final firmaSemana = '$nombre|$semana|$mejorSemana';
      if (mejorSemana > 0 && firmaSemana != ultimaSemana) {
        try {
          await nube.enviarSemana(nombre, semana, mejorSemana);
          ultimaSemana = firmaSemana;
        } catch (error) {
          debugPrint('Ranking semanal no disponible: $error');
        }
      }
    } catch (error) {
      debugPrint('La subida queda pendiente: $error');
    } finally {
      subiendo = false;
    }
  }

  /// Revisa que el nombre sea válido y que no lo tenga otro. Si un nombre automático ya estaba
  /// tomado, se cambia por otro sin molestar al jugador.
  Future<bool> asegurarNombre(String nombre) async {
    if (!ServicioNube.esNombreSeguro(nombre)) return false;
    if (nombre == nombreVerificado) return true;
    final libre = await nube.nombreDisponible(nombre);
    if (libre == true) {
      nombreVerificado = nombre;
      await escribir();
      return true;
    }
    if (libre == false && nombreAutomatico.hasMatch(nombre)) {
      final otro = nombreAleatorio();
      estado?['Nombre'] = otro;
      alCambiarNombre?.call(otro);
    }
    return false;
  }

  /// Mensaje para el campo del nombre en el perfil (null = se deja el texto normal del juego).
  Future<String?> validarNombre(String nombre) async {
    final limpio = nombre.trim();
    if (limpio.length < 3) return null;
    if (!ServicioNube.esNombreSeguro(limpio)) {
      return 'Usa solo letras, números, espacios y _ . -';
    }
    if (limpio == nombreVerificado) return null;
    final libre = await nube.nombreDisponible(limpio);
    if (libre == null) return 'Sin conexión. Lo revisamos cuando vuelvas a tener internet.';
    if (!libre) return 'Ese nombre ya lo tiene otro jugador. Prueba con otro.';
    nombreVerificado = limpio;
    await escribir();
    relojNube?.cancel();
    relojNube = Timer(const Duration(milliseconds: 300), subirNube);
    return null;
  }

  /// Pone sobre el estado del celular lo que había en la cuenta de Google.
  Map<String, dynamic> aplicarNube(Map<String, dynamic> local, Map<String, dynamic> datosNube) {
    final resultado = Map<String, dynamic>.from(local);
    // Lo de la nube se revisa campo por campo: un registro dañado no debe romper el juego
    int entero(dynamic valor, int maximo) => valor is num ? valor.toInt().clamp(0, maximo) : 0;
    final nombre = datosNube[CamposNube.nombreJugador];
    if (nombre is String && ServicioNube.esNombreSeguro(nombre)) {
      resultado['Nombre'] = nombre.trim();
      nombreVerificado = nombre.trim();
    }
    resultado['Mejor'] = entero(datosNube[CamposNube.puntaje], 500000);
    resultado['Monedas'] = entero(datosNube[CamposNube.monedas], 1000000);
    final totalSkins = Constantes.preciosSkins.length;
    final skins = ((datosNube[CamposNube.skins] as List?) ?? [0])
        .whereType<num>()
        .map((skin) => skin.toInt())
        .where((skin) => skin >= 0 && skin < totalSkins)
        .toSet()
        .toList();
    if (!skins.contains(0)) skins.insert(0, 0);
    resultado['Skins'] = skins;
    final equipada = entero(datosNube[CamposNube.skinEquipada], totalSkins - 1);
    resultado['Equipada'] = skins.contains(equipada) ? equipada : 0;
    resultado['Logros'] = ((datosNube[CamposNube.logros] as List?) ?? []).whereType<String>().take(50).toList();
    final totales = (local['Monedastotales'] as num?)?.toInt() ?? 0;
    resultado['Monedastotales'] = max(totales, resultado['Monedas'] as int);
    // La racha más larga gana, venga de donde venga
    final rachaNube = entero(datosNube[CamposNube.racha], 50000);
    if (rachaNube > 0) {
      final rachaLocal = (local['Racha'] as num?)?.toInt() ?? 1;
      resultado['Racha'] = max(rachaLocal, rachaNube);
    }
    final ultimoDia = datosNube[CamposNube.ultimoDia];
    if (ultimoDia is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(ultimoDia)) resultado['Ultimodia'] = ultimoDia;
    ultimaSubida = '';
    return resultado;
  }

  /// Al cerrar sesión el celular empieza de cero; el progreso sigue en la cuenta de Google.
  Future<String> reiniciar() async {
    relojGuardar?.cancel();
    relojNube?.cancel();
    final nombre = nombreAleatorio();
    estado = {'Nombre': nombre};
    nombreVerificado = '';
    ultimaSubida = '';
    ultimaSemana = '';
    await escribir();
    return nombre;
  }
}
