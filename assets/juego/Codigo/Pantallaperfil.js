/* Vista de perfil, estadísticas, ajustes y soporte */
(function () {
  var Nj = window.Neonjump, Ui = Nj.Interfaz;
  var Patroncorreo = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
  var Minimos = { Nombre: 3, Correo: 6, Asunto: 5, Descripcion: 15 };
  var Iconochulo = '<svg width="22" height="22" viewBox="0 0 14 14" fill="none" stroke="currentColor" stroke-width="2.2" aria-hidden="true"><path d="M2 7.5l3.2 3L12 3.5"/></svg>';

  function Textoayuda(Nombre) {
    if (Nj.Validarnombre) {
      var Revision = Nj.Validarnombre(Nombre);
      if (!Revision.Valido) return Revision.Error;
      return Revision.Limpio.length + '/20 · así te verán en el ranking.';
    }
    var Largo = (Nombre || '').trim().length;
    return Largo < 3 ? 'Usa al menos 3 caracteres.' : Largo + '/20 · así te verán en el ranking.';
  }

  var Estilocampo = 'margin-top:5px;width:100%;padding:10px 12px;background:var(--tinta);border:1px solid var(--linea-fuerte);border-radius:10px;color:var(--hueso);font-family:var(--f-cuerpo);font-size:14px;outline:none';
  var Tipossolicitud = ['PQR', 'Soporte'];

  function Envolvercampo(Id, Clave, Etiqueta, Etiquetaderecha, Control) {
    return '<div style="margin-top:12px">' +
      '<div style="display:flex;justify-content:space-between;align-items:baseline">' +
      '<label for="' + Id + '" style="font-family:var(--f-mono);font-size:10px;letter-spacing:.12em;color:var(--hueso-2)">' + Etiqueta + '</label>' +
      '<span id="nj-ayuda-cnt-' + Clave + '" style="font-family:var(--f-mono);font-size:10px;color:var(--hueso-3)">' + Etiquetaderecha + '</span></div>' +
      Control + '</div>';
  }

  function Campo(Id, Clave, Etiqueta, Tipo, Minimo, Maximo, Ejemplo, Multilinea) {
    var Control = Multilinea
      ? '<textarea id="' + Id + '" class="nj-foco" rows="3" data-ayuda="' + Clave + '" minlength="' + Minimo + '" maxlength="' + Maximo + '" placeholder="' + Ui.Escapar(Ejemplo) + '" style="' + Estilocampo + ';resize:none;line-height:1.4"></textarea>'
      : '<input id="' + Id + '" class="nj-foco" type="' + Tipo + '" data-ayuda="' + Clave + '" minlength="' + Minimo + '" maxlength="' + Maximo + '" placeholder="' + Ui.Escapar(Ejemplo) + '" style="' + Estilocampo + ';height:42px">';
    return Envolvercampo(Id, Clave, Etiqueta, 'Mín. ' + Minimo + ' car.', Control);
  }

  function Camposelect(Id, Clave, Etiqueta, Opciones) {
    var Html = '<option value="" disabled selected hidden>Selecciona una opción...</option>';
    for (var Indice = 0; Indice < Opciones.length; Indice++) {
      var Valor = Ui.Escapar(Opciones[Indice]);
      Html += '<option value="' + Valor + '" style="background:#16132E;color:#F3F1FF">' + Valor + '</option>';
    }
    var Control = '<select id="' + Id + '" class="nj-foco" data-ayuda="' + Clave + '" style="' + Estilocampo + ';height:42px;cursor:pointer">' + Html + '</select>';
    return Envolvercampo(Id, Clave, Etiqueta, 'Obligatorio', Control);
  }

  // Revisa un campo y devuelve si está bien y qué mostrar en su contador
  function Revisarcampo(Clave, Valor) {
    var Limpio = (Valor || '').trim();
    if (Clave === 'Tipo') {
      var Elegido = Tipossolicitud.indexOf(Limpio) >= 0;
      return { Correcto: Elegido, Texto: Elegido ? 'Listo' : 'Obligatorio', Alerta: false };
    }
    var Minimo = Minimos[Clave], Largo = Limpio.length;
    if (Clave === 'Correo') {
      var Valido = Largo >= Minimo && Patroncorreo.test(Limpio);
      return { Correcto: Valido, Texto: Valido ? 'Válido' : (Largo === 0 ? 'Mín. ' + Minimo + ' car.' : 'Correo inválido'), Alerta: Largo > 0 && !Valido };
    }
    var Correcto = Largo >= Minimo;
    return {
      Correcto: Correcto,
      Texto: Correcto ? (Clave === 'Descripcion' ? Largo + '/500' : 'Listo') : Largo + '/' + Minimo + ' mín.',
      Alerta: false
    };
  }

  function Validarformulario() {
    var Claves = ['Tipo', 'Nombre', 'Correo', 'Asunto', 'Descripcion'], Todobien = true;
    for (var Indice = 0; Indice < Claves.length; Indice++) {
      var Clave = Claves[Indice];
      var Entrada = document.querySelector('[data-ayuda="' + Clave + '"]');
      var Contador = document.getElementById('nj-ayuda-cnt-' + Clave);
      if (!Entrada) return false;
      var Revision = Revisarcampo(Clave, Entrada.value);
      if (!Revision.Correcto) Todobien = false;
      if (Contador) {
        Contador.textContent = Revision.Texto;
        Contador.style.color = Revision.Correcto ? 'var(--verde)' : (Revision.Alerta ? 'var(--coral)' : 'var(--hueso-3)');
      }
    }
    var Boton = document.getElementById('nj-ayuda-enviar');
    if (Boton) Boton.disabled = Enviando || !Todobien;
    return Todobien;
  }

  var Enviando = false;
  var Envioid = 0;

  function Mostrarerrorayuda(Mensaje) {
    var Aviso = document.getElementById('nj-ayuda-error');
    if (!Aviso) return;
    Aviso.textContent = Mensaje || '';
    Aviso.style.display = Mensaje ? 'block' : 'none';
  }

  function Mostrarconfirmacion(Datos) {
    var Cuerpo = document.getElementById('nj-ayuda-cuerpo');
    if (!Cuerpo) return;
    Cuerpo.innerHTML =
      '<div style="text-align:center;padding:18px 4px 8px 4px">' +
      '<div aria-hidden="true" style="width:52px;height:52px;margin:0 auto 14px auto;border-radius:999px;background:rgba(94,214,160,.16);border:1px solid var(--verde);display:flex;align-items:center;justify-content:center;color:var(--verde)">' + Iconochulo + '</div>' +
      '<h3 style="margin:0;' + Ui.Fuente.Titular + 'font-size:30px;line-height:1">¡Solicitud enviada!</h3>' +
      '<p style="margin:10px 0 0 0;font-size:13px;line-height:1.45;color:var(--hueso-2)">Gracias, <strong style="color:var(--hueso)">' + Ui.Escapar(Datos.Nombre) + '</strong>. Recibimos tu solicitud (<strong style="color:var(--hueso)">' + Ui.Escapar(Datos.Tipo) + '</strong>) sobre «' + Ui.Escapar(Datos.Asunto) + '» y te responderemos pronto a <span style="color:var(--acento)">' + Ui.Escapar(Datos.Correo) + '</span>.</p>' +
      '<button type="button" data-accion="Cerrarayuda" class="nj-btn" style="margin-top:20px;width:100%;height:48px;background:var(--acento);border:0;color:var(--tinta);font-family:var(--f-mono);font-size:12px;font-weight:700;letter-spacing:.12em">ENTENDIDO</button></div>';
  }

  function Enviarformulario(Estado) {
    if (Enviando || !Validarformulario()) return false;
    var Datos = {
      Tipo: document.getElementById('nj-ayuda-tipo').value.trim(),
      Nombre: document.getElementById('nj-ayuda-nom').value.trim(),
      Correo: document.getElementById('nj-ayuda-correo').value.trim(),
      Asunto: document.getElementById('nj-ayuda-asunto').value.trim(),
      Descripcion: document.getElementById('nj-ayuda-desc').value.trim(),
      Jugador: (Estado && Estado.Nombre) || '',
      Version: Nj.Version || ''
    };
    Mostrarerrorayuda('');

    if (Nj.Puente && Nj.Puente.Enviarsoporte) {
      Enviando = true;
      var Esteenvio = ++Envioid;
      var Boton = document.getElementById('nj-ayuda-enviar');
      if (Boton) {
        Boton.disabled = true;
        Boton.textContent = 'ENVIANDO...';
      }
      Nj.Puente.Enviarsoporte(Datos).then(function (Respuesta) {
        if (Esteenvio !== Envioid) return;
        Enviando = false;
        if (!document.getElementById('nj-ayuda-cuerpo')) return;
        if (Respuesta && Respuesta.ok) {
          Mostrarconfirmacion(Datos);
          return;
        }
        var Botonactual = document.getElementById('nj-ayuda-enviar');
        if (Botonactual) Botonactual.textContent = 'ENVIAR';
        Validarformulario();
        Mostrarerrorayuda((Respuesta && Respuesta.error) || 'No se pudo enviar. Revisa tu conexión e intenta de nuevo.');
      });
      return true;
    }

    // Respaldo HTTP si se configura Nj.Urlsoporte fuera del puente nativo
    if (Nj.Urlsoporte && window.fetch) {
      try {
        fetch(Nj.Urlsoporte, {
          method: 'POST', mode: 'no-cors',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(Datos)
        }).catch(function () {});
      } catch (Fallo) {}
    }
    Mostrarconfirmacion(Datos);
    return true;
  }

  // Hoja que sube desde abajo con el formulario de ayuda
  Nj.Pantallas.Ayuda = function () {
    Enviando = false;
    Envioid++;
    return '<div role="dialog" aria-modal="true" aria-labelledby="nj-ayuda-titulo" style="position:absolute;inset:0;display:flex;align-items:flex-end;background:rgba(14,12,34,.86)">' +
      '<div data-accion="Cerrarayuda" style="position:absolute;inset:0"></div>' +
      '<div class="nj-raiz nj-hoja-sube" style="position:relative;width:100%;max-height:90%;overflow-y:auto;background:var(--tinta-2);border-top:1px solid var(--linea-fuerte);border-radius:22px 22px 0 0;padding:12px 20px 24px 20px;box-shadow:0 -18px 50px rgba(0,0,0,.55)">' +
      '<div aria-hidden="true" style="width:40px;height:4px;border-radius:999px;background:var(--linea-fuerte);margin:0 auto 12px auto"></div>' +
      '<div id="nj-ayuda-cuerpo">' +
      '<h3 id="nj-ayuda-titulo" style="margin:0;' + Ui.Fuente.Titular + 'font-size:28px;line-height:1">¿Necesitas ayuda?</h3>' +
      '<p style="margin:4px 0 2px 0;font-size:13px;color:var(--hueso-2)">Elige si es PQR o Soporte y completa los campos.</p>' +
      '<form id="nj-form-ayuda">' +
      Camposelect('nj-ayuda-tipo', 'Tipo', 'TIPO DE SOLICITUD', Tipossolicitud) +
      Campo('nj-ayuda-nom', 'Nombre', 'NOMBRE', 'text', Minimos.Nombre, 60, 'Tu nombre', false) +
      Campo('nj-ayuda-correo', 'Correo', 'CORREO', 'email', Minimos.Correo, 100, 'tu@correo.com', false) +
      Campo('nj-ayuda-asunto', 'Asunto', 'ASUNTO', 'text', Minimos.Asunto, 80, 'Ej. Problema con mis monedas', false) +
      Campo('nj-ayuda-desc', 'Descripcion', 'DESCRIPCIÓN', 'text', Minimos.Descripcion, 500, 'Describe tu solicitud con detalle...', true) +
      '<p id="nj-ayuda-error" role="alert" style="display:none;margin:10px 0 0 0;font-size:12px;line-height:1.35;color:var(--coral)"></p>' +
      '<div style="display:flex;gap:10px;margin-top:16px">' +
      '<button type="button" data-accion="Cerrarayuda" class="nj-btn" style="flex:1;height:48px;background:transparent;border:1px solid var(--linea-fuerte);color:var(--hueso-2);font-family:var(--f-mono);font-size:12px;font-weight:700;letter-spacing:.1em">CANCELAR</button>' +
      '<button type="button" id="nj-ayuda-enviar" data-accion="Enviarayuda" disabled class="nj-btn" style="flex:1;height:48px;background:var(--acento);border:0;color:var(--tinta);font-family:var(--f-mono);font-size:12px;font-weight:700;letter-spacing:.1em">ENVIAR</button>' +
      '</div></form></div></div></div>';
  };
  Nj.Pantallas.Ayuda.Validar = Validarformulario;
  Nj.Pantallas.Ayuda.Enviar = Enviarformulario;

  Nj.Pantallas.Perfil = {
    Textoayuda: Textoayuda,
    Render: function (App) {
      var Estado = App.Estado, Skin = Nj.Skins[Estado.Equipada];
      var Datos = [['PARTIDAS', Estado.Partidas], ['CAÍDAS', Estado.Caidas], ['RÉCORD', Nj.Formatear(Estado.Mejor)],
        ['MONEDAS', Nj.Formatear(Estado.Monedastotales)], ['JUGADO', Math.round(Estado.Segundosjugados / 60) + ' min'], ['RACHA', Estado.Racha + ' días']];
      var Estadisticas = Ui.Lista(Datos, function (Dato, Indice) {
        return '<div style="padding:12px 0 12px ' + (Indice % 3 ? '12px;border-left:1px solid var(--linea)' : '0') + ';border-bottom:1px solid var(--linea)"><dt style="font-family:var(--f-mono);font-size:10px;letter-spacing:.12em;color:var(--hueso-2)">' + Dato[0] + '</dt>' +
          '<dd style="margin:4px 0 0 0;font-family:var(--f-titular);font-weight:800;font-size:26px;line-height:1">' + Dato[1] + '</dd></div>';
      });
      var Interruptor = function (Clave, Nombre) {
        var Encendido = !!Estado[Clave];
        return '<div style="display:flex;justify-content:space-between;align-items:center;height:56px;border-bottom:1px solid var(--linea)"><span id="nj-sw-' + Clave + '" style="font-size:15px">' + Nombre + '</span>' +
          '<button type="button" role="switch" aria-checked="' + Encendido + '" aria-labelledby="nj-sw-' + Clave + '" data-accion="Alternar" data-valor="' + Clave + '" class="nj-btn" style="width:52px;height:28px;padding:3px;border:1px solid ' + (Encendido ? 'var(--acento)' : 'var(--linea-fuerte)') + ';background:' + (Encendido ? 'var(--acento)' : 'transparent') + ';display:flex;justify-content:' + (Encendido ? 'flex-end' : 'flex-start') + '">' +
          '<span style="width:20px;height:20px;border-radius:6px;background:' + (Encendido ? 'var(--tinta)' : 'var(--hueso-2)') + '"></span></button></div>';
      };
      var Enlace = 'color:var(--hueso-2)';

      return '<main class="nj-raiz" style="position:relative;width:390px;height:844px;overflow-x:hidden;overflow-y:auto;background:var(--tinta)">' +
        '<header style="display:flex;justify-content:space-between;align-items:center;padding:34px 20px 0 20px">' + Ui.Volver +
        '<p style="margin:0;font-family:var(--f-mono);font-size:10px;letter-spacing:.14em;color:var(--hueso-3)">' + Ui.Escapar(Nj.Version || 'VERSIÓN 1.1.3') + '</p></header>' +
        '<section style="display:grid;grid-template-columns:72px 1fr;gap:16px;align-items:end;padding:18px 20px 0 20px">' + Ui.Bola(Skin, 72, 'Tu skin: ' + Skin.Nombre) +
        '<h1 style="margin:0;' + Ui.Fuente.Titular + 'font-size:64px;line-height:.8">Perfil</h1></section>' +

        '<section style="padding:20px 20px 0 20px"><label for="nj-nombre" style="display:block;font-family:var(--f-mono);font-size:10px;letter-spacing:.14em;color:var(--hueso-2)">NOMBRE EN EL RANKING</label>' +
        '<input id="nj-nombre" class="nj-foco" type="text" data-entrada="nombre" value="' + Ui.Escapar(Estado.Nombre) + '" maxlength="20" autocomplete="nickname" style="margin-top:6px;width:100%;height:48px;padding:0 12px;background:var(--tinta-2);border:1px solid var(--linea-fuerte);border-radius:10px;color:var(--hueso);font-family:var(--f-mono);font-size:16px">' +
        '<p id="nj-ayuda-nombre" style="margin:6px 0 0 0;font-size:12px;color:var(--hueso-3)">' + Textoayuda(Estado.Nombre) + '</p></section>' +

        '<section aria-label="Cuenta" class="nj-caja" style="margin:18px 20px 0 20px;padding:14px;background:var(--tinta-2);border:1px solid var(--linea);display:grid;grid-template-columns:1fr auto;gap:12px;align-items:center">' +
        '<div><p style="margin:0;font-size:15px;font-weight:700">Cuenta de Google</p><p style="margin:2px 0 0 0;font-size:13px;color:var(--hueso-2)">' +
        (Estado.Google ? 'Vinculada. Tu progreso se respalda en la nube.' : 'Sin vincular. Vincúlala para no perder récord, monedas ni skins.') + '</p></div>' +
        '<button type="button" class="nj-btn" data-accion="Alternar" data-valor="Google" style="height:44px;padding:0 14px;border:' + (Estado.Google ? '1px solid var(--linea-fuerte)' : '0') + ';background:' + (Estado.Google ? 'transparent' : 'var(--acento)') + ';color:' + (Estado.Google ? 'var(--hueso-2)' : 'var(--tinta)') + ';font-family:var(--f-mono);font-size:11px;font-weight:700;letter-spacing:.12em">' + (Estado.Google ? 'DESVINCULAR' : 'VINCULAR') + '</button></section>' +

        '<dl style="margin:18px 20px 0 20px;display:grid;grid-template-columns:repeat(3, minmax(0, 1fr));border-top:1px solid var(--linea-fuerte)">' + Estadisticas + '</dl>' +

        '<section aria-label="Ajustes" style="padding:18px 20px 0 20px"><h2 style="margin:0 0 4px 0;font-family:var(--f-titular);font-weight:800;font-size:24px;text-transform:uppercase">Ajustes</h2>' +
        Interruptor('Sonido', 'Efectos de sonido') + Interruptor('Musica', 'Música') + Interruptor('Vibracion', 'Vibración al rebotar') +
        '<div style="padding:14px 0;border-bottom:1px solid var(--linea)"><div style="display:flex;justify-content:space-between"><label for="nj-sens" style="font-size:15px">Sensibilidad del control</label>' +
        '<span id="nj-sens-valor" style="font-family:var(--f-mono);font-size:13px;color:var(--acento)">' + Estado.Sensibilidad + '</span></div>' +
        '<input id="nj-sens" class="nj-foco" type="range" min="0" max="100" step="5" data-entrada="sensibilidad" value="' + Estado.Sensibilidad + '" style="width:100%;margin-top:10px;accent-color:var(--acento)">' +
        '<div style="display:flex;justify-content:space-between;font-family:var(--f-mono);font-size:10px;color:var(--hueso-3)"><span>SUAVE</span><span>RÁPIDA</span></div></div></section>' +

        '<nav aria-label="Legal" style="display:flex;flex-direction:column;align-items:center;gap:14px;padding:26px 20px 48px 20px;font-size:13px">' +
        '<div style="display:flex;flex-wrap:wrap;justify-content:center;align-items:center;gap:10px 22px">' +
        '<a href="#" style="' + Enlace + '">Política de privacidad</a>' +
        '<a href="#" style="' + Enlace + '">Condiciones del servicio</a></div>' +
        '<div style="display:flex;flex-wrap:wrap;justify-content:center;align-items:center;gap:10px 22px">' +
        '<a href="#" style="color:var(--rosa)">Eliminar mi cuenta</a>' +
        '<a href="#" data-accion="Ayuda" style="color:var(--acento);font-weight:600;text-decoration:none">¿Necesitas ayuda?</a></div></nav></main>';
    }
  };
})();
