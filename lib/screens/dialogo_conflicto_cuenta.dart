import 'package:flutter/material.dart';
import '../services/game_state.dart';

/// Muestra el diálogo cuando la cuenta de Google vinculada ya contiene datos en la nube.
/// Permite al usuario elegir entre retomar la partida previa o reemplazarla con los datos locales.
void mostrarDialogoConflictoCuenta(
  BuildContext context,
  GameState gameState,
  LoginResult resultado,
) {
  final nombreNube = resultado.cloudName ?? '';
  final puntajeNube = resultado.cloudScore ?? 0;
  final monedasNube = resultado.cloudCoins ?? 0;
  final skinsNube = resultado.cloudOwnedSkins ?? [0];
  final skinActualNube = resultado.cloudCurrentSkinIndex ?? 0;
  final logrosNube = resultado.cloudAchievements ?? [];
  final cantidadLogrosLocales = gameState.achievements.where((a) => a.isUnlocked).length;
  final messenger = ScaffoldMessenger.of(context);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.cyanAccent, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Row(
          children: [
            Icon(Icons.person_search, color: Colors.cyanAccent),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '¡Usuario encontrado!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Esta cuenta de Google ya tiene datos guardados:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              construirTarjetaPartida(
                etiqueta: 'CUENTA DE GOOGLE',
                color: Colors.cyanAccent,
                nombre: nombreNube,
                puntaje: puntajeNube,
                monedas: monedasNube,
                cantidadSkins: skinsNube.length,
                cantidadLogros: logrosNube.length,
              ),
              const SizedBox(height: 10),
              construirTarjetaPartida(
                etiqueta: 'PARTIDA ACTUAL',
                color: Colors.pinkAccent,
                nombre: gameState.playerName,
                puntaje: gameState.highScore,
                monedas: gameState.coins,
                cantidadSkins: gameState.ownedSkins.length,
                cantidadLogros: cantidadLogrosLocales,
              ),
              const SizedBox(height: 14),
              const Text(
                '¿Deseas retomar los datos que ya tenías o reemplazarlos por los de la partida actual?',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await gameState.resolveLoginConflict(
                true,
                nombreNube,
                puntajeNube,
                monedasNube,
                cloudOwnedSkins: skinsNube,
                cloudCurrentSkinIndex: skinActualNube,
                cloudAchievements: logrosNube,
              );
              messenger.showSnackBar(
                SnackBar(content: Text('¡Bienvenido de vuelta, $nombreNube! Datos recuperados')),
              );
            },
            child: const Text(
              'RETOMAR',
              style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: dialogContext,
                builder: (c) => AlertDialog(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.redAccent, width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  title: const Text(
                    '¿Reemplazar datos?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    'Se borrarán definitivamente los datos de "$nombreNube" ($puntajeNube pts, $monedasNube monedas, ${skinsNube.length} skins, ${logrosNube.length} logros) y se guardará la partida actual en tu cuenta de Google.',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(c).pop(false),
                      child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(c).pop(true),
                      child: const Text('REEMPLAZAR', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
              if (confirmar != true) return;
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              final exitoso = await gameState.resolveLoginConflict(
                false,
                nombreNube,
                puntajeNube,
                monedasNube,
              );
              messenger.showSnackBar(
                SnackBar(
                  content: Text(exitoso
                      ? 'Datos reemplazados por la partida actual'
                      : 'No se pudo reemplazar. Revisa tu conexión e inténtalo de nuevo'),
                ),
              );
            },
            child: const Text(
              'REEMPLAZAR',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );
}

/// Tarjeta visual comparativa para resumir las estadísticas de una partida.
Widget construirTarjetaPartida({
  required String etiqueta,
  required Color color,
  required String nombre,
  required int puntaje,
  required int monedas,
  required int cantidadSkins,
  required int cantidadLogros,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      border: Border.all(color: color.withValues(alpha: 0.7)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 6),
        Text(
          nombre.isEmpty ? '(sin nombre)' : nombre,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.yellowAccent, size: 18),
            const SizedBox(width: 4),
            Text('Récord: $puntaje', style: const TextStyle(color: Colors.yellowAccent)),
            const SizedBox(width: 16),
            const Icon(Icons.monetization_on, color: Colors.amberAccent, size: 18),
            const SizedBox(width: 4),
            Text('$monedas', style: const TextStyle(color: Colors.amberAccent)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.palette, color: Colors.pinkAccent, size: 18),
            const SizedBox(width: 4),
            Text('Skins: $cantidadSkins', style: const TextStyle(color: Colors.white70)),
            const SizedBox(width: 16),
            const Icon(Icons.military_tech, color: Colors.cyanAccent, size: 18),
            const SizedBox(width: 4),
            Text('Logros: $cantidadLogros', style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ],
    ),
  );
}

