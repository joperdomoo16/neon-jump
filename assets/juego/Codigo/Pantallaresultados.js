/* Vista de resultados al finalizar la partida */
(function () {
  var Nj = window.Neonjump, Ui = Nj.Interfaz;
  var Etiqueta = 'font-family:var(--f-mono);font-size:10px;letter-spacing:.14em;color:var(--hueso-2)';

  Nj.Pantallas.Resultados = {
    Render: function (App) {
      var Estado = App.Estado, Resultado = Estado.Resultado;
      if (!Resultado) return Nj.Pantallas.Menu.Render(App);
      // [nombre, rebotes, color de la barra, color de la muestra, borde de la muestra]
      var Tipos = [
        ['Normal', Resultado.Rebotes.Normal, 'var(--rosa)', 'var(--rosa)', '0'],
        ['Móvil', Resultado.Rebotes.Movil, 'var(--amarillo)', 'var(--amarillo)', '0'],
        ['Frágil', Resultado.Rebotes.Fragil, '#E06D5E', '#E06D5E', '0'],
        ['Resorte', Resultado.Rebotes.Resorte, 'var(--verde)', 'var(--verde)', '0']];
      var Total = Tipos.reduce(function (Suma, Tipo) { return Suma + Tipo[1]; }, 0);
      var Insignias = Resultado.Logrosnuevos.map(function (Logro) { return [Logro.Titulo, '+' + Logro.Premio, 'var(--acento)']; });
      if (Resultado.Retohecho) Insignias.push(['Reto del día', '+' + Estado.Reto.Premio, 'var(--rosa)']);
      var Siguiente = Nj.Logros.filter(function (Logro) { return Logro.Categoria === 'Altura' && Estado.Logros.indexOf(Logro.Id) < 0; })[0];
      var Segundos = Math.round(Resultado.Segundos);
      var Linea = Resultado.Nuevorecord ? 'Superaste tu marca anterior de ' + Nj.Formatear(Resultado.Mejoranterior) + '.' : 'Tu récord es ' + Nj.Formatear(Resultado.Mejoranterior) + '. Te faltaron ' + Nj.Formatear(Resultado.Mejoranterior - Resultado.Puntaje + 1) + ' puntos.';
      var Revivir = function (Accion, Borde, Subtitulo, Color, Deshabilitado) {
        return '<button type="button" class="nj-btn" data-accion="' + Accion + '"' + (Deshabilitado ? ' disabled' : '') + ' style="height:52px;display:flex;flex-direction:column;align-items:center;justify-content:center;background:transparent;border:1px solid ' + Borde + ';color:var(--hueso)">' +
          '<span style="font-family:var(--f-titular);font-weight:800;font-size:20px;line-height:1;text-transform:uppercase">Revivir</span><span style="font-family:var(--f-mono);font-size:10px;letter-spacing:.1em;color:' + Color + '">' + Subtitulo + '</span></button>';
      };
      var Celda = function (Titulo, Valor, Conborde) {
        return '<div style="padding:12px 0 12px ' + (Conborde ? '12px;border-left:1px solid var(--linea)' : '0') + '"><dt style="' + Etiqueta + '">' + Titulo + '</dt><dd style="margin:4px 0 0 0;font-family:var(--f-titular);font-weight:800;font-size:30px;line-height:1">' + Valor + '</dd></div>';
      };

      var Puntajetexto = Nj.Formatear(Resultado.Puntaje);
      var Tamanopuntaje = Puntajetexto.length > 7 ? 72 : Puntajetexto.length > 5 ? 92 : 112;

      return '<main class="nj-raiz" style="position:relative;width:390px;height:844px;overflow:hidden;background:linear-gradient(180deg, #1B1840 0%, #231E4A 100%);padding:36px 20px 0 20px;display:flex;flex-direction:column">' +
        '<header style="display:flex;justify-content:space-between;font-family:var(--f-mono);font-size:11px;letter-spacing:.14em;color:var(--hueso-2)"><span>FIN DEL ASCENSO</span><span>PARTIDA #' + Estado.Partidas + '</span></header>' +
        '<section class="nj-sube" style="position:relative;margin-top:16px">' +
        '<div style="display:flex;justify-content:space-between;align-items:center;min-height:28px"><h1 style="margin:0;font-family:var(--f-mono);font-size:11px;font-weight:500;letter-spacing:.16em;color:var(--hueso-2)">PUNTOS</h1>' +
        (Resultado.Nuevorecord ? '<p class="nj-sello" style="margin:0;padding:4px 10px;border-radius:8px;border:1.5px solid var(--acento);color:var(--acento);' + Ui.Fuente.Titular + 'font-size:16px;line-height:1;background:var(--tinta)">Nuevo récord</p>' : '') + '</div>' +
        '<p style="margin:6px 0 0 0;font-family:var(--f-titular);font-weight:900;font-size:' + Tamanopuntaje + 'px;line-height:.92;letter-spacing:-.01em;font-variant-numeric:tabular-nums;white-space:nowrap">' + Puntajetexto + '</p>' +
        '<p style="margin:10px 0 0 0;font-size:14px;color:var(--hueso-2)">' + Linea + '</p></section>' +

        '<dl style="margin:20px 0 0 0;display:grid;grid-template-columns:repeat(3, minmax(0, 1fr));border-top:1px solid var(--linea-fuerte);border-bottom:1px solid var(--linea-fuerte)">' +
        Celda('MONEDAS', '<span style="color:var(--oro)">+' + Resultado.Monedas + '</span>') + Celda('ALTURA', Nj.Formatear(Resultado.Alturam) + ' m', true) +
        Celda('EN EL AIRE', Math.floor(Segundos / 60) + ':' + String(Segundos % 60).padStart(2, '0'), true) + '</dl>' +

        '<section aria-label="Rebotes por tipo de plataforma" style="margin-top:18px"><div style="display:flex;justify-content:space-between;' + Etiqueta + '"><span>REBOTES</span><span>' + Total + ' EN TOTAL</span></div>' +
        '<div aria-hidden="true" style="display:flex;height:10px;margin-top:8px;gap:2px">' + Ui.Lista(Tipos, function (Tipo) { return '<span style="flex:' + Math.max(Tipo[1], 0.0001) + ' 1 0;min-width:2px;border-radius:3px;background:' + Tipo[2] + '"></span>'; }) + '</div>' +
        '<ul style="list-style:none;margin:10px 0 0 0;padding:0;display:grid;grid-template-columns:repeat(2, minmax(0, 1fr));gap:6px 16px">' +
        Ui.Lista(Tipos, function (Tipo) {
          return '<li style="display:flex;align-items:center;gap:10px;font-size:14px"><span aria-hidden="true" style="width:22px;height:6px;border-radius:3px;background:' + Tipo[3] + ';border:' + Tipo[4] + '"></span><span style="flex:1;color:var(--hueso-2)">' + Tipo[0] + '</span><span style="font-family:var(--f-mono);font-weight:700">' + Tipo[1] + '</span></li>';
        }) + '</ul></section>' +

        '<section aria-label="Logros y reto" style="margin-top:16px;border-top:1px solid var(--linea);padding-top:12px"><p style="margin:0;' + Etiqueta + '">ESTA PARTIDA</p><div style="display:flex;flex-wrap:wrap;gap:6px;margin-top:8px">' +
        (Insignias.length ? Ui.Lista(Insignias, function (Insignia) {
          return '<span style="display:inline-flex;gap:8px;align-items:center;padding:6px 12px;border-radius:999px;border:1px solid ' + Insignia[2] + ';font-size:13px">' + Ui.Escapar(Insignia[0]) + ' <strong style="font-family:var(--f-mono);color:var(--acento)">' + Insignia[1] + '</strong></span>';
        }) : '<span style="font-size:13px;color:var(--hueso-3)">Sin logros nuevos esta vez. El siguiente está a ' + (Siguiente ? Nj.Formatear(Siguiente.Meta - Estado.Mejor) + ' puntos' : 'un salto') + '.</span>') + '</div></section>' +

        '<a href="#" data-accion="Ir" data-valor="Ranking" class="nj-fila" style="margin-top:14px;display:flex;justify-content:space-between;align-items:center;padding:10px 0;border-top:1px solid var(--linea);border-bottom:1px solid var(--linea);color:var(--hueso);text-decoration:none;font-size:14px">' +
        '<span>Con este puntaje quedas <strong style="font-family:var(--f-mono);color:var(--acento)">#' + Resultado.Posicion + '</strong> del ranking</span><span class="nj-flecha" aria-hidden="true" style="font-family:var(--f-mono)">→</span></a>' +

        '<div style="margin-top:auto;padding-bottom:28px;display:flex;flex-direction:column;gap:12px"><div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">' +
        Revivir('Reviviranuncio', 'var(--acento)', 'VER ANUNCIO', 'var(--hueso-2)', false) + Revivir('Revivirmonedas', 'var(--oro)', '100 MONEDAS', 'var(--oro)', Estado.Monedas < 100) + '</div>' +
        '<button type="button" class="nj-btn" data-accion="Jugar" style="height:68px;display:flex;align-items:center;justify-content:space-between;padding:0 20px;background:var(--acento);color:var(--tinta);border:0;border-radius:18px;box-shadow:0 6px 0 var(--acento-hondo), 0 14px 30px rgba(79,216,232,.18)">' +
        '<span style="' + Ui.Fuente.Titular + 'font-size:40px">Otra vez</span><svg width="28" height="28" viewBox="0 0 28 28" fill="none" stroke="currentColor" stroke-width="3" aria-hidden="true"><path d="M23 14a9 9 0 1 1-3-6.7"/><path d="M21 2v6h-6"/></svg></button>' +
        '<button type="button" class="nj-btn" data-accion="Menu" style="height:44px;background:transparent;border:0;color:var(--hueso-2);font-family:var(--f-mono);font-size:12px;letter-spacing:.16em">VOLVER AL MENÚ</button></div></main>';
    }
  };

  /* Vista de respaldo para anuncio bonificado fuera de entorno nativo */
  Nj.Pantallas.Anuncio = function (Segundos) {
    return '<div role="dialog" aria-modal="true" aria-label="Anuncio bonificado" class="nj-raiz" style="position:absolute;inset:0;z-index:50;background:var(--tinta);display:flex;flex-direction:column;justify-content:space-between;padding:28px 24px 36px;pointer-events:auto">' +
      '<div style="display:flex;justify-content:space-between;align-items:center;font-family:var(--f-mono);font-size:12px;letter-spacing:.12em;color:var(--hueso-2)"><span>PUBLICIDAD · ANUNCIO BONIFICADO</span><span style="border:1px solid var(--linea-fuerte);border-radius:999px;padding:4px 10px;color:var(--hueso)">' + Segundos + ' s</span></div>' +
      '<div class="nj-puntos nj-caja" style="flex:1;margin:24px 0;border:1px dashed var(--linea-fuerte);display:flex;align-items:center;justify-content:center;text-align:center;padding:24px"><p style="margin:0;font-family:var(--f-mono);font-size:13px;line-height:1.6;color:var(--hueso-2)">Aquí se reproduce el anuncio de AdMob.<br>Al terminar, vuelves al aire justo donde caíste.</p></div>' +
      '<p style="margin:0;' + Ui.Fuente.Titular + 'font-size:44px;line-height:.9;color:var(--acento)">Recargando<br>impulso</p></div>';
  };
})();
