/* Pantalla de bienvenida y registro inicial */
(function () {
  var Nj = (window.Neonjump = window.Neonjump || {}), Ui = Nj.Interfaz;
  var Borrador = '', Error = '', Ocupado = false, Confirmando = false;

  var Iconogoogle = '<svg width="18" height="18" viewBox="0 0 18 18" aria-hidden="true">' +
    '<path fill="#4285F4" d="M17.1 9.2c0-.6-.1-1.2-.2-1.8H9v3.4h4.5a3.9 3.9 0 0 1-1.7 2.5v2.1h2.7c1.6-1.5 2.6-3.7 2.6-6.2z"/>' +
    '<path fill="#34A853" d="M9 17.5c2.3 0 4.2-.8 5.6-2.1l-2.7-2.1c-.8.5-1.7.8-2.9.8-2.2 0-4.1-1.5-4.8-3.5H1.4v2.2A8.5 8.5 0 0 0 9 17.5z"/>' +
    '<path fill="#FBBC05" d="M4.2 10.6a5.1 5.1 0 0 1 0-3.2V5.2H1.4a8.5 8.5 0 0 0 0 7.6l2.8-2.2z"/>' +
    '<path fill="#EA4335" d="M9 3.9c1.2 0 2.4.4 3.2 1.3l2.4-2.4A8.4 8.4 0 0 0 9 .5 8.5 8.5 0 0 0 1.4 5.2l2.8 2.2C4.9 5.4 6.8 3.9 9 3.9z"/>' +
    '</svg>';

  function Renderaviso() {
    return '<div role="dialog" aria-modal="true" aria-labelledby="nj-riesgo-titulo" style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;padding:24px;background:rgba(14,12,34,.9)">' +
      '<div class="nj-cristal nj-caja nj-sube" style="width:100%;padding:22px 20px;border:1px solid var(--linea-fuerte);background:var(--tinta-2);text-align:center">' +
      '<p style="margin:0;font-family:var(--f-mono);font-size:10px;letter-spacing:.16em;color:var(--amarillo)">AVISO IMPORTANTE</p>' +
      '<h2 id="nj-riesgo-titulo" style="margin:8px 0 0 0;' + Ui.Fuente.Titular + 'font-size:32px;line-height:.95;color:var(--hueso)">Progreso sin respaldo</h2>' +
      '<p style="margin:12px 0 0 0;font-size:14px;line-height:1.45;color:var(--hueso-2)">Si continúas sin vincular tu cuenta de Google, corres el riesgo de perder tu progreso.</p>' +
      '<div style="display:flex;gap:10px;margin-top:20px">' +
      '<button type="button" data-accion="Cancelarriesgo" class="nj-btn" style="flex:1;height:48px;background:transparent;border:1px solid var(--linea-fuerte);color:var(--hueso-2);font-family:var(--f-mono);font-size:11px;font-weight:700;letter-spacing:.08em">VOLVER</button>' +
      '<button type="button" data-accion="Confirmarriesgo" class="nj-btn" style="flex:1.3;height:48px;background:var(--acento);border:0;color:var(--tinta);font-family:var(--f-mono);font-size:11px;font-weight:700;letter-spacing:.06em;box-shadow:0 4px 0 var(--acento-hondo)">CONTINUAR DE TODAS FORMAS</button>' +
      '</div></div></div>';
  }

  function Validarremoto(Nombre, Callback) {
    if (!Nj.Puente || !Nj.Puente.Validarnombre) { Callback(''); return; }
    Nj.Puente.Validarnombre(Nombre).then(function (Mensaje) {
      Callback(Mensaje && Mensaje.indexOf('Sin conexión') < 0 ? Mensaje : '');
    });
  }

  Nj.Pantallas.Bienvenida = {
    Reiniciar: function (Nombreinicial) {
      Borrador = Nombreinicial && !/^Jugador_\d{5}$/.test(Nombreinicial.trim()) ? Nombreinicial.trim() : '';
      Error = '';
      Ocupado = false;
      Confirmando = false;
    },

    Confirmandoactual: function () { return Confirmando; },

    Alescribir: function (Valor) {
      Borrador = String(Valor || '').slice(0, 20);
      Error = '';
      var Contador = document.getElementById('nj-bienvenida-cnt');
      if (Contador) Contador.textContent = Borrador.trim().length + '/20';
      var Alerta = document.getElementById('nj-bienvenida-error');
      if (Alerta) {
        var Revision = Nj.Validarnombre(Borrador);
        var Incompleto = Borrador.trim().length >= 3 && !Revision.Valido;
        Alerta.textContent = Incompleto ? Revision.Error : '3 a 20 caracteres: letras, números, espacios, _ . -';
        Alerta.style.color = Incompleto ? 'var(--coral)' : 'var(--hueso-3)';
      }
    },

    Continuar: function (Internos) {
      if (Ocupado) return;
      var Limpio = Borrador.trim();
      if (!Limpio) {
        Error = 'Debes registrar un nombre de usuario para poder continuar.';
        Internos.Dibujar();
        return;
      }
      var Revision = Nj.Validarnombre(Limpio);
      if (!Revision.Valido) {
        Error = Revision.Error;
        Internos.Dibujar();
        return;
      }
      Borrador = Revision.Limpio;
      Ocupado = true; Error = ''; Internos.Dibujar();
      Validarremoto(Borrador, function (Mensaje) {
        Ocupado = false;
        if (Mensaje) { Error = Mensaje; Internos.Dibujar(); return; }
        Confirmando = true;
        Internos.Dibujar();
      });
    },

    Vincular: function (Internos) {
      if (Ocupado) return;
      var Limpio = Borrador.trim();
      if (Limpio) {
        var Revision = Nj.Validarnombre(Limpio);
        if (!Revision.Valido) { Error = Revision.Error; Internos.Dibujar(); return; }
        Borrador = Revision.Limpio;
      }
      var Ejecutarvinculo = function (Nombreparagoogle) {
        if (!Nj.Puente || !Nj.Puente.Vinculargoogle) { Internos.Entrarmenu(Nombreparagoogle || 'Jugador', false); return; }
        Ocupado = true; Error = ''; Internos.Dibujar();
        Nj.Puente.Vinculargoogle(Nombreparagoogle).then(function (Res) {
          Ocupado = false;
          if (Res && Res.Google) { Internos.Entrarmenu(null, false); return; }
          if (Res && Res.Sinperfil) {
            Error = 'No tienes un perfil con nosotros. Crea un nombre de usuario primero y luego vuelve a pinchar el botón de Google.';
          } else {
            Error = 'No se completó el inicio con Google.';
          }
          Internos.Dibujar();
        });
      };
      if (!Limpio) { Ejecutarvinculo(''); return; }
      Ocupado = true; Error = ''; Internos.Dibujar();
      Validarremoto(Borrador, function (Mensaje) {
        if (Mensaje) { Ocupado = false; Error = Mensaje; Internos.Dibujar(); return; }
        Ejecutarvinculo(Borrador);
      });
    },

    Cancelarriesgo: function (Internos) { Confirmando = false; Internos.Dibujar(); },

    Confirmarriesgo: function (Internos) {
      Confirmando = false;
      Internos.Entrarmenu(Borrador.trim(), true);
    },

    Render: function (App) {
      var Skin = Nj.Skins[App.Estado.Equipada], Largo = Borrador.trim().length;
      return '<main class="nj-raiz" style="position:relative;width:390px;height:844px;overflow-y:auto;background:linear-gradient(180deg, #1B1840 0%, #2B2457 60%, #3D3068 100%)">' +
        '<div aria-hidden="true" class="nj-puntos" style="position:absolute;inset:0;pointer-events:none"></div>' +
        '<div style="position:relative;min-height:100%;display:flex;flex-direction:column;justify-content:center;padding:38px 22px 26px 22px;text-align:center">' +
        '<div style="margin:0 auto 10px auto">' + Ui.Bola(Skin, 32) + '</div>' +
        '<h1 style="margin:0;' + Ui.Fuente.Titular + 'font-size:40px;line-height:.92;color:var(--hueso)">Crea un nombre de usuario para el ranking</h1>' +
        '<section class="nj-cristal nj-caja" style="margin-top:16px;padding:16px;border:1px solid var(--linea-fuerte);text-align:left">' +
        '<div style="display:flex;justify-content:space-between;align-items:baseline">' +
        '<label for="nj-bienvenida-nombre" style="font-family:var(--f-mono);font-size:10px;letter-spacing:.14em;color:var(--hueso-2)">NOMBRE DE USUARIO</label>' +
        '<span id="nj-bienvenida-cnt" style="font-family:var(--f-mono);font-size:10px;color:var(--hueso-3)">' + Largo + '/20</span></div>' +
        '<input id="nj-bienvenida-nombre" class="nj-foco" type="text" data-entrada="bienvenida" value="' + Ui.Escapar(Borrador) + '" maxlength="20" autocomplete="nickname" placeholder="Ej. NeonPro_21" ' + (Ocupado ? 'disabled ' : '') +
        'style="margin-top:8px;width:100%;height:48px;padding:0 12px;background:var(--tinta);border:1px solid var(--linea-fuerte);border-radius:10px;color:var(--hueso);font-family:var(--f-mono);font-size:16px">' +
        '<p id="nj-bienvenida-error" role="alert" style="margin:8px 0 0 0;min-height:18px;font-size:12px;line-height:1.35;color:' + (Error ? 'var(--coral)' : 'var(--hueso-3)') + '">' +
        Ui.Escapar(Error || '3 a 20 caracteres: letras, números, espacios, _ . -') + '</p></section>' +
        '<p style="margin:20px 0 10px 0;font-size:14px;color:var(--hueso-2)">¿Estás volviendo? <strong style="color:var(--hueso)">¡Qué bueno!</strong></p>' +
        '<button type="button" data-accion="Vincularbienvenida" ' + (Ocupado ? 'disabled ' : '') +
        'class="nj-btn" style="width:100%;height:52px;display:flex;align-items:center;justify-content:center;gap:10px;background:var(--hueso);color:var(--tinta);border:0;border-radius:14px;font-family:var(--f-mono);font-size:12px;font-weight:700;letter-spacing:.08em">' +
        Iconogoogle + (Ocupado ? 'CONECTANDO...' : 'CONTINUAR CON GOOGLE') + '</button>' +
        '<button type="button" data-accion="Continuarsinvinculo" ' + (Ocupado ? 'disabled ' : '') +
        'class="nj-btn" style="margin-top:12px;width:100%;height:54px;background:var(--acento);color:var(--tinta);border:0;border-radius:14px;box-shadow:0 5px 0 var(--acento-hondo);' + Ui.Fuente.Titular + 'font-size:28px">' +
        (Ocupado ? 'Verificando...' : 'Continuar') + '</button>' +
        '</div>' + (Confirmando ? Renderaviso() : '') + '</main>';
    }
  };

  Nj.Pantallas.Avisorespaldo = function () {
    return '<div role="dialog" aria-modal="true" aria-labelledby="nj-respaldo-msg" style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;padding:24px;background:rgba(14,12,34,.86)">' +
      '<div class="nj-cristal nj-caja nj-sube" style="width:100%;padding:22px 20px;border:1px solid rgba(79,216,232,.45);background:var(--tinta-2);text-align:center">' +
      '<p style="margin:0;font-family:var(--f-mono);font-size:10px;letter-spacing:.16em;color:var(--acento)">CONSEJO</p>' +
      '<p id="nj-respaldo-msg" style="margin:10px 0 0 0;font-size:15px;line-height:1.45;color:var(--hueso)">Puedes guardar tu progreso cuando quieras en los ajustes de tu perfil.</p>' +
      '<div style="display:flex;gap:10px;margin-top:18px">' +
      '<button type="button" data-accion="Iraperfilrespaldo" class="nj-btn" style="flex:1;height:46px;background:transparent;border:1px solid var(--linea-fuerte);color:var(--hueso-2);font-family:var(--f-mono);font-size:11px;font-weight:700;letter-spacing:.08em">IR A AJUSTES</button>' +
      '<button type="button" data-accion="Cerraravisorespaldo" class="nj-btn" style="flex:1;height:46px;background:var(--acento);border:0;color:var(--tinta);font-family:var(--f-mono);font-size:11px;font-weight:700;letter-spacing:.08em;box-shadow:0 4px 0 var(--acento-hondo)">ENTENDIDO</button>' +
      '</div></div></div>';
  };
})();
