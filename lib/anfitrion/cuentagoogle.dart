import 'package:flutter/foundation.dart';

import '../servicios/nube.dart';
import '../servicios/progreso.dart';
import '../servicios/soporte.dart';
import 'dialogosnativos.dart';

/// Vincular y desvincular la cuenta de Google desde el perfil del juego.
/// Las respuestas van al puente con las claves que espera Puente.js (Estado, Google, Reiniciar, Nombre).
class CuentaGoogle {
  CuentaGoogle(this.dialogos);

  final DialogosNativos dialogos;
  final progreso = Progreso();
  final nube = ServicioNube();

  // Lo que llega de la nube puede venir con tipos raros; lo que no sea del tipo esperado se ignora
  static List<int> listaSkins(dynamic lista) =>
      (lista is List ? lista : [0]).whereType<num>().map((skin) => skin.toInt()).toList();
  static List<String> listaLogros(dynamic lista) => (lista is List ? lista : []).whereType<String>().toList();
  static int numero(dynamic valor) => valor is num ? valor.toInt() : 0;

  static bool mismoConjunto<T>(List<T> primera, List<T> segunda) {
    final uno = primera.toSet(), dos = segunda.toSet();
    return uno.length == dos.length && uno.containsAll(dos);
  }

  static String resumen(dynamic mejor, dynamic monedas, dynamic skins) =>
      'Récord ${mejor ?? 0} · ${monedas ?? 0} monedas · ${(skins as List?)?.length ?? 1} skins';

  /// Vincula la cuenta y, si quedó vinculada con Google, pide el correo de bienvenida.
  Future<Map<String, dynamic>> vincular(Map<String, dynamic> local) async {
    final resultado = await vincularCuenta(local);
    if (resultado['Google'] == true) {
      final estado = resultado['Estado'];
      final nombre = (estado is Map ? estado['Nombre'] : local['Nombre']) ?? '';
      enviarBienvenida(nombre.toString()); // sin await: el correo no frena el juego
    }
    return resultado;
  }

  // El script revisa el token y no repite el correo, así que no importa si se llama más de una vez
  Future<void> enviarBienvenida(String nombre) async {
    try {
      final token = await nube.autenticacion.currentUser?.getIdToken();
      if (token == null) return;
      await ServicioSoporte().enviar({'Tipo': 'Bienvenida', 'Token': token, 'Nombre': nombre});
    } catch (error) {
      debugPrint('Correo de bienvenida pendiente: $error');
    }
  }

  Future<Map<String, dynamic>> vincularCuenta(Map<String, dynamic> local) async {
    final credencial = await nube.iniciarConGoogle();
    if (credencial == null) {
      dialogos.aviso('No se pudo vincular la cuenta de Google.');
      return {'Google': nube.googleVinculado, 'Cancelado': true};
    }
    Map<String, dynamic>? enNube;
    try {
      enNube = await nube.datosUsuario();
    } catch (error) {
      enNube = null;
    }

    final hayNube = enNube != null &&
        ((enNube[CamposNube.nombreJugador] ?? '').toString().isNotEmpty ||
            numero(enNube[CamposNube.puntaje]) > 0 ||
            numero(enNube[CamposNube.monedas]) > 0 ||
            listaSkins(enNube[CamposNube.skins]).length > 1 ||
            listaLogros(enNube[CamposNube.logros]).isNotEmpty);

    // La cuenta de Google no tenía perfil guardado aún: exige nombre válido antes de crear respaldo
    if (!hayNube) {
      final nombre = (local['Nombre'] ?? '').toString().trim();
      final esAutomatico = RegExp(r'^Jugador_\d{5}$').hasMatch(nombre);
      if (nombre.isEmpty || esAutomatico || !ServicioNube.esNombreSeguro(nombre)) {
        await nube.cerrarSesion();
        return {'Google': false, 'Sinperfil': true};
      }
      progreso.guardar(local);
      await progreso.subirNube();
      dialogos.aviso('Cuenta vinculada. Tu progreso queda respaldado en la nube.');
      return {'Google': true};
    }

    final hayLocal = numero(local['Mejor']) > 0 ||
        numero(local['Monedas']) > 0 ||
        listaSkins(local['Skins']).length > 1 ||
        listaLogros(local['Logros']).isNotEmpty;
    final distinto = numero(local['Mejor']) != numero(enNube[CamposNube.puntaje]) ||
        numero(local['Monedas']) != numero(enNube[CamposNube.monedas]) ||
        !mismoConjunto(listaSkins(local['Skins']), listaSkins(enNube[CamposNube.skins])) ||
        !mismoConjunto(listaLogros(local['Logros']), listaLogros(enNube[CamposNube.logros]));

    var usarNube = true;
    if (hayLocal && distinto) {
      usarNube = await dialogos.conflicto(
        resumenNube: resumen(enNube[CamposNube.puntaje], enNube[CamposNube.monedas], enNube[CamposNube.skins]),
        resumenCelular: resumen(local['Mejor'], local['Monedas'], local['Skins']),
      );
    }

    if (usarNube) {
      final nuevo = progreso.aplicarNube(local, enNube);
      progreso.guardar(nuevo);
      dialogos.aviso('Progreso recuperado de tu cuenta de Google.');
      return {'Estado': nuevo, 'Google': true};
    }

    final subio = await nube.sobrescribirDatos((local['Nombre'] ?? '').toString(), ProgresoNube.desdeEstado(local));
    dialogos.aviso(subio
        ? 'Cuenta vinculada con el progreso de este celular.'
        : 'Cuenta vinculada, pero no se pudo subir el progreso.');
    return {'Google': true};
  }

  Future<Map<String, dynamic>> desvincular() async {
    final acepta = await dialogos.confirmar(
      titulo: 'Desvincular cuenta',
      texto: 'Se cerrará la sesión de Google y este celular empezará de cero. '
          'Tu progreso sigue guardado en tu cuenta: lo recuperas cuando la vuelvas a vincular.',
      aceptar: 'DESVINCULAR',
    );
    if (!acepta) return {'Google': true};
    await progreso.vaciar();
    await nube.cerrarSesion();
    final nombre = await progreso.reiniciar();
    dialogos.aviso('Sesión cerrada.');
    return {'Reiniciar': true, 'Nombre': nombre};
  }
}
