/* Motor de física, colisiones y generación procedural de plataformas */
(function () {
  var Nj = (window.Neonjump = window.Neonjump || {});
  var Ancho = 390, Alto = 844, Gravedad = 1200, Salto = -800, Aceleracion = 2000, Frenado = 1600;
  var Anchoplataforma = 78, Altoplataforma = 12, Radio = 15, Piso = 780, Tope = Piso - Altoplataforma / 2, Cero = Tope - Radio;
  var Colores = { Normal: '#F0577E', Movil: '#F2CF5B', Fragil: '#FF7B6B', Resorte: '#5ED6A0', Suelo: '#BDB7E0' };
  var Semilla = 0, Secuencia = 1, Poolchispas = [];

  // Con semilla siempre sale la misma partida (sirve para revisar); sin semilla es al azar
  function Azar() {
    if (!Semilla) return Math.random();
    Semilla = (Semilla * 16807) % 2147483647;
    return (Semilla - 1) / 2147483646;
  }
  function Entre(Minimo, Maximo) { return Minimo + Azar() * (Maximo - Minimo); }

  function Plataforma(Tipo, X, Y) {
    var Id = Secuencia++;
    return {
      Id: Id, Clave: Id, Tipo: Tipo, X: X, Y: Y, Base: X,
      T: Entre(0, 6), Velocidad: Entre(1.3, 2.3), Rango: Entre(60, 120), Roto: 0, Usada: 0, Golpe: 0,
      Normal: Tipo === 'Normal', Movil: Tipo === 'Movil', Fragil: Tipo === 'Fragil', Resorte: Tipo === 'Resorte',
      VistaX: Math.round(X - Anchoplataforma / 2), VistaY: Math.round(Y - Altoplataforma / 2), Opacidad: 1
    };
  }

  function Nuevamoneda(X, Y) {
    var Id = Secuencia++;
    return { Id: Id, Clave: Id, X: X, Y: Y, VistaX: Math.round(X - 9), VistaY: Math.round(Y - 9) };
  }

  // Va poniendo plataformas por encima de la cámara; entre más puntos, más separadas y traicioneras
  function Generar(Partida) {
    while (Partida.Cima > Partida.Camara - Alto * 0.9) {
      var Puntos = Partida.Puntaje;
      var Separacion = Math.min(96 + Puntos * 0.012, 210) + Entre(-12, 12);
      var Movil = Math.min(0.1 + Puntos / 25000, 0.5), Fragil = Math.min(0.05 + Puntos / 50000, 0.3), Resorte = 0.06;
      var X = Entre(Anchoplataforma / 2 + 6, Ancho - Anchoplataforma / 2 - 6);
      if (Math.abs(X - Partida.Ultimax) > 250) X = Partida.Ultimax + Math.sign(X - Partida.Ultimax) * 250;
      Partida.Cima -= Separacion;
      Partida.Ultimax = X;
      var Suerte = Azar();
      var Tipo = Suerte < Fragil ? 'Fragil' : Suerte < Fragil + Movil ? 'Movil' : Suerte < Fragil + Movil + Resorte ? 'Resorte' : 'Normal';
      var Nueva = Plataforma(Tipo, X, Partida.Cima);
      if (Tipo === 'Movil') Nueva.Base = Math.max(Anchoplataforma / 2 + Nueva.Rango, Math.min(Ancho - Anchoplataforma / 2 - Nueva.Rango, X));
      Partida.Plataformas.push(Nueva);
      if (Tipo === 'Resorte' && Azar() < 0.75) {
        Partida.Monedas.push(Nuevamoneda(X, Partida.Cima - 36));
        Partida.Monedas.push(Nuevamoneda(X, Partida.Cima - 74));
      } else if (Tipo !== 'Fragil' && Azar() < 0.26) {
        Partida.Monedas.push(Nuevamoneda(X, Partida.Cima - 36));
      }
    }
  }

  /* Basemetros: arrancar ya arriba para revisar zonas altas del cielo (esos metros no suman puntos) */
  Nj.Crearpartida = function (Consemilla, Basemetros) {
    Semilla = Consemilla || 0;
    var Base = (Basemetros || 0) * 10;
    var Partida = {
      Jugador: { X: Ancho / 2, Y: Cero, Vx: 0, Vy: 0, Sx: 1, Sy: 1, Rotacion: 0 },
      Plataformas: [], Monedas: [], Chispas: [], Camara: 0, Camarameta: 0, Maxaltura: 0, Puntaje: 0, Recogidas: 0,
      Rebotes: { Normal: 0, Movil: 0, Fragil: 0, Resorte: 0 }, Tiempo: 0, Relojestela: 0, Base: Base, Piso: !Base,
      Estado: 'espera', Revividas: 0, Cima: Piso, Ultimax: Ancho / 2, Fondo: Nj.Crearfondo ? Nj.Crearfondo() : null,
      Zona: '', Avisozona: null
    };
    if (Base) Partida.Plataformas.push(Plataforma('Normal', Ancho / 2, Piso));
    Generar(Partida);
    Partida.Zona = Nj.Zona ? Nj.Zona(Base / 10).Nombre : '';
    return Partida;
  };

  function Nuevachispa(X, Y, Vx, Vy, Vida, Color, Estela, Escarcha, Gravedad) {
    var C = Poolchispas.length ? Poolchispas.pop() : {};
    C.Id = Secuencia++; C.X = X; C.Y = Y; C.Vx = Vx; C.Vy = Vy;
    C.Vida = Vida; C.Maximo = Vida; C.Color = Color;
    C.Estela = !!Estela; C.Escarcha = !!Escarcha; C.Gravedad = Gravedad || 150;
    return C;
  }

  function Chispa(Partida, X, Y, Color, Cantidad, Fuerza) {
    for (var Indice = 0; Indice < Cantidad; Indice++) {
      if (Partida.Chispas.length >= 36) break;
      var Esbrillo = Azar() > 0.5;
      Partida.Chispas.push(Nuevachispa(
        X, Y, Entre(-0.5, 0.5) * 90, Entre(-1, -0.25) * Fuerza,
        0.55, Color, false, Esbrillo, 150
      ));
    }
  }

  function Rebotar(Partida, Jugador, Altura, Tipo, Multiplicador) {
    Jugador.Y = Altura - Radio;
    Jugador.Vy = Salto * Multiplicador;
    Jugador.Sx = 1.25; Jugador.Sy = 0.75;
    Chispa(Partida, Jugador.X, Altura, Colores[Tipo], Tipo === 'Resorte' ? 12 : 8, Tipo === 'Resorte' ? 185 : 130);
  }

  /* Avanza un cuadro de la simulación y devuelve lo que pasó (rebotes, monedas, caída, zona nueva) */
  Nj.Paso = function (Partida, Delta, Entrada) {
    var Eventos = [];
    Delta = Math.min(Delta, 1 / 30);
    if (Partida.Fondo && Partida.Estado === 'espera') Nj.Pasofondo(Partida.Fondo, Delta, (Partida.Base - Partida.Camara) / 10, 0);
    if (Partida.Estado !== 'jugando') return Eventos;
    Partida.Tiempo += Delta;
    var Jugador = Partida.Jugador, Maxima = 250 + (Entrada.Sensibilidad || 70) * 2;
    Jugador.Vy += Gravedad * Delta;
    var Anterior = Jugador.Y;
    if (Entrada && Entrada.ObjetivoX != null) {
      var Meta = Math.max(Radio, Math.min(Ancho - Radio, Entrada.ObjetivoX));
      var Xantes = Jugador.X;
      Jugador.X += (Meta - Jugador.X) * (1 - Math.exp(-25 * Delta));
      Jugador.Vx = Delta > 0 ? (Jugador.X - Xantes) / Delta : 0;
    } else {
      var Direccion = (Entrada.Derecha ? 1 : 0) - (Entrada.Izquierda ? 1 : 0);
      if (Direccion) Jugador.Vx = Math.max(-Maxima, Math.min(Maxima, Jugador.Vx + Direccion * Aceleracion * Delta));
      else Jugador.Vx = Jugador.Vx > 0 ? Math.max(0, Jugador.Vx - Frenado * Delta) : Math.min(0, Jugador.Vx + Frenado * Delta);
      Jugador.X += Jugador.Vx * Delta;
    }
    Jugador.Y += Jugador.Vy * Delta;
    if (Jugador.X < Radio) { Jugador.X = Radio; Jugador.Vx = 0; }
    if (Jugador.X > Ancho - Radio) { Jugador.X = Ancho - Radio; Jugador.Vx = 0; }

    Partida.Plataformas.forEach(function (Una) {
      if (Una.Tipo === 'Movil' && !Una.Usada) { Una.T += Delta; Una.X = Una.Base + Una.Rango * Math.sin(Una.T * Una.Velocidad); }
      if (Una.Golpe > 0) Una.Golpe = Math.max(0, Una.Golpe - Delta * 5);
      if (Una.Roto) Una.Roto += Delta;
      if (Una.Usada) Una.Usada += Delta;
    });

    // Cada plataforma admite un único rebote para evitar quedarse reposando en ella
    if (Jugador.Vy > 0) {
      var Toco = false;
      for (var Indice = 0; Indice < Partida.Plataformas.length; Indice++) {
        var Una = Partida.Plataformas[Indice], Borde = Una.Y - Altoplataforma / 2;
        if (Una.Roto || Una.Usada) continue;
        if (Anterior + Radio <= Borde + 3 && Jugador.Y + Radio >= Borde && Math.abs(Jugador.X - Una.X) <= Anchoplataforma / 2 + Radio * 0.55) {
          Rebotar(Partida, Jugador, Borde, Una.Tipo, Una.Tipo === 'Resorte' ? 1.6 : 1);
          Una.Golpe = 1;
          Partida.Rebotes[Una.Tipo]++;
          if (Una.Tipo === 'Fragil') Una.Roto = 0.001;
          else Una.Usada = 0.001;
          var Meta = Una.Y - Alto * 0.72;
          if (Meta < Partida.Camarameta) Partida.Camarameta = Meta;
          Partida.Piso = false;
          Eventos.push({ Tipo: 'rebote', Plataforma: Una.Tipo });
          Toco = true;
          break;
        }
      }
      if (!Toco && Partida.Piso && Jugador.Y + Radio >= Tope) {
        Rebotar(Partida, Jugador, Tope, 'Suelo', 1);
        Eventos.push({ Tipo: 'rebote', Plataforma: 'Suelo' });
      }
    }

    var Monedasvivas = 0;
    for (var Im = 0; Im < Partida.Monedas.length; Im++) {
      var Moneda = Partida.Monedas[Im];
      var Dx = Moneda.X - Jugador.X, Dy = Moneda.Y - Jugador.Y;
      if (Dx * Dx + Dy * Dy < (Radio + 10) * (Radio + 10)) {
        Partida.Recogidas++;
        Chispa(Partida, Moneda.X, Moneda.Y, '#F5C84C', 5, 120);
        Eventos.push({ Tipo: 'moneda' });
      } else if (Moneda.Y - Partida.Camara < Alto + 120) {
        Partida.Monedas[Monedasvivas++] = Moneda;
      }
    }
    Partida.Monedas.length = Monedasvivas;

    // La cámara acompaña el ascenso en cada salto
    var Camaraantes = Partida.Camara;
    var Objetivo = Math.min(Jugador.Y - Alto * 0.62, Partida.Camarameta || 0);
    if (Objetivo < Partida.Camara) {
      Partida.Camara += (Objetivo - Partida.Camara) * (1 - Math.exp(-12 * Delta));
      if (Jugador.Y < Partida.Camara + Alto * 0.14) Partida.Camara = Objetivo;
    }
    var Altura = Cero - Jugador.Y;
    if (Altura > Partida.Maxaltura) { Partida.Maxaltura = Altura; Partida.Puntaje = Math.floor(Altura / 2); }
    if (Partida.Fondo) {
      var Metros = (Partida.Base - Partida.Camara) / 10;
      Nj.Pasofondo(Partida.Fondo, Delta, Metros, Math.max(0, Camaraantes - Partida.Camara));
      var Zona = Nj.Zona(Metros).Nombre;
      if (Zona !== Partida.Zona) { Partida.Zona = Zona; Partida.Avisozona = { Nombre: Zona, T: 0 }; Eventos.push({ Tipo: 'zona', Nombre: Zona }); }
    }
    if (Partida.Avisozona) { Partida.Avisozona.T += Delta; if (Partida.Avisozona.T > 2.6) Partida.Avisozona = null; }

    var Platvivas = 0;
    for (var Ip = 0; Ip < Partida.Plataformas.length; Ip++) {
      var Plat = Partida.Plataformas[Ip];
      if (Plat.Y - Partida.Camara < Alto + 60 && Plat.Roto < 0.5 && Plat.Usada < 0.35) Partida.Plataformas[Platvivas++] = Plat;
    }
    Partida.Plataformas.length = Platvivas;
    Generar(Partida);

    // Estela ligera con reutilización de objetos (object pooling)
    Partida.Relojestela += Delta;
    if (Partida.Relojestela > 0.065 && Partida.Chispas.length < 32) {
      Partida.Relojestela = 0;
      var Vyo = -Jugador.Vy * 0.1;
      Partida.Chispas.push(Nuevachispa(Jugador.X, Jugador.Y, Entre(-14, 14), Entre(-14, 14) + Vyo, 0.38, '', true, false, 50));
      if (Azar() > 0.45) {
        Partida.Chispas.push(Nuevachispa(Jugador.X, Jugador.Y, Entre(-14, 14), Entre(-14, 14) + Vyo, 0.38, '#FFFFFF', false, true, 50));
      }
    }
    var Chispasvivas = 0;
    for (var Ic = 0; Ic < Partida.Chispas.length; Ic++) {
      var Ch = Partida.Chispas[Ic];
      Ch.Vida -= Delta; Ch.X += Ch.Vx * Delta; Ch.Y += Ch.Vy * Delta; Ch.Vy += (Ch.Gravedad || 150) * Delta;
      if (Ch.Vida > 0) Partida.Chispas[Chispasvivas++] = Ch;
      else if (Poolchispas.length < 64) Poolchispas.push(Ch);
    }
    Partida.Chispas.length = Chispasvivas;
    // La bola se aplasta al rebotar y vuelve poco a poco a su forma; gira al rodar o en el aire
    var Recuperacion = Math.min(1, Delta * 14);
    Jugador.Sx += (1 - Jugador.Sx) * Recuperacion; Jugador.Sy += (1 - Jugador.Sy) * Recuperacion;
    if (Math.abs(Jugador.Vx) > 5) {
      Jugador.Rotacion += ((Jugador.Vx / Radio) * Delta * 0.9) * (180 / Math.PI);
    } else if (Math.abs(Jugador.Vy) > 40) {
      Jugador.Rotacion += ((Jugador.Vy > 0 ? 0.3 : -0.3) * Delta) * (180 / Math.PI);
    }

    if (Jugador.Y - Partida.Camara > Alto + Radio * 2) { Partida.Estado = 'fin'; Eventos.push({ Tipo: 'caida' }); }
    return Eventos;
  };

  // Lo pone en la mitad de la pantalla con una plataforma nueva justo debajo
  Nj.Revivir = function (Partida) {
    var Jugador = Partida.Jugador;
    Jugador.X = Ancho / 2; Jugador.Y = Partida.Camara + Alto * 0.5; Jugador.Vx = 0; Jugador.Vy = 0;
    Partida.Plataformas = Partida.Plataformas.filter(function (Una) { return Math.abs(Una.Y - (Jugador.Y + 44)) > 30; });
    Partida.Plataformas.push(Plataforma('Normal', Ancho / 2, Jugador.Y + 44));
    Partida.Revividas++;
    Partida.Estado = 'espera';
  };

  /* Lo que se dibuja: el mundo en sus coordenadas y la cámara aparte */
  Nj.Vistapartida = function (Partida) {
    var Camara = Partida.Camara, Jugador = Partida.Jugador, Altura = Partida.Base - Camara;
    var Desde = Math.max(0, Math.ceil((Altura - 100) / 200) * 200);
    if (Partida.DesdeRegla !== Desde || !Partida.Vistaregla) {
      Partida.DesdeRegla = Desde;
      var Regla = [];
      for (var Marca = Desde; Marca < Altura + Alto; Marca += 200) {
        Regla.push({ Clave: 'r' + Marca, Y: Math.round(Cero - (Marca - Partida.Base)), Etiqueta: Nj.Formatear(Marca / 10) + ' m' });
      }
      Partida.Vistaregla = Regla;
    }
    for (var Ip = 0; Ip < Partida.Plataformas.length; Ip++) {
      var Una = Partida.Plataformas[Ip];
      Una.VistaX = Math.round(Una.X - Anchoplataforma / 2);
      Una.VistaY = Math.round(Una.Y - Altoplataforma / 2 + Una.Golpe * 4 + Una.Roto * 260 + Una.Usada * 80);
      Una.Opacidad = Una.Roto ? Math.max(0, 1 - Una.Roto * 2.2) : Una.Usada ? Math.max(0, 1 - Una.Usada * 3.0) : 1;
    }
    return {
      // La cámara mueve un solo contenedor; las piezas del mundo se actualizan en el lugar sin crear arreglos nuevos
      Camara: Math.round(Camara),
      Fondo: Partida.Fondo ? Nj.Vistafondo(Partida.Fondo, Altura) : null,
      Plataformas: Partida.Plataformas,
      Monedas: Partida.Monedas,
      Chispas: Partida.Chispas,
      Jugador: { X: Math.round(Jugador.X - Radio), Y: Math.round(Jugador.Y - Radio), Sx: Jugador.Sx.toFixed(2), Sy: Jugador.Sy.toFixed(2), Rotacion: Math.round(Jugador.Rotacion) },
      Regla: Partida.Vistaregla, Puntaje: Nj.Formatear(Partida.Puntaje), Recogidas: Partida.Recogidas,
      Alturam: Nj.Formatear((Partida.Maxaltura + Partida.Base) / 10), Zona: Partida.Zona.toUpperCase(),
      Avisozona: !!Partida.Avisozona, Avisozonanombre: Partida.Avisozona ? Partida.Avisozona.Nombre : '',
      Espera: Partida.Estado === 'espera', Jugando: Partida.Estado === 'jugando', Pausa: Partida.Estado === 'pausa', Fin: Partida.Estado === 'fin',
      Primeravez: Partida.Revividas === 0
    };
  };
})();
