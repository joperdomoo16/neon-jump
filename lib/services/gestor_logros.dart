import '../models/achievement.dart';

/// Administra la lista de logros del juego, sus metas y la entrega de recompensas.
class GestorLogros {
  Function(Achievement)? onAchievementUnlocked;
  bool _evaluando = false;

  final List<Achievement> listaLogros = [
    // Metas de puntuación
    Achievement(id: 'score_1000', title: 'Calentamiento', description: 'Alcanza 1,000 puntos', bonusCoins: 5),
    Achievement(id: 'score_5000', title: 'Primeros Pasos', description: 'Alcanza 5,000 puntos', bonusCoins: 10),
    Achievement(id: 'score_10000', title: 'Saltador Experto', description: 'Alcanza 10,000 puntos', bonusCoins: 15),
    Achievement(id: 'score_15000', title: 'Velocidad Luz', description: 'Alcanza 15,000 puntos', bonusCoins: 20),
    Achievement(id: 'score_25000', title: 'Maestro del Neón', description: 'Alcanza 25,000 puntos', bonusCoins: 25),
    Achievement(id: 'score_50000', title: 'Leyenda Cibernética', description: 'Alcanza 50,000 puntos', bonusCoins: 50),
    Achievement(id: 'score_100000', title: 'Ascenso Infinito', description: 'Alcanza 100,000 puntos', bonusCoins: 100),

    // Monedas acumuladas en total
    Achievement(id: 'coins_50', title: 'Bolsillo Lleno', description: 'Acumula 50 monedas en total', bonusCoins: 10),
    Achievement(id: 'coins_200', title: 'Tesoro Neón', description: 'Acumula 200 monedas en total', bonusCoins: 25),
    Achievement(id: 'coins_500', title: 'Magnate del Salto', description: 'Acumula 500 monedas en total', bonusCoins: 50),
    Achievement(id: 'coins_1000', title: 'Billonario Neón', description: 'Acumula 1,000 monedas en total', bonusCoins: 100),

    // Monedas recogidas en una misma partida
    Achievement(id: 'match_coins_5', title: 'Recolector Astuto', description: 'Recoge 5 monedas en una sola partida', bonusCoins: 10),
    Achievement(id: 'match_coins_15', title: 'Avaro del Aire', description: 'Recoge 15 monedas en una sola partida', bonusCoins: 25),

    // Colección de skins
    Achievement(id: 'skin_1', title: 'A la Moda', description: 'Desbloquea 2 skins', bonusCoins: 10),
    Achievement(id: 'skin_3', title: 'Pasarela de Neón', description: 'Desbloquea 3 skins', bonusCoins: 20),
    Achievement(id: 'skin_all', title: 'Colección Neón', description: 'Desbloquea 6 skins', bonusCoins: 50),
    Achievement(id: 'skin_10', title: 'Maestro del Estilo', description: 'Desbloquea 10 skins', bonusCoins: 50),
    Achievement(id: 'skin_master', title: 'Colección Legendaria', description: 'Desbloquea 20 skins', bonusCoins: 100),

    // Oportunidades aprovechadas (revivir)
    Achievement(id: 'revive_1', title: 'Segunda Oportunidad', description: 'Revive por primera vez', bonusCoins: 5),
    Achievement(id: 'revive_3', title: 'Inmortal', description: 'Revive 3 veces en una sola partida', bonusCoins: 15),
    Achievement(id: 'revive_5', title: 'Gato de 9 Vidas', description: 'Revive 5 veces en una sola partida', bonusCoins: 30),

    // Caídas y persistencia
    Achievement(id: 'die_1', title: 'Tropezón Inicial', description: 'Cae al vacío por primera vez', bonusCoins: 5),
    Achievement(id: 'die_10', title: 'Víctima de la Gravedad', description: 'Pierde 10 veces en total', bonusCoins: 15),
    Achievement(id: 'die_25', title: 'Persistencia Pura', description: 'Pierde 25 veces en total', bonusCoins: 25),

    // Maniobras en plataformas
    Achievement(id: 'bounce_spring', title: 'Super Impulso', description: 'Rebota en una plataforma resorte', bonusCoins: 10),
    Achievement(id: 'bounce_moving_5', title: 'Equilibrista', description: 'Rebota 5 veces en plataformas móviles en una partida', bonusCoins: 15),
    Achievement(id: 'bounce_fragile_5', title: 'Pisa Fuerte', description: 'Rompe 5 plataformas frágiles en una partida', bonusCoins: 15),
  ];

  List<String> get idsDesbloqueados =>
      listaLogros.where((a) => a.isUnlocked).map((a) => a.id).toList();

  void cargarDesbloqueados(List<String> ids) {
    for (var logro in listaLogros) {
      if (ids.contains(logro.id)) {
        logro.isUnlocked = true;
      }
    }
  }

  void reiniciar() {
    for (var logro in listaLogros) {
      logro.isUnlocked = false;
    }
  }

  void evaluarMetas({
    required int puntajeActual,
    required int totalMonedas,
    required int monedasPartida,
    required int cantidadSkins,
    required int revividasPartida,
    required int muertesTotales,
    required Map<String, int> rebotesPlataforma,
    required void Function(int monedasPremio) onPremio,
    required Future<void> Function() onGuardar,
  }) {
    if (_evaluando) return;
    _evaluando = true;
    try {
      // Puntuación
      _probarLogro('score_1000', () => puntajeActual >= 1000, onPremio, onGuardar);
      _probarLogro('score_5000', () => puntajeActual >= 5000, onPremio, onGuardar);
      _probarLogro('score_10000', () => puntajeActual >= 10000, onPremio, onGuardar);
      _probarLogro('score_15000', () => puntajeActual >= 15000, onPremio, onGuardar);
      _probarLogro('score_25000', () => puntajeActual >= 25000, onPremio, onGuardar);
      _probarLogro('score_50000', () => puntajeActual >= 50000, onPremio, onGuardar);
      _probarLogro('score_100000', () => puntajeActual >= 100000, onPremio, onGuardar);

      // Monedas acumuladas
      _probarLogro('coins_50', () => totalMonedas >= 50, onPremio, onGuardar);
      _probarLogro('coins_200', () => totalMonedas >= 200, onPremio, onGuardar);
      _probarLogro('coins_500', () => totalMonedas >= 500, onPremio, onGuardar);
      _probarLogro('coins_1000', () => totalMonedas >= 1000, onPremio, onGuardar);

      // Monedas en partida
      _probarLogro('match_coins_5', () => monedasPartida >= 5, onPremio, onGuardar);
      _probarLogro('match_coins_15', () => monedasPartida >= 15, onPremio, onGuardar);

      // Skins
      _probarLogro('skin_1', () => cantidadSkins >= 2, onPremio, onGuardar);
      _probarLogro('skin_3', () => cantidadSkins >= 3, onPremio, onGuardar);
      _probarLogro('skin_all', () => cantidadSkins >= 6, onPremio, onGuardar);
      _probarLogro('skin_10', () => cantidadSkins >= 10, onPremio, onGuardar);
      _probarLogro('skin_master', () => cantidadSkins >= 20, onPremio, onGuardar);

      // Revives
      _probarLogro('revive_1', () => revividasPartida >= 1, onPremio, onGuardar);
      _probarLogro('revive_3', () => revividasPartida >= 3, onPremio, onGuardar);
      _probarLogro('revive_5', () => revividasPartida >= 5, onPremio, onGuardar);

      // Muertes
      _probarLogro('die_1', () => muertesTotales >= 1, onPremio, onGuardar);
      _probarLogro('die_10', () => muertesTotales >= 10, onPremio, onGuardar);
      _probarLogro('die_25', () => muertesTotales >= 25, onPremio, onGuardar);

      // Plataformas
      _probarLogro('bounce_spring', () => (rebotesPlataforma['SpringPlatform'] ?? 0) >= 1, onPremio, onGuardar);
      _probarLogro('bounce_moving_5', () => (rebotesPlataforma['MovingPlatform'] ?? 0) >= 5, onPremio, onGuardar);
      _probarLogro('bounce_fragile_5', () => (rebotesPlataforma['FragilePlatform'] ?? 0) >= 5, onPremio, onGuardar);
    } finally {
      _evaluando = false;
    }
  }

  void _probarLogro(
    String id,
    bool Function() cumple,
    void Function(int monedasPremio) onPremio,
    Future<void> Function() onGuardar,
  ) {
    final indice = listaLogros.indexWhere((l) => l.id == id);
    if (indice != -1) {
      final logro = listaLogros[indice];
      if (!logro.isUnlocked && cumple()) {
        logro.isUnlocked = true;
        onPremio(logro.bonusCoins);
        onGuardar();
        onAchievementUnlocked?.call(logro);
      }
    }
  }
}

