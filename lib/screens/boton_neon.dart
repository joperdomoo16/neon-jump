import 'package:flutter/material.dart';

/// Botón con estética retro neón y efecto de resplandor (glow).
class BotonNeon extends StatelessWidget {
  final String texto;
  final Color color;
  final VoidCallback alPresionar;
  final double ancho;

  const BotonNeon({
    super.key,
    required this.texto,
    required this.color,
    required this.alPresionar,
    this.ancho = 200,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: alPresionar,
      child: Container(
        width: ancho,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(color: color, blurRadius: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

