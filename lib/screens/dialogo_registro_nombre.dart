import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/game_state.dart';

/// Muestra la ventana emergente para registrar el nombre del jugador o recuperar su partida con Google.
void mostrarDialogoRegistroNombre(
  BuildContext context,
  GameState gameState, {
  void Function(LoginResult resultado)? onConflictoEncontrado,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) {
      String nombreIngresado = '';
      bool verificando = false;
      String? mensajeError;

      return StatefulBuilder(
        builder: (contextoEstado, setDialogState) {
          void verificarYGuardar() async {
            final nombreLimpio = nombreIngresado.trim();
            if (nombreLimpio.isEmpty) return;

            if (nombreLimpio.length < 3) {
              setDialogState(() {
                mensajeError = 'El nombre debe tener al menos 3 caracteres.';
              });
              return;
            }

            if (nombreLimpio.length > 20) {
              setDialogState(() {
                mensajeError = 'El nombre no puede superar los 20 caracteres.';
              });
              return;
            }

            if (!RegExp(r'[a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ]').hasMatch(nombreLimpio)) {
              setDialogState(() {
                mensajeError = 'El nombre debe contener al menos una letra o número.';
              });
              return;
            }

            setDialogState(() {
              verificando = true;
              mensajeError = null;
            });

            final disponible = await gameState.isNameAvailable(nombreLimpio);

            if (!dialogCtx.mounted) return;

            if (disponible) {
              gameState.setPlayerName(nombreLimpio);
              Navigator.of(dialogCtx).pop();
            } else {
              setDialogState(() {
                verificando = false;
                mensajeError = 'Ese nombre ya está en uso. ¡Elige otro!\nSi ya tenías cuenta, inicia sesión con Google.';
              });
            }
          }

          return AlertDialog(
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.cyanAccent, width: 2),
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text(
              'Bienvenido',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ingresa tu nombre para el Ranking Global:',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    maxLength: 20,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ _\.-]')),
                    ],
                    decoration: InputDecoration(
                      counterStyle: const TextStyle(color: Colors.white38),
                      hintText: 'Tu nombre (3-20 letras)',
                      hintStyle: const TextStyle(color: Colors.white30),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.cyanAccent),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.cyanAccent),
                      ),
                      errorText: mensajeError,
                      errorMaxLines: 2,
                    ),
                    onChanged: (val) {
                      nombreIngresado = val;
                      if (mensajeError != null) {
                        setDialogState(() {
                          mensajeError = null;
                        });
                      }
                    },
                    onSubmitted: (val) {
                      if (!verificando) verificarYGuardar();
                    },
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    '¿Ya habías jugado? Recupera tu progreso',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                    icon: const Icon(Icons.login, color: Colors.white),
                    label: const Text('GOOGLE LOGIN', style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      if (verificando) return;
                      setDialogState(() {
                        verificando = true;
                        mensajeError = null;
                      });
                      final messenger = ScaffoldMessenger.of(context);
                      final resultado = await gameState.loginWithGoogle();
                      if (!dialogCtx.mounted) return;

                      if (resultado.hasConflict) {
                        Navigator.of(dialogCtx).pop();
                        onConflictoEncontrado?.call(resultado);
                      } else if (resultado.success) {
                        if (gameState.playerName.isEmpty) {
                          setDialogState(() {
                            verificando = false;
                            mensajeError = 'Sesión iniciada con Google. Ahora elige un nombre para el ranking.';
                          });
                        } else {
                          Navigator.of(dialogCtx).pop();
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Progreso recuperado con éxito')),
                          );
                        }
                      } else {
                        setDialogState(() {
                          verificando = false;
                          mensajeError = 'Error al conectar con Google';
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              verificando
                  ? const CircularProgressIndicator(color: Colors.pinkAccent)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                      onPressed: verificarYGuardar,
                      child: const Text('GUARDAR', style: TextStyle(color: Colors.white)),
                    ),
            ],
          );
        },
      );
    },
  );
}

