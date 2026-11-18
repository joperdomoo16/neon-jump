/* Síntesis de audio y música de fondo con Web Audio API */
(function () {
  var Nj = (window.Neonjump = window.Neonjump || {});

  var Contexto = null;
  var Gananciaefectos = null;
  var Gananciamusica = null;
  var Musicasonando = false;
  var Intervalomusica = null;
  var Vocesacorde = [];
  var Pasoacorde = 0;
  var Musicaactiva = true;
  var Sonidoactivo = true;

  // La vuelta de acordes: La menor, Fa, Do, Sol (en octava audible en altavoces de celular)
  var Acordes = [
    [220.0, 261.63, 329.63],
    [174.61, 220.0, 261.63],
    [261.63, 329.63, 392.0],
    [196.0, 246.94, 293.66]
  ];
  var Notasarpegio = [440.0, 523.25, 587.33, 659.25, 783.99, 880.0];

  function Obtenercontexto() {
    if (!Contexto) {
      var Constructor = window.AudioContext || window.webkitAudioContext;
      if (!Constructor) return null;
      try {
        Contexto = new Constructor();
        Gananciaefectos = Contexto.createGain();
        Gananciaefectos.gain.value = Sonidoactivo ? 1.0 : 0;
        Gananciaefectos.connect(Contexto.destination);

        Gananciamusica = Contexto.createGain();
        Gananciamusica.gain.value = 0; // arranca en silencio y sube suave al iniciar
        Gananciamusica.connect(Contexto.destination);
      } catch (Fallo) {
        Contexto = null;
      }
    }
    if (Contexto && Contexto.state === 'suspended') {
      Contexto.resume().then(function () {
        if (Musicaactiva && !Musicasonando) Iniciarmusica();
      }).catch(function () {});
    }
    return Contexto;
  }

  // El navegador no deja sonar nada hasta que la persona toque la pantalla por primera vez
  function Desbloquear() {
    if (Contexto && Contexto.state === 'running' && (!Musicaactiva || Musicasonando)) return;
    Obtenercontexto();
  }
  window.addEventListener('pointerdown', Desbloquear, { passive: true });
  window.addEventListener('touchstart', Desbloquear, { passive: true });
  window.addEventListener('keydown', Desbloquear, { passive: true });

  /* Rebote: un tono cálido y definido para altavoces de celular */
  function Reproducirrebote(Tipo, Activo) {
    if (Activo === false || !Sonidoactivo) return;
    var Motor = Obtenercontexto();
    if (!Motor) return;
    if (Motor.state === 'suspended') {
      Motor.resume().then(function () { Reproducirrebote(Tipo, Activo); }).catch(function () {});
      return;
    }

    var Ahora = Motor.currentTime;
    var Oscilador = Motor.createOscillator();
    var Volumen = Motor.createGain();
    var Filtro = Motor.createBiquadFilter();

    Filtro.type = 'lowpass';
    Filtro.frequency.setValueAtTime(1500, Ahora);
    Oscilador.type = 'sine';

    var Inicio = 360, Fin = 185, Duracion = 0.095, Nivel = 0.34;

    if (Tipo === 'Resorte') {
      Inicio = 380; Fin = 820; Duracion = 0.14; Nivel = 0.38;
      Filtro.frequency.setValueAtTime(2200, Ahora);
    } else if (Tipo === 'Fragil') {
      Inicio = 340; Fin = 135; Duracion = 0.07; Nivel = 0.30;
      Filtro.frequency.setValueAtTime(1400, Ahora);
    } else if (Tipo === 'Movil') {
      Inicio = 380; Fin = 195; Duracion = 0.095; Nivel = 0.34;
    } else if (Tipo === 'Suelo') {
      Inicio = 310; Fin = 155; Duracion = 0.095; Nivel = 0.32;
      Filtro.frequency.setValueAtTime(1300, Ahora);
    }

    Oscilador.frequency.setValueAtTime(Inicio, Ahora);
    Oscilador.frequency.exponentialRampToValueAtTime(Math.max(20, Fin), Ahora + Duracion);

    Volumen.gain.setValueAtTime(Nivel, Ahora);
    Volumen.gain.exponentialRampToValueAtTime(0.0001, Ahora + Duracion);

    Oscilador.connect(Filtro);
    Filtro.connect(Volumen);
    Volumen.connect(Gananciaefectos);

    Oscilador.onended = function () {
      try { Oscilador.disconnect(); Filtro.disconnect(); Volumen.disconnect(); } catch (Fallo) {}
    };
    Oscilador.start(Ahora);
    Oscilador.stop(Ahora + Duracion + 0.01);
  }

  /* Moneda: dos notas cortitas, una detrás de la otra */
  function Reproducirmoneda(Activo) {
    if (Activo === false || !Sonidoactivo) return;
    var Motor = Obtenercontexto();
    if (!Motor) return;
    if (Motor.state === 'suspended') {
      Motor.resume().then(function () { Reproducirmoneda(Activo); }).catch(function () {});
      return;
    }

    var Ahora = Motor.currentTime;
    var Primera = Motor.createOscillator();
    var Segunda = Motor.createOscillator();
    var Volumen = Motor.createGain();

    Primera.type = 'sine';
    Segunda.type = 'sine';
    Primera.frequency.setValueAtTime(659.25, Ahora); // Mi
    Segunda.frequency.setValueAtTime(880.0, Ahora + 0.04); // La

    Volumen.gain.setValueAtTime(0.22, Ahora);
    Volumen.gain.exponentialRampToValueAtTime(0.0001, Ahora + 0.14);

    Primera.connect(Volumen);
    Segunda.connect(Volumen);
    Volumen.connect(Gananciaefectos);

    Segunda.onended = function () {
      try { Primera.disconnect(); Segunda.disconnect(); Volumen.disconnect(); } catch (Fallo) {}
    };
    Primera.start(Ahora);
    Primera.stop(Ahora + 0.05);
    Segunda.start(Ahora + 0.04);
    Segunda.stop(Ahora + 0.12);
  }

  /* Música de fondo */
  function Tocarnota(Frecuencia, Motor, Momento, Nivel) {
    var Oscilador = Motor.createOscillator();
    var Volumen = Motor.createGain();
    var Filtro = Motor.createBiquadFilter();

    Filtro.type = 'lowpass';
    Filtro.frequency.setValueAtTime(1800, Momento);
    Oscilador.type = 'sine';
    Oscilador.frequency.setValueAtTime(Frecuencia, Momento);

    Volumen.gain.setValueAtTime(0.0001, Momento);
    Volumen.gain.linearRampToValueAtTime(Nivel, Momento + 0.08);
    Volumen.gain.exponentialRampToValueAtTime(0.0001, Momento + 1.2);

    Oscilador.connect(Filtro);
    Filtro.connect(Volumen);
    Volumen.connect(Gananciamusica);

    Oscilador.onended = function () {
      try { Oscilador.disconnect(); Filtro.disconnect(); Volumen.disconnect(); } catch (Fallo) {}
    };
    Oscilador.start(Momento);
    Oscilador.stop(Momento + 1.25);
  }

  function Avanzarcompas() {
    var Motor = Obtenercontexto();
    if (!Motor || !Musicasonando || Motor.state !== 'running') return;

    var Ahora = Motor.currentTime;
    var Notas = Acordes[Pasoacorde % Acordes.length];
    Pasoacorde++;

    // El acorde anterior se apaga despacio mientras entra el nuevo
    for (var Indice = 0; Indice < Vocesacorde.length; Indice++) {
      try {
        Vocesacorde[Indice].Volumen.gain.setTargetAtTime(0.0001, Ahora, 0.8);
        Vocesacorde[Indice].Oscilador.stop(Ahora + 2.5);
      } catch (Fallo) {}
    }
    Vocesacorde = [];

    var Filtropad = Motor.createBiquadFilter();
    Filtropad.type = 'lowpass';
    Filtropad.frequency.setValueAtTime(1200, Ahora);

    for (var Numero = 0; Numero < Notas.length; Numero++) {
      var Oscilador = Motor.createOscillator();
      var Volumen = Motor.createGain();

      Oscilador.type = Numero === 0 ? 'sine' : 'triangle';
      Oscilador.frequency.setValueAtTime(Notas[Numero], Ahora);
      // Un poquito desafinado, como los sintetizadores viejos
      Oscilador.detune.setValueAtTime((Numero % 2 === 0 ? 3 : -3), Ahora);

      Volumen.gain.setValueAtTime(0.0001, Ahora);
      Volumen.gain.linearRampToValueAtTime(0.10, Ahora + 0.6);

      Oscilador.connect(Filtropad);
      Filtropad.connect(Volumen);
      Volumen.connect(Gananciamusica);

      (function (Osc, Vol, Fil, Ultimo) {
        Osc.onended = function () {
          try { Osc.disconnect(); Vol.disconnect(); if (Ultimo) Fil.disconnect(); } catch (Fallo) {}
        };
      })(Oscilador, Volumen, Filtropad, Numero === Notas.length - 1);
      Oscilador.start(Ahora);
      Vocesacorde.push({ Oscilador: Oscilador, Volumen: Volumen });
    }

    // Dos notas altas sueltas encima del acorde
    var Notauno = Notasarpegio[(Pasoacorde * 2) % Notasarpegio.length];
    var Notados = Notasarpegio[(Pasoacorde * 2 + 3) % Notasarpegio.length];
    Tocarnota(Notauno, Motor, Ahora + 0.4, 0.12);
    Tocarnota(Notados, Motor, Ahora + 1.8, 0.10);
  }

  function Iniciarmusica() {
    if (Musicasonando || !Musicaactiva) return;
    var Motor = Obtenercontexto();
    if (!Motor) return;
    if (Motor.state === 'suspended') {
      Motor.resume().then(function () {
        if (Musicaactiva && !Musicasonando) Iniciarmusica();
      }).catch(function () {});
      return;
    }

    Musicasonando = true;
    var Ahora = Motor.currentTime;
    Gananciamusica.gain.cancelScheduledValues(Ahora);
    Gananciamusica.gain.setTargetAtTime(0.28, Ahora, 0.35);

    Avanzarcompas();
    clearInterval(Intervalomusica);
    Intervalomusica = setInterval(Avanzarcompas, 3200); // cada acorde dura 3,2 segundos
  }

  function Pararmusica(Inmediato) {
    Musicasonando = false;
    clearInterval(Intervalomusica);
    Intervalomusica = null;

    if (Contexto) {
      var Ahora = Contexto.currentTime;
      for (var Indice = 0; Indice < Vocesacorde.length; Indice++) {
        try {
          Vocesacorde[Indice].Volumen.gain.cancelScheduledValues(Ahora);
          Vocesacorde[Indice].Volumen.gain.setTargetAtTime(0.0001, Ahora, 0.04);
          Vocesacorde[Indice].Oscilador.stop(Ahora + 0.12);
        } catch (Fallo) {}
      }
      Vocesacorde = [];
      if (Gananciamusica) {
        Gananciamusica.gain.cancelScheduledValues(Ahora);
        if (Inmediato) Gananciamusica.gain.setValueAtTime(0, Ahora);
        else Gananciamusica.gain.setTargetAtTime(0, Ahora, 0.08);
      }
    }
  }

  // Se llama en cada dibujo de pantalla para seguir lo que diga el perfil
  function Sincronizar(Estado) {
    if (!Estado) return;
    Sonidoactivo = Estado.Sonido !== false;
    var Quieremusica = Estado.Musica !== false;
    if (Sonidoactivo || Quieremusica) Obtenercontexto();

    if (Contexto && Gananciaefectos) {
      Gananciaefectos.gain.setTargetAtTime(Sonidoactivo ? 1.0 : 0, Contexto.currentTime, 0.015);
    }

    if (Musicaactiva !== Quieremusica) {
      Musicaactiva = Quieremusica;
      if (!Musicaactiva) Pararmusica(true);
      else Iniciarmusica();
    } else if (!Musicaactiva && Musicasonando) {
      Pararmusica(true);
    } else if (Musicaactiva && !Musicasonando && Contexto && Contexto.state === 'running') {
      Iniciarmusica();
    }
  }

  function Pausar() {
    Pararmusica(false);
  }

  function Reanudar() {
    Obtenercontexto();
    if (Musicaactiva) Iniciarmusica();
  }

  Nj.Audio = {
    Iniciar: Obtenercontexto,
    Rebote: Reproducirrebote,
    Moneda: Reproducirmoneda,
    Sincronizar: Sincronizar,
    Pausar: Pausar,
    Reanudar: Reanudar
  };
})();
