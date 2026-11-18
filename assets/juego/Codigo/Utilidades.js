/* Utilidades compartidas de interfaz y sincronización DOM */
(function () {
  var Nj = (window.Neonjump = window.Neonjump || {});
  var Ui = (Nj.Interfaz = {});
  Nj.Pantallas = Nj.Pantallas || {};

  // Todo texto que escribe el jugador pasa por acá antes de meterlo al HTML
  Ui.Escapar = function (Texto) {
    return String(Texto == null ? '' : Texto).replace(/[&<>"']/g, function (Caracter) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[Caracter];
    });
  };

  Ui.Lista = function (Arreglo, Dibujar) { return Arreglo.map(Dibujar).join(''); };

  // Moldes ya interpretados: una pieza nueva se copia de aquí en vez de volver a leer su HTML
  var Moldes = new Map(), Maximomoldes = 300;
  function Crearnodo(Html) {
    var Molde = Moldes.get(Html);
    if (!Molde) {
      var Plantilla = document.createElement('template');
      Plantilla.innerHTML = Html.trim();
      Molde = Plantilla.content.firstElementChild;
      if (Moldes.size < Maximomoldes) Moldes.set(Html, Molde);
      else return Molde;
    }
    return Molde.cloneNode(true);
  }

  /* Pone al día los hijos de un contenedor según su Clave: crea los nuevos, mueve los que siguen y borra los que sobran.
     Así el juego no rehace todo el DOM en cada cuadro. Cada vuelta lleva un número para saber qué piezas siguen vivas. */
  Ui.Sincronizar = function (Contenedor, Elementos, Crear, Actualizar) {
    var Mapa = Contenedor.Mapanodos || (Contenedor.Mapanodos = new Map());
    var Vuelta = (Contenedor.Vuelta || 0) + 1;
    Contenedor.Vuelta = Vuelta;
    for (var Indice = 0; Indice < Elementos.length; Indice++) {
      var Elemento = Elementos[Indice], Nodo = Mapa.get(Elemento.Clave);
      if (!Nodo) {
        Nodo = Crearnodo(Crear(Elemento));
        Mapa.set(Elemento.Clave, Nodo);
        Contenedor.appendChild(Nodo);
      }
      Nodo.Vueltavista = Vuelta;
      Actualizar(Nodo, Elemento);
    }
    if (Mapa.size > Elementos.length) {
      Mapa.forEach(function (Nodo, Clave) { if (Nodo.Vueltavista !== Vuelta) { Nodo.remove(); Mapa.delete(Clave); } });
    }
  };

  /* Escribir un estilo obliga al navegador a recalcular; estas tres solo escriben si el valor cambió de verdad */
  Ui.Mover = function (Nodo, X, Y) {
    if (Nodo.Ultimax === X && Nodo.Ultimay === Y) return;
    Nodo.Ultimax = X; Nodo.Ultimay = Y;
    Nodo.style.transform = 'translate3d(' + X + 'px,' + Y + 'px,0)';
  };
  Ui.Transformar = function (Nodo, Valor) {
    if (Nodo.Ultimatransformacion === Valor) return;
    Nodo.Ultimatransformacion = Valor;
    Nodo.style.transform = Valor;
  };
  Ui.Opacidad = function (Nodo, Valor) {
    if (Nodo.Ultimaopacidad === Valor) return;
    Nodo.Ultimaopacidad = Valor;
    Nodo.style.opacity = Valor;
  };

  // Solo toca el texto si cambió, para no repintar de gana
  Ui.Texto = function (Nodo, Valor) {
    var Nuevo = String(Valor);
    if (Nodo && Nodo.Ultimovalor !== Nuevo) { Nodo.textContent = Nuevo; Nodo.Ultimovalor = Nuevo; }
  };

  // La bola del jugador: halo limpio sin animación de opacidad por cuadro para mantener la textura en GPU
  Ui.Bola = function (Skin, Tamano, Etiqueta) {
    var Rol = Etiqueta ? ' role="img" aria-label="' + Ui.Escapar(Etiqueta) + '"' : '';
    if (Skin.Imagen) {
      var Borde = Math.max(1.5, Math.round(Tamano * 0.08 * 10) / 10);
      return '<div style="position:relative;width:' + Tamano + 'px;height:' + Tamano + 'px;border-radius:50%">' +
        '<span aria-hidden="true" style="position:absolute;inset:-2px;border-radius:50%;border:' + Borde + 'px solid ' + Skin.Color + ';opacity:.45;pointer-events:none"></span>' +
        '<img data-esfera="1" src="' + Skin.Imagen + '" alt="' + Ui.Escapar(Etiqueta || '') + '" style="position:relative;width:100%;height:100%;border-radius:50%;display:block;object-fit:cover;transform-origin:50% 50%">' +
        '<span aria-hidden="true" style="position:absolute;inset:0;border-radius:50%;border:1px solid ' + Skin.Color + ';opacity:.6;pointer-events:none"></span></div>';
    }
    var Brillo = Math.round(Tamano * 0.35);
    return '<div' + Rol + ' style="width:' + Tamano + 'px;height:' + Tamano + 'px;border-radius:50%;background:radial-gradient(circle at 35% 32%, #FFFFFF 0%, ' + Skin.Color + ' 45%, ' + Skin.Color + ' 100%);box-shadow:0 0 ' + Brillo + 'px ' + Skin.Color + '88"></div>';
  };

  Ui.Moneda = function (Tamano) {
    return '<span aria-hidden="true" style="flex:none;display:inline-block;width:' + Tamano + 'px;height:' + Tamano + 'px;border-radius:50%;background:radial-gradient(circle at 35% 30%, #FFE9A8, #F5C84C 55%, #C9962E)"></span>';
  };

  Ui.Volver = '<button type="button" class="nj-btn nj-cristal" data-accion="Ir" data-valor="Menu" aria-label="Volver al menú" style="width:44px;height:44px;border:0;border-radius:999px;font-family:var(--f-mono);font-size:18px;padding:0">←</button>';

  Ui.Fuente = { Titular: 'font-family:var(--f-titular);font-weight:900;text-transform:uppercase;', Mono: 'font-family:var(--f-mono);' };
})();
