/* Catálogos de skins y logros, ranking base y estado inicial */
(function () {
  var Nj = (window.Neonjump = window.Neonjump || {});
  var Imagenes = ['Baloncesto', 'Tenis', 'Voleibol', 'Futbol', 'Bolos', 'Bolaocho', 'Beisbol', 'Orbecyber', 'Magma', 'Tierra',
    'Dona', 'Bomba', 'Disco', 'Ojocyber', 'Peligro', 'Galaxia'];

  var Nombres = ['Cian', 'Rosa', 'Amarillo', 'Verde', 'Naranja', 'Púrpura', 'Baloncesto', 'Tenis', 'Voleibol', 'Fútbol',
    'Bolos', 'Bola 8', 'Béisbol', 'Orbe Cyber', 'Magma', 'Tierra', 'Dona', 'Bomba', 'Disco', 'Ojo Cyber', 'Peligro', 'Galaxia'];
  var Colores = ['#4FD8E8', '#F0577E', '#F2CF5B', '#5ED6A0', '#FF8A5B', '#B57BEA', '#FF9800', '#B2FF59', '#FFFFFF', '#FFFFFF',
    '#78909C', '#B388FF', '#FF5252', '#18FFFF', '#FF6E40', '#40C4FF', '#FF4081', '#FFD740', '#FFC107', '#00E5FF', '#76FF03', '#E040FB'];
  var Precios = [0, 30, 60, 100, 150, 220, 300, 400, 500, 650, 800, 950, 1100, 1300, 1500, 1750, 2000, 2300, 2700, 3200, 3800, 4500];

  // Las primeras 6 son de color, luego deportes, creativas y las caras al final
  function Categoria(Indice) { return Indice < 6 ? 'neon' : Indice < 13 ? 'deportes' : Indice < 18 ? 'creativas' : 'legendarias'; }

  Nj.Categoriastienda = [
    { Id: 'neon', Nombre: 'Neón' }, { Id: 'deportes', Nombre: 'Deportes' },
    { Id: 'creativas', Nombre: 'Creativas' }, { Id: 'legendarias', Nombre: 'Legendarias' }];

  Nj.Skins = Nombres.map(function (Nombre, Indice) {
    return {
      Id: Indice, Nombre: Nombre, Color: Colores[Indice], Precio: Precios[Indice], Categoria: Categoria(Indice),
      Imagen: Indice >= 6 ? 'Imagenes/' + Imagenes[Indice - 6] + '.png' : ''
    };
  });

  /* Definición de logros por categoría; los IDs se conservan por compatibilidad con Firestore. */
  function Logro(Id, Categoria, Titulo, Descripcion, Premio, Meta, Valor) {
    return { Id: Id, Categoria: Categoria, Titulo: Titulo, Descripcion: Descripcion, Premio: Premio, Meta: Meta, Valor: Valor };
  }
  var Mejor = function (Estado) { return Estado.Mejor; };
  var Monedastotales = function (Estado) { return Estado.Monedastotales; };
  var Monedaspartida = function (Estado) { return Estado.Mejormonedaspartida; };
  var Cantidadskins = function (Estado) { return Estado.Skins.length; };
  var Caidas = function (Estado) { return Estado.Caidas; };
  Nj.Logros = [
    Logro('score_1000', 'Altura', 'Calentamiento', 'Alcanza 1.000 puntos', 5, 1000, Mejor),
    Logro('score_5000', 'Altura', 'Primeros Pasos', 'Alcanza 5.000 puntos', 10, 5000, Mejor),
    Logro('score_10000', 'Altura', 'Saltador Experto', 'Alcanza 10.000 puntos', 15, 10000, Mejor),
    Logro('score_15000', 'Altura', 'Velocidad Luz', 'Alcanza 15.000 puntos', 20, 15000, Mejor),
    Logro('score_25000', 'Altura', 'Maestro del Neón', 'Alcanza 25.000 puntos', 25, 25000, Mejor),
    Logro('score_50000', 'Altura', 'Leyenda Cibernética', 'Alcanza 50.000 puntos', 50, 50000, Mejor),
    Logro('score_100000', 'Altura', 'Ascenso Infinito', 'Alcanza 100.000 puntos', 100, 100000, Mejor),
    Logro('coins_50', 'Monedas', 'Bolsillo Lleno', 'Acumula 50 monedas en total', 10, 50, Monedastotales),
    Logro('coins_200', 'Monedas', 'Tesoro Neón', 'Acumula 200 monedas en total', 25, 200, Monedastotales),
    Logro('coins_500', 'Monedas', 'Magnate del Salto', 'Acumula 500 monedas en total', 50, 500, Monedastotales),
    Logro('coins_1000', 'Monedas', 'Billonario Neón', 'Acumula 1.000 monedas en total', 100, 1000, Monedastotales),
    Logro('match_coins_5', 'Monedas', 'Recolector Astuto', 'Recoge 5 monedas en una partida', 10, 5, Monedaspartida),
    Logro('match_coins_15', 'Monedas', 'Avaro del Aire', 'Recoge 15 monedas en una partida', 25, 15, Monedaspartida),
    Logro('skin_1', 'Colección', 'A la Moda', 'Desbloquea 2 skins', 10, 2, Cantidadskins),
    Logro('skin_3', 'Colección', 'Pasarela de Neón', 'Desbloquea 3 skins', 20, 3, Cantidadskins),
    Logro('skin_all', 'Colección', 'Colección Neón', 'Desbloquea 6 skins', 50, 6, Cantidadskins),
    Logro('skin_10', 'Colección', 'Maestro del Estilo', 'Desbloquea 10 skins', 50, 10, Cantidadskins),
    Logro('skin_master', 'Colección', 'Colección Legendaria', 'Desbloquea 20 skins', 100, 20, Cantidadskins),
    Logro('revive_1', 'Revivir', 'Segunda Oportunidad', 'Revive por primera vez', 5, 1, function (Estado) { return Estado.Revivestotales; }),
    Logro('revive_3', 'Revivir', 'Inmortal', 'Revive 3 veces en una partida', 15, 3, function (Estado) { return Estado.Revividasmax; }),
    Logro('revive_5', 'Revivir', 'Gato de 9 Vidas', 'Revive 5 veces en una partida', 30, 5, function (Estado) { return Estado.Revividasmax; }),
    Logro('die_1', 'Caídas', 'Tropezón Inicial', 'Cae al vacío por primera vez', 5, 1, Caidas),
    Logro('die_10', 'Caídas', 'Víctima de la Gravedad', 'Pierde 10 veces en total', 15, 10, Caidas),
    Logro('die_25', 'Caídas', 'Persistencia Pura', 'Pierde 25 veces en total', 25, 25, Caidas),
    Logro('bounce_spring', 'Maniobras', 'Súper Impulso', 'Rebota en una plataforma resorte', 10, 1, function (Estado) { return Estado.Resortetotal; }),
    Logro('bounce_moving_5', 'Maniobras', 'Equilibrista', 'Rebota 5 veces en móviles en una partida', 15, 5, function (Estado) { return Estado.Movilmax; }),
    Logro('bounce_fragile_5', 'Maniobras', 'Pisa Fuerte', 'Rompe 5 frágiles en una partida', 15, 5, function (Estado) { return Estado.Fragilmax; })];

  Nj.Progresologro = function (Logrodato, Estado) {
    var Valor = Math.min(Logrodato.Valor(Estado) || 0, Logrodato.Meta);
    return { Valor: Valor, Meta: Logrodato.Meta, Porcentaje: Math.round((Valor / Logrodato.Meta) * 100), Hecho: Estado.Logros.indexOf(Logrodato.Id) >= 0 };
  };

  // Los que ya se cumplieron pero todavía no están marcados como ganados
  Nj.Logrosnuevos = function (Estado) {
    return Nj.Logros.filter(function (Logrodato) {
      return Estado.Logros.indexOf(Logrodato.Id) < 0 && (Logrodato.Valor(Estado) || 0) >= Logrodato.Meta;
    });
  };

  // Datos locales iniciales cuando no hay conexión a Firestore
  Nj.Ranking = [];
  Nj.Rankingsemana = [];

  // Formato numérico con separador de miles
  Nj.Formatear = function (Numero) { return Math.round(Numero || 0).toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.'); };

  Nj.Estadoinicial = function () {
    return {
      Pantalla: 'Menu', Nombre: 'Jugador', Mejor: 0, Monedas: 0, Monedastotales: 0,
      Skins: [0], Equipada: 0, Partidas: 0, Caidas: 0, Revivestotales: 0, Revividasmax: 0,
      Mejormonedaspartida: 0, Resortetotal: 0, Movilmax: 0, Fragilmax: 0, Segundosjugados: 0, Racha: 1,
      Logros: [],
      Google: false, Sonido: true, Musica: true, Vibracion: true, Sensibilidad: 70,
      Tiendacat: 'neon', Tiendasel: 0, Rankingtab: 'global', Aviso: null, Anuncio: 0,
      Reto: { Texto: 'Rebota 8 veces en plataformas móviles en una sola partida', Clave: 'Movil', Meta: 8, Premio: 30, Progreso: 0, Hecho: false },
      Resultado: null
    };
  };
})();
