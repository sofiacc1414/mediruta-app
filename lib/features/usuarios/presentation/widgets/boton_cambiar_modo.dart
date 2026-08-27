import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/theme/app_colors.dart';
import '../../domain/entities/rol_asignado.dart';
import '../providers/auth_session_provider.dart';

const _iconosRol = {'PACIENTE': Icons.medication_outlined, 'DOMICILIARIO': Icons.moped_outlined};

/// Selector de modo (Paciente/Domiciliario) para cuentas con los 2
/// roles — vive en la esquina superior derecha de Home (antes era un
/// botón más de `MainBottomBar`, mudado acá para despejar la barra).
/// El ícono muestra el modo ACTUAL; tocarlo alterna al otro rol. No
/// navega a ningún lado — ya se está en Home, que es donde vive el
/// contenido específico de cada modo.
class BotonCambiarModo extends ConsumerWidget {
  const BotonCambiarModo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(authSessionProvider);
    final usuario = estado is AuthAutenticado ? estado.usuario : null;
    final roles = usuario?.roles ?? const <RolAsignado>[];
    if (roles.length < 2) return const SizedBox.shrink();

    final modo = ref.watch(modoActivoProvider) ?? roles.first.codigo;

    return Material(
      color: AppColors.navy,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          final otroRol = roles.firstWhere((r) => r.codigo != modo, orElse: () => roles.first);
          ref.read(modoActivoProvider.notifier).state = otroRol.codigo;
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(_iconosRol[modo] ?? Icons.swap_horiz, color: AppColors.white, size: 20),
        ),
      ),
    );
  }
}
