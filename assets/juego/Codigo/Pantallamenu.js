/* Vista principal del menú de inicio */
(function () {
  var Nj = window.Neonjump, Ui = Nj.Interfaz;

  var Ciudad = '<svg aria-hidden="true" width="440" height="210" viewBox="-25 0 440 210" style="position:absolute;left:-25px;bottom:0;display:block">' +
    '<g class="nj-ciudad-fondo" fill="#2A2456"><rect x="-30" y="76" width="30" height="134"/><rect x="0" y="40" width="24" height="170"/><rect x="26" y="91" width="43" height="119"/><rect x="69" y="70" width="44" height="140"/><rect x="113" y="110" width="45" height="100"/><rect x="158" y="60" width="42" height="150"/><rect x="200" y="30" width="48" height="180"/><rect x="248" y="80" width="48" height="130"/><rect x="296" y="42" width="48" height="168"/><rect x="344" y="96" width="46" height="114"/><rect x="390" y="68" width="34" height="142"/></g>' +
    '<g class="nj-ciudad-frente"><g fill="#1C1838"><rect x="-30" y="112" width="24" height="98"/><rect x="-6" y="123" width="44" height="87"/><rect x="38" y="101" width="47" height="109"/><rect x="88" y="130" width="58" height="80"/><rect x="146" y="80" width="58" height="130"/><rect x="204" y="110" width="52" height="100"/><rect x="256" y="98" width="53" height="112"/><rect x="309" y="124" width="37" height="86"/><rect x="349" y="105" width="45" height="105"/><rect x="394" y="120" width="30" height="90"/></g>' +
    '<g class="nj-ventanas" fill="#F5C84C"><rect x="51" y="111" width="3" height="5"/><rect x="67" y="122" width="3" height="5"/><rect x="159" y="92" width="3" height="5"/><rect x="175" y="103" width="3" height="5"/><rect x="191" y="125" width="3" height="5"/><rect x="217" y="121" width="3" height="5"/><rect x="269" y="109" width="3" height="5"/><rect x="293" y="131" width="3" height="5"/><rect x="362" y="115" width="3" height="5"/><rect x="21" y="135" width="3" height="5"/></g></g></svg>';

  var Iconosonido = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round" stroke-linecap="round" aria-hidden="true"><path d="M3 8h3l4-3.5v11L6 12H3z"/><path d="M13 7.5a3.5 3.5 0 0 1 0 5M15.5 5a7 7 0 0 1 0 10"/></svg>';
  var Iconosilencio = '<svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="var(--hueso-3)" stroke-width="1.8" stroke-linejoin="round" stroke-linecap="round" aria-hidden="true"><path d="M3 8h3l4-3.5v11L6 12H3z"/><path d="M13 7.5l5 5M18 7.5l-5 5"/></svg>';

  Nj.Pantallas.Menu = {
    Render: function (App) {
      var Estado = App.Estado, Skin = Nj.Skins[Estado.Equipada], Reto = Estado.Reto;
      var Puesto = Nj.Ranking.filter(function (Fila) { return Fila.Puntaje > Estado.Mejor; }).length + 1;
      var Progreso = Math.min(Reto.Progreso, Reto.Meta);
      var Segmentos = '';
      for (var Indice = 0; Indice < Reto.Meta; Indice++) Segmentos += '<span style="height:6px;border-radius:3px;background:' + (Indice < Reto.Progreso || Reto.Hecho ? 'var(--acento)' : 'rgba(243,241,255,.16)') + '"></span>';
      var Audioactivo = !!(Estado.Sonido || Estado.Musica);
      var Nombre = Ui.Escapar((Estado.Nombre || 'Jugador').trim());
      var Secciones = [['01', 'Ranking', 'PUESTO #' + Puesto, 'Ranking'], ['02', 'Tienda', Estado.Skins.length + '/' + Nj.Skins.length + ' SKINS', 'Tienda'],
        ['03', 'Logros', Estado.Logros.length + '/' + Nj.Logros.length, 'Logros'], ['04', 'Perfil', 'AJUSTES', 'Perfil']];

      return '<main class="nj-raiz" style="position:relative;width:390px;height:844px;overflow:hidden;background:linear-gradient(180deg, #1B1840 0%, #2B2457 60%, #3D3068 100%)">' +
        '<div aria-hidden="true" class="nj-puntos nj-cielo-deriva" style="position:absolute;inset:-16px"></div>' + Ciudad +

        '<header style="position:relative;display:flex;justify-content:space-between;align-items:center;padding:36px 20px 0 20px">' +
        '<p style="margin:0;font-family:var(--f-mono);font-size:11px;letter-spacing:.14em;color:var(--hueso-2);line-height:1.4">ASCENSO INFINITO</p>' +
        '<div style="display:flex;gap:8px;align-items:center">' +
        '<a href="#" data-accion="Ir" data-valor="Tienda" class="nj-btn nj-cristal" aria-label="Monedas: ' + Nj.Formatear(Estado.Monedas) + '. Abrir tienda" style="height:44px;display:flex;align-items:center;gap:8px;padding:0 14px;border-radius:999px;text-decoration:none;color:var(--hueso);font-family:var(--f-mono);font-size:14px;font-weight:700">' + Ui.Moneda(16) + Nj.Formatear(Estado.Monedas) + '</a>' +
        '<button type="button" data-accion="Silenciartodo" class="nj-btn nj-cristal" aria-label="' + (Audioactivo ? 'Silenciar sonido' : 'Activar sonido') + '" aria-pressed="' + Audioactivo + '" style="width:44px;height:44px;display:flex;align-items:center;justify-content:center;border:0;border-radius:999px;padding:0">' + (Audioactivo ? Iconosonido : Iconosilencio) + '</button>' +
        '</div></header>' +

        '<section aria-label="NEON JUMP" style="position:relative;padding:14px 20px 0 20px;height:258px">' +
        '<h1 style="margin:0;' + Ui.Fuente.Titular + 'line-height:.8;letter-spacing:-.01em">' +
        '<span aria-hidden="true" style="display:block;font-size:56px;color:transparent;-webkit-text-stroke:1px rgba(189,183,224,.4)">Neon</span>' +
        '<span aria-hidden="true" style="display:block;font-size:56px;color:transparent;-webkit-text-stroke:1.4px rgba(189,183,224,.75)">Neon</span>' +
        '<span style="display:block;font-size:56px;color:var(--hueso)">Neon</span>' +
        '<span style="display:block;font-size:128px;color:var(--acento);margin-top:2px;text-shadow:0 6px 30px rgba(79,216,232,.25)">Jump</span></h1>' +
        '<svg aria-hidden="true" width="150" height="150" viewBox="0 0 150 150" style="position:absolute;right:18px;top:6px" fill="none"><path d="M8 140 C 30 40, 95 20, 118 44" stroke="rgba(189,183,224,.55)" stroke-width="1.5" stroke-dasharray="3 6" stroke-linecap="round"/><ellipse class="nj-chispa-rebote" cx="118" cy="98" rx="22" ry="6" stroke="#F0577E" stroke-width="2"/><g class="nj-plataforma-rebote"><rect x="90" y="96" width="56" height="10" rx="5" fill="#F0577E"/><rect x="90" y="102" width="56" height="6" rx="3" fill="#A8335A"/></g></svg>' +
        '<div class="nj-bola-rebote" style="position:absolute;right:30px;top:14px;width:40px;height:40px;transform-origin:50% 100%">' + Ui.Bola(Skin, 40, 'Skin equipada: ' + Skin.Nombre) + '</div></section>' +

        '<div style="position:relative;display:flex;justify-content:space-between;align-items:baseline;padding:0 20px;margin-top:4px">' +
        '<p style="margin:0;font-size:15px;color:var(--hueso)">Hola, <strong style="font-weight:700">' + Nombre + '</strong></p>' +
        '<p style="margin:0;font-family:var(--f-mono);font-size:11px;letter-spacing:.1em;color:var(--oro)">RACHA · ' + Estado.Racha + ' DÍAS</p></div>' +

        '<section aria-label="Reto del día" class="nj-cristal nj-caja" style="position:relative;margin:12px 20px 0 20px;border:1px solid var(--linea);padding:12px 14px">' +
        '<div style="display:flex;justify-content:space-between;font-family:var(--f-mono);font-size:11px;letter-spacing:.12em;color:var(--hueso-2)"><span>RETO DEL DÍA</span><span style="color:var(--acento)">' +
        (Reto.Hecho ? 'COMPLETADO' : Progreso + '/' + Reto.Meta + ' · +' + Reto.Premio) + '</span></div>' +
        '<p style="margin:6px 0 10px 0;font-size:14px;line-height:1.35;color:var(--hueso)">' + Ui.Escapar(Reto.Texto) + '</p>' +
        '<div role="progressbar" aria-label="Progreso del reto" aria-valuemin="0" aria-valuemax="' + Reto.Meta + '" aria-valuenow="' + Progreso + '" style="display:grid;grid-template-columns:repeat(8, minmax(0, 1fr));gap:4px">' + Segmentos + '</div></section>' +

        '<div style="position:relative;padding:16px 20px 0 20px"><button type="button" data-accion="Jugar" class="nj-btn" style="width:100%;height:70px;display:flex;align-items:center;justify-content:space-between;padding:0 22px;background:var(--acento);color:var(--tinta);border:0;border-radius:18px;box-shadow:0 6px 0 var(--acento-hondo), 0 14px 30px rgba(79,216,232,.18)">' +
        '<span style="' + Ui.Fuente.Titular + 'font-size:46px;line-height:1;letter-spacing:.01em">Jugar</span>' +
        '<svg width="34" height="20" viewBox="0 0 34 20" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2 10h28M21 2l9 8-9 8"/></svg></button></div>' +

        '<nav aria-label="Secciones" style="position:relative;margin-top:18px;border-top:1px solid var(--linea)">' +
        Ui.Lista(Secciones, function (Seccion) {
          return '<a href="#" data-accion="Ir" data-valor="' + Seccion[3] + '" class="nj-fila" style="height:48px;display:grid;grid-template-columns:44px 1fr auto 24px;align-items:center;padding:0 20px;border-bottom:1px solid var(--linea);color:var(--hueso);text-decoration:none">' +
            '<span style="font-family:var(--f-mono);font-size:11px;color:var(--hueso-3)">' + Seccion[0] + '</span>' +
            '<span style="font-family:var(--f-titular);font-weight:800;font-size:26px;text-transform:uppercase;letter-spacing:.01em">' + Seccion[1] + '</span>' +
            '<span style="font-family:var(--f-mono);font-size:11px;color:var(--hueso-2)">' + Seccion[2] + '</span>' +
            '<span class="nj-flecha" aria-hidden="true" style="text-align:right;font-family:var(--f-mono);font-size:14px">→</span></a>';
        }) + '</nav>' +

        // Banner propio (Khronos y MiTecho); en la app, cuando AdMob tiene banner, el suyo va encima y este se esconde
        '<aside aria-label="Espacio publicitario" class="nj-cristal" style="position:absolute;left:35px;bottom:12px;width:320px;height:50px;border-radius:10px;overflow:hidden">' + (Nj.Anuncios ? Nj.Anuncios.Banner() : '') + '</aside>' +
        '</main>';
    }
  };
})();
