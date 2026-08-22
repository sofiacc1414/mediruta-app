import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared/core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MediRutaApp()));
}

class MediRutaApp extends StatelessWidget {
  const MediRutaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediRuta',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _InfraCheckScreen(),
    );
  }
}

/// Pantalla placeholder — confirma que el scaffold (tema + Riverpod)
/// arranca correctamente. Se reemplaza por la pantalla real de login
/// cuando se implemente HU-01 siguiendo el plan previo (context.md, sección 12).
class _InfraCheckScreen extends StatelessWidget {
  const _InfraCheckScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MediRuta')),
      body: const Center(
        child: Text('Infraestructura lista — pendiente de implementar HU-01'),
      ),
    );
  }
}
