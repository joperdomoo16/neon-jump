/* Gestión de anuncios propios de respaldo (banner e intersticial/bonificado) */
(function () {
  var Nj = window.Neonjump;

  // Los enlaces de aquí solo se usan en el navegador; dentro de la app Flutter abre los suyos (Constantes.anunciosPropios).
  // Sin Enlace el anuncio se muestra pero no lleva a ningún lado (MiTecho sigue en prueba cerrada en Play)
  var Catalogo = [
    { Clave: 'khronos', Archivo: 'Khronos', Nombre: 'Khronos', Lema: 'Domina tu tiempo, conquista tus proyectos.', Boton: 'Entrar',
      Fondo: '#363838', Color: '#EFE8D5', Tinta: '#363838', Enlace: 'https://khronos-co.web.app/' },
    { Clave: 'mitecho', Archivo: 'Mitecho', Nombre: 'MiTecho', Lema: '¿Cuánto te presta el banco para tu casa?', Boton: 'Descargar',
      Fondo: '#0B0C0A', Color: '#D4FF3A', Tinta: '#0B0C0A', Enlace: '' }
  ];
  var Turnobanner = 15000;   // cada banner se queda 15 s en el menú
  var Cerrarintersticial = 5; // segundos antes de poder cerrar el intersticial
  var Duracionimagen = 5;     // si el video no arranca, se muestra el banner grande estos segundos

  var Siguiente = Math.floor(Math.random() * Catalogo.length), Abierto = null;

  function Ruta(Anuncio, Extension) { return 'Anuncios/' + Anuncio.Archivo + '.' + Extension; }
  function Turnoactual() { return Math.floor(Date.now() / Turnobanner) % Catalogo.length; }

  /* ---------- Banner del menú ---------- */

  // El turno sale del reloj: redibujar el menú no reinicia el banner que se está viendo
  function Banner() {
    var Turno = Turnoactual();
    return Catalogo.map(function (Anuncio, Indice) {
      var Clase = 'nj-anuncio-banner' + (Indice === Turno ? ' nj-visible' : '');
      var Etiqueta = 'Publicidad · ' + Anuncio.Nombre + ': ' + Anuncio.Lema;
      var Imagen = '<img src="' + Ruta(Anuncio, 'png') + '" alt="" width="320" height="50" draggable="false">';
      if (!Anuncio.Enlace) return '<div class="' + Clase + '" role="img" aria-label="' + Etiqueta + '">' + Imagen + '</div>';
      return '<a href="' + Anuncio.Enlace + '" target="_blank" rel="noopener" data-anuncio="' + Anuncio.Clave + '" class="' + Clase + '" aria-label="' + Etiqueta + '">' + Imagen + '</a>';
    }).join('');
  }
  setInterval(function () {
    var Banners = document.querySelectorAll('.nj-anuncio-banner');
    if (!Banners.length) return;
    var Turno = Turnoactual();
    for (var Indice = 0; Indice < Banners.length; Indice++) Banners[Indice].classList.toggle('nj-visible', Indice === Turno);
  }, 5000);

  // Dentro de la app el enlace lo abre Flutter (solo recibe la clave); en el navegador se sigue el enlace normal
  document.addEventListener('click', function (Evento) {
    var Enlace = Evento.target.closest && Evento.target.closest('[data-anuncio]');
    if (!Enlace || !Nj.Puente || !Nj.Puente.Abriranuncio) return;
    Evento.preventDefault();
    Nj.Puente.Abriranuncio(Enlace.dataset.anuncio);
  });

  /* ---------- Video a pantalla completa ---------- */

  // Mientras se ve el anuncio la música del juego se queda callada
  if (Nj.Audio) {
    ['Sincronizar', 'Reanudar'].forEach(function (Nombre) {
      var Original = Nj.Audio[Nombre];
      Nj.Audio[Nombre] = function () { if (!Abierto) return Original.apply(Nj.Audio, arguments); };
    });
  }

  /* Opciones: { Tipo: 'intersticial' | 'bonificado', Silencio, Alterminar(Completo) }.
     Da false si no se pudo mostrar (ya había otro abierto). Completo es true si se vio hasta el final. */
  function Mostrar(Opciones) {
    Opciones = Opciones || {};
    var Escenario = document.getElementById('nj-escenario');
    if (Abierto || !Escenario) return false;
    var Anuncio = Catalogo[Siguiente % Catalogo.length];
    Siguiente += 1;

    var Capa = document.createElement('div');
    Capa.className = 'nj-raiz nj-anuncio';
    Capa.setAttribute('role', 'dialog');
    Capa.setAttribute('aria-modal', 'true');
    Capa.setAttribute('aria-label', 'Publicidad: ' + Anuncio.Nombre);
    Capa.style.background = Anuncio.Fondo;
    var Enlaceseguro = Anuncio.Enlace && (!Nj.Esenlaceseguro || Nj.Esenlaceseguro(Anuncio.Enlace)) ? Anuncio.Enlace : '';
    var Nombreesc = Nj.Interfaz && Nj.Interfaz.Escapar ? Nj.Interfaz.Escapar(Anuncio.Nombre) : Anuncio.Nombre;
    var Lemaesc = Nj.Interfaz && Nj.Interfaz.Escapar ? Nj.Interfaz.Escapar(Anuncio.Lema) : Anuncio.Lema;
    var Botonesc = Nj.Interfaz && Nj.Interfaz.Escapar ? Nj.Interfaz.Escapar(Anuncio.Boton) : Anuncio.Boton;
    Capa.innerHTML =
      '<video class="nj-anuncio-video" src="' + Ruta(Anuncio, 'mp4') + '" playsinline preload="auto" disablepictureinpicture disableremoteplayback></video>' +
      '<img class="nj-anuncio-imagen" src="' + Ruta(Anuncio, 'png') + '" alt="' + Nombreesc + ': ' + Lemaesc + '" hidden>' +
      '<div class="nj-anuncio-barra"><span>PUBLICIDAD · ' + Nombreesc.toUpperCase() + '</span>' +
      '<button type="button" class="nj-anuncio-cerrar" disabled></button></div>' +
      (Enlaceseguro
        ? '<a class="nj-anuncio-accion" href="' + Enlaceseguro + '" target="_blank" rel="noopener" data-anuncio="' + Anuncio.Clave + '" style="background:' + Anuncio.Color + ';color:' + Anuncio.Tinta + '">' +
          '<span>' + Nombreesc + '</span><span>' + Botonesc + ' →</span></a>'
        : '');

    var Sesion = {
      Capa: Capa, Video: Capa.querySelector('video'), Imagen: Capa.querySelector('img'), Cerrar: Capa.querySelector('button'),
      Bonificado: Opciones.Tipo === 'bonificado', Alterminar: Opciones.Alterminar,
      Duracion: 15, Visto: 0, Quieto: 0, Ultimo: Date.now(), Imagenmodo: false, Pausado: false, Cerrable: null, Texto: ''
    };
    Sesion.Video.muted = !!Opciones.Silencio;
    Sesion.Video.addEventListener('loadedmetadata', function () {
      var Duracion = Sesion.Video.duration;
      if (isFinite(Duracion) && Duracion > 0) Sesion.Duracion = Math.min(Duracion, 30);
    });
    Sesion.Video.addEventListener('ended', function () { Terminar(Sesion, true); });
    Sesion.Video.addEventListener('error', function () { Pasaraimagen(Sesion); });
    Sesion.Cerrar.addEventListener('click', function () { if (Sesion.Cerrable) Terminar(Sesion, false); });

    Abierto = Sesion;
    Escenario.appendChild(Capa);
    if (Nj.Audio) Nj.Audio.Pausar();
    Pintarcontador(Sesion);
    Sesion.Reloj = setInterval(function () { Tic(Sesion); }, 250);
    Reproducir(Sesion);
    return true;
  }

  function Reproducir(Sesion) {
    var Promesa;
    try { Promesa = Sesion.Video.play(); } catch (Fallo) { Pasaraimagen(Sesion); return; }
    if (!Promesa || !Promesa.catch) return;
    Promesa.catch(function () {
      if (Abierto !== Sesion || Sesion.Pausado || Sesion.Imagenmodo) return;
      // Si no lo dejan sonar sin un toque, sigue en silencio; si ni así arranca, queda la imagen
      if (!Sesion.Video.muted) { Sesion.Video.muted = true; Reproducir(Sesion); } else Pasaraimagen(Sesion);
    });
  }

  function Pasaraimagen(Sesion) {
    if (Abierto !== Sesion || Sesion.Imagenmodo) return;
    Sesion.Imagenmodo = true;
    Sesion.Visto = 0;
    try { Sesion.Video.pause(); } catch (Fallo) { /* ya estaba quieto */ }
    Sesion.Video.hidden = true;
    Sesion.Imagen.hidden = false;
  }

  function Total(Sesion) { return Sesion.Imagenmodo ? Duracionimagen : Sesion.Duracion; }

  // El tiempo cuenta lo que se ha visto del video, no el reloj: si se pausa o se traba, no avanza
  function Tic(Sesion) {
    if (Abierto !== Sesion || Sesion.Pausado) return;
    var Ahora = Date.now(), Paso = Math.min((Ahora - Sesion.Ultimo) / 1000, 1);
    Sesion.Ultimo = Ahora;
    if (Sesion.Imagenmodo) {
      Sesion.Visto += Paso;
    } else {
      var Tiempo = Sesion.Video.currentTime || 0;
      if (Tiempo > Sesion.Visto) { Sesion.Visto = Tiempo; Sesion.Quieto = 0; }
      else if ((Sesion.Quieto += Paso) >= 5) Pasaraimagen(Sesion); // 5 s sin avanzar: el video no va a arrancar
    }
    if (Sesion.Visto >= Total(Sesion)) { Terminar(Sesion, true); return; }
    Pintarcontador(Sesion);
  }

  function Pintarcontador(Sesion) {
    var Fin = Total(Sesion), Texto, Cerrable = false;
    if (Sesion.Bonificado) {
      Texto = 'REVIVES EN ' + Math.max(1, Math.ceil(Fin - Sesion.Visto)) + ' s';
    } else {
      var Espera = Math.min(Cerrarintersticial, Fin) - Sesion.Visto;
      Cerrable = Espera <= 0;
      Texto = Cerrable ? 'CERRAR ✕' : 'CERRAR EN ' + Math.ceil(Espera) + ' s';
    }
    if (Texto !== Sesion.Texto) { Sesion.Texto = Texto; Sesion.Cerrar.textContent = Texto; }
    if (Cerrable !== Sesion.Cerrable) {
      Sesion.Cerrable = Cerrable;
      Sesion.Cerrar.disabled = !Cerrable;
      if (Cerrable) Sesion.Cerrar.setAttribute('aria-label', 'Cerrar anuncio');
      else Sesion.Cerrar.removeAttribute('aria-label');
    }
  }

  function Terminar(Sesion, Completo) {
    if (Abierto !== Sesion) return;
    Abierto = null;
    clearInterval(Sesion.Reloj);
    try { Sesion.Video.pause(); Sesion.Video.removeAttribute('src'); Sesion.Video.load(); } catch (Fallo) { /* sin video que soltar */ }
    if (Sesion.Capa.parentNode) Sesion.Capa.parentNode.removeChild(Sesion.Capa);
    if (Nj.Audio) Nj.Audio.Reanudar();
    if (Sesion.Alterminar) Sesion.Alterminar(!!Completo);
  }

  Nj.Anuncios = {
    Banner: Banner,
    Mostrar: Mostrar,
    Abierto: function () { return !!Abierto; },
    /* La app se fue a segundo plano (por ejemplo, abrió el enlace del anuncio) */
    Pausar: function () {
      var Sesion = Abierto;
      if (!Sesion || Sesion.Pausado) return;
      Sesion.Pausado = true;
      try { Sesion.Video.pause(); } catch (Fallo) { /* ya estaba quieto */ }
    },
    Reanudar: function () {
      var Sesion = Abierto;
      if (!Sesion || !Sesion.Pausado) return;
      Sesion.Pausado = false;
      Sesion.Ultimo = Date.now();
      if (!Sesion.Imagenmodo) Reproducir(Sesion);
    },
    /* Botón atrás: el intersticial se cierra cuando ya se puede; el de revivir hay que verlo completo */
    Atras: function () {
      var Sesion = Abierto;
      if (Sesion && Sesion.Cerrable) Terminar(Sesion, false);
      return !!Sesion;
    }
  };
})();
