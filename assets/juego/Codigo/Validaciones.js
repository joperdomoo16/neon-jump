/* Validación y saneamiento de datos de usuario y estado guardado */
(function () {
  var Nj = (window.Neonjump = window.Neonjump || {});

  var Camposnumericos = {
    Mejor: [0, 500000], Monedas: [0, 1000000], Monedastotales: [0, 100000000], Partidas: [0, 10000000], Caidas: [0, 10000000],
    Revivestotales: [0, 10000000], Revividasmax: [0, 1000], Mejormonedaspartida: [0, 100000], Resortetotal: [0, 10000000],
    Movilmax: [0, 100000], Fragilmax: [0, 100000], Segundosjugados: [0, 1000000000], Racha: [1, 50000], Sensibilidad: [0, 100],
    Mejorsemana: [0, 500000]
  };
  var Booleanos = ['Google', 'Sonido', 'Musica', 'Vibracion'];
  var Patronfecha = /^\d{4}-\d{2}-\d{2}$/;
  var Patronsemana = /^\d{4}-W\d{2}$/;
  var Patronnombre = /^[a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ _\.-]{3,20}$/;
  var Tieneletranumero = /[a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ]/;

  Nj.Validarnombre = function (Valor) {
    var Limpio = typeof Valor === 'string' ? Valor.trim() : '';
    if (Limpio.length < 3) return { Valido: false, Limpio: Limpio, Error: 'Debe tener al menos 3 caracteres.' };
    if (Limpio.length > 20) return { Valido: false, Limpio: Limpio, Error: 'Máximo 20 caracteres.' };
    if (!Tieneletranumero.test(Limpio)) return { Valido: false, Limpio: Limpio, Error: 'Debe incluir al menos una letra o un número.' };
    if (!Patronnombre.test(Limpio)) return { Valido: false, Limpio: Limpio, Error: 'Usa solo letras, números, espacios y _ . -' };
    return { Valido: true, Limpio: Limpio, Error: '' };
  };

  var Pantallasvalidas = ['Menu', 'Juego', 'Tienda', 'Ranking', 'Logros', 'Perfil', 'Resultados', 'Bienvenida'];
  var Alternablesvalidos = ['Sonido', 'Musica', 'Vibracion', 'Google'];

  Nj.Espantallavalida = function (Nombre) { return Pantallasvalidas.indexOf(Nombre) >= 0; };
  Nj.Esalternablevalido = function (Clave) { return Alternablesvalidos.indexOf(Clave) >= 0; };
  Nj.Esenlaceseguro = function (Url) {
    if (typeof Url !== 'string') return false;
    var Limpia = Url.trim();
    return /^https:\/\/[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(\/[^\s<>"]*)?$/.test(Limpia);
  };

  Nj.Necesitaregistro = function (Estado) {
    var Nombre = Estado && typeof Estado.Nombre === 'string' ? Estado.Nombre.trim() : '';
    if (!Nombre || /^Jugador_\d{5}$/.test(Nombre)) return true;
    return !Nj.Validarnombre(Nombre).Valido;
  };

  function Entero(Valor, Minimo, Maximo, Defecto) {
    var Numero = Math.floor(Number(Valor));
    if (!isFinite(Numero)) return Defecto;
    return Math.min(Maximo, Math.max(Minimo, Numero));
  }

  function Texto(Valor, Largo) { return typeof Valor === 'string' ? Valor.slice(0, Largo) : ''; }

  Nj.Sanearestado = function (Estado, Retodeldia, Clavesreto, Hoy) {
    var Limpio = Object.assign({}, Estado);
    Object.keys(Camposnumericos).forEach(function (Campo) {
      var Rango = Camposnumericos[Campo];
      Limpio[Campo] = Entero(Limpio[Campo], Rango[0], Rango[1], Campo === 'Sensibilidad' ? 70 : Rango[0]);
    });
    Booleanos.forEach(function (Campo) { Limpio[Campo] = Limpio[Campo] !== false && Limpio[Campo] != null && Limpio[Campo] !== 'false'; });
    Limpio.Google = Estado.Google === true;
    var Nombrecrudo = Texto(Limpio.Nombre, 20).trim();
    if (/^Jugador_\d{5}$/.test(Nombrecrudo) || Nj.Validarnombre(Nombrecrudo).Valido) {
      Limpio.Nombre = Nombrecrudo;
    } else {
      Limpio.Nombre = '';
    }

    // Skins: solo números que existan en el catálogo, sin repetidos y siempre con la primera
    var Totalskins = Nj.Skins ? Nj.Skins.length : 22;
    var Skins = Array.isArray(Limpio.Skins) ? Limpio.Skins : [0];
    Skins = Skins.map(function (Skin) { return Entero(Skin, -1, Totalskins, -1); })
      .filter(function (Skin, Posicion, Lista) { return Skin >= 0 && Skin < Totalskins && Lista.indexOf(Skin) === Posicion; });
    if (Skins.indexOf(0) < 0) Skins.unshift(0);
    Limpio.Skins = Skins;
    Limpio.Equipada = Entero(Limpio.Equipada, 0, Totalskins - 1, 0);
    if (Skins.indexOf(Limpio.Equipada) < 0) Limpio.Equipada = 0;
    Limpio.Tiendasel = Entero(Limpio.Tiendasel, 0, Totalskins - 1, 0);

    // Logros: solo los que existen
    var Conocidos = (Nj.Logros || []).map(function (Logro) { return Logro.Id; });
    Limpio.Logros = (Array.isArray(Limpio.Logros) ? Limpio.Logros : []).filter(function (Id, Posicion, Lista) {
      return typeof Id === 'string' && Conocidos.indexOf(Id) >= 0 && Lista.indexOf(Id) === Posicion;
    });

    var Categorias = (Nj.Categoriastienda || []).map(function (Categoria) { return Categoria.Id; });
    if (Categorias.indexOf(Limpio.Tiendacat) < 0) Limpio.Tiendacat = 'neon';
    if (Limpio.Rankingtab !== 'semana') Limpio.Rankingtab = 'global';
    Limpio.Ultimodia = Patronfecha.test(Limpio.Ultimodia) ? Limpio.Ultimodia : '';
    Limpio.Semana = Patronsemana.test(Limpio.Semana) ? Limpio.Semana : '';

    // El texto y el premio del reto salen siempre del catálogo; de lo guardado solo se toma el avance
    if (Retodeldia) {
      var Guardado = Limpio.Reto || {}, Fecha = Hoy();
      var Reto = Retodeldia(Fecha);
      if (Guardado.Dia === Fecha && Clavesreto.indexOf(Guardado.Clave) >= 0 && Guardado.Clave === Reto.Clave) {
        Reto.Progreso = Entero(Guardado.Progreso, 0, Reto.Meta, 0);
        Reto.Hecho = Guardado.Hecho === true;
      }
      Limpio.Reto = Reto;
    }
    return Limpio;
  };

  // Filas del ranking: nombre en lista blanca (máximo 20) y puntaje entero
  Nj.Sanearranking = function (Filas) {
    if (!Array.isArray(Filas)) return [];
    return Filas.filter(function (Fila) { return Fila && typeof Fila === 'object'; }).map(function (Fila) {
      var Crudo = Texto(Fila.Nombre, 20).trim();
      var Seguro = (Nj.Validarnombre(Crudo).Valido || /^Jugador_\d{5}$/.test(Crudo)) ? Crudo : 'Jugador';
      return { Nombre: Seguro, Puntaje: Entero(Fila.Puntaje, 0, 500000, 0) };
    });
  };

  Nj.Sanearversion = function (Version) {
    var Limpia = Texto(Version, 40).replace(/[^a-zA-Z0-9ÁÉÍÓÚáéíóúñÑ ._-]/g, '');
    return Limpia || 'VERSIÓN 1.1.3';
  };
})();
