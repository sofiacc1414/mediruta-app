import 'package:flutter_test/flutter_test.dart';

import 'package:mediruta_app/features/notificaciones/domain/destino_notificacion.dart';

void main() {
  test('4. el paciente abre el detalle de su pedido', () {
    expect(
      destinoNotificacion(tipo: 'cambio_estado', modo: 'PACIENTE'),
      DestinoNotificacion.detallePedido,
    );
  });

  test('4. el domiciliario abre el pedido asignado', () {
    expect(
      destinoNotificacion(tipo: 'asignacion', modo: 'DOMICILIARIO'),
      DestinoNotificacion.pedidoAsignado,
    );
  });

  test('4. la validación de cuenta abre el perfil', () {
    expect(
      destinoNotificacion(tipo: 'validacion_cuenta', modo: 'DOMICILIARIO'),
      DestinoNotificacion.perfil,
    );
  });

  test('un paciente no abre una asignación ajena', () {
    expect(
      destinoNotificacion(tipo: 'asignacion', modo: 'PACIENTE'),
      DestinoNotificacion.sinPermiso,
    );
  });

  test('un domiciliario no abre el aviso de estado del paciente', () {
    expect(
      destinoNotificacion(tipo: 'cambio_estado', modo: 'DOMICILIARIO'),
      DestinoNotificacion.sinPermiso,
    );
  });

  test('un mensaje de chat abre el chat del pedido, para paciente', () {
    expect(
      destinoNotificacion(tipo: 'mensaje_chat', modo: 'PACIENTE'),
      DestinoNotificacion.chatPedido,
    );
  });

  test('un mensaje de chat abre el chat del pedido, para domiciliario', () {
    expect(
      destinoNotificacion(tipo: 'mensaje_chat', modo: 'DOMICILIARIO'),
      DestinoNotificacion.chatPedido,
    );
  });
}
