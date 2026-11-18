/* Simulación de zonas de altura, nubes, cuerpos celestes y vehículos de fondo */
(function () {
  var Nj = (window.Neonjump = window.Neonjump || {});
  var Ancho = 390, Alto = 844, Piso = 774;
  var Secuencia = 1;

  // Número "aleatorio" pero siempre igual para la misma entrada, así las nubes no cambian de sitio
  function Hash(Numero) { var X = Math.sin(Numero * 127.1 + 311.7) * 43758.5453; return X - Math.floor(X); }
  function Mezclar(Desde, Hasta, Avance) { return Desde + (Hasta - Desde) * Avance; }
  function Tramo(Metros, Desde, Hasta) { return Math.max(0, Math.min(1, (Metros - Desde) / (Hasta - Desde))); }
  function Rgb(Color) { return [1, 3, 5].map(function (Posicion) { return parseInt(Color.slice(Posicion, Posicion + 2), 16); }); }
  function Tinte(ColorA, ColorB, Avance) {
    var Primero = Rgb(ColorA), Segundo = Rgb(ColorB);
    return 'rgb(' + [0, 1, 2].map(function (Canal) { return Math.round(Mezclar(Primero[Canal], Segundo[Canal], Avance)); }).join(',') + ')';
  }
  function Entre(Minimo, Maximo) { return Minimo + Math.random() * (Maximo - Minimo); }

  // [metros, color de arriba, color de abajo]
  var Tonoscielo = [[0, '#1B1840', '#3D3068'], [250, '#1D1D4C', '#33407A'], [800, '#181A4A', '#2A3778'], [1150, '#111134', '#202862'],
    [1600, '#0A0A23', '#141A46'], [2100, '#07071A', '#0C0D27'], [3500, '#0C0721', '#170D2F']];
  function Cielo(Metros) {
    for (var Indice = 0; Indice < Tonoscielo.length - 1; Indice++) {
      var Actual = Tonoscielo[Indice], Siguiente = Tonoscielo[Indice + 1];
      if (Metros <= Siguiente[0]) {
        var Avance = Tramo(Metros, Actual[0], Siguiente[0]);
        return 'linear-gradient(180deg, ' + Tinte(Actual[1], Siguiente[1], Avance) + ' 0%, ' + Tinte(Actual[2], Siguiente[2], Avance) + ' 100%)';
      }
    }
    var Ultimo = Tonoscielo[Tonoscielo.length - 1];
    return 'linear-gradient(180deg, ' + Ultimo[1] + ' 0%, ' + Ultimo[2] + ' 100%)';
  }

  // Qué cruza el cielo en cada tramo de altura y cada cuántos segundos
  Nj.Zonas = [
    { Desde: 0, Nombre: 'Ciudad', Tabla: [], Cada: [6, 9] },
    { Desde: 80, Nombre: 'Globos', Tabla: [['Globo', 1]], Cada: [2.2, 4.5] },
    { Desde: 300, Nombre: 'Avionetas', Tabla: [['Avioneta', 0.65], ['Globo', 0.35]], Cada: [2.5, 4.5] },
    { Desde: 550, Nombre: 'Ruta aérea', Tabla: [['Comercial', 0.65], ['Avioneta', 0.35]], Cada: [3, 5] },
    { Desde: 850, Nombre: 'Zona militar', Tabla: [['Militar', 0.6], ['Comercial', 0.4]], Cada: [2.8, 4.5] },
    { Desde: 1150, Nombre: 'Estratosfera', Tabla: [['Estrato', 0.35], ['Militar', 0.2]], Cada: [4, 7] },
    { Desde: 1550, Nombre: 'Órbita', Tabla: [['Estrato', 0.15], ['Meteoro', 0.3]], Cada: [4, 7] },
    { Desde: 2000, Nombre: 'Espacio', Tabla: [['Meteoro', 0.6]], Cada: [2.5, 5] },
    { Desde: 3000, Nombre: 'Espacio profundo', Tabla: [['Meteoro', 0.45], ['Ovni', 0.22]], Cada: [2.5, 5] }];
  Nj.Zona = function (Metros) {
    var Encontrada = Nj.Zonas[0];
    Nj.Zonas.forEach(function (Zona) { if (Metros >= Zona.Desde) Encontrada = Zona; });
    return Encontrada;
  };

  var Anchos = { Globo: 44, Avioneta: 60, Comercial: 170, Militar: 70, Estrato: 70, Ovni: 64, Meteoro: 12 };

  // Cada tipo sale de un lado distinto, con su velocidad, tamaño y opacidad suave de fondo
  function Volador(Tipo) {
    var Direccion = Math.random() < 0.5 ? 1 : -1, Escala = 1;
    var Nuevo = { Id: 'v' + Secuencia++, Tipo: Tipo, Direccion: Direccion, T: 0, Opacidad: 0.28, Variante: Math.random() < 0.5, Deriva: 0.35 };
    if (Tipo === 'Globo') { Escala = Entre(0.7, 1.15); Nuevo.Vx = Direccion * Entre(16, 28); Nuevo.Vy = 0; Nuevo.Y = Entre(130, 560); Nuevo.Opacidad = 0.20 + 0.10 * Escala; }
    if (Tipo === 'Avioneta') { Escala = Entre(0.8, 1.1); Nuevo.Vx = Direccion * Entre(60, 85); Nuevo.Vy = 0; Nuevo.Y = Entre(120, 600); Nuevo.Opacidad = 0.26; }
    if (Tipo === 'Comercial') { Escala = Entre(0.75, 1); Nuevo.Vx = Direccion * Entre(90, 125); Nuevo.Vy = 0; Nuevo.Y = Entre(120, 560); Nuevo.Opacidad = 0.28; }
    if (Tipo === 'Militar') { Escala = Entre(0.8, 1); Nuevo.Vx = Direccion * Entre(240, 300); Nuevo.Vy = 0; Nuevo.Y = Entre(140, 520); Nuevo.Opacidad = 0.28; }
    if (Tipo === 'Estrato') { Escala = Entre(0.9, 1.2); Nuevo.Vx = Direccion * Entre(5, 10); Nuevo.Vy = 6; Nuevo.Y = -140; Nuevo.Deriva = 0.22; Nuevo.Opacidad = 0.25; }
    if (Tipo === 'Ovni') { Escala = 1; Nuevo.Vx = Direccion * Entre(110, 150); Nuevo.Vy = 0; Nuevo.Y = Entre(160, 520); Nuevo.Deriva = 0.2; Nuevo.Opacidad = 0.30; }
    if (Tipo === 'Meteoro') { Nuevo.Vx = Direccion * Entre(150, 230); Nuevo.Vy = Entre(200, 280); Nuevo.Y = -30; Nuevo.Deriva = 0.1; Nuevo.Opacidad = 0.32; }
    Nuevo.Escala = Escala;
    Nuevo.X = Tipo === 'Meteoro' ? Entre(40, 350) : Tipo === 'Estrato' ? Entre(30, 290) : Direccion > 0 ? -Anchos[Tipo] * Escala - 10 : Ancho + 10;
    return Nuevo;
  }

  // Los militares siempre vuelan en pareja
  function Acompanante(Lider) {
    var Pareja = Volador('Militar');
    Pareja.Direccion = Lider.Direccion; Pareja.Vx = Lider.Vx; Pareja.Escala = Lider.Escala * 0.9;
    Pareja.Y = Lider.Y + 22; Pareja.X = Lider.X - Lider.Direccion * 46;
    return Pareja;
  }

  Nj.Crearfondo = function () {
    var Estrellas = [];
    for (var Indice = 0; Indice < 46; Indice++) {
      Estrellas.push({
        Clave: 'e' + Indice, X: Hash(Indice) * Ancho, Y: Hash(Indice + 99) * Alto, Tamano: Hash(Indice + 7) < 0.82 ? 2 : 3,
        Opacidad: 0.45 + Hash(Indice + 31) * 0.55, Paralaje: 0.02 + Hash(Indice + 53) * 0.05
      });
    }
    return { Voladores: [], Reloj: 1.5, T: 0, Estrellas: Estrellas };
  };

  /* Subida: cuántos píxeles subió la cámara en este cuadro, para que todo se vaya quedando abajo */
  Nj.Pasofondo = function (Fondo, Delta, Metros, Subida) {
    Fondo.T += Delta;
    Fondo.Reloj -= Delta;
    var Zona = Nj.Zona(Metros);
    if (Fondo.Reloj <= 0) {
      Fondo.Reloj = Entre(Zona.Cada[0], Zona.Cada[1]);
      if (Fondo.Voladores.length < 3) {
        var Suerte = Math.random(), Acumulado = 0;
        for (var Indice = 0; Indice < Zona.Tabla.length; Indice++) {
          Acumulado += Zona.Tabla[Indice][1];
          if (Suerte < Acumulado) {
            var Nuevo = Volador(Zona.Tabla[Indice][0]);
            Fondo.Voladores.push(Nuevo);
            if (Nuevo.Tipo === 'Militar') Fondo.Voladores.push(Acompanante(Nuevo));
            break;
          }
        }
      }
    }
    var Vivos = 0;
    for (var Indice = 0; Indice < Fondo.Voladores.length; Indice++) {
      var Uno = Fondo.Voladores[Indice];
      Uno.T += Delta;
      Uno.X += Uno.Vx * Delta;
      Uno.Y += Uno.Vy * Delta + Subida * Uno.Deriva;
      var Medida = Anchos[Uno.Tipo] * Uno.Escala;
      if (Uno.X > -Medida - 60 && Uno.X < Ancho + 60 && Uno.Y < Alto + 160 && Uno.Y > -320) {
        Fondo.Voladores[Vivos++] = Uno;
      }
    }
    Fondo.Voladores.length = Vivos;
  };

  function Nubes(Altura) {
    var Paralaje = Altura * 0.7, Lista = [], Desde = Math.max(0, Math.floor((Paralaje - 1100) / 150)), Hasta = Math.floor((Paralaje + 600) / 150);
    for (var Fila = Desde; Fila <= Hasta; Fila++) {
      var Alturanube = 380 + Fila * 150, Y = 420 + (Paralaje - Alturanube), Metrosnube = Alturanube / 7;
      if (Hash(Fila + 3) < 0.28 || Y < -90 || Y > Alto + 20) continue;
      var Opacidad = Tramo(Metrosnube, 40, 140) * (1 - Tramo(Metrosnube, 1050, 1450)) * (0.18 + Hash(Fila + 11) * 0.22);
      if (Opacidad <= 0.01) continue;
      var Anchonube = Math.round(100 + Hash(Fila + 5) * 150);
      Lista.push({ Clave: 'n' + Fila, X: Math.round(Hash(Fila) * (Ancho + 120) - 120), Y: Math.round(Y), Ancho: Anchonube, Alto: Math.round(Anchonube * 0.44), Opacidad: Opacidad.toFixed(2) });
    }
    return Lista;
  }

  var Tiposcuerpo = ['Luna', 'Rojo', 'Anillos', 'Hielo', 'Gigante', 'Nebulosa'];
  function Cuerpos(Altura) {
    var Paralaje = Altura * 0.12, Lista = [], Desde = Math.max(0, Math.floor((Paralaje - 1300 - 2640) / 300)), Hasta = Math.floor((Paralaje + 300 - 2640) / 300) + 1;
    for (var Fila = Desde; Fila <= Hasta; Fila++) {
      var Alturacuerpo = 2640 + Fila * 300, Y = 300 + (Paralaje - Alturacuerpo), Metroscuerpo = Alturacuerpo / 1.2;
      var Probabilidad = Math.min(0.35 + (Metroscuerpo - 2200) / 2500, 0.9);
      if (Fila > 0 && Hash(Fila + 71) > Probabilidad) continue;
      if (Y < -200 || Y > Alto + 60) continue;
      var Tipo = Fila === 0 ? 'Luna' : Tiposcuerpo[Math.floor(Hash(Fila + 13) * Tiposcuerpo.length)];
      var Tamano = Math.round(Tipo === 'Gigante' ? 96 + Hash(Fila) * 40 : Tipo === 'Nebulosa' ? 180 : 26 + Hash(Fila + 2) * 46);
      var Cuerpo = { Clave: 'c' + Fila, X: Math.round(Hash(Fila + 29) * (Ancho - Tamano)), Y: Math.round(Y), Tamano: Tamano };
      Tiposcuerpo.forEach(function (Nombre) { Cuerpo[Nombre] = Nombre === Tipo; });
      Lista.push(Cuerpo);
    }
    return Lista;
  }

  // La curva de la Tierra aparece en la estratosfera y se va achicando al subir
  function Tierra(Metros) {
    if (Metros < 1080 || Metros > 2750) return { Ver: false };
    var Arriba, Anchotierra;
    if (Metros < 1350) { Arriba = Mezclar(960, 700, Tramo(Metros, 1080, 1350)); Anchotierra = 2800; }
    else { var Avance = Tramo(Metros, 1350, 2750); Arriba = Mezclar(700, 980, Avance); Anchotierra = Mezclar(2800, 560, Avance); }
    return { Ver: true, Y: Math.round(Arriba), X: Math.round(Ancho / 2 - Anchotierra / 2), Ancho: Math.round(Anchotierra) };
  }

  var Tiposvolador = ['Globo', 'Avioneta', 'Comercial', 'Militar', 'Estrato', 'Ovni', 'Meteoro'];

  function Estrellasvisibles(Fondo, Altura, Brillo) {
    return Fondo.Estrellas.map(function (Estrella) {
      return { Clave: Estrella.Clave, X: Math.round(Estrella.X), Y: Math.round(((Estrella.Y + Altura * Estrella.Paralaje) % Alto + Alto) % Alto), Tamano: Estrella.Tamano, Opacidad: (Estrella.Opacidad * Brillo).toFixed(2) };
    });
  }

  /* Altura: píxeles que lleva subidos la cámara (0 = el suelo) */
  Nj.Vistafondo = function (Fondo, Altura) {
    var Metros = Altura / 10, Brillo = Metros < 1000 ? 0.32 : Mezclar(0.32, 1, Tramo(Metros, 1000, 2100));
    var Tramocielo = Math.round(Metros / 4) * 4;
    if (Fondo.Tramocielo !== Tramocielo) {
      Fondo.Tramocielo = Tramocielo;
      Fondo.Colorcielo = Cielo(Tramocielo);
      Fondo.Oscuridad = Math.min(0.88, Math.max(0, (Metros - 150) / 1950)).toFixed(2);
    }
    var PasoNubes = Math.round(Altura * 0.35);
    if (Fondo.PasoNubes !== PasoNubes) { Fondo.PasoNubes = PasoNubes; Fondo.Vistanubes = Nubes(Altura); }
    var PasoCuerpos = Math.round(Altura * 0.12);
    if (Fondo.PasoCuerpos !== PasoCuerpos) { Fondo.PasoCuerpos = PasoCuerpos; Fondo.Vistacuerpos = Cuerpos(Altura); }
    return {
      Cielo: Fondo.Colorcielo, Oscuridad: Fondo.Oscuridad || '0.00', Zona: Nj.Zona(Metros).Nombre,
      Estrellas: Fondo.Estrellas,
      Estrellasy1: Math.round((Altura * 0.025) % Alto),
      Estrellasy2: Math.round((Altura * 0.055) % Alto),
      Brilloestrellas: Brillo.toFixed(2),
      Ciudad: Altura < 1500, Ycerca: Math.round(Piso - 150 + Altura), Ylejos: Math.round(Piso - 290 + Altura * 0.55),
      Nubes: Fondo.Vistanubes || [], Cuerpos: Fondo.Vistacuerpos || [], Tierra: Tierra(Metros),
      Voladores: Fondo.Voladores.map(function (Uno) {
        var Vaiven = Uno.Tipo === 'Globo' ? Math.sin(Uno.T * 1.4) * 6 : Uno.Tipo === 'Ovni' ? Math.sin(Uno.T * 3) * 14 : 0;
        var Vista = {
          Clave: Uno.Id, X: Math.round(Uno.X), Y: Math.round(Uno.Y + Vaiven),
          Escala: Uno.Escala.toFixed(2), Giro: Uno.Direccion, Opacidad: Uno.Opacidad.toFixed(2), Angulo: Math.round(Math.atan2(Uno.Vy, Uno.Vx) * 57.3),
          Variante: Uno.Variante, Normal: !Uno.Variante
        };
        Tiposvolador.forEach(function (Nombre) { Vista[Nombre] = Uno.Tipo === Nombre; });
        return Vista;
      })
    };
  };

})();
