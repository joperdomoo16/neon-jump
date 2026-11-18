import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as datoszonas;
import 'package:timezone/timezone.dart' as zonas;

/// Recordatorios de la racha: dos al día, a la 1 de la tarde y a las 8 de la noche (hora del celular).
///
/// Se vuelven a programar cada vez que el jugador entra o cambia su racha:
/// - Si ya entró hoy, hoy no se le avisa; los avisos arrancan mañana.
/// - El primer día pendiente la racha sigue viva ("tu racha de N días te espera").
/// - Los días siguientes ya se habría perdido ("empieza una nueva racha").
/// - Se programan 7 días. Si no vuelve en una semana, se dejan de mandar para no fastidiar.
class Notificaciones {
  static final Notificaciones instancia = Notificaciones.interno();
  factory Notificaciones() => instancia;
  Notificaciones.interno();

  static const String idCanal = 'Recordatoriosracha';
  static const String nombreCanal = 'Recordatorios de racha';
  static const int idBase = 100;
  static const int dias = 7;
  static const List<int> horas = [13, 20];

  final FlutterLocalNotificationsPlugin complemento = FlutterLocalNotificationsPlugin();
  bool iniciado = false;
  bool permisoPedido = false;
  String ultimaFirma = '';

  Future<void> iniciar() async {
    if (iniciado) return;
    datoszonas.initializeTimeZones();
    const ajustes = InitializationSettings(
      android: AndroidInitializationSettings('ic_notificacion'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await complemento.initialize(settings: ajustes);
    iniciado = true;
  }

  /// [racha]: días seguidos que lleva. [ultimoDia]: último día que entró (AAAA-MM-DD, hora local).
  Future<void> programar({required int racha, required String ultimoDia}) async {
    final firma = '$racha|$ultimoDia|${textoDia(DateTime.now())}';
    if (firma == ultimaFirma) return;
    ultimaFirma = firma;
    try {
      await iniciar();
      if (!permisoPedido) {
        permisoPedido = true;
        await complemento
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }

      for (var indice = 0; indice < dias * horas.length; indice++) {
        await complemento.cancel(id: idBase + indice);
      }

      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);
      final ultimo = DateTime.tryParse(ultimoDia) ?? hoy;
      // La racha sigue viva solo el día siguiente al último ingreso
      final diaVivo = DateTime(ultimo.year, ultimo.month, ultimo.day + 1);
      final inicio = ultimoDia == textoDia(hoy) ? 1 : 0;

      const detalles = NotificationDetails(
        android: AndroidNotificationDetails(
          idCanal,
          nombreCanal,
          channelDescription: 'Dos avisos al día para no perder tu racha en Neon Jump',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: 'ic_notificacion',
          color: Color(0xFF4FD8E8),
        ),
        iOS: DarwinNotificationDetails(),
      );

      for (var dia = 0; dia < dias; dia++) {
        final fecha = DateTime(hoy.year, hoy.month, hoy.day + inicio + dia);
        final viva = fecha == diaVivo && racha >= 1;
        for (var hora = 0; hora < horas.length; hora++) {
          final momento = DateTime(fecha.year, fecha.month, fecha.day, horas[hora]);
          if (!momento.isAfter(ahora)) continue;
          final texto = textoAviso(viva: viva, racha: racha, noche: hora == 1);
          await complemento.zonedSchedule(
            id: idBase + dia * horas.length + hora,
            title: texto.$1,
            body: texto.$2,
            // La hora se arma en hora del celular y se programa ese mismo instante en UTC
            scheduledDate: zonas.TZDateTime.from(momento, zonas.UTC),
            notificationDetails: detalles,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      }
    } catch (error) {
      ultimaFirma = '';
      debugPrint('No se pudieron programar los recordatorios: $error');
    }
  }

  (String, String) textoAviso({required bool viva, required int racha, required bool noche}) {
    if (viva && racha >= 2) {
      return noche
          ? ('Tu racha de $racha días termina hoy', 'Entra antes de medianoche y llega a ${racha + 1} días.')
          : ('Tu racha de $racha días te espera', 'Un salto rápido y mañana serán ${racha + 1}.');
    }
    if (viva) {
      return noche
          ? ('Aún estás a tiempo', 'Entra hoy y empieza una racha de 2 días.')
          : ('Vuelve a saltar hoy', 'Entra y empieza una racha de 2 días.');
    }
    return noche
        ? ('La noche está despejada', 'Entra a NEON JUMP y empieza una nueva racha.')
        : ('El cielo te espera', 'Empieza una nueva racha hoy en NEON JUMP.');
  }

  static String textoDia(DateTime fecha) =>
      '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
}
