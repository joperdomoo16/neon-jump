/* Renderizado de capas de cielo, ciudad y elementos ambientales */
(function () {
  var Nj = window.Neonjump, Ui = Nj.Interfaz;

  var Ciudadlejos = '<svg width="390" height="260" viewBox="0 0 390 260" fill="#2A2456" style="display:block"><rect x="0" y="40" width="24" height="220"/><rect x="26" y="91" width="43" height="169"/><rect x="69" y="89" width="44" height="171"/><rect x="113" y="129" width="45" height="131"/><rect x="158" y="153" width="42" height="107"/><rect x="200" y="55" width="48" height="205"/><rect x="224" y="41" width="2" height="14"/><rect x="248" y="70" width="48" height="190"/><rect x="296" y="42" width="48" height="218"/><rect x="344" y="117" width="46" height="143"/><rect x="367" y="103" width="2" height="14"/></svg><div style="height:760px;background:#2A2456"></div>';

  var Ventanas = [[31, 81], [7, 103], [15, 114], [31, 114], [75, 59], [51, 81], [67, 92], [43, 103], [51, 125], [75, 125], [109, 88], [125, 99], [117, 110], [93, 121], [133, 132], [175, 9], [159, 20], [191, 31], [151, 53], [167, 64], [183, 64], [159, 86], [191, 86], [175, 97], [183, 119], [151, 130], [167, 130], [225, 31], [209, 42], [241, 42], [217, 53], [233, 64], [249, 64], [225, 75], [249, 119], [217, 141], [293, 56], [277, 67], [301, 78], [269, 89], [293, 89], [277, 100], [261, 111], [293, 133], [314, 52], [338, 63], [322, 85], [338, 107], [322, 118], [330, 129], [362, 63], [370, 74], [354, 85], [362, 140], [385, 78]]
    .map(function (Punto) { return '<rect x="' + Punto[0] + '" y="' + Punto[1] + '" width="3" height="5"/>'; }).join('');
  var Faroles = [39, 117, 273, 351].map(function (X) {
    return '<rect x="' + X + '" y="124" width="2" height="26" fill="#3A3470"/><circle cx="' + (X + 1) + '" cy="123" r="3" fill="#F5C84C" opacity=".85"/>';
  }).join('');
  var Ciudadcerca = '<svg width="390" height="270" viewBox="0 0 390 270" style="display:block"><g fill="#1C1838"><rect x="-6" y="73" width="44" height="77"/><rect x="38" y="51" width="47" height="99"/><rect x="88" y="80" width="58" height="70"/><rect x="146" y="1" width="58" height="149"/><rect x="204" y="23" width="52" height="127"/><rect x="256" y="48" width="53" height="102"/><rect x="309" y="44" width="37" height="106"/><rect x="349" y="55" width="31" height="95"/><rect x="380" y="59" width="51" height="91"/></g>' +
    '<g fill="#F5C84C" opacity=".5">' + Ventanas + '</g><rect x="0" y="150" width="390" height="120" fill="#13102A"/><rect x="0" y="150" width="390" height="3" fill="#3A3470"/>' + Faroles + '</svg><div style="height:600px;background:#13102A"></div>';

  var Globo = function (Colorizquierdo, Colorcentro, Colorfranja) {
    return '<svg width="44" height="60" viewBox="0 0 44 60" style="display:block"><path d="M22 2C10 2 3 11 3 21c0 9 8 16 13 22h12c5-6 13-13 13-22C41 11 34 2 22 2z" fill="' + Colorizquierdo + '"/><path d="M22 2c-5 0-8 9-8 19 0 9 3 16 4 22h8c1-6 4-13 4-22 0-10-3-19-8-19z" fill="' + Colorcentro + '"/><path d="M22 2c-2 0-3 9-3 19 0 9 1 16 1 22h4c0-6 1-13 1-22 0-10-1-19-3-19z" fill="' + Colorfranja + '"/><path d="M16 43l2 8M28 43l-2 8" stroke="#6E689E" stroke-width="1"/><rect x="17" y="51" width="10" height="7" rx="1.5" fill="#463D6E"/></svg>';
  };
  // Paleta atmosférica apagada para que ningún elemento decorativo se confunda con plataformas ni obstáculos
  var Dibujos = {
    Globoa: Globo('#5E4B8B', '#7B6FA8', '#49588A'),
    Globob: Globo('#49588A', '#736B9E', '#5E4B8B'),
    Avioneta: '<svg width="60" height="24" viewBox="0 0 60 24" style="display:block"><path d="M8 10L4 2h6l6 8z" fill="#585086"/><path d="M8 10h36c7 0 12 2 12 5s-5 4-12 4H12L6 12z" fill="#7D76AD"/><path d="M40 10h5c3 0 5 1 6 3H40z" fill="#4E6496"/><path d="M24 15h14l-4 7h-6z" fill="#635B91"/><rect x="56" y="8" width="2" height="13" rx="1" fill="#6E689E"/></svg>',
    Comercial: '<svg width="170" height="34" viewBox="0 0 170 34" style="display:block"><rect x="0" y="25" width="22" height="2" rx="1" fill="#8A84B8" opacity=".15"/><rect x="20" y="25" width="22" height="2" rx="1" fill="#8A84B8" opacity=".25"/><rect x="40" y="25" width="48" height="2" rx="1" fill="#8A84B8" opacity=".35"/><path d="M54 13L48 0h9l12 13z" fill="#585086"/><path d="M50 18l-4 5h12l4-5z" fill="#686196"/><rect x="50" y="13" width="110" height="10" rx="5" fill="#7D76AD"/><path d="M155 13c6 0 11 2 13 5-2 3-7 5-13 5z" fill="#7D76AD"/><path d="M95 20l-12 12h9l18-12z" fill="#686196"/><rect x="88" y="23" width="13" height="5" rx="2.5" fill="#585086"/><path d="M66 16.5h80" stroke="#463F73" stroke-width="2" stroke-dasharray="2 3"/><path d="M158 15h5l2 2h-7z" fill="#3B3563"/></svg>',
    Militar: '<svg width="70" height="22" viewBox="0 0 70 22" style="display:block"><path d="M8 9l-7 2 7 2z" fill="#6E689E"/><path d="M14 9L8 1h6l8 8z" fill="#48507A"/><path d="M8 11L30 6h22c8 0 14 3 16 5-2 2-8 5-16 5H30z" fill="#626C99"/><path d="M30 11L22 21h10l14-10z" fill="#48507A"/><path d="M50 7h6c3 0 6 1 7 3H50z" fill="#4E6496"/></svg>',
    Estrato: '<svg width="70" height="126" viewBox="0 0 70 126" style="display:block"><path d="M35 2C18 2 8 20 8 38c0 18 15 30 27 34 12-4 27-16 27-34C62 20 52 2 35 2z" fill="#8A84B8" opacity=".65"/><path d="M35 2c-6 0-10 18-10 36 0 18 5 30 10 34M35 2c6 0 10 18 10 36 0 18-5 30-10 34" stroke="#6E689E" fill="none" opacity=".6"/><path d="M35 72v40" stroke="#6E689E" stroke-width="1"/><rect x="28" y="112" width="14" height="10" rx="2" fill="#686196"/><rect x="20" y="115" width="8" height="3" fill="#4E6496"/><rect x="42" y="115" width="8" height="3" fill="#4E6496"/></svg>',
    Ovni: '<svg width="64" height="30" viewBox="0 0 64 30" style="display:block"><path d="M18 17c0-8 6-13 14-13s14 5 14 13z" fill="#526899" opacity=".75"/><ellipse cx="32" cy="20" rx="30" ry="8" fill="#635B91"/><ellipse cx="32" cy="18" rx="30" ry="3" fill="#7D76AD"/><circle cx="14" cy="21" r="2" fill="#8A84B8"/><circle cx="32" cy="24" r="2" fill="#8A84B8"/><circle cx="50" cy="21" r="2" fill="#8A84B8"/></svg>'
  };
  // Los aviones se voltean según para dónde vuelen; los globos y el resto no
  var Giran = { Avioneta: 1, Comercial: 1, Militar: 1 };
  var Tiposvolador = ['Globo', 'Avioneta', 'Comercial', 'Militar', 'Estrato', 'Ovni', 'Meteoro'];
  var Tiposcuerpo = ['Luna', 'Rojo', 'Anillos', 'Hielo', 'Gigante', 'Nebulosa'];

  var Planetas = {
    Luna: 'border-radius:50%;background:radial-gradient(circle at 62% 56%, rgba(90,85,125,.45) 0 10%, transparent 11%), radial-gradient(circle at 36% 68%, rgba(90,85,125,.38) 0 7%, transparent 8%), radial-gradient(circle at 48% 30%, rgba(90,85,125,.3) 0 5%, transparent 6%), radial-gradient(circle at 34% 30%, #E7E4F4 0%, #BAB6D2 48%, #75709A 100%);box-shadow:0 0 30px rgba(231,228,244,.18)',
    Rojo: 'border-radius:50%;background:radial-gradient(circle at 35% 30%, #F2A48A 0%, #C9694F 52%, #5E2A28 100%)',
    Hielo: 'border-radius:50%;background:radial-gradient(circle at 35% 30%, #E2F7FF 0%, #8FC9E8 50%, #34557F 100%)',
    Gigante: 'border-radius:50%;background:repeating-linear-gradient(172deg, rgba(110,62,52,0) 0 9px, rgba(110,62,52,.24) 9px 15px), radial-gradient(circle at 35% 30%, #F6D2A6 0%, #D9946A 55%, #6E3D33 100%)'
  };

  function Cuerpohtml(Cuerpo) {
    var Tipo = Tiposcuerpo.filter(function (Nombre) { return Cuerpo[Nombre]; })[0];
    var Caja = '<div style="position:absolute;left:0;top:0;width:' + Cuerpo.Tamano + 'px;height:' + Cuerpo.Tamano + 'px">';
    if (Tipo === 'Anillos') {
      return Caja + '<div style="position:relative;width:100%;height:100%"><div style="width:100%;height:100%;border-radius:50%;background:radial-gradient(circle at 35% 30%, #F4E3BC 0%, #C9A970 55%, #5E4A33 100%)"></div><div style="position:absolute;left:-38%;top:34%;width:176%;height:32%;border-radius:50%;border:2px solid rgba(244,227,188,.6);transform:rotate(-16deg)"></div></div></div>';
    }
    if (Tipo === 'Nebulosa') {
      return Caja + '<div style="width:100%;height:70%;border-radius:50%;background:radial-gradient(circle at 45% 50%, rgba(240,87,126,.22) 0%, rgba(79,216,232,.10) 42%, transparent 70%)"></div></div>';
    }
    return Caja + '<div style="width:100%;height:100%;' + Planetas[Tipo] + '"></div></div>';
  }

  function Voladorhtml(Volador) {
    var Tipo = Tiposvolador.filter(function (Nombre) { return Volador[Nombre]; })[0];
    if (Tipo === 'Meteoro') {
      return '<div style="position:absolute;left:0;top:0"><div style="position:relative;transform:rotate(' + Volador.Angulo + 'deg);transform-origin:0 0">' +
        '<span style="position:absolute;left:-100px;top:-1.5px;width:100px;height:3px;border-radius:2px;background:linear-gradient(90deg, rgba(255,178,122,0), rgba(255,190,140,.85))"></span>' +
        '<span style="position:absolute;left:-6px;top:-6px;width:12px;height:12px;border-radius:50%;background:radial-gradient(circle at 35% 35%, #F7CBA8, #B9785A 60%, #6B4134);box-shadow:0 0 10px rgba(255,154,107,.55)"></span></div></div>';
    }
    var Dibujo = Tipo === 'Globo' ? (Volador.Variante ? Dibujos.Globob : Dibujos.Globoa) : Dibujos[Tipo];
    var Volteo = Giran[Tipo] ? 'transform:scaleX(' + Volador.Giro + ');transform-origin:50% 50%' : '';
    return '<div style="position:absolute;left:0;top:0"><div style="transform-origin:0 0;transform:scale(' + Volador.Escala + ')"><div style="' + Volteo + '">' + Dibujo + '</div></div></div>';
  }

  var Mover = Ui.Mover;

  function Capasestrellas() {
    function Hash(Numero) { var X = Math.sin(Numero * 127.1 + 311.7) * 43758.5453; return X - Math.floor(X); }
    var Lejos = '', Cerca = '';
    for (var Indice = 0; Indice < 46; Indice++) {
      var X = Math.round(Hash(Indice) * 390), Y = Math.round(Hash(Indice + 99) * 844);
      var Tamano = Hash(Indice + 7) < 0.82 ? 2 : 3;
      var Op = (0.45 + Hash(Indice + 31) * 0.55).toFixed(2);
      var Par = '<span style="position:absolute;left:' + X + 'px;top:' + Y + 'px;width:' + Tamano + 'px;height:' + Tamano + 'px;border-radius:50%;background:#F3F1FF;opacity:' + Op + '"></span>' +
        '<span style="position:absolute;left:' + X + 'px;top:' + (Y - 844) + 'px;width:' + Tamano + 'px;height:' + Tamano + 'px;border-radius:50%;background:#F3F1FF;opacity:' + Op + '"></span>';
      if (Indice % 2 === 0) Lejos += Par; else Cerca += Par;
    }
    return '<div data-c="Estrellas1" style="position:absolute;inset:0;will-change:transform">' + Lejos + '</div>' +
      '<div data-c="Estrellas2" style="position:absolute;inset:0;will-change:transform">' + Cerca + '</div>';
  }

  Nj.Cielo = {
    Montar: function (Contenedor) {
      Contenedor.innerHTML = '<div data-c="Raiz" aria-hidden="true" style="position:absolute;inset:0;overflow:hidden;background:linear-gradient(180deg, #1B1840 0%, #3D3068 100%)">' +
        '<div data-c="Oscuridad" style="position:absolute;inset:0;background:linear-gradient(180deg, #07071A 0%, #140D2B 100%);opacity:0;pointer-events:none"></div>' +
        '<div data-c="Estrellas" style="position:absolute;inset:0;opacity:.32">' + Capasestrellas() + '</div><div data-c="Cuerpos"></div>' +
        '<div data-c="Tierra" style="position:absolute;display:none;border-radius:50%;background:radial-gradient(ellipse at 50% 0%, #5B93D0 0%, #2C548F 3%, #19335F 10%, #0F1E3F 26%)"></div>' +
        '<div data-c="Nubes"></div>' +
        '<div data-c="Ciudad"><div data-c="Lejos" style="position:absolute;left:0;top:0;width:390px;will-change:transform">' + Ciudadlejos + '</div>' +
        '<div data-c="Cerca" style="position:absolute;left:0;top:0;width:390px;will-change:transform">' + Ciudadcerca + '</div></div>' +
        '<div data-c="Voladores"></div></div>';
      var Refs = {};
      Contenedor.querySelectorAll('[data-c]').forEach(function (Nodo) { Refs[Nodo.dataset.c] = Nodo; });
      return Refs;
    },

    Actualizar: function (Refs, Fondo) {
      if (!Fondo) return;
      Ui.Opacidad(Refs.Oscuridad, Fondo.Oscuridad);
      Ui.Opacidad(Refs.Estrellas, Fondo.Brilloestrellas);
      Ui.Transformar(Refs.Estrellas1, 'translate3d(0,' + Fondo.Estrellasy1 + 'px,0)');
      Ui.Transformar(Refs.Estrellas2, 'translate3d(0,' + Fondo.Estrellasy2 + 'px,0)');
      if (Refs.Ultimoscuerpos !== Fondo.Cuerpos) {
        Refs.Ultimoscuerpos = Fondo.Cuerpos;
        Ui.Sincronizar(Refs.Cuerpos, Fondo.Cuerpos, Cuerpohtml, function (Nodo, Cuerpo) { Mover(Nodo, Cuerpo.X, Cuerpo.Y); });
      }
      // La Tierra solo se toca cuando cambia su posición o su tamaño
      var Tierra = Fondo.Tierra, Estilo = Refs.Tierra.style;
      var Firmatierra = Tierra.Ver ? Tierra.X + '|' + Tierra.Y + '|' + Tierra.Ancho : 'oculta';
      if (Refs.Ultimatierra !== Firmatierra) {
        Refs.Ultimatierra = Firmatierra;
        Estilo.display = Tierra.Ver ? 'block' : 'none';
        if (Tierra.Ver) { Estilo.left = Tierra.X + 'px'; Estilo.top = Tierra.Y + 'px'; Estilo.width = Tierra.Ancho + 'px'; Estilo.height = Tierra.Ancho + 'px'; }
      }
      if (Refs.Ultimasnubes !== Fondo.Nubes) {
        Refs.Ultimasnubes = Fondo.Nubes;
        Ui.Sincronizar(Refs.Nubes, Fondo.Nubes, function (Nube) {
          return '<svg width="' + Nube.Ancho + '" height="' + Nube.Alto + '" viewBox="0 0 100 44" style="position:absolute;left:0;top:0"><path d="M12 40h76c7 0 12-5 12-11s-5-11-12-11c-1-9-9-16-18-16-7 0-13 4-16 10-3-3-7-4-11-4-9 0-16 7-16 15C4 23 0 28 0 33c0 4 5 7 12 7z" fill="#A39CDB"/></svg>';
        }, function (Nodo, Nube) { Mover(Nodo, Nube.X, Nube.Y); Ui.Opacidad(Nodo, Nube.Opacidad); });
      }
      if (Refs.Ultimaciudad !== Fondo.Ciudad) { Refs.Ultimaciudad = Fondo.Ciudad; Refs.Ciudad.style.display = Fondo.Ciudad ? 'block' : 'none'; }
      if (Fondo.Ciudad) {
        Ui.Transformar(Refs.Lejos, 'translate3d(0,' + Fondo.Ylejos + 'px,0)');
        Ui.Transformar(Refs.Cerca, 'translate3d(0,' + Fondo.Ycerca + 'px,0)');
      }
      Ui.Sincronizar(Refs.Voladores, Fondo.Voladores, Voladorhtml, function (Nodo, Volador) { Mover(Nodo, Volador.X, Volador.Y); Ui.Opacidad(Nodo, Volador.Opacidad); });
    }
  };
})();
