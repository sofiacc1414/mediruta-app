import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../solicitudes/presentation/screens/historial_pedidos_screen.dart';
import '../../../solicitudes/presentation/screens/mis_solicitudes_screen.dart';
import '../../../solicitudes/presentation/screens/pedidos_disponibles_screen.dart';
import '../../domain/entities/rol_asignado.dart';
import '../providers/auth_session_provider.dart';
import '../providers/disponibilidad_domiciliario_provider.dart';
import '../screens/home_screen.dart';
import '../screens/perfil_screen.dart';
import 'app_bottom_bar.dart';

const _iconosRol = {'PACIENTE': Icons.medication_outlined, 'DOMICILIARIO': Icons.moped_outlined};
const _etiquetasRol = {'PACIENTE': 'Paciente', 'DOMICILIARIO': 'Domiciliario'};

/// La navegación de toda la app — no solo de Home. Cada pantalla
/// principal la agrega como su `bottomNavigationBar`, así que siempre
/// está presente, en cualquier punto del flujo.
///
/// Cada toque reemplaza toda la pila de navegación (en vez de apilar
/// otra pantalla arriba) — son destinos, no un "volver": tocar el
/// mismo destino en el que ya estás simplemente lo refresca.
///
/// El selector de modo (si la cuenta tiene los 2 roles) vive acá
/// como un botón más de la barra, no en el cuerpo de Home: tocarlo
/// alterna el rol activo y lleva a Inicio, que es donde vive el
/// contenido específico de cada modo.
class MainBottomBar extends ConsumerWidget {
  const MainBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(authSessionProvider);
    final usuario = estado is AuthAutenticado ? estado.usuario : null;
    final roles = usuario?.roles ?? const <RolAsignado>[];
    final modo = ref.watch(modoActivoProvider) ?? (roles.isNotEmpty ? roles.first.codigo : null);
    final esDomiciliario = modo == 'DOMICILIARIO';
    final disponible = ref.watch(disponibilidadDomiciliarioProvider).disponible;

    void irA(String routeName) {
      Navigator.of(context).pushNamedAndRemoveUntil(routeName, (_) => false);
    }

    return AppBottomNavBar(
      items: [
        if (roles.length > 1)
          AppBottomNavAction(
            icono: _iconosRol[modo] ?? Icons.swap_horiz,
            etiqueta: _etiquetasRol[modo] ?? 'Modo',
            onTap: () {
              final otroRol = roles.firstWhere((r) => r.codigo != modo, orElse: () => roles.first);
              ref.read(modoActivoProvider.notifier).state = otroRol.codigo;
              irA(HomeScreen.routeName);
            },
          ),
        AppBottomNavAction(
          icono: Icons.person_outline,
          etiqueta: 'Perfil',
          onTap: () => irA(PerfilScreen.routeName),
        ),
        AppBottomNavAction(
          icono: Icons.home_rounded,
          etiqueta: 'Inicio',
          onTap: () => irA(HomeScreen.routeName),
        ),
        AppBottomNavAction(
          icono: Icons.receipt_long_outlined,
          etiqueta: esDomiciliario ? 'Mis pedidos' : 'Mis solicitudes',
          onTap: () => irA(esDomiciliario ? HistorialPedidosScreen.routeName : MisSolicitudesScreen.routeName),
        ),
        // Solo el Domiciliario, y solo mientras está en línea — el
        // Paciente nunca tiene este destino en su barra.
        if (esDomiciliario && disponible)
          AppBottomNavAction(
            icono: Icons.explore_outlined,
            etiqueta: 'Disponibles',
            onTap: () => irA(PedidosDisponiblesScreen.routeName),
          ),
      ],
    );
  }
}
