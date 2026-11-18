/* Vista de catálogo y progreso de logros */
(function () {
  var Nj = window.Neonjump, Ui = Nj.Interfaz;
  var Chulo = '<span aria-label="Desbloqueado" style="width:24px;height:24px;border-radius:7px;background:var(--acento);display:flex;align-items:center;justify-content:center;margin-top:2px"><svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="#16132E" stroke-width="2.4" aria-hidden="true"><path d="M2 7.5l3.2 3L12 3.5"/></svg></span>';
  var Candado = '<span aria-label="Bloqueado" style="width:24px;height:24px;border-radius:7px;border:1px solid var(--linea-fuerte);margin-top:2px"></span>';

  Nj.Pantallas.Logros = {
    Render: function (App) {
      var Estado = App.Estado, Familias = [], Ganadas = 0;
      Nj.Logros.forEach(function (Logro) { if (Familias.indexOf(Logro.Categoria) < 0) Familias.push(Logro.Categoria); });
      // Una rayita por logro: las prendidas son las que ya se ganaron
      var Segmentos = Ui.Lista(Nj.Logros, function (Logro) {
        var Hecho = Estado.Logros.indexOf(Logro.Id) >= 0;
        if (Hecho) Ganadas += Logro.Premio;
        return '<span style="height:14px;border-radius:3px;background:' + (Hecho ? 'var(--acento)' : 'var(--tinta-3)') + '"></span>';
      });
      var Grupos = Ui.Lista(Familias, function (Familia) {
        var Delafamilia = Nj.Logros.filter(function (Logro) { return Logro.Categoria === Familia; });
        var Hechos = Delafamilia.filter(function (Logro) { return Estado.Logros.indexOf(Logro.Id) >= 0; }).length;
        return '<section aria-label="' + Ui.Escapar(Familia) + '"><h2 style="position:sticky;top:0;z-index:1;margin:0;display:flex;justify-content:space-between;align-items:baseline;padding:14px 20px 8px 20px;background:var(--tinta);font-family:var(--f-titular);font-weight:800;font-size:24px;text-transform:uppercase">' +
          Ui.Escapar(Familia) + ' <span style="font-family:var(--f-mono);font-size:11px;font-weight:500;color:var(--hueso-2)">' + Hechos + '/' + Delafamilia.length + '</span></h2><ul style="list-style:none;margin:0;padding:0">' +
          Ui.Lista(Delafamilia, function (Logro) {
            var Progreso = Nj.Progresologro(Logro, Estado);
            return '<li style="display:grid;grid-template-columns:28px 1fr auto;gap:12px;align-items:start;padding:12px 20px;border-top:1px solid var(--linea)">' + (Progreso.Hecho ? Chulo : Candado) +
              '<div style="min-width:0"><p style="margin:0;font-size:15px;font-weight:700;color:' + (Progreso.Hecho ? 'var(--hueso)' : 'var(--hueso-2)') + '">' + Ui.Escapar(Logro.Titulo) + '</p>' +
              '<p style="margin:2px 0 0 0;font-size:13px;color:var(--hueso-2)">' + Ui.Escapar(Logro.Descripcion) + '</p>' +
              (Progreso.Hecho ? '' : '<div style="display:flex;align-items:center;gap:8px;margin-top:8px"><span style="flex:1;height:4px;border-radius:2px;background:var(--linea)"><span style="display:block;height:4px;border-radius:2px;width:' + Progreso.Porcentaje + '%;background:var(--hueso)"></span></span><span style="font-family:var(--f-mono);font-size:10px;color:var(--hueso-2)">' + Nj.Formatear(Progreso.Valor) + ' / ' + Nj.Formatear(Progreso.Meta) + '</span></div>') +
              '</div><span style="font-family:var(--f-mono);font-size:13px;font-weight:700;color:' + (Progreso.Hecho ? 'var(--acento)' : 'var(--hueso-3)') + '">+' + Logro.Premio + '</span></li>';
          }) + '</ul></section>';
      });

      return '<main class="nj-raiz" style="position:relative;width:390px;height:844px;overflow:hidden;background:var(--tinta);display:flex;flex-direction:column">' +
        '<header style="padding:34px 20px 0 20px"><div style="display:flex;justify-content:space-between;align-items:center">' + Ui.Volver +
        '<p style="margin:0;font-family:var(--f-mono);font-size:10px;letter-spacing:.14em;color:var(--hueso-2);text-align:right">' + Nj.Logros.length + ' METAS<br>' + Familias.length + ' FAMILIAS</p></div>' +
        '<h1 style="margin:12px 0 0 0;display:flex;align-items:flex-end;gap:12px">' +
        '<span style="font-family:var(--f-titular);font-weight:900;font-size:112px;line-height:.78;color:var(--acento)">' + Estado.Logros.length + '</span>' +
        '<span style="font-family:var(--f-titular);font-weight:900;font-size:112px;line-height:.78;color:transparent;-webkit-text-stroke:1.4px var(--linea-fuerte)">/' + Nj.Logros.length + '</span>' +
        '<span style="margin-left:auto;padding-bottom:4px;font-family:var(--f-titular);font-weight:800;font-size:26px;line-height:.9;text-transform:uppercase;text-align:right">Logros</span></h1>' +
        '<div role="progressbar" aria-label="Logros desbloqueados" aria-valuemin="0" aria-valuemax="' + Nj.Logros.length + '" aria-valuenow="' + Estado.Logros.length + '" style="display:grid;grid-template-columns:repeat(27, minmax(0, 1fr));gap:2px;margin-top:16px">' + Segmentos + '</div>' +
        '<p style="margin:10px 0 0 0;font-family:var(--f-mono);font-size:11px;letter-spacing:.08em;color:var(--hueso-2)">GANASTE <span style="color:var(--oro)">+' + Ganadas + ' MONEDAS</span> CON LOGROS</p></header>' +
        '<div style="flex:1;overflow-y:auto;margin-top:16px;border-top:1px solid var(--linea-fuerte);padding-bottom:24px">' + Grupos + '</div></main>';
    }
  };
})();
