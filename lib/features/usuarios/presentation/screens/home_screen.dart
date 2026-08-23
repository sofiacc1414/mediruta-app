import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_session_provider.dart';

/// Placeholder post-login — todavía no hay más historias implementadas
/// (solicitudes/documentos/entregas). Sirve para probar G06/G07 desde una
/// sesión real. Se reemplaza cuando se implemente la siguiente historia.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(authSessionProvider);
    final usuario = estado is AuthAutenticado ? estado.usuario : null;

    return Scaffold(
      appBar: AppBar(title: const Text('MediRuta')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  usuario != null ? 'Hola, ${usuario.correo}' : 'Sesión activa',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                if (usuario != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Roles: ${usuario.roles.map((r) => '${r.codigo} (${r.estado})').join(', ')}',
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/cambiar-contrasena'),
                  child: const Text('Cambiar contraseña'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    await ref.read(authSessionProvider.notifier).cerrarSesion();
                    if (context.mounted) {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/login', (_) => false);
                    }
                  },
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
