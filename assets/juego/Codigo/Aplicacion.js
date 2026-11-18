/* Controlador principal de la aplicación, estado, bucle y entrada */
(function () {
  var Nj = window.Neonjump, Clavealmacen = 'neonjump.estado.v2';
  // Con ?zona=espacio en la dirección la partida arranca a esa altura (sirve para revisar el fondo)
  var Bases = { Suelo: 0, Globos: 100, Avionetas: 320, Comerciales: 580, Militares: 880, Estratosfera: 1180, Orbita: 1580, Espacio: 2050, Profundo: 3050 };
  var Zonapedida = new URLSearchParams(location.search).get('zona') || '';
  var Clavezona = Zonapedida.charAt(0).toUpperCase() + Zonapedida.slice(1).toLowerCase();
  var Base = Object.prototype.hasOwnProperty.call(Bases, Clavezona) ? Bases[Clavezona] : 0;
  var Raiz = document.getElementById('nj-app'), Capa = document.getElementById('nj-capa'), Escenario = document.getElementById('nj-escenario');
  var Estado = Cargar(), Partida = null, Entrada = { Izquierda: false, Derecha: false, ObjetivoX: null, Punteroid: null, Ultimax: 0 };
  var Avisos = [], Relojaviso = null, Relojanuncio = null, Relojfin = null, Logrospartida = [], Revision = 0, Ultimo = 0;
  var Refs = null, Montada = '', Escala = 1, Bucleactivo = false;

  function Cargar() {
    var Nuevo = Nj.Estadoinicial();
    try {
      var Guardado = Nj.Puente ? Nj.Puente.Estadoguardado() : JSON.parse(localStorage.getItem(Clavealmacen) || 'null');
      if (Guardado && typeof Guardado === 'object') Object.assign(Nuevo, Guardado);
      // En modo web aplica validación local (en Android lo valida el puente)
      if (!Nj.Puente && Nj.Sanearestado) Nuevo = Nj.Sanearestado(Nuevo);
    } catch (Fallo) { /* sin almacenamiento se queda con los datos de ejemplo */ }
    var Pedirregistro = Nj.Necesitaregistro && Nj.Necesitaregistro(Nuevo);
    if (Pedirregistro && Nj.Pantallas.Bienvenida) Nj.Pantallas.Bienvenida.Reiniciar(Nuevo.Nombre);
    Nuevo.Pantalla = Pedirregistro ? 'Bienvenida' : 'Menu';
    Nuevo.Aviso = null; Nuevo.Anuncio = 0; Nuevo.Resultado = null; Nuevo.Ayuda = false; Nuevo.Avisorespaldo = false;
    return Nuevo;
  }
  function Guardar() {
    try {
      var Copia = Object.assign({}, Estado);
      // Esto es de la sesión, no tiene sentido guardarlo
      ['Pantalla', 'Aviso', 'Anuncio', 'Resultado', 'Ayuda', 'Avisorespaldo'].forEach(function (Clave) { delete Copia[Clave]; });
      if (Nj.Puente) { Nj.Puente.Guardar(Copia); return; } // en la app lo guarda Flutter cifrado
      localStorage.setItem(Clavealmacen, JSON.stringify(Copia));
    } catch (Fallo) { /* modo privado o almacenamiento bloqueado */ }
  }

  function App() { return { Estado: Estado, Juego: Partida && Estado.Pantalla === 'Juego' ? Nj.Vistapartida(Partida) : null }; }

  function Dibujar() {
    var Pantalla = Nj.Espantallavalida && Nj.Espantallavalida(Estado.Pantalla) ? Estado.Pantalla : 'Menu';
    Estado.Pantalla = Pantalla;
    if (Pantalla === 'Juego') {
      // La pantalla de juego se arma una vez; después solo se actualiza
      if (Montada !== 'Juego') { Refs = Nj.Pantallas.Juego.Montar(Raiz, App()); Conectarzonas(Refs); Montada = 'Juego'; }
      Nj.Pantallas.Juego.Actualizar(Refs, App());
      if (!Bucleactivo) { Bucleactivo = true; Ultimo = 0; requestAnimationFrame(Bucle); }
    } else {
      Raiz.innerHTML = Nj.Pantallas[Pantalla].Render(App());
      Montada = Pantalla; Refs = null;
    }
    var Capahtml = Estado.Anuncio > 0
      ? Nj.Pantallas.Anuncio(Estado.Anuncio)
      : Estado.Ayuda && Nj.Pantallas.Ayuda
        ? Nj.Pantallas.Ayuda(Estado)
        : (Pantalla === 'Menu' && Estado.Avisorespaldo && Nj.Pantallas.Avisorespaldo ? Nj.Pantallas.Avisorespaldo() : '');
    if (Capa.Ultimovalor !== Capahtml) { Capa.innerHTML = Capahtml; Capa.Ultimovalor = Capahtml; }
    if (window.innerWidth <= 500) {
      if (Pantalla === 'Menu' || Pantalla === 'Bienvenida') document.body.style.background = 'linear-gradient(180deg, #1B1840 0%, #2B2457 60%, #3D3068 100%)';
      else if (Pantalla === 'Resultados') document.body.style.background = 'linear-gradient(180deg, #1B1840 0%, #231E4A 100%)';
      else if (Pantalla !== 'Juego') document.body.style.background = '#16132E';
    }
    if (Nj.Audio) Nj.Audio.Sincronizar(Estado);
    if (Nj.Puente) Nj.Puente.Alrender(Pantalla);
  }
  function Cambiar(Hacer) { Hacer(Estado); Guardar(); Dibujar(); }

  // El perfil más lo que va de la partida, para revisar los logros en vivo
  function Estadoconpartida() {
    var Compromiso = Partida.Compromiso || { Recogidas: 0, Resorte: 0 };
    return Object.assign({}, Estado, {
      Mejor: Math.max(Estado.Mejor, Partida.Puntaje),
      Monedastotales: Estado.Monedastotales + Partida.Recogidas - Compromiso.Recogidas,
      Mejormonedaspartida: Math.max(Estado.Mejormonedaspartida, Partida.Recogidas),
      Resortetotal: Estado.Resortetotal + Partida.Rebotes.Resorte - Compromiso.Resorte,
      Movilmax: Math.max(Estado.Movilmax, Partida.Rebotes.Movil),
      Fragilmax: Math.max(Estado.Fragilmax, Partida.Rebotes.Fragil),
      Revividasmax: Math.max(Estado.Revividasmax, Partida.Revividas)
    });
  }

  function Revisarlogros(Fuente) {
    var Nuevos = Nj.Logrosnuevos(Fuente || (Partida ? Estadoconpartida() : Estado));
    if (!Nuevos.length) return;
    if (Partida) Logrospartida = Logrospartida.concat(Nuevos);
    Cambiar(function (Cambio) { Nuevos.forEach(function (Logro) { Cambio.Logros = Cambio.Logros.concat(Logro.Id); Cambio.Monedas += Logro.Premio; }); });
    Nuevos.forEach(function (Logro) { Avisos.push({ Titulo: Logro.Titulo, Premio: Logro.Premio }); });
    Siguienteaviso();
  }

  // Los avisos de logro salen de a uno, cada uno dura 2,6 segundos
  function Siguienteaviso() {
    if (Relojaviso || !Avisos.length) return;
    var Aviso = Avisos.shift();
    Cambiar(function (Cambio) { Cambio.Aviso = Aviso; });
    Relojaviso = setTimeout(function () {
      Relojaviso = null;
      Cambiar(function (Cambio) { Cambio.Aviso = null; });
      setTimeout(Siguienteaviso, 120);
    }, 2600);
  }

  function Confirmarparcial(Actual) {
    if (!Actual) return;
    var Compromiso = Actual.Compromiso || { Recogidas: 0, Resorte: 0, Tiempo: 0 };
    var Nuevas = Math.max(0, Actual.Recogidas - Compromiso.Recogidas);
    var Nuevosres = Math.max(0, Actual.Rebotes.Resorte - Compromiso.Resorte);
    var Nuevotiempo = Math.max(0, Actual.Tiempo - Compromiso.Tiempo);
    if (!Nuevas && !Nuevosres && !Nuevotiempo && Actual.Puntaje <= Estado.Mejor &&
        Actual.Recogidas <= Estado.Mejormonedaspartida && Actual.Rebotes.Movil <= Estado.Movilmax &&
        Actual.Rebotes.Fragil <= Estado.Fragilmax) return;
    Estado.Monedas += Nuevas;
    Estado.Monedastotales += Nuevas;
    Estado.Resortetotal += Nuevosres;
    Estado.Segundosjugados += Nuevotiempo;
    Estado.Mejor = Math.max(Estado.Mejor, Actual.Puntaje);
    Estado.Mejormonedaspartida = Math.max(Estado.Mejormonedaspartida, Actual.Recogidas);
    Estado.Movilmax = Math.max(Estado.Movilmax, Actual.Rebotes.Movil);
    Estado.Fragilmax = Math.max(Estado.Fragilmax, Actual.Rebotes.Fragil);
    Actual.Compromiso = { Recogidas: Actual.Recogidas, Resorte: Actual.Rebotes.Resorte, Tiempo: Actual.Tiempo };
    Guardar();
  }

  function Alcaer() {
    var Actual = Partida;
    Revisarlogros();
    // Compromiso: lo que ya se sumó al perfil antes de revivir, para no contarlo dos veces
    var Compromiso = Actual.Compromiso || { Recogidas: 0, Resorte: 0, Tiempo: 0 }, Mejorantes = Estado.Mejor;
    Cambiar(function (Cambio) {
      var Nuevas = Actual.Recogidas - Compromiso.Recogidas;
      Cambio.Monedas += Nuevas; Cambio.Monedastotales += Nuevas;
      Cambio.Resortetotal += Actual.Rebotes.Resorte - Compromiso.Resorte;
      Cambio.Segundosjugados += Actual.Tiempo - Compromiso.Tiempo;
      Cambio.Caidas += 1;
      Cambio.Mejor = Math.max(Cambio.Mejor, Actual.Puntaje);
      Cambio.Mejormonedaspartida = Math.max(Cambio.Mejormonedaspartida, Actual.Recogidas);
      Cambio.Movilmax = Math.max(Cambio.Movilmax, Actual.Rebotes.Movil);
      Cambio.Fragilmax = Math.max(Cambio.Fragilmax, Actual.Rebotes.Fragil);
      var Reto = Object.assign({}, Cambio.Reto), Retohecho = false;
      if (!Reto.Hecho) {
        Reto.Progreso = Math.max(Reto.Progreso, Actual.Rebotes[Reto.Clave] || 0);
        if (Reto.Progreso >= Reto.Meta) { Reto.Hecho = true; Retohecho = true; Cambio.Monedas += Reto.Premio; }
      }
      Cambio.Reto = Reto;
      Cambio.Resultado = {
        Puntaje: Actual.Puntaje, Mejoranterior: Mejorantes, Nuevorecord: Actual.Puntaje > Mejorantes, Monedas: Actual.Recogidas,
        Segundos: Actual.Tiempo, Alturam: (Actual.Maxaltura + Actual.Base) / 10, Rebotes: Object.assign({}, Actual.Rebotes), Revividas: Actual.Revividas,
        Logrosnuevos: Logrospartida.map(function (Logro) { return { Titulo: Logro.Titulo, Premio: Logro.Premio }; }),
        Posicion: Nj.Ranking.filter(function (Fila) { return Fila.Puntaje > Actual.Puntaje; }).length + 1, Retohecho: Retohecho
      };
    });
    Actual.Compromiso = { Recogidas: Actual.Recogidas, Resorte: Actual.Rebotes.Resorte, Tiempo: Actual.Tiempo };
    if (Nj.Puente) Nj.Puente.Alcaer(Estado.Resultado);
    // Se deja ver el sello de "Caída" un momento antes de pasar a resultados
    Relojfin = setTimeout(function () { Cambiar(function (Cambio) { Cambio.Pantalla = 'Resultados'; }); }, 700);
  }

  function Revivirahora() {
    Nj.Revivir(Partida);
    Cambiar(function (Cambio) { Cambio.Pantalla = 'Juego'; Cambio.Anuncio = 0; Cambio.Revivestotales += 1; });
    Revisarlogros();
  }

  var Apibienvenida = {
    Dibujar: Dibujar,
    Entrarmenu: function (Nombre, Conaviso) {
      Cambiar(function (Cambio) {
        if (Nombre) Cambio.Nombre = Nombre;
        Cambio.Avisorespaldo = !!Conaviso;
        Cambio.Pantalla = 'Menu';
      });
    }
  };

  // Cada botón tiene data-accion con el nombre de una de estas, y data-valor con lo que recibe
  var Acciones = {
    Ir: function (Pantalla) {
      if (Nj.Espantallavalida && !Nj.Espantallavalida(Pantalla)) return;
      Cambiar(function (Cambio) { Cambio.Pantalla = Pantalla; });
    },
    Jugar: function () {
      clearTimeout(Relojfin);
      if (Nj.Audio) Nj.Audio.Iniciar();
      Partida = Nj.Crearpartida(0, Base); Logrospartida = [];
      Entrada = { Izquierda: false, Derecha: false, ObjetivoX: null, Punteroid: null, Ultimax: 0 };
      Montada = '';
      Cambiar(function (Cambio) { Cambio.Pantalla = 'Juego'; Cambio.Partidas += 1; Cambio.Resultado = null; });
    },
    Empezar: function () { if (Partida && Partida.Estado === 'espera') { Partida.Estado = 'jugando'; Ultimo = 0; if (!Bucleactivo) { Bucleactivo = true; requestAnimationFrame(Bucle); } } },
    Pausar: function () { if (Partida && Partida.Estado === 'jugando') { Confirmarparcial(Partida); Partida.Estado = 'pausa'; Dibujar(); } },
    Continuar: function () { if (Partida && Partida.Estado === 'pausa') { Partida.Estado = 'jugando'; Ultimo = 0; Dibujar(); } },
    Reiniciar: function () { Confirmarparcial(Partida); Acciones.Jugar(); },
    Menu: function () { clearTimeout(Relojfin); Confirmarparcial(Partida); Partida = null; Cambiar(function (Cambio) { Cambio.Pantalla = 'Menu'; Cambio.Aviso = null; }); },
    Revivirmonedas: function () {
      if (Estado.Monedas < 100) return;
      Cambiar(function (Cambio) { Cambio.Monedas -= 100; });
      Revivirahora();
    },
    // Respaldo de temporizador fuera de entorno nativo
    Reviviranuncio: function () {
      Cambiar(function (Cambio) { Cambio.Anuncio = 3; });
      clearInterval(Relojanuncio);
      Relojanuncio = setInterval(function () {
        if (Estado.Anuncio <= 1) { clearInterval(Relojanuncio); Revivirahora(); return; }
        Cambiar(function (Cambio) { Cambio.Anuncio -= 1; });
      }, 1000);
    },
    Seleccionarskin: function (Id) { Cambiar(function (Cambio) { Cambio.Tiendasel = Number(Id); }); },
    Tiendacat: function (Categoria) {
      var Primera = Nj.Skins.filter(function (Skin) { return Skin.Categoria === Categoria; })[0].Id;
      Cambiar(function (Cambio) { Cambio.Tiendacat = Categoria; Cambio.Tiendasel = Primera; });
    },
    Accionskin: function (Id) {
      Id = Number(Id);
      var Skin = Nj.Skins[Id];
      if (Estado.Skins.indexOf(Id) >= 0) { Cambiar(function (Cambio) { Cambio.Equipada = Id; }); return; }
      if (Estado.Monedas < Skin.Precio) return;
      Cambiar(function (Cambio) { Cambio.Monedas -= Skin.Precio; Cambio.Skins = Cambio.Skins.concat(Id); Cambio.Equipada = Id; });
      Revisarlogros(Estado);
    },
    Rankingtab: function (Pestana) {
      if (Pestana !== 'global' && Pestana !== 'semana') return;
      Cambiar(function (Cambio) { Cambio.Rankingtab = Pestana; });
    },
    Alternar: function (Clave) {
      if (Nj.Esalternablevalido && !Nj.Esalternablevalido(Clave)) return;
      Cambiar(function (Cambio) { Cambio[Clave] = !Cambio[Clave]; });
    },
    Silenciartodo: function () {
      var Activo = !!(Estado.Sonido || Estado.Musica);
      Cambiar(function (Cambio) { Cambio.Sonido = !Activo; Cambio.Musica = !Activo; });
      if (!Activo && Nj.Audio) Nj.Audio.Iniciar();
    },
    Ayuda: function () {
      Estado.Ayuda = true;
      Dibujar();
      var Campo = document.getElementById('nj-ayuda-tipo') || document.getElementById('nj-ayuda-nom');
      if (Campo) Campo.focus();
    },
    Cerrarayuda: function () { Estado.Ayuda = false; Dibujar(); },
    Enviarayuda: function () { if (Nj.Pantallas.Ayuda && Nj.Pantallas.Ayuda.Enviar) Nj.Pantallas.Ayuda.Enviar(Estado); },
    Vincularbienvenida: function () { if (Nj.Pantallas.Bienvenida) Nj.Pantallas.Bienvenida.Vincular(Apibienvenida); },
    Continuarsinvinculo: function () { if (Nj.Pantallas.Bienvenida) Nj.Pantallas.Bienvenida.Continuar(Apibienvenida); },
    Cancelarriesgo: function () { if (Nj.Pantallas.Bienvenida) Nj.Pantallas.Bienvenida.Cancelarriesgo(Apibienvenida); },
    Confirmarriesgo: function () { if (Nj.Pantallas.Bienvenida) Nj.Pantallas.Bienvenida.Confirmarriesgo(Apibienvenida); },
    Cerraravisorespaldo: function () { Estado.Avisorespaldo = false; Dibujar(); },
    Iraperfilrespaldo: function () { Estado.Avisorespaldo = false; Acciones.Ir('Perfil'); }
  };

  function Bucle(Tiempo) {
    if (!Partida || Estado.Pantalla !== 'Juego' || Partida.Estado === 'pausa') { Bucleactivo = false; Ultimo = 0; return; }
    var Delta = Ultimo ? (Tiempo - Ultimo) / 1000 : 0;
    Ultimo = Tiempo;
    if (Delta > 0) {
      var Eventos = Nj.Paso(Partida, Delta, {
        Izquierda: Entrada.Izquierda, Derecha: Entrada.Derecha,
        ObjetivoX: Entrada.ObjetivoX, Sensibilidad: Estado.Sensibilidad
      });
      if (Eventos.length) {
        for (var Ev = 0; Ev < Eventos.length; Ev++) {
          if (Eventos[Ev].Tipo === 'moneda') { Confirmarparcial(Partida); break; }
        }
        if (Nj.Puente) {
          Nj.Puente.Eventos(Eventos);
        } else if (Nj.Audio) {
          for (var Numero = 0; Numero < Eventos.length; Numero++) {
            if (Eventos[Numero].Tipo === 'rebote') Nj.Audio.Rebote(Eventos[Numero].Plataforma, Estado.Sonido);
            else if (Eventos[Numero].Tipo === 'moneda') Nj.Audio.Moneda(Estado.Sonido);
          }
        }
      }
      // Los logros se revisan unas tres veces por segundo, no en cada cuadro
      Revision += Delta;
      if (Revision > 0.3 && Partida.Estado === 'jugando') { Revision = 0; Revisarlogros(); }
      for (var Indice = 0; Indice < Eventos.length; Indice++) if (Eventos[Indice].Tipo === 'caida') Alcaer();
      if (Refs && Estado.Pantalla === 'Juego') Nj.Pantallas.Juego.Actualizar(Refs, App());
    }
    if (Estado.Pantalla === 'Juego') requestAnimationFrame(Bucle);
    else Bucleactivo = false;
  }

  // Arrastrar horizontalmente en cualquier parte mueve la bola de forma continua y precisa
  function Conectarzonas(Zonas) {
    var Zona = Zonas.Tactil;
    if (!Zona) return;
    function Soltar(Evento) {
      if (Entrada.Punteroid !== null && Evento.pointerId !== Entrada.Punteroid) return;
      Entrada.Punteroid = null;
      Entrada.ObjetivoX = null;
      if (Partida) Partida.Jugador.Vx = 0;
    }
    Zona.addEventListener('pointerdown', function (Evento) {
      if (Nj.Audio) Nj.Audio.Iniciar();
      if (Partida && Partida.Estado === 'espera') Acciones.Empezar();
      if (!Partida || Partida.Estado !== 'jugando') return;
      Entrada.Punteroid = Evento.pointerId;
      Entrada.Ultimax = Evento.clientX;
      Entrada.ObjetivoX = Partida.Jugador.X;
      try { Zona.setPointerCapture(Evento.pointerId); } catch (Fallo) { /* sin captura igual funciona */ }
    });
    Zona.addEventListener('pointermove', function (Evento) {
      if (Entrada.Punteroid !== Evento.pointerId || Entrada.ObjetivoX === null || !Partida || Partida.Estado !== 'jugando') return;
      var Factor = 0.75 + ((Estado.Sensibilidad != null ? Estado.Sensibilidad : 70) / 100) * 0.6;
      var Desplazamiento = ((Evento.clientX - Entrada.Ultimax) / (Escala || 1)) * Factor;
      Entrada.Ultimax = Evento.clientX;
      Entrada.ObjetivoX = Math.max(15, Math.min(375, Entrada.ObjetivoX + Desplazamiento));
    }, { passive: true });
    ['pointerup', 'pointercancel', 'lostpointercapture'].forEach(function (Nombre) {
      Zona.addEventListener(Nombre, Soltar);
    });
  }

  document.addEventListener('click', function (Evento) {
    var Boton = Evento.target.closest('[data-accion]');
    if (Boton) {
      Evento.preventDefault();
      var Accion = Acciones[Boton.dataset.accion];
      if (Accion) Accion(Boton.dataset.valor);
      return;
    }
    if (Estado.Pantalla === 'Juego' && Evento.target.closest('[data-juego]')) Acciones.Empezar();
  });

  // El formulario de ayuda se maneja con botones; Enter no debe recargar la página
  document.addEventListener('submit', function (Evento) { Evento.preventDefault(); });

  function Tecla(Presionada) {
    return function (Evento) {
      if (Presionada && Evento.key === 'Escape' && Estado.Ayuda) { Acciones.Cerrarayuda(); return; }
      if (Presionada && Evento.key === 'Enter' && Estado.Pantalla === 'Bienvenida' && Evento.target && Evento.target.id === 'nj-bienvenida-nombre') {
        Evento.preventDefault(); Acciones.Continuarsinvinculo(); return;
      }
      if (Estado.Pantalla !== 'Juego' || Estado.Anuncio > 0) return;
      var Clave = Evento.key;
      if (Clave === 'ArrowLeft' || Clave === 'a' || Clave === 'A') { Entrada.Izquierda = Presionada; Evento.preventDefault(); }
      if (Clave === 'ArrowRight' || Clave === 'd' || Clave === 'D') { Entrada.Derecha = Presionada; Evento.preventDefault(); }
      if (Presionada && (Clave === ' ' || Clave === 'Enter') && !Evento.target.closest('button')) { Evento.preventDefault(); Acciones.Empezar(); }
      if (Presionada && (Clave === 'Escape' || Clave === 'p' || Clave === 'P')) Acciones.Pausar();
    };
  }
  document.addEventListener('keydown', Tecla(true));
  document.addEventListener('keyup', Tecla(false));

  function Validarayudacampo(Campo) {
    if (Campo && Campo.dataset && Campo.dataset.ayuda && Nj.Pantallas.Ayuda && Nj.Pantallas.Ayuda.Validar) {
      Nj.Pantallas.Ayuda.Validar();
    }
  }

  // Los campos del perfil se guardan sin redibujar, si no se pierde el foco mientras se escribe
  document.addEventListener('input', function (Evento) {
    var Campo = Evento.target, Tipo = Campo.dataset && Campo.dataset.entrada;
    if (Tipo === 'bienvenida' && Nj.Pantallas.Bienvenida) {
      Nj.Pantallas.Bienvenida.Alescribir(Campo.value);
    }
    if (Tipo === 'nombre') {
      Estado.Nombre = Campo.value.slice(0, 20); Guardar();
      var Ayuda = document.getElementById('nj-ayuda-nombre');
      if (Ayuda) Ayuda.textContent = Nj.Pantallas.Perfil.Textoayuda(Estado.Nombre);
    }
    if (Tipo === 'sensibilidad') {
      Estado.Sensibilidad = Number(Campo.value); Guardar();
      var Valor = document.getElementById('nj-sens-valor');
      if (Valor) Valor.textContent = Campo.value;
    }
    Validarayudacampo(Campo);
  });
  document.addEventListener('change', function (Evento) { Validarayudacampo(Evento.target); });

  // La app mide 390 × 844 y se escala para que quepa completa en cualquier pantalla
  function Ajustar() {
    Escala = Math.min(1.6, Math.min(window.innerWidth / 390, window.innerHeight / 844));
    Escenario.style.transform = 'scale(' + Escala + ') translateZ(0)';
  }
  window.addEventListener('resize', Ajustar);
  Ajustar();
  function Arrancar() { Estado = Cargar(); Dibujar(); }
  // Dentro de la app se espera a que Flutter mande los datos reales antes de dibujar
  if (Nj.Puente) {
    Nj.Puente.Conectar({
      Acciones: Acciones, Cambiar: Cambiar, Dibujar: Dibujar, Revivirahora: Revivirahora,
      Estado: function () { return Estado; }, Partida: function () { return Partida; },
      Reemplazar: function (Nuevo) {
        if (Nj.Necesitaregistro && Nj.Necesitaregistro(Nuevo) && Nj.Pantallas.Bienvenida) {
          Nj.Pantallas.Bienvenida.Reiniciar(Nuevo.Nombre);
          Nuevo.Pantalla = 'Bienvenida';
        }
        Estado = Nuevo; Guardar(); Dibujar();
      }
    }, Arrancar);
  } else Arrancar();
})();
