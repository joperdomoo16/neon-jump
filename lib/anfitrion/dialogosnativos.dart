import 'package:flutter/material.dart';

import '../utilidades/constantes.dart';

/// Avisos y diálogos nativos con los colores del juego, para que no se vean como de otra app.
class DialogosNativos {
  DialogosNativos(this.contexto);

  final BuildContext Function() contexto;

  void aviso(String texto) {
    final actual = contexto();
    if (!actual.mounted) return;
    ScaffoldMessenger.maybeOf(actual)?.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Constantes.tintaDos,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0x664FD8E8)),
      ),
      content: Text(texto, style: const TextStyle(color: Constantes.hueso, fontSize: 14)),
    ));
  }

  Future<bool> confirmar({
    required String titulo,
    required String texto,
    required String aceptar,
    String cancelar = 'CANCELAR',
  }) async {
    final actual = contexto();
    if (!actual.mounted) return false;
    final respuesta = await showDialog<bool>(
      context: actual,
      builder: (dialogo) => DialogoNeon(
        titulo: titulo,
        cuerpo: Text(texto, style: const TextStyle(color: Constantes.huesoDos, fontSize: 14, height: 1.4)),
        aceptar: aceptar,
        cancelar: cancelar,
      ),
    );
    return respuesta == true;
  }

  /// Cuando la cuenta de Google y el celular tienen progresos distintos, la persona elige con cuál quedarse.
  /// Devuelve true si escoge el de la nube.
  Future<bool> conflicto({required String resumenNube, required String resumenCelular}) async {
    final actual = contexto();
    if (!actual.mounted) return true;
    final respuesta = await showDialog<bool>(
      context: actual,
      barrierDismissible: false,
      builder: (dialogo) => DialogoNeon(
        titulo: 'Ya tienes progreso guardado',
        cuerpo: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Esta cuenta de Google ya tiene un progreso distinto al de este celular. ¿Con cuál te quedas?',
                style: TextStyle(color: Constantes.huesoDos, fontSize: 14, height: 1.4)),
            const SizedBox(height: 14),
            const Text('EN LA NUBE',
                style: TextStyle(color: Constantes.acento, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
            Text(resumenNube, style: const TextStyle(color: Constantes.hueso, fontSize: 14)),
            const SizedBox(height: 10),
            const Text('EN ESTE CELULAR',
                style: TextStyle(color: Constantes.huesoDos, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
            Text(resumenCelular, style: const TextStyle(color: Constantes.hueso, fontSize: 14)),
          ],
        ),
        aceptar: 'USAR LA NUBE',
        cancelar: 'USAR ESTE',
      ),
    );
    return respuesta != false;
  }
}

class DialogoNeon extends StatelessWidget {
  const DialogoNeon({
    super.key,
    required this.titulo,
    required this.cuerpo,
    required this.aceptar,
    required this.cancelar,
  });

  final String titulo;
  final Widget cuerpo;
  final String aceptar;
  final String cancelar;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Constantes.tintaDos,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0x1FF3F1FF)),
      ),
      title: Text(titulo.toUpperCase(),
          style: const TextStyle(color: Constantes.hueso, fontSize: 22, fontWeight: FontWeight.w900, height: 1)),
      content: cuerpo,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: Constantes.huesoDos),
          child: Text(cancelar, style: const TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Constantes.acento,
            foregroundColor: Constantes.tinta,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(aceptar, style: const TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
