/* Puente de comunicación entre WebView y Flutter */
(function () {
  var Nj = (window.Neonjump = window.Neonjump || {});
  var Canal = window.Canalnativo;
  if (!Canal || !Canal.postMessage) return;

  var Pendientes = {}, Secuencia = 0, Api = null, Alarrancar = null, Datos = null, Ultimapantalla = '', Ocupado = false, Viendoanuncio = false;

  function Enviar(Id, Metodo, Contenido) {
    Canal.postMessage(JSON.stringify({ Id: Id, Metodo: Metodo, Datos: Contenido === undefined ? null : Contenido }));
  }
  // Llamar espera respuesta de Flutter; Avisar solo manda el mensaje y sigue
  function Llamar(Metodo, Contenido) {
    return new Promise(function (Resolver) { var Id = ++Secuencia; Pendientes[Id] = Resolver; Enviar(Id, Metodo, Contenido); });
  }
  function Avisar(Metodo, Contenido) { Enviar(0, Metodo, Contenido); }

  /* Fechas en hora del celular: sirven para la racha, el reto del día y el ranking semanal */
  function Dia(Fecha) { return Fecha.getFullYear() + '-' + String(Fecha.getMonth() + 1).padStart(2, '0') + '-' + String(Fecha.getDate()).padStart(2, '0'); }
  function Hoy() { return Dia(new Date()); }
  function Ayer() { var Fecha = new Date(); Fecha.setDate(Fecha.getDate() - 1); return Dia(Fecha); }
  function Semanaiso() {
    var Fecha = new Date(), Utc = new Date(Date.UTC(Fecha.getFullYear(), Fecha.getMonth(), Fecha.getDate()));
    Utc.setUTCDate(Utc.getUTCDate() + 4 - (Utc.getUTCDay() || 7));
    var Numero = Math.ceil(((Utc - Date.UTC(Utc.getUTCFullYear(), 0, 1)) / 86400000 + 1) / 7);
    return Utc.getUTCFullYear() + '-W' + String(Numero).padStart(2, '0');
  }

  /* El reto cambia cada día y siempre tiene 8 pasos, que es lo que cabe en la barrita del inicio */
  var Retos = [
    ['Movil', 'Rebota 8 veces en plataformas móviles en una sola partida', 30],
    ['Fragil', 'Rompe 8 plataformas frágiles en una sola partida', 35],
    ['Resorte', 'Rebota 8 veces en plataformas resorte en una sola partida', 40]];
  var Clavesreto = ['Movil', 'Fragil', 'Resorte'];
  function Retodeldia(Fecha) {
    var Numero = Math.floor(Date.parse(Fecha + 'T12:00:00Z') / 86400000), Reto = Retos[((Numero % Retos.length) + Retos.length) % Retos.length];
    return { Texto: Reto[1], Clave: Reto[0], Meta: 8, Premio: Reto[2], Progreso: 0, Hecho: false, Dia: Fecha };
  }

  // Pone al día la racha, el reto y la semana según la fecha de hoy
  function Normalizar(Estado) {
    var Fecha = Hoy();
    if (Estado.Ultimodia !== Fecha) { Estado.Racha = Estado.Ultimodia === Ayer() ? (Estado.Racha || 0) + 1 : 1; Estado.Ultimodia = Fecha; }
    if (!Estado.Reto || Estado.Reto.Dia !== Fecha || Clavesreto.indexOf(Estado.Reto.Clave) < 0) Estado.Reto = Retodeldia(Fecha);
    var Semana = Semanaiso();
    if (Estado.Semana !== Semana) { Estado.Semana = Semana; Estado.Mejorsemana = 0; }
    return Estado;
  }

  /* Estado inicial para nuevos jugadores */
  Nj.Estadoinicial = function () {
    return {
      Pantalla: 'Menu', Nombre: '', Mejor: 0, Monedas: 0, Monedastotales: 0,
      Skins: [0], Equipada: 0, Partidas: 0, Caidas: 0, Revivestotales: 0, Revividasmax: 0,
      Mejormonedaspartida: 0, Resortetotal: 0, Movilmax: 0, Fragilmax: 0, Segundosjugados: 0, Racha: 1,
      Logros: [], Google: false, Sonido: true, Musica: true, Vibracion: true, Sensibilidad: 70,
      Tiendacat: 'neon', Tiendasel: 0, Rankingtab: 'global', Aviso: null, Anuncio: 0,
      Reto: Retodeldia(Hoy()), Resultado: null, Ultimodia: '', Semana: '', Mejorsemana: 0
    };
  };
  Nj.Ranking = [];
  Nj.Rankingsemana = [];
  Nj.Etiquetaranking = 'TODOS LOS<br>JUGADORES';

  function Ponerranking(Ranking) {
    if (!Ranking || typeof Ranking !== 'object') return;
    if (Ranking.Global) Nj.Ranking = Nj.Sanearranking(Ranking.Global);
    if (Ranking.Semana) Nj.Rankingsemana = Nj.Sanearranking(Ranking.Semana);
  }
  // Todo estado que viene de Flutter pasa por la revisión antes de usarse
  function Sanear(Estado) { return Nj.Sanearestado(Estado, Retodeldia, Clavesreto, Hoy); }
  function Refrescarranking() {
    Llamar('ranking', { Semana: Semanaiso() }).then(function (Ranking) {
      Ponerranking(Ranking);
      if (Api && Api.Estado().Pantalla === 'Ranking') Api.Dibujar();
    });
  }

  // Estilos que solo aplican en la app: el banner real tapa el hueco y no se selecciona texto al tocar
  var Hoja = document.createElement('link');
  Hoja.rel = 'stylesheet';
  Hoja.href = 'Estilos/Nativo.css';
  document.head.appendChild(Hoja);

  function Cuentagoogle(Nombretemporal) {
    if (Ocupado || !Api) return Promise.resolve({ Google: false });
    Ocupado = true;
    var Estado = Api.Estado();
    var Carga = !Estado.Google && typeof Nombretemporal === 'string'
      ? Object.assign({}, Estado, { Nombre: Nombretemporal })
      : Estado;
    return (Estado.Google ? Llamar('desvincularGoogle') : Llamar('vincularGoogle', Carga)).then(function (Respuesta) {
      Ocupado = false;
      if (!Respuesta) return { Google: false };
      var Vinculado = !!Respuesta.Google;
      if (Respuesta.Sinperfil) return { Google: false, Sinperfil: true };
      if (Respuesta.Reiniciar) {
        // Al desvincular, el celular empieza de cero pero conserva los ajustes
        var Actual = Api.Estado(), Nuevo = Nj.Estadoinicial();
        ['Sonido', 'Musica', 'Vibracion', 'Sensibilidad'].forEach(function (Clave) { Nuevo[Clave] = Actual[Clave]; });
        Nuevo.Nombre = Respuesta.Nombre || '';
        Nuevo.Google = false;
        Nuevo.Pantalla = Actual.Pantalla;
        Api.Reemplazar(Normalizar(Sanear(Nuevo)));
      } else if (Respuesta.Estado && typeof Respuesta.Estado === 'object') {
        var Mezcla = Sanear(Object.assign(Nj.Estadoinicial(), Respuesta.Estado, { Google: Vinculado }));
        Mezcla.Pantalla = Api.Estado().Pantalla;
        Api.Reemplazar(Normalizar(Mezcla));
      } else if (Vinculado || Respuesta.Estado) {
        Api.Cambiar(function (Cambio) {
          if (typeof Nombretemporal === 'string' && Nombretemporal) Cambio.Nombre = Nombretemporal;
          Cambio.Google = Vinculado;
        });
      }
      Refrescarranking();
      return { Google: Vinculado, Cancelado: !!Respuesta.Cancelado };
    });
  }

  // Los enlaces legales del perfil los abre Flutter
  var Legales = { 'Opciones de privacidad': 'privacidad', 'Condiciones del servicio': 'condiciones', 'Política de privacidad': 'politica', 'Eliminar mi cuenta': 'eliminar' };
  document.addEventListener('click', function (Evento) {
    var Enlace = Evento.target.closest && Evento.target.closest('nav[aria-label="Legal"] a');
    if (!Enlace || Enlace.dataset.accion) return;
    Evento.preventDefault();
    var Clave = Legales[Enlace.textContent.trim()];
    if (Clave) Avisar('legal', Clave);
  }, true);

  /* Anuncio propio (Khronos o MiTecho) a pantalla completa cuando AdMob no tiene uno listo.
     Da false si no se pudo mostrar. Mientras se ve, Flutter no pone el banner de AdMob encima. */
  function Anunciopropio(Tipo, Alterminar) {
    if (!Nj.Anuncios || !Api) return false;
    var Estado = Api.Estado(), Partida = Api.Partida();
    // Por si la partida nueva ya arrancó, que no siga corriendo debajo del anuncio
    if (Partida && Partida.Estado === 'jugando' && Estado.Pantalla === 'Juego') Api.Acciones.Pausar();
    var Mostrado = Nj.Anuncios.Mostrar({
      Tipo: Tipo,
      Silencio: !(Estado.Sonido || Estado.Musica),
      Alterminar: function (Completo) {
        Ultimapantalla = '';
        Nj.Puente.Alrender(Api.Estado().Pantalla);
        if (Alterminar) Alterminar(Completo);
      }
    });
    if (Mostrado) { Ultimapantalla = 'Anuncio'; Avisar('pantalla', 'Anuncio'); }
    return Mostrado;
  }

  // Flutter contesta true cuando tocaba intersticial y AdMob no tenía uno listo
  function Intersticial() {
    Llamar('intersticial').then(function (Propio) { if (Propio === true) Anunciopropio('intersticial'); });
  }

  // El nombre del ranking tiene que ser único: se revisa en la nube cuando la persona deja de escribir
  var Relojnombre = null;
  document.addEventListener('input', function (Evento) {
    if (!Api || !Evento.target.dataset || Evento.target.dataset.entrada !== 'nombre') return;
    clearTimeout(Relojnombre);
    Relojnombre = setTimeout(function () {
      var Nombre = Api.Estado().Nombre;
      Llamar('validarNombre', Nombre).then(function (Mensaje) {
        var Ayuda = document.getElementById('nj-ayuda-nombre');
        if (Mensaje && Ayuda && Api.Estado().Nombre === Nombre) Ayuda.textContent = Mensaje;
      });
    }, 700);
  });

  Nj.Puente = {
    /* Aplicacion.js lo llama al cargar; el juego arranca cuando Flutter manda los datos del jugador */
    Conectar: function (Internos, Arrancar) {
      Api = Internos;
      Alarrancar = Arrancar;
      var Acciones = Api.Acciones;

      Acciones.Reviviranuncio = function () {
        if (Viendoanuncio) return;
        Viendoanuncio = true;
        Llamar('anuncioBonificado').then(function (Gano) {
          // 'propio': AdMob no tenía anuncio; se ve uno propio y, si se ve completo, también revive
          var Propio = Gano === 'propio' && Anunciopropio('bonificado', function (Completo) {
            Viendoanuncio = false;
            if (Completo && Api.Estado().Pantalla === 'Resultados') Api.Revivirahora();
          });
          if (Propio) return;
          Viendoanuncio = false;
          if (Gano === true && Api.Estado().Pantalla === 'Resultados') Api.Revivirahora();
        });
      };
      var Alternar = Acciones.Alternar;
      Acciones.Alternar = function (Clave) { if (Clave === 'Google') Cuentagoogle(); else Alternar(Clave); };
      var Ir = Acciones.Ir;
      Acciones.Ir = function (Pantalla) { Ir(Pantalla); if (Pantalla === 'Ranking') Refrescarranking(); };
      var Jugar = Acciones.Jugar;
      Acciones.Jugar = function () { if (Api.Estado().Pantalla === 'Resultados') Intersticial(); Jugar(); };
      var Menu = Acciones.Menu;
      Acciones.Menu = function () { if (Api.Estado().Pantalla === 'Resultados') Intersticial(); Menu(); };

      Avisar('listo');
    },

    Iniciar: function (Recibidos) {
      if (Datos) return;
      Datos = Recibidos && typeof Recibidos === 'object' ? Recibidos : {};
      if (Datos.Version) Nj.Version = Nj.Sanearversion(Datos.Version);
      Ponerranking(Datos.Ranking);
      var Guardado = Datos.Estado && typeof Datos.Estado === 'object' ? Datos.Estado : {};
      var Estado = Sanear(Object.assign(Nj.Estadoinicial(), Guardado, { Google: Datos.Google === true }));
      Datos.Estado = Normalizar(Estado);
      if (Alarrancar) Alarrancar();
      Api.Cambiar(function () { });
      Refrescarranking();
    },

    Estadoguardado: function () { return Datos ? Datos.Estado : null; },
    Guardar: function (Estado) { Avisar('guardar', Estado); },

    Responder: function (Id, Valor) {
      var Resolver = Pendientes[Id];
      if (Resolver) { delete Pendientes[Id]; Resolver(Valor); }
    },

    Alrender: function (Pantalla) {
      if (Nj.Anuncios && Nj.Anuncios.Abierto()) return; // el anuncio propio tapa la pantalla y no debe quedar el banner encima
      if (Pantalla !== Ultimapantalla) { Ultimapantalla = Pantalla; Avisar('pantalla', Pantalla); }
    },

    /* Flutter avisa si el banner de AdMob está cargado: así el banner propio del hueco se esconde o vuelve a verse */
    Banneradmob: function (Listo) { document.documentElement.classList.toggle('nj-admob-banner', Listo === true); },

    /* Los anuncios propios solo mandan su clave; Flutter tiene la lista de enlaces que puede abrir */
    Abriranuncio: function (Clave) { Avisar('abrirAnuncio', String(Clave)); },

    Eventos: function (Eventos) {
      if (!Api) return;
      var Estado = Api.Estado();
      if (Estado && Estado.Vibracion) {
        for (var Indice = 0; Indice < Eventos.length; Indice++) {
          if (Eventos[Indice].Tipo === 'rebote') Avisar('vibrar', Eventos[Indice].Plataforma === 'Resorte' ? 'medio' : 'suave');
        }
      }
      if (Nj.Audio && Estado) {
        for (var Otro = 0; Otro < Eventos.length; Otro++) {
          if (Eventos[Otro].Tipo === 'rebote') Nj.Audio.Rebote(Eventos[Otro].Plataforma, Estado.Sonido);
          else if (Eventos[Otro].Tipo === 'moneda') Nj.Audio.Moneda(Estado.Sonido);
        }
      }
    },

    Alcaer: function (Resultado) {
      if (!Api) return;
      if (Api.Estado().Vibracion) Avisar('vibrar', 'fuerte');
      if (Resultado) Api.Cambiar(function (Estado) { Normalizar(Estado); Estado.Mejorsemana = Math.max(Estado.Mejorsemana || 0, Resultado.Puntaje); });
    },

    Validarnombre: function (Nombre) { return Llamar('validarNombre', Nombre); },
    Vinculargoogle: function (Nombre) { return Cuentagoogle(Nombre); },
    Enviarsoporte: function (Solicitud) { return Llamar('enviarSoporte', Solicitud); },

    /* La app se fue a segundo plano: se pausa la partida y la música */
    Pausar: function () {
      if (Nj.Anuncios) Nj.Anuncios.Pausar();
      if (Nj.Audio) Nj.Audio.Pausar();
      if (!Api) return;
      var Partida = Api.Partida();
      if (Partida && Partida.Estado === 'jugando' && Api.Estado().Pantalla === 'Juego') Api.Acciones.Pausar();
    },

    /* La app volvió: de pronto ya cambió el día */
    Alvolver: function () {
      if (Nj.Anuncios) Nj.Anuncios.Reanudar();
      if (Nj.Audio) Nj.Audio.Reanudar(); // con un anuncio propio abierto la música sigue callada
      if (!Api || !Datos) return;
      var Estado = Api.Estado();
      if (Estado.Ultimodia !== Hoy() || Estado.Semana !== Semanaiso()) Api.Cambiar(function (Cambio) { Normalizar(Cambio); });
    },

    Fijarnombre: function (Nombre) {
      if (Api && typeof Nombre === 'string') Api.Cambiar(function (Estado) { Estado.Nombre = Nombre.slice(0, 20); });
    },

    /* Botón atrás de Android: devuelve true si el juego se encargó */
    Atras: function () {
      if (!Api || !Datos) return false;
      if (Nj.Anuncios && Nj.Anuncios.Abierto()) { Nj.Anuncios.Atras(); return true; }
      var Estado = Api.Estado(), Partida = Api.Partida();
      if (Estado.Ayuda) { Api.Acciones.Cerrarayuda(); return true; }
      if (Estado.Avisorespaldo) { Api.Acciones.Cerraravisorespaldo(); return true; }
      if (Estado.Pantalla === 'Bienvenida') {
        if (Nj.Pantallas.Bienvenida && Nj.Pantallas.Bienvenida.Confirmandoactual()) { Api.Acciones.Cancelarriesgo(); return true; }
        return false;
      }
      if (Estado.Pantalla === 'Menu') return false;
      if (Estado.Pantalla === 'Juego' && Partida) {
        if (Partida.Estado === 'jugando') Api.Acciones.Pausar();
        else if (Partida.Estado === 'pausa') Api.Acciones.Continuar();
        else if (Partida.Estado === 'espera') Api.Acciones.Menu();
        return true;
      }
      if (Estado.Pantalla === 'Resultados') { Api.Acciones.Menu(); return true; }
      Api.Acciones.Ir('Menu');
      return true;
    }
  };
})();
