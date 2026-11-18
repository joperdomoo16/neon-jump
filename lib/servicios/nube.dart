import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Nombres de los campos en Firestore. Se dejan tal cual porque así están los datos de los jugadores,
/// las reglas publicadas y las versiones de la app que ya están instaladas.
class CamposNube {
  static const coleccionRanking = 'leaderboard';
  static const coleccionSemanal = 'ranking_semanal';
  static const subcoleccionJugadores = 'jugadores';
  static const nombreJugador = 'playerName';
  static const nombreNormalizado = 'normalizedName';
  static const puntaje = 'score';
  static const monedas = 'coins';
  static const skins = 'ownedSkins';
  static const skinEquipada = 'currentSkinIndex';
  static const logros = 'unlockedAchievements';
  static const racha = 'racha';
  static const ultimoDia = 'ultimoDia';
  static const fecha = 'timestamp';
  static const vence = 'expiresAt';
  static const puntajeSemana = 'puntaje';
}

/// Ranking global y semanal, respaldo del progreso y cuenta de Google.
class ServicioNube {
  static final ServicioNube instancia = ServicioNube.interno();
  factory ServicioNube() => instancia;
  ServicioNube.interno();

  final FirebaseFirestore baseDatos = FirebaseFirestore.instance;
  final FirebaseAuth autenticacion = FirebaseAuth.instance;
  static const Duration espera = Duration(seconds: 10);
  static final RegExp nombrePermitido = RegExp(r'^[a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ _\.-]{3,20}$');
  static final RegExp tieneLetraONumero = RegExp(r'[a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ]');
  static final RegExp patronSemana = RegExp(r'^\d{4}-W\d{2}$');

  // Los jugadores no se borran por inactividad: la fecha de vencimiento queda muy lejos
  static final Timestamp vencimiento = Timestamp.fromDate(DateTime(2099, 12, 31));

  static bool esNombreSeguro(String nombre) {
    final limpio = nombre.trim();
    return nombrePermitido.hasMatch(limpio) && tieneLetraONumero.hasMatch(limpio);
  }

  String? get uid => autenticacion.currentUser?.uid;

  bool get googleVinculado =>
      autenticacion.currentUser?.providerData.any((proveedor) => proveedor.providerId == 'google.com') ?? false;

  /// Si no entró con Google, se le crea una sesión anónima para poder escribir en el ranking.
  Future<User?> asegurarSesion() async {
    final actual = autenticacion.currentUser;
    if (actual != null) return actual;
    try {
      final credencial = await autenticacion.signInAnonymously();
      return credencial.user;
    } catch (error) {
      debugPrint('No se pudo abrir la sesión anónima: $error');
      return null;
    }
  }

  /// Minúsculas y sin tildes, para que "Andrés" y "andres" cuenten como el mismo nombre.
  static String normalizarNombre(String nombre) {
    var resultado = nombre.trim().toLowerCase();
    const conTilde = 'áàäâãéèëêíìïîóòöôõúùüûñ';
    const sinTilde = 'aaaaaeeeeiiiiooooouuuun';
    for (var posicion = 0; posicion < conTilde.length; posicion++) {
      resultado = resultado.replaceAll(conTilde[posicion], sinTilde[posicion]);
    }
    return resultado.replaceAll(RegExp(r'\s+'), ' ');
  }

  Map<String, dynamic> armarRegistro(String nombre, ProgresoNube progreso) {
    return {
      CamposNube.nombreJugador: nombre.trim(),
      CamposNube.nombreNormalizado: normalizarNombre(nombre),
      CamposNube.fecha: FieldValue.serverTimestamp(),
      CamposNube.vence: vencimiento,
      CamposNube.monedas: progreso.monedas,
      CamposNube.skins: progreso.skins,
      CamposNube.skinEquipada: progreso.skinEquipada,
      CamposNube.logros: progreso.logros,
      CamposNube.racha: progreso.racha,
      if (progreso.ultimoDia.isNotEmpty) CamposNube.ultimoDia: progreso.ultimoDia,
    };
  }

  /// Sube el progreso. El puntaje nunca baja: si en la nube hay uno mayor, se deja ese.
  Future<void> enviarPuntaje(String nombre, ProgresoNube progreso) async {
    if (!esNombreSeguro(nombre)) return;
    final usuario = await asegurarSesion();
    if (usuario == null) return;

    final documento = baseDatos.collection(CamposNube.coleccionRanking).doc(usuario.uid);
    final actual = await documento.get().timeout(espera);
    final registro = armarRegistro(nombre, progreso);
    if (actual.exists) {
      final anterior = (actual.data()?[CamposNube.puntaje] as num?)?.toInt() ?? 0;
      registro[CamposNube.puntaje] = progreso.mejor > anterior ? progreso.mejor : anterior;
      await documento.update(registro).timeout(espera);
    } else {
      registro[CamposNube.puntaje] = progreso.mejor;
      await documento.set(registro).timeout(espera);
    }
  }

  /// Récord de la semana en ranking_semanal/{semana}/jugadores/{uid}.
  Future<void> enviarSemana(String nombre, String semana, int puntaje) async {
    if (!esNombreSeguro(nombre) || !patronSemana.hasMatch(semana)) return;
    final usuario = await asegurarSesion();
    if (usuario == null) return;
    final documento = baseDatos
        .collection(CamposNube.coleccionSemanal)
        .doc(semana)
        .collection(CamposNube.subcoleccionJugadores)
        .doc(usuario.uid);
    final actual = await documento.get().timeout(espera);
    final anterior = (actual.data()?[CamposNube.puntajeSemana] as num?)?.toInt() ?? 0;
    await documento.set({
      CamposNube.nombreJugador: nombre.trim(),
      CamposNube.puntajeSemana: puntaje > anterior ? puntaje : anterior,
      CamposNube.fecha: FieldValue.serverTimestamp(),
    }).timeout(espera);
  }

  /// Reemplaza lo de la nube por lo del celular. Como las reglas no dejan bajar el puntaje,
  /// toca borrar el registro y volverlo a crear.
  Future<bool> sobrescribirDatos(String nombre, ProgresoNube progreso) async {
    if (!esNombreSeguro(nombre)) return false;
    try {
      final usuario = await asegurarSesion();
      if (usuario == null) return false;
      final documento = baseDatos.collection(CamposNube.coleccionRanking).doc(usuario.uid);
      await documento.delete();
      final registro = armarRegistro(nombre, progreso);
      registro[CamposNube.puntaje] = progreso.mejor;
      await documento.set(registro);
      return true;
    } catch (error) {
      debugPrint('No se pudo reemplazar el progreso en la nube: $error');
      return false;
    }
  }

  /// true si el nombre está libre (o ya es de este jugador), false si lo tiene otro
  /// y null si no se pudo revisar (sin conexión).
  Future<bool?> nombreDisponible(String nombre) async {
    final limpio = nombre.trim();
    if (limpio.length < 3 || limpio.length > 20) return false;
    try {
      await asegurarSesion();
      final miUid = uid;
      const soloServidor = GetOptions(source: Source.server);
      final ranking = baseDatos.collection(CamposNube.coleccionRanking);
      var encontrados = (await ranking
              .where(CamposNube.nombreNormalizado, isEqualTo: normalizarNombre(limpio))
              .get(soloServidor)
              .timeout(espera))
          .docs;
      if (encontrados.isEmpty) {
        // Los registros más viejos no tenían el nombre normalizado
        encontrados = (await ranking
                .where(CamposNube.nombreJugador, isEqualTo: limpio)
                .get(soloServidor)
                .timeout(espera))
            .docs;
      }
      if (encontrados.isEmpty) return true;
      return encontrados.length == 1 && miUid != null && encontrados.first.id == miUid;
    } catch (error) {
      debugPrint('No se pudo revisar el nombre: $error');
      return null;
    }
  }

  /// Todos los jugadores con puntaje, sin incluir al actual (el juego lo agrega aparte).
  /// Por ahora son pocos y se muestran todos; si crece la base, se le pasa un límite.
  Future<List<Map<String, dynamic>>> rankingGlobal({int? limite}) async {
    Query<Map<String, dynamic>> consulta = baseDatos
        .collection(CamposNube.coleccionRanking)
        .where(CamposNube.puntaje, isGreaterThan: 0)
        .orderBy(CamposNube.puntaje, descending: true);
    if (limite != null) consulta = consulta.limit(limite + 1);
    final resultado = await consulta.get().timeout(espera);
    return filasRanking(resultado.docs, CamposNube.puntaje, limite);
  }

  Future<List<Map<String, dynamic>>> rankingSemana(String semana, {int? limite}) async {
    // La semana llega desde el juego: si no tiene la forma 2026-W46 no se arma ninguna ruta con ella
    if (!patronSemana.hasMatch(semana)) return [];
    Query<Map<String, dynamic>> consulta = baseDatos
        .collection(CamposNube.coleccionSemanal)
        .doc(semana)
        .collection(CamposNube.subcoleccionJugadores)
        .orderBy(CamposNube.puntajeSemana, descending: true);
    if (limite != null) consulta = consulta.limit(limite + 1);
    final resultado = await consulta.get().timeout(espera);
    return filasRanking(resultado.docs, CamposNube.puntajeSemana, limite);
  }

  // Formato de fila para el ranking en la vista web: {Nombre, Puntaje}
  List<Map<String, dynamic>> filasRanking(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> documentos, String campo, int? limite) {
    final miUid = uid;
    return documentos
        .where((documento) => documento.id != miUid)
        .map((documento) => <String, dynamic>{
              'Nombre': (documento.data()[CamposNube.nombreJugador] ?? '').toString(),
              'Puntaje': (documento.data()[campo] as num?)?.toInt() ?? 0,
            })
        .where((fila) => (fila['Puntaje'] as int) > 0)
        .take(limite ?? documentos.length)
        .toList();
  }

  Future<UserCredential?> iniciarConGoogle() async {
    try {
      final cuenta = await GoogleSignIn().signIn();
      if (cuenta == null) return null; // la persona canceló

      final datosCuenta = await cuenta.authentication;
      final credencial = GoogleAuthProvider.credential(
        accessToken: datosCuenta.accessToken,
        idToken: datosCuenta.idToken,
      );

      final actual = autenticacion.currentUser;
      if (actual != null && actual.isAnonymous) {
        try {
          // Se une la sesión anónima con Google: mismo uid, así no aparece dos veces en el ranking
          return await actual.linkWithCredential(credencial);
        } on FirebaseAuthException catch (error) {
          if (error.code == 'credential-already-in-use') {
            // Esa cuenta de Google ya tenía su registro: borro el anónimo para no duplicar
            try {
              await baseDatos.collection(CamposNube.coleccionRanking).doc(actual.uid).delete();
            } catch (fallo) {
              debugPrint('No se pudo borrar el registro anónimo: $fallo');
            }
          }
          return await autenticacion.signInWithCredential(credencial);
        }
      }
      return await autenticacion.signInWithCredential(credencial);
    } catch (error) {
      debugPrint('No se pudo entrar con Google: $error');
      return null;
    }
  }

  Future<void> cerrarSesion() async {
    await autenticacion.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (fallo) {
      debugPrint('Cierre de Google: $fallo');
    }
    await asegurarSesion();
  }

  Future<Map<String, dynamic>?> datosUsuario() async {
    final miUid = uid;
    if (miUid == null) return null;
    final documento = await baseDatos.collection(CamposNube.coleccionRanking).doc(miUid).get().timeout(espera);
    return documento.data();
  }
}

/// Lo que se sube a la nube del progreso de un jugador.
class ProgresoNube {
  ProgresoNube({
    required this.mejor,
    required this.monedas,
    required this.skins,
    required this.skinEquipada,
    required this.logros,
    required this.racha,
    required this.ultimoDia,
  });

  final int mejor;
  final int monedas;
  final List<int> skins;
  final int skinEquipada;
  final List<String> logros;
  final int racha;
  final String ultimoDia;

  /// Saca los datos del estado del juego (las claves son las de Aplicacion.js).
  /// Los valores se acotan a lo que aceptan las reglas de Firestore, así una subida nunca falla por un dato raro.
  factory ProgresoNube.desdeEstado(Map<String, dynamic> estado) {
    int entero(dynamic valor, int minimo, int maximo) => valor is num ? valor.toInt().clamp(minimo, maximo) : minimo;
    final skins = estado['Skins'] is List ? estado['Skins'] as List : [0];
    final logros = estado['Logros'] is List ? estado['Logros'] as List : [];
    final ultimoDia = estado['Ultimodia'];
    return ProgresoNube(
      mejor: entero(estado['Mejor'], 0, 500000),
      monedas: entero(estado['Monedas'], 0, 1000000),
      skins: skins.whereType<num>().map((skin) => skin.toInt().clamp(0, 50)).toSet().take(50).toList(),
      skinEquipada: entero(estado['Equipada'], 0, 50),
      logros: logros.whereType<String>().take(50).toList(),
      racha: entero(estado['Racha'], 1, 50000),
      ultimoDia: ultimoDia is String && ultimoDia.length <= 20 ? ultimoDia : '',
    );
  }
}
