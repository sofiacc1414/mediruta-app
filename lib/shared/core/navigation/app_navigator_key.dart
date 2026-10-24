import 'package:flutter/material.dart';

/// Clave global del `Navigator` raíz — la necesita
/// `NotificacionesPushService` para navegar al tocar una notificación
/// push estando la app en background o recién abierta desde cero (ahí
/// no hay ningún `BuildContext` de pantalla disponible todavía). Vive
/// separada de `main.dart` para que el servicio no tenga que importar
/// la app entera.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
