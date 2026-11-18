/* Renderizado de la vista de partida activa y HUD */
(function () {
  var Nj = window.Neonjump, Ui = Nj.Interfaz;
  var Mover = Ui.Mover;

  var Plataformas = {
    Normal: '<div style="width:78px;height:12px;border-radius:6px;background:var(--rosa);box-shadow:0 4px 0 var(--rosa-hondo)"></div>',
    Movil: '<div style="width:78px;height:12px;border-radius:6px;background:var(--amarillo);box-shadow:0 4px 0 #B0912F;display:flex;justify-content:space-between;align-items:center;padding:0 7px;font-family:var(--f-mono);font-size:11px;font-weight:700;line-height:1;color:var(--tinta-3)"><span>‹</span><span>›</span></div>',
    Fragil: '<div style="position:relative;width:78px;height:12px;border-radius:6px;background:#E06D5E;box-shadow:0 4px 0 #8F3930;overflow:hidden"><svg width="78" height="12" viewBox="0 0 78 12" style="display:block" fill="none"><path d="M18 0L23 5L19 12M38 0L34 5L41 8L37 12M59 0L55 6L61 12" stroke="#16132E" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/><path d="M20 0L25 5M40 0L36 5L43 8M61 0L57 6" stroke="#FFB8AD" stroke-width="1" opacity=".75"/><polygon points="35,0 41,0 38,4" fill="#16132E"/><polygon points="16,12 22,12 19,8" fill="#16132E"/><polygon points="58,12 64,12 61,8" fill="#16132E"/></svg></div>',
    Resorte: '<div style="position:relative;width:78px;height:12px;border-radius:6px;background:var(--verde);box-shadow:0 4px 0 #2F9A6C"><div style="position:absolute;left:18px;top:-4px;width:42px;height:6px;border-radius:4px 4px 2px 2px;background:#B9F6CA;border:1.5px solid #2F9A6C"></div><svg width="28" height="16" viewBox="0 0 28 16" style="position:absolute;left:25px;top:-16px" fill="none"><path d="M5 12L14 5L23 12" stroke="#5ED6A0" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/><path d="M8 7L14 2L20 7" stroke="#B9F6CA" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg></div>'
  };

  // Lo que va encima del juego: aviso de zona, logro, "toca para despegar", sello de caída y la pausa
  function Capas(Vista, Estado) {
    var Html = '';
    if (Vista.Avisozona) {
      Html += '<div class="nj-aviso" role="status" style="position:absolute;left:0;right:0;top:214px;display:flex;flex-direction:column;align-items:center;pointer-events:none">' +
        '<p style="margin:0;font-family:var(--f-mono);font-size:10px;letter-spacing:.24em;color:var(--acento)">NUEVA ZONA</p>' +
        '<p style="margin:2px 0 0 0;' + Ui.Fuente.Titular + 'font-size:44px;line-height:1;color:var(--hueso);text-shadow:0 2px 18px rgba(22,19,46,.8)">' + Ui.Escapar(Vista.Avisozonanombre) + '</p></div>';
    }
    if (Estado.Aviso) {
      Html += '<div class="nj-aviso nj-cristal" role="status" style="position:absolute;left:20px;right:20px;top:140px;display:grid;grid-template-columns:36px 1fr auto;align-items:center;gap:12px;padding:12px 16px;border-radius:var(--radio);border:1px solid rgba(79,216,232,.4);pointer-events:none">' +
        '<span style="width:36px;height:36px;border-radius:10px;background:var(--acento);display:flex;align-items:center;justify-content:center"><svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke="#16132E" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 9.5l4 4L15 5"/></svg></span>' +
        '<div><p style="margin:0;font-family:var(--f-mono);font-size:10px;letter-spacing:.14em;color:var(--acento)">LOGRO DESBLOQUEADO</p>' +
        '<p style="margin:2px 0 0 0;font-family:var(--f-titular);font-weight:800;font-size:24px;line-height:1;text-transform:uppercase">' + Ui.Escapar(Estado.Aviso.Titulo) + '</p></div>' +
        '<p style="margin:0;font-family:var(--f-mono);font-size:15px;font-weight:700;color:var(--oro)">+' + Estado.Aviso.Premio + '</p></div>';
    }
    if (Vista.Espera) {
      Html += '<div class="nj-sube nj-cristal" style="position:absolute;left:20px;right:20px;top:176px;padding:22px 22px 18px 22px;border-radius:20px;border:1px solid var(--linea);pointer-events:none">' +
        '<p style="margin:0;' + Ui.Fuente.Titular + 'font-size:60px;line-height:.84;color:var(--hueso)">Toca para<br><span class="nj-respira" style="color:var(--acento)">' + (Vista.Primeravez ? 'despegar' : 'seguir') + '</span></p>' +
        '<div style="margin-top:18px;padding:10px 14px;border-radius:10px;background:rgba(243,241,255,.06);font-family:var(--f-mono);font-size:10px;letter-spacing:.1em;color:var(--hueso-2);text-align:center">← DESLIZA EL DEDO PARA MOVERTE →</div>' +
        '<p style="margin:12px 0 0 0;font-family:var(--f-mono);font-size:10px;letter-spacing:.08em;color:var(--hueso-3)">TECLADO: ← → O A / D · ESPACIO EMPIEZA · P PAUSA</p></div>';
    }
    if (Vista.Fin) {
      Html += '<div style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;pointer-events:none"><p class="nj-sello nj-cristal" style="margin:0;padding:8px 22px;border-radius:16px;border:2px solid var(--rosa);' + Ui.Fuente.Titular + 'font-size:80px;line-height:1;color:var(--rosa)">Caída</p></div>';
    }
    if (Vista.Pausa) {
      var Boton = 'class="nj-btn nj-cristal" style="height:56px;border:1px solid var(--linea-fuerte);font-family:var(--f-titular);font-weight:800;font-size:24px;text-transform:uppercase"';
      Html += '<div role="dialog" aria-modal="true" aria-label="Juego en pausa" style="position:absolute;inset:0;background:rgba(22,19,46,.94);padding:120px 20px 40px 20px;display:flex;flex-direction:column">' +
        '<p aria-hidden="true" style="margin:0;' + Ui.Fuente.Titular + 'font-size:112px;line-height:.78;color:transparent;-webkit-text-stroke:1.4px var(--linea-fuerte)">Pausa<br>Pausa</p>' +
        '<h2 style="margin:0;' + Ui.Fuente.Titular + 'font-size:112px;line-height:.78;color:var(--hueso)">Pausa</h2>' +
        '<p style="margin:18px 0 0 0;font-family:var(--f-mono);font-size:12px;letter-spacing:.1em;color:var(--hueso-2)">' + Vista.Puntaje + ' PUNTOS · ' + Vista.Recogidas + ' MONEDAS · ' + Vista.Alturam + ' M · ' + Ui.Escapar(Vista.Zona) + '</p>' +
        '<div style="margin-top:auto;display:flex;flex-direction:column;gap:14px">' +
        '<button type="button" class="nj-btn" data-accion="Continuar" style="height:64px;display:flex;align-items:center;justify-content:space-between;padding:0 22px;background:var(--acento);color:var(--tinta);border:0;border-radius:16px;box-shadow:0 6px 0 var(--acento-hondo);' + Ui.Fuente.Titular + 'font-size:34px">Continuar <span aria-hidden="true" style="font-family:var(--f-mono);font-size:20px">▸</span></button>' +
        '<div style="display:grid;grid-template-columns:1fr 1fr;gap:12px"><button type="button" data-accion="Reiniciar" ' + Boton + '>Reiniciar</button><button type="button" data-accion="Menu" ' + Boton + '>Menú</button></div></div></div>';
    }
    return Html;
  }

  Nj.Pantallas.Juego = {
    Montar: function (Raiz, App) {
      var Skin = Nj.Skins[App.Estado.Equipada];
      Raiz.innerHTML = '<div class="nj-raiz nj-juego" data-juego tabindex="0" role="application" aria-label="Área de juego. Flechas o A y D para moverte, espacio para empezar, P para pausar." style="position:relative;width:390px;height:844px;overflow:hidden;background:var(--tinta);user-select:none;-webkit-user-select:none;touch-action:none">' +
        '<div data-g="Cielo" style="position:absolute;inset:0"></div>' +
        '<canvas data-g="Chispas" width="390" height="844" aria-hidden="true" style="position:absolute;left:0;top:0;width:390px;height:844px;pointer-events:none"></canvas>' +
        '<div data-g="Mundo" aria-hidden="true" style="position:absolute;left:0;top:0;width:390px;height:0;will-change:transform">' +
        '<div data-g="Regla" style="position:absolute;left:0;top:0;width:70px;height:844px"></div>' +
        '<div data-g="Monedas"></div><div data-g="Plataformas"></div>' +
        '<div data-g="Jugador" style="position:absolute;left:0;top:0;width:30px;height:30px;transform-origin:50% 50%;will-change:transform">' + Ui.Bola(Skin, 30) + '</div></div>' +
        '<div data-g="Tactil" aria-hidden="true" style="position:absolute;inset:0;touch-action:none"></div>' +
        '<header style="position:absolute;left:0;top:0;right:0;height:164px;display:flex;justify-content:space-between;align-items:flex-start;padding:34px 20px 0 20px;pointer-events:none;background:linear-gradient(to bottom, rgba(22,19,46,.82) 40%, rgba(22,19,46,0))">' +
        '<div><p style="margin:0;font-family:var(--f-mono);font-size:10px;letter-spacing:.16em;color:var(--hueso-2)">PUNTOS</p>' +
        '<p data-g="Puntaje" style="margin:4px 0 0 0;font-family:var(--f-titular);font-weight:900;font-size:60px;line-height:.92;color:var(--hueso);font-variant-numeric:tabular-nums">0</p>' +
        '<div style="display:flex;align-items:center;gap:8px;margin-top:6px"><span style="font-family:var(--f-mono);font-size:11px;font-weight:700;letter-spacing:.08em;color:var(--acento)"><span data-g="Altura">0</span> M</span>' +
        '<span data-g="Zona" class="nj-cristal" style="padding:3px 9px;border-radius:999px;font-family:var(--f-mono);font-size:9px;letter-spacing:.14em;color:var(--hueso-2)"></span></div></div>' +
        '<div style="display:flex;gap:8px;align-items:center;pointer-events:auto">' +
        '<div class="nj-cristal" style="height:44px;display:flex;align-items:center;gap:8px;padding:0 14px;border-radius:999px;font-family:var(--f-mono);font-size:14px;font-weight:700">' + Ui.Moneda(16) + '<span data-g="Recogidas" aria-label="Monedas en esta partida">0</span></div>' +
        '<button type="button" class="nj-btn nj-cristal" data-accion="Pausar" aria-label="Pausar" style="width:44px;height:44px;display:flex;align-items:center;justify-content:center;gap:5px;border:0;border-radius:999px;padding:0"><span style="width:4px;height:15px;border-radius:2px;background:var(--hueso)"></span><span style="width:4px;height:15px;border-radius:2px;background:var(--hueso)"></span></button></div></header>' +
        '<div data-g="Capas"></div></div>';
      var Refs = { Raiz: Raiz.firstElementChild, Skin: Skin, HabiaChispas: false };
      Raiz.querySelectorAll('[data-g]').forEach(function (Nodo) { Refs[Nodo.dataset.g] = Nodo; });
      Refs.Contextochispas = Refs.Chispas && Refs.Chispas.getContext ? Refs.Chispas.getContext('2d') : null;
      Refs.Esfera = Refs.Jugador ? Refs.Jugador.querySelector('[data-esfera]') : null;
      Refs.Refscielo = Nj.Cielo.Montar(Refs.Cielo);
      Refs.Raiz.focus({ preventScroll: true });
      return Refs;
    },

    Actualizar: function (Refs, App) {
      var Vista = App.Juego;
      if (!Vista) return;
      Nj.Cielo.Actualizar(Refs.Refscielo, Vista.Fondo);
      // Subir la cámara es mover un solo contenedor acelerado por GPU
      Ui.Transformar(Refs.Mundo, 'translate3d(0,' + (-Vista.Camara) + 'px,0)');
      if (Refs.Ultimaregla !== Vista.Regla) {
        Refs.Ultimaregla = Vista.Regla;
        Ui.Sincronizar(Refs.Regla, Vista.Regla, function (Marca) {
          return '<div style="position:absolute;left:0;top:0;display:flex;align-items:center;gap:6px"><span style="width:10px;height:2px;border-radius:1px;background:var(--linea-fuerte)"></span><span style="font-family:var(--f-mono);font-size:9px;letter-spacing:.08em;color:var(--hueso-2);opacity:.8">' + Marca.Etiqueta + '</span></div>';
        }, function (Nodo, Marca) { Ui.Transformar(Nodo, 'translate3d(0,' + Marca.Y + 'px,0)'); });
      }
      Ui.Sincronizar(Refs.Monedas, Vista.Monedas, function () {
        return '<div style="position:absolute;left:0;top:0;width:18px;height:18px;border-radius:50%;background:radial-gradient(circle at 35% 30%, #FFE9A8 0%, #F5C84C 55%, #C9962E 100%);box-shadow:0 2px 0 #9E721D"></div>';
      }, function (Nodo, Moneda) { Mover(Nodo, Moneda.VistaX, Moneda.VistaY); });
      Ui.Sincronizar(Refs.Plataformas, Vista.Plataformas, function (Una) {
        var Tipo = Una.Movil ? 'Movil' : Una.Fragil ? 'Fragil' : Una.Resorte ? 'Resorte' : 'Normal';
        return '<div style="position:absolute;left:0;top:0;width:78px;height:12px">' + Plataformas[Tipo] + '</div>';
      }, function (Nodo, Una) { Mover(Nodo, Una.VistaX, Una.VistaY); Ui.Opacidad(Nodo, Una.Opacidad); });
      // Chispas y estela dibujadas directamente en Canvas 2D: cero creación/destrucción de nodos DOM
      var Ctx = Refs.Contextochispas, Chispas = Vista.Chispas;
      if (Ctx && (Chispas.length || Refs.HabiaChispas)) {
        Ctx.clearRect(0, 0, 390, 844);
        Refs.HabiaChispas = Chispas.length > 0;
        for (var Indice = 0; Indice < Chispas.length; Indice++) {
          var Una = Chispas[Indice], Yp = Una.Y - Vista.Camara;
          if (Yp < -16 || Yp > 860) continue;
          Ctx.globalAlpha = Math.max(0, Math.min(1, Una.Vida / Una.Maximo));
          Ctx.fillStyle = Una.Escarcha ? '#FFFFFF' : (Una.Color || Refs.Skin.Color);
          Ctx.beginPath();
          Ctx.arc(Una.X, Yp, Una.Escarcha ? 2.2 : (Una.Estela ? 4 : 3), 0, 6.2832);
          Ctx.fill();
        }
        Ctx.globalAlpha = 1;
      }
      var Jugador = Vista.Jugador;
      Ui.Transformar(Refs.Jugador, 'translate3d(' + Jugador.X + 'px,' + Jugador.Y + 'px,0) scale(' + Jugador.Sx + ',' + Jugador.Sy + ')');
      if (Refs.Esfera) Ui.Transformar(Refs.Esfera, 'rotate(' + Jugador.Rotacion + 'deg)');
      Ui.Texto(Refs.Puntaje, Vista.Puntaje);
      Ui.Texto(Refs.Altura, Vista.Alturam);
      Ui.Texto(Refs.Zona, Vista.Zona);
      Ui.Texto(Refs.Recogidas, Vista.Recogidas);
      // Las capas solo se vuelven a armar cuando cambia algo de lo que muestran
      var Estado = App.Estado;
      var Firma = [Vista.Espera, Vista.Pausa, Vista.Fin, Vista.Primeravez, Vista.Avisozona ? Vista.Avisozonanombre : '', Estado.Aviso ? Estado.Aviso.Titulo : '', Vista.Pausa ? Vista.Puntaje : ''].join('|');
      if (Refs.Ultimafirma !== Firma) { Refs.Ultimafirma = Firma; Refs.Capas.innerHTML = Capas(Vista, Estado); }
    }
  };
})();
