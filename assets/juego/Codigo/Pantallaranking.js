/* Vista de clasificación global */
(function () {
  var Nj = window.Neonjump, Ui = Nj.Interfaz;
  // Cambiar a true cuando haya suficientes jugadores para mostrar la pestaña semanal
  var MostrarSemanal = false;

  Nj.Pantallas.Ranking = {
    Render: function (App) {
      var Estado = App.Estado, Semana = MostrarSemanal && Estado.Rankingtab === 'semana';
      // El jugador se mete a la tabla para saber en qué puesto queda
      var Mio = { Nombre: Estado.Nombre || 'Tú', Puntaje: Semana ? (Nj.Puente ? Estado.Mejorsemana || 0 : Math.round(Estado.Mejor * 0.55)) : Estado.Mejor, Yo: true };
      var Tabla = (Semana ? Nj.Rankingsemana : Nj.Ranking).concat([Mio]).sort(function (Primero, Segundo) { return Segundo.Puntaje - Primero.Puntaje; });
      var Puesto = Tabla.indexOf(Mio) + 1, Arriba = Tabla[Puesto - 2];
      var Alturas = [168, 128, 100];
      // El podio va en orden 2, 1, 3 para que el primero quede en la mitad
      var Podio = Ui.Lista([1, 0, 2], function (Indice) {
        var Fila = Tabla[Indice];
        if (!Fila) return '<div></div>'; // con menos de 3 jugadores el podio queda incompleto
        var Fondo = Indice === 0 ? 'var(--acento)' : Indice === 1 ? 'var(--rosa)' : 'var(--tinta-3)';
        return '<div style="display:flex;flex-direction:column;justify-content:flex-end;min-width:0">' +
          '<p style="margin:0;font-size:13px;font-weight:700;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">' + Ui.Escapar(Fila.Nombre) + '</p>' +
          '<p style="margin:2px 0 6px 0;font-family:var(--f-mono);font-size:11px;color:var(--hueso-2)">' + Nj.Formatear(Fila.Puntaje) + '</p>' +
          '<div style="height:' + Alturas[Indice] + 'px;border-radius:12px 12px 0 0;background:' + Fondo + ';border:' + (Indice === 2 ? '1px solid var(--linea-fuerte)' : '0') + ';display:flex;align-items:flex-end;padding:0 8px 4px 8px">' +
          '<span style="font-family:var(--f-titular);font-weight:900;font-size:72px;line-height:.8;color:' + (Indice === 0 ? 'var(--tinta)' : 'var(--hueso)') + '">' + (Indice + 1) + '</span></div></div>';
      });
      var Lista = Ui.Lista(Tabla.slice(3), function (Fila, Indice) {
        return '<li style="display:grid;grid-template-columns:36px 1fr auto;align-items:center;gap:8px;height:50px;padding:0 20px;border-bottom:1px solid var(--linea);background:' + (Fila.Yo ? 'var(--tinta-3)' : 'transparent') + '">' +
          '<span style="font-family:var(--f-mono);font-size:12px;color:var(--hueso-3)">' + String(Indice + 4).padStart(2, '0') + '</span>' +
          '<span style="min-width:0"><span style="display:block;font-size:15px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">' + Ui.Escapar(Fila.Nombre) + '</span>' +
          (Fila.Yo ? '<span style="display:block;font-family:var(--f-mono);font-size:10px;letter-spacing:.08em;color:var(--acento)">TÚ</span>' : '') + '</span>' +
          '<span style="font-family:var(--f-mono);font-size:14px;font-weight:700;font-variant-numeric:tabular-nums">' + Nj.Formatear(Fila.Puntaje) + '</span></li>';
      });
      var Pestana = function (Id, Nombre) {
        var Activa = Estado.Rankingtab === Id;
        return '<button type="button" role="tab" aria-selected="' + Activa + '" data-accion="Rankingtab" data-valor="' + Id + '" class="nj-btn" style="height:40px;border:0;background:' + (Activa ? 'var(--acento)' : 'transparent') + ';color:' + (Activa ? 'var(--tinta)' : 'var(--hueso-2)') + ';font-family:var(--f-mono);font-size:11px;font-weight:700;letter-spacing:.14em">' + Nombre + '</button>';
      };

      return '<main class="nj-raiz" style="position:relative;width:390px;height:844px;overflow:hidden;background:var(--tinta);display:flex;flex-direction:column">' +
        '<header style="padding:34px 20px 0 20px"><div style="display:flex;justify-content:space-between;align-items:center">' + Ui.Volver +
        '<p style="margin:0;font-family:var(--f-mono);font-size:10px;letter-spacing:.14em;color:var(--hueso-3);text-align:right">' + (Nj.Etiquetaranking || 'TOP 100<br>GLOBAL') + '</p></div>' +
        '<h1 style="margin:14px 0 0 0;' + Ui.Fuente.Titular + 'font-size:76px;line-height:.8">Ranking</h1>' +
        (MostrarSemanal ? '<div role="tablist" aria-label="Periodo" style="display:grid;grid-template-columns:1fr 1fr;gap:4px;padding:4px;margin-top:14px;border-radius:14px;background:var(--tinta-2)">' + Pestana('global', 'GLOBAL') + Pestana('semana', 'ESTA SEMANA') + '</div>' : '') +
        '</header>' +
        '<section aria-label="Podio" style="display:grid;grid-template-columns:repeat(3, minmax(0, 1fr));align-items:end;gap:8px;padding:18px 20px 0 20px;height:252px">' + Podio + '</section>' +
        '<ol style="list-style:none;margin:14px 0 0 0;padding:0;flex:1;overflow-y:auto;border-top:1px solid var(--linea-fuerte)">' + Lista + '</ol>' +
        '<footer style="display:grid;grid-template-columns:auto 1fr auto;align-items:center;gap:12px;padding:14px 20px 26px 20px;background:var(--acento);color:var(--tinta)">' +
        '<span style="font-family:var(--f-titular);font-weight:900;font-size:44px;line-height:.9">#' + Puesto + '</span>' +
        '<span style="font-size:13px;line-height:1.3"><strong>' + Ui.Escapar(Mio.Nombre) + '</strong><br>' + (Arriba ? 'A ' + Nj.Formatear(Arriba.Puntaje - Mio.Puntaje + 1) + ' puntos de ' + Ui.Escapar(Arriba.Nombre) : 'Lideras la tabla') + '</span>' +
        '<span style="font-family:var(--f-mono);font-size:15px;font-weight:700">' + Nj.Formatear(Mio.Puntaje) + '</span></footer></main>';
    }
  };
})();
