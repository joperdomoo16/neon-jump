import 'package:flutter/material.dart';

class Constantes {
  // Bloques de anuncios de AdMob
  static const String idBanner = 'ca-app-pub-1945212468802352/3476895282';
  static const String idIntersticial = 'ca-app-pub-1945212468802352/9645436557';
  static const String idBonificado = 'ca-app-pub-1945212468802352/4497051651';

  // Anuncios propios que el juego muestra cuando AdMob no tiene anuncio (assets/juego/Anuncios).
  // El juego solo manda la clave: así el WebView no puede pedir que se abra cualquier enlace.
  // MiTecho no lleva enlace mientras siga en prueba cerrada; al publicarla se agrega
  // 'mitecho': 'https://play.google.com/store/apps/details?id=co.mitecho.app' aquí y su Enlace en Anuncios.js.
  static const Map<String, String> anunciosPropios = {
    'khronos': 'https://khronos-co.web.app/',
  };

  // Páginas legales publicadas en Firebase Hosting (carpeta public)
  static const String urlPolitica = 'https://neon-jump-stellar.web.app/politica-de-privacidad';
  static const String urlCondiciones = 'https://neon-jump-stellar.web.app/terminos-de-uso';
  static const String urlEliminarCuenta = 'https://neon-jump-stellar.web.app/eliminar-cuenta';

  // Web App de Google Apps Script para registrar PQR y Soporte en Google Sheets
  static const String urlSoporte =
      'https://script.google.com/macros/s/AKfycbzU25gA8FZd8VA2I2G1C3Q8HkFtlLEw4G8cMQGmVPBEHT2fkC3eckl69aW1j1Y8f-0/exec';

  // Lo que vale cada skin, en el mismo orden de Datos.js. Solo se usa al pasar el progreso de la versión vieja
  static const List<int> preciosSkins = [
    0, 30, 60, 100, 150, 220, 300, 400, 500, 650, 800,
    950, 1100, 1300, 1500, 1750, 2000, 2300, 2700, 3200, 3800, 4500,
  ];

  // Colores base de la interfaz (Tokens.css) para los diálogos nativos
  static const Color tinta = Color(0xFF16132E);
  static const Color tintaDos = Color(0xFF1F1B40);
  static const Color hueso = Color(0xFFF3F1FF);
  static const Color huesoDos = Color(0xFFBDB7E0);
  static const Color acento = Color(0xFF4FD8E8);
}
