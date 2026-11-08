import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../services/game_state.dart';
import 'boton_neon.dart';
import 'dialogo_conflicto_cuenta.dart';

/// Bloque de la interfaz del menú principal que gestiona el inicio y cierre de sesión con Google.
class SeccionAutenticacion extends StatelessWidget {
  final VoidCallback onAbrirRegistroNombre;

  const SeccionAutenticacion({
    super.key,
    required this.onAbrirRegistroNombre,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (streamCtx, snapshot) {
        final user = snapshot.data;
        final isGoogleLinked = user?.providerData.any((p) => p.providerId == 'google.com') ?? false;

        if (isGoogleLinked) {
          return Column(
            children: [
              const Text('Conectado con Google', style: TextStyle(color: Colors.greenAccent)),
              const SizedBox(height: 5),
              TextButton(
                onPressed: () => _confirmarCierreSesion(context),
                child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
              ),
              const SizedBox(height: 15),
            ],
          );
        }

        return Column(
          children: [
            const Text(
              '¡Guarda tu progreso!',
              style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            BotonNeon(
              texto: 'GOOGLE LOGIN',
              color: Colors.blueAccent,
              alPresionar: () => _iniciarSesionGoogle(context),
            ),
          ],
        );
      },
    );
  }

  Future<void> _iniciarSesionGoogle(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final gameState = Provider.of<GameState>(context, listen: false);
    final resultado = await gameState.loginWithGoogle();

    if (!context.mounted) return;

    if (resultado.hasConflict) {
      mostrarDialogoConflictoCuenta(context, gameState, resultado);
    } else if (resultado.success) {
      if (gameState.playerName.isEmpty) {
        onAbrirRegistroNombre();
        messenger.showSnackBar(
          const SnackBar(content: Text('Sesión iniciada. Por favor elige un nombre para el ranking.')),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Cuenta vinculada con éxito')),
        );
      }
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Error al iniciar sesión con Google')),
      );
    }
  }

  Future<void> _confirmarCierreSesion(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final gameState = Provider.of<GameState>(context, listen: false);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.redAccent, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión? Tus datos locales se reiniciarán en este dispositivo.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('CERRAR SESIÓN', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    await FirebaseAuth.instance.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

    if (!context.mounted) return;

    await gameState.wipeLocalData();

    if (!context.mounted) return;

    messenger.showSnackBar(
      const SnackBar(content: Text('Sesión cerrada')),
    );
    onAbrirRegistroNombre();
  }
}

