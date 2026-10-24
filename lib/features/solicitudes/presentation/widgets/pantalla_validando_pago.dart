import 'package:flutter/material.dart';

import '../../../../shared/core/theme/app_colors.dart';

/// Módulo 4 — overlay a pantalla completa, no cerrable, que se muestra
/// mientras se procesa un pago con tarjeta o transferencia (pasarela
/// simulada): mismo lenguaje visual que una redirección tipo PSE
/// mientras "confirma" la transacción con el banco. Ver
/// `PantallaValidandoPagoController`, que maneja el cambio entre sus
/// dos fases desde `_onEnviar` en `nueva_solicitud_screen.dart`.
enum _FasePago { validando, exitoso }

class _PantallaValidandoPago extends StatelessWidget {
  const _PantallaValidandoPago({required this.fase});

  final ValueNotifier<_FasePago> fase;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Material(
        color: AppColors.fondoPagina,
        child: SafeArea(
          child: Center(
            child: ValueListenableBuilder<_FasePago>(
              valueListenable: fase,
              builder: (context, fase, _) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: fase == _FasePago.validando
                      ? _ContenidoValidando(key: const ValueKey('validando'))
                      : _ContenidoExitoso(key: const ValueKey('exitoso')),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ContenidoValidando extends StatelessWidget {
  const _ContenidoValidando({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'MediRuta Pagos',
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Conectando con la pasarela de pago...',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.teal, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 4),
          Text(
            'No cierres ni actualices esta pantalla.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ContenidoExitoso extends StatelessWidget {
  const _ContenidoExitoso({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.teal, AppColors.navy],
              ),
            ),
            child: Icon(Icons.check_rounded, color: AppColors.sobreEnfasis, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            'Pago exitoso',
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ya podés continuar con tu pedido.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.teal, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Punto de entrada usado por las pantallas de checkout: abre el overlay
/// con `showGeneralDialog` (no descartable por el usuario) y expone
/// [mostrarExito]/[cerrar] para que quien hizo la llamada a la pasarela
/// controle la transición una vez sabe si la API respondió bien o mal.
class PantallaValidandoPagoController {
  PantallaValidandoPagoController._(this._fase, this._cerrar);

  final ValueNotifier<_FasePago> _fase;
  final VoidCallback _cerrar;

  static PantallaValidandoPagoController mostrar(BuildContext context) {
    final fase = ValueNotifier<_FasePago>(_FasePago.validando);
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, _, _) => _PantallaValidandoPago(fase: fase),
    );
    return PantallaValidandoPagoController._(fase, () {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    });
  }

  /// Cambia el overlay ya abierto al estado de éxito — sigue mostrado,
  /// no se cierra solo. Quien llama decide cuánto se ve (ver
  /// `_onEnviar`) y cierra después con [cerrar].
  void mostrarExito() {
    _fase.value = _FasePago.exitoso;
  }

  /// Cierra el overlay sin pasar por el estado de éxito — usado cuando
  /// la pasarela/API respondió con un error.
  void cerrar() {
    _cerrar();
    _fase.dispose();
  }
}
