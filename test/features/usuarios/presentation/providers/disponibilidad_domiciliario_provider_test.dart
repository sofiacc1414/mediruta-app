import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediruta_app/features/usuarios/presentation/providers/disponibilidad_domiciliario_provider.dart';
import 'package:mediruta_app/features/usuarios/presentation/providers/perfil_providers.dart';

import '../../domain/usecases/fake_perfil_repository.dart';

void main() {
  group('DisponibilidadDomiciliarioNotifier.refrescarUbicacionTrasEntrega', () {
    // Regresión del bug reportado: tras entregar un pedido, la posición
    // guardada del domiciliario quedaba congelada en donde estaba al
    // prender "Disponible" la primera vez (nunca se refrescaba en
    // ningún paso del ciclo del pedido) — ver doc del método bajo
    // prueba. Este test cubre el guard: si el domiciliario ya no está
    // "disponible" en el momento en que se dispara el refresco (por
    // ejemplo, lo apagó manualmente mientras entregaba), no debe llamar
    // al use case ni pisar su estado apagado con una ubicación.
    test('no llama al use case si el domiciliario no está disponible', () async {
      final fakeRepo = FakePerfilRepository();
      final container = ProviderContainer(
        overrides: [perfilRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      // Estado inicial del notifier: `disponible = false` (default).
      await container
          .read(disponibilidadDomiciliarioProvider.notifier)
          .refrescarUbicacionTrasEntrega();

      expect(fakeRepo.ultimaLlamada, isNull);
    });
  });
}
