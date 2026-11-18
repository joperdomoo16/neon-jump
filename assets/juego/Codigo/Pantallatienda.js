/* Vista de tienda y selección de skins */
(function () {
  var Nj = window.Neonjump, Ui = Nj.Interfaz;

  Nj.Pantallas.Tienda = {
    Render: function (App) {
      var Estado = App.Estado;
      var Tiene = function (Id) { return Estado.Skins.indexOf(Id) >= 0; };
      var Skin = Nj.Skins[Estado.Tiendasel], Propia = Tiene(Skin.Id), Puesta = Estado.Equipada === Skin.Id, Alcanza = Estado.Monedas >= Skin.Precio;
      var Bloqueado = Puesta || (!Propia && !Alcanza);
      var Categoria = Nj.Categoriastienda.filter(function (Una) { return Una.Id === Skin.Categoria; })[0].Nombre.toUpperCase();
      // Los nombres largos se achican para que quepan en la tarjeta
      var Tamanotitulo = Skin.Nombre.length > 9 ? 30 : Skin.Nombre.length > 7 ? 36 : 44;
      var Estadotexto = Puesta ? 'La llevas puesta ahora mismo.' : Propia ? 'Ya es tuya. Póntela cuando quieras.' : Alcanza ? 'Cuesta ' + Nj.Formatear(Skin.Precio) + ' monedas.' : 'Te faltan ' + Nj.Formatear(Skin.Precio - Estado.Monedas) + ' monedas.';
      var Textoboton = Puesta ? 'Equipada' : Propia ? 'Equipar' : Alcanza ? 'Comprar · ' + Nj.Formatear(Skin.Precio) : 'Faltan ' + Nj.Formatear(Skin.Precio - Estado.Monedas);
      var Grande = Skin.Imagen
        ? '<img src="' + Skin.Imagen + '" alt="' + Ui.Escapar(Skin.Nombre) + '" style="width:96px;height:96px;border-radius:50%;box-shadow:0 0 36px rgba(255,255,255,.16);margin-bottom:34px">'
        : '<div style="margin-bottom:34px">' + Ui.Bola(Skin, 96, Skin.Nombre) + '</div>';

      var Categorias = Ui.Lista(Nj.Categoriastienda, function (Una) {
        var Delacategoria = Nj.Skins.filter(function (Otra) { return Otra.Categoria === Una.Id; }), Activa = Estado.Tiendacat === Una.Id;
        return '<button type="button" role="tab" aria-selected="' + Activa + '" data-accion="Tiendacat" data-valor="' + Una.Id + '" class="nj-btn" style="height:48px;background:transparent;border:0;border-radius:0;border-bottom:3px solid ' + (Activa ? 'var(--acento)' : 'transparent') + ';padding:0;display:flex;flex-direction:column;align-items:center;justify-content:center;color:' + (Activa ? 'var(--hueso)' : 'var(--hueso-2)') + '">' +
          '<span style="font-family:var(--f-titular);font-weight:800;font-size:17px;text-transform:uppercase">' + Una.Nombre + '</span><span style="font-family:var(--f-mono);font-size:10px;color:var(--hueso-3)">' +
          Delacategoria.filter(function (Otra) { return Tiene(Otra.Id); }).length + '/' + Delacategoria.length + '</span></button>';
      });

      var Tarjetas = Ui.Lista(Nj.Skins.filter(function (Una) { return Una.Categoria === Estado.Tiendacat; }), function (Una) {
        var Mia = Tiene(Una.Id), Activo = Una.Id === Estado.Tiendasel, Opacidad = Mia ? 1 : 0.55;
        var Bola = Una.Imagen ? '<img src="' + Una.Imagen + '" alt="" style="width:44px;height:44px;border-radius:50%;opacity:' + Opacidad + '">' : '<span style="opacity:' + Opacidad + '">' + Ui.Bola(Una, 44) + '</span>';
        var Pie = Estado.Equipada === Una.Id ? 'PUESTA' : Mia ? 'TUYA' : Nj.Formatear(Una.Precio);
        var Colorpie = Estado.Equipada === Una.Id ? 'var(--acento)' : Mia ? 'var(--hueso-2)' : 'var(--oro)';
        return '<li><button type="button" data-accion="Seleccionarskin" data-valor="' + Una.Id + '" aria-pressed="' + Activo + '" aria-label="' + Ui.Escapar(Una.Nombre + (Mia ? ', ya es tuya' : ', cuesta ' + Una.Precio + ' monedas')) + '" class="nj-btn" style="position:relative;width:100%;height:112px;background:' + (Activo ? 'var(--tinta-3)' : 'var(--tinta-2)') + ';border:' + (Activo ? '2px solid var(--acento)' : '1px solid var(--linea)') + ';display:flex;flex-direction:column;align-items:center;justify-content:center;gap:8px;padding:0">' +
          Bola + '<span style="font-family:var(--f-mono);font-size:10px;letter-spacing:.06em;text-transform:uppercase;color:var(--hueso)">' + Ui.Escapar(Una.Nombre) + '</span>' +
          '<span style="font-family:var(--f-mono);font-size:10px;color:' + Colorpie + '">' + Pie + '</span></button></li>';
      });

      return '<main class="nj-raiz" style="position:relative;width:390px;height:844px;overflow:hidden;background:var(--tinta);display:flex;flex-direction:column">' +
        '<header style="display:flex;justify-content:space-between;align-items:center;padding:34px 20px 0 20px">' + Ui.Volver +
        '<h1 style="margin:0;' + Ui.Fuente.Titular + 'font-size:34px;letter-spacing:.02em">Tienda</h1>' +
        '<div class="nj-cristal" style="height:44px;display:flex;align-items:center;gap:8px;padding:0 14px;border-radius:999px;font-family:var(--f-mono);font-size:14px;font-weight:700">' + Ui.Moneda(16) + '<span aria-label="Monedas disponibles">' + Nj.Formatear(Estado.Monedas) + '</span></div></header>' +

        '<section aria-label="Skin seleccionada" class="nj-puntos nj-caja" style="position:relative;margin:16px 20px 0 20px;height:232px;overflow:hidden;background-color:var(--tinta-2);border:1px solid var(--linea);display:grid;grid-template-columns:150px 1fr">' +
        '<div style="position:relative;display:flex;align-items:center;justify-content:center;border-right:1px solid var(--linea)">' + Grande +
        '<span aria-hidden="true" style="position:absolute;left:30px;right:30px;bottom:44px;height:10px;border-radius:5px;background:var(--rosa);box-shadow:0 4px 0 var(--rosa-hondo)"></span></div>' +
        '<div style="padding:16px 16px 14px 16px;display:flex;flex-direction:column;min-width:0">' +
        '<p style="margin:0;font-family:var(--f-mono);font-size:10px;letter-spacing:.14em;color:var(--hueso-2)">SKIN ' + String(Skin.Id + 1).padStart(2, '0') + '/' + Nj.Skins.length + ' · ' + Categoria + '</p>' +
        '<h2 style="margin:8px 0 0 0;' + Ui.Fuente.Titular + 'font-size:' + Tamanotitulo + 'px;line-height:.85">' + Ui.Escapar(Skin.Nombre) + '</h2>' +
        '<p style="margin:8px 0 0 0;font-size:13px;color:var(--hueso-2)">' + Estadotexto + '</p>' +
        '<button type="button" class="nj-btn" data-accion="Accionskin" data-valor="' + Skin.Id + '"' + (Bloqueado ? ' disabled' : '') + ' style="margin-top:auto;height:48px;border:' + (Bloqueado ? '1px solid var(--linea-fuerte)' : '0') + ';background:' + (Bloqueado ? 'transparent' : 'var(--acento)') + ';color:' + (Bloqueado ? 'var(--hueso)' : 'var(--tinta)') + ';' + Ui.Fuente.Titular + 'font-size:22px">' + Textoboton + '</button></div></section>' +

        '<div role="tablist" aria-label="Categorías" style="display:grid;grid-template-columns:repeat(4, minmax(0, 1fr));margin:16px 20px 0 20px;border-bottom:1px solid var(--linea-fuerte)">' + Categorias + '</div>' +
        '<ul aria-label="Skins" style="list-style:none;margin:0;padding:14px 20px 24px 20px;flex:1;overflow-y:auto;display:grid;grid-template-columns:repeat(3, minmax(0, 1fr));grid-auto-rows:112px;gap:8px">' + Tarjetas + '</ul></main>';
    }
  };
})();
