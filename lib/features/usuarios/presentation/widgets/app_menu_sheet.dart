import 'package:flutter/material.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_segmented_tabs.dart';
import '../../domain/entities/rol_asignado.dart';

/// Contenido del bottom sheet que abre el botón "Cuenta" de
/// `AppBottomNavBar` — agrupa lo que antes vivía suelto en el cuerpo
/// de Home: identidad, cambio de modo (si la cuenta es multirrol),
/// accesos a Perfil/Mis pedidos, y Cerrar sesión.
class AppMenuSheet extends StatelessWidget {
  const AppMenuSheet({
    super.key,
    required this.nombre,
    required this.correo,
    required this.fotoUrl,
    required this.roles,
    required this.modo,
    required this.etiquetaMisPedidos,
    required this.onCambiarModo,
    required this.onIrPerfil,
    required this.onIrMisPedidos,
    required this.onCerrarSesion,
  });

  final String? nombre;
  final String correo;
  final String? fotoUrl;
  final List<RolAsignado> roles;
  final String? modo;
  final String etiquetaMisPedidos;
  final ValueChanged<String> onCambiarModo;
  final VoidCallback onIrPerfil;
  final VoidCallback onIrMisPedidos;
  final VoidCallback onCerrarSesion;

  static const _etiquetasRol = {'PACIENTE': 'Paciente', 'DOMICILIARIO': 'Domiciliario'};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.skyBlue,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _AvatarChico(fotoUrl: fotoUrl, nombre: nombre),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre ?? 'Sesión activa',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        correo,
                        style: const TextStyle(color: AppColors.teal, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (roles.length > 1) ...[
              const SizedBox(height: 20),
              AppSegmentedTabs(
                opciones: [for (final rol in roles) _etiquetasRol[rol.codigo] ?? rol.codigo],
                seleccionado: roles.indexWhere((r) => r.codigo == modo).clamp(0, roles.length - 1),
                onSeleccionar: (i) => onCambiarModo(roles[i].codigo),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(color: AppColors.skyBlue),
            _ItemMenu(
              icono: Icons.person_outline,
              texto: 'Mi perfil',
              onTap: () {
                Navigator.of(context).pop();
                onIrPerfil();
              },
            ),
            _ItemMenu(
              icono: Icons.receipt_long_outlined,
              texto: etiquetaMisPedidos,
              onTap: () {
                Navigator.of(context).pop();
                onIrMisPedidos();
              },
            ),
            const Divider(color: AppColors.skyBlue),
            _ItemMenu(
              icono: Icons.logout,
              texto: 'Cerrar sesión',
              onTap: () {
                Navigator.of(context).pop();
                onCerrarSesion();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  const _ItemMenu({required this.icono, required this.texto, required this.onTap});

  final IconData icono;
  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icono, color: AppColors.navy),
      title: Text(texto, style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}

class _AvatarChico extends StatelessWidget {
  const _AvatarChico({required this.fotoUrl, required this.nombre});

  final String? fotoUrl;
  final String? nombre;

  @override
  Widget build(BuildContext context) {
    const tamano = 44.0;
    final letra = (nombre != null && nombre!.trim().isNotEmpty)
        ? nombre!.trim()[0].toUpperCase()
        : '?';
    return ClipOval(
      child: fotoUrl != null
          ? Image.network(
              fotoUrl!,
              width: tamano,
              height: tamano,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _iniciales(tamano, letra),
            )
          : _iniciales(tamano, letra),
    );
  }

  Widget _iniciales(double tamano, String letra) {
    return Container(
      width: tamano,
      height: tamano,
      color: AppColors.skyBlue,
      alignment: Alignment.center,
      child: Text(
        letra,
        style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700),
      ),
    );
  }
}
