import 'package:flutter/material.dart';

/// Paleta oficial del proyecto (DOCS/context.md, Parte A, sección 3),
/// ahora dinámica — modo oscuro y alto contraste (Perfil → Apariencia/
/// Accesibilidad). Los 5 nombres históricos (`navy`/`teal`/`skyBlue`/
/// `beige`/`white`) se mantienen como ROLES semánticos (ink principal,
/// acento, relleno claro, fondo de página, superficie de tarjeta) en
/// vez de colores literales — en modo oscuro esos roles se repintan
/// con variantes de los mismos tonos de marca, nunca con una paleta
/// ajena. `border`/`textSecondary`/`shadow` son roles nuevos para
/// reemplazar los `Colors.grey`/`Colors.black` sueltos que había por
/// toda la app (que no cambiaban con el tema).
///
/// `configurar()` lo llama una sola vez por rebuild `MediRutaApp` (raíz
/// de la app, ver `main.dart`) — todo lo demás lee estos getters sin
/// necesitar `BuildContext`, exactamente como antes.
class AppColors {
  AppColors._();

  static bool _oscuro = false;
  static bool _altoContraste = false;

  static void configurar({required bool oscuro, required bool altoContraste}) {
    _oscuro = oscuro;
    _altoContraste = altoContraste;
  }

  static bool get modoOscuro => _oscuro;

  /// Ink/texto principal — antes "navy" literal, ahora el rol
  /// "texto/acento fuerte": claro sobre fondo oscuro, oscuro sobre
  /// fondo claro.
  static Color get navy {
    if (_altoContraste) {
      return _oscuro ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    }
    return _oscuro ? const Color(0xFFE9EEF3) : const Color(0xFF2F4156);
  }

  /// Acento secundario.
  static Color get teal {
    if (_altoContraste) {
      return _oscuro ? const Color(0xFF8FE3FF) : const Color(0xFF0B4F6C);
    }
    return _oscuro ? const Color(0xFF8FB4C4) : const Color(0xFF567C8D);
  }

  /// Relleno claro (badges, círculos de ícono).
  static Color get skyBlue {
    if (_altoContraste) {
      return _oscuro ? const Color(0xFF2E3B47) : const Color(0xFFB8CEDD);
    }
    return _oscuro ? const Color(0xFF24384A) : const Color(0xFFC8D9E6);
  }

  /// Fondo decorativo cálido (login/onboarding, pantallas de éxito,
  /// relleno de campos de texto) — el rol histórico de "beige", NUNCA
  /// el fondo genérico de un Scaffold (ver `fondoPagina` para eso). En
  /// claro es el mismo crema de siempre; en oscuro es un gris cálido
  /// oscuro, distinto del gris neutro de `white`, para conservar esa
  /// diferencia "cálido vs. neutro" que ya existía en modo claro.
  static Color get beige {
    if (_altoContraste) {
      return _oscuro ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    }
    return _oscuro ? const Color(0xFF55504A) : const Color(0xFFF5EFEB);
  }

  /// Fondo genérico de página (Scaffold) — en claro, blanco puro (así
  /// estaba diseñada la app antes de modo oscuro/alto contraste, no
  /// cambia). En oscuro, "gris ratón" medio — legible, ni negro ni un
  /// azul-negro parejo donde no se distinguía nada (CA real reportado:
  /// pedido explícito de un gris medio, no casi-negro) — un escalón
  /// más oscuro que `white` para que las tarjetas sigan "levantadas".
  static Color get fondoPagina {
    if (_altoContraste) {
      return _oscuro ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    }
    return _oscuro ? const Color(0xFF4A4A4A) : const Color(0xFFFFFFFF);
  }

  /// Superficie de tarjeta/panel — distinta del fondo de página para
  /// que las tarjetas sigan "levantadas" en modo oscuro. Gris ratón
  /// medio, un escalón más claro que `fondoPagina` (legible, nunca
  /// casi-negro).
  static Color get white {
    if (_altoContraste) {
      return _oscuro ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    }
    return _oscuro ? const Color(0xFF5C5C5C) : const Color(0xFFFFFFFF);
  }

  /// Reemplaza los `Colors.grey.withValues(alpha: ...)` usados como
  /// borde de tarjeta por toda la app — en alto contraste, borde
  /// sólido del color de texto en vez de gris difuso. En oscuro, un
  /// gris más claro que `white` para que se note contra la tarjeta
  /// (con el fondo casi-negro anterior, uno más oscuro que la tarjeta
  /// quedaba invisible; con grises medios hay que ir para el otro
  /// lado).
  static Color get border {
    if (_altoContraste) return navy;
    return _oscuro ? const Color(0xFF7A7A7A) : const Color(0x332F4156);
  }

  /// Reemplaza los `Colors.grey`/`Colors.grey[600]` sueltos usados
  /// como texto secundario.
  static Color get textSecondary {
    if (_altoContraste) return navy;
    return _oscuro ? const Color(0xFFB7C3CC) : const Color(0xFF6B7280);
  }

  /// Reemplaza `Colors.grey.withValues(alpha: 0.05)`/`Colors.black26`
  /// usados en `boxShadow`.
  static Color get shadow {
    if (_altoContraste) return Colors.transparent;
    return _oscuro ? Colors.black.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.05);
  }

  /// Relleno fijo para elementos "seleccionados"/CTA (botón primario,
  /// pestaña activa de AppSegmentedTabs) — a diferencia de `navy` (rol de
  /// texto que se invierte en oscuro), este relleno NO se invierte: tiene
  /// que seguir siendo oscuro en ambos temas para que el texto claro fijo
  /// encima siga siendo legible. En alto contraste se comporta igual que
  /// `navy` (ahí sí conviene el extremo blanco/negro).
  static Color get enfasis {
    if (_altoContraste) return _oscuro ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    return const Color(0xFF2F4156);
  }

  /// Texto/ícono sobre `enfasis` — blanco fijo (alto contraste: invierte
  /// igual que el resto de esos roles).
  static Color get sobreEnfasis {
    if (_altoContraste) return _oscuro ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    return const Color(0xFFFFFFFF);
  }

  /// Degradé decorativo "hero" (tarjetas de bienvenida en Home) — los
  /// celestes claros fijos de antes dejaban el texto `navy` (que se
  /// invierte en oscuro) ilegible; en oscuro/alto contraste usa en cambio
  /// un degradé a partir de `skyBlue`, que sí es theme-aware.
  static List<Color> get gradienteHero {
    if (_oscuro || _altoContraste) {
      return [skyBlue, skyBlue.withValues(alpha: 0.6)];
    }
    return const [Color(0xFFE3EFFD), Color(0xFFC0D9F5)];
  }

  /// Degradé decorativo más sutil (tarjeta "Mis pedidos"/disponibilidad en
  /// Home, notificación no leída) — mismo motivo que `gradienteHero`.
  static List<Color> get gradienteSutil {
    if (_oscuro || _altoContraste) {
      return [skyBlue.withValues(alpha: 0.5), skyBlue.withValues(alpha: 0.3)];
    }
    return const [Color(0xFFF5FAFF), Color(0xFFEAF3FC)];
  }
}
