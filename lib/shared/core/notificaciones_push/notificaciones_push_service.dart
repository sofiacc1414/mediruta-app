import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../../features/notificaciones/data/notificaciones_remote_datasource.dart';
import '../../../features/notificaciones/presentation/notificaciones_screen.dart';
import '../../widgets/snackbar_exito.dart';
import '../navigation/app_navigator_key.dart';

/// Notificaciones push (FCM) — solo Android por ahora (ver
/// `android/app/build.gradle.kts`, que requiere `google-services.json`;
/// iOS queda pendiente de una ronda futura).
///
/// Se arranca/para desde `main.dart` según `authSessionProvider`, nunca
/// antes de que haya sesión: `/notificaciones/dispositivo` requiere auth,
/// así que pedir permiso/token sin sesión no tendría a quién asociarlos.
class NotificacionesPushService {
  NotificacionesPushService(this._datasource);

  final NotificacionesRemoteDatasource _datasource;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;
  bool _activo = false;

  /// Lo llama el listener de `authSessionProvider` en `main.dart` apenas
  /// el estado pasa a `AuthAutenticado` (login, registro o sesión
  /// restaurada al abrir la app). Idempotente: si ya está activo (ej. un
  /// segundo `AuthAutenticado` por `refrescarIdentidad`) no repite nada.
  Future<void> iniciarSesion() async {
    if (_activo) return;
    _activo = true;

    try {
      final permiso = await FirebaseMessaging.instance.requestPermission();
      if (permiso.authorizationStatus == AuthorizationStatus.denied) {
        // La persona puede seguir usando la app sin push — no es
        // bloqueante, solo no se registra el token.
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _registrar(token);
      }

      _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(_registrar);

      // App abierta: FCM no muestra la notificación del sistema sola,
      // hay que avisar nosotros (background/terminada sí la muestra
      // Android automáticamente, sin código extra de nuestro lado).
      _onMessageSub = FirebaseMessaging.onMessage.listen(_mostrarEnForeground);

      // Se tocó la notificación con la app en background.
      _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(
        (_) => _irANotificaciones(),
      );

      // Se tocó la notificación con la app cerrada del todo.
      final mensajeInicial = await FirebaseMessaging.instance.getInitialMessage();
      if (mensajeInicial != null) {
        _irANotificaciones();
      }
    } catch (error) {
      // Sin `google-services.json` real (o cualquier otro fallo de FCM)
      // esto no debe tumbar la sesión ni el resto de la app.
      debugPrint('NotificacionesPushService.iniciarSesion falló: $error');
      _activo = false;
    }
  }

  /// Lo llama el mismo listener al cerrar sesión — sin esto, seguiríamos
  /// escuchando `onTokenRefresh` y reintentando registrar contra un
  /// token de acceso que ya se borró.
  Future<void> detenerSesion() async {
    _activo = false;
    await _tokenRefreshSub?.cancel();
    await _onMessageSub?.cancel();
    await _onMessageOpenedAppSub?.cancel();
    _tokenRefreshSub = null;
    _onMessageSub = null;
    _onMessageOpenedAppSub = null;
  }

  Future<void> _registrar(String token) async {
    try {
      await _datasource.registrarDispositivo(token: token, plataforma: 'android');
    } catch (error) {
      // Falló el registro (sin conexión, 401 por sesión vencida, etc.) —
      // no es razón para romper el login; en el próximo `onTokenRefresh`
      // o la próxima sesión se vuelve a intentar.
      debugPrint('NotificacionesPushService._registrar falló: $error');
    }
  }

  void _mostrarEnForeground(RemoteMessage mensaje) {
    final contexto = appNavigatorKey.currentState?.context;
    final titulo = mensaje.notification?.title;
    final cuerpo = mensaje.notification?.body;
    if (contexto == null || titulo == null) return;
    final texto = cuerpo == null ? titulo : '$titulo\n$cuerpo';
    ScaffoldMessenger.of(contexto).showSnackBar(snackBarExito(texto));
  }

  /// Fallback deliberado: el payload trae `referenciaTipo`/`referenciaId`
  /// (ver `AvisoPush`/`fcm-push.adapter.ts` del lado API), pero mapear
  /// cada tipo a su pantalla exacta necesita el "modo activo" de la
  /// cuenta (ver `destino_notificacion.dart`), que no está disponible
  /// acá fuera del árbol de widgets. Hasta que se resuelva eso, cualquier
  /// toque de push lleva a la pantalla de notificaciones, donde la lista
  /// ya sabe navegar bien según `destinoNotificacion`.
  void _irANotificaciones() {
    appNavigatorKey.currentState?.pushNamed(NotificacionesScreen.routeName);
  }
}
