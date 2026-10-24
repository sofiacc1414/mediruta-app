import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../usuarios/presentation/widgets/main_bottom_bar.dart';
import '../../domain/entities/wallet_domiciliario.dart';
import '../providers/wallet_providers.dart';
import '../../../../shared/core/theme/modo_alto_contraste_provider.dart';
import '../../../../shared/core/theme/modo_oscuro_provider.dart';

String _formatearCop(num valor) {
  final texto = valor.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < texto.length; i++) {
    if (i > 0 && (texto.length - i) % 3 == 0) buffer.write('.');
    buffer.write(texto[i]);
  }
  return '\$$buffer';
}

String _formatearFecha(DateTime fecha) {
  final meses = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
}

/// Módulo 3 — "Mi billetera" del Domiciliario. Dos bloques: el balance
/// del rango de fechas elegido (lo que generó trabajando en ese
/// periodo) y el acumulado histórico de la billetera (saldo cobrado,
/// pendiente de que la empresa le pague, y deuda con la empresa).
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  static const routeName = '/wallet';

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  WalletDomiciliario? _wallet;
  WalletDomiciliarioPeriodo? _periodo;
  bool _cargando = true;
  String? _error;

  late DateTimeRange _rango;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _rango = DateTimeRange(start: DateTime(hoy.year, hoy.month, 1), end: hoy);
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final resultados = await Future.wait([
        ref.read(obtenerWalletUseCaseProvider).execute(),
        ref.read(obtenerWalletPeriodoUseCaseProvider).execute(
              _isoFecha(_rango.start),
              _isoFecha(_rango.end),
            ),
      ]);
      if (mounted) {
        setState(() {
          _wallet = resultados[0] as WalletDomiciliario;
          _periodo = resultados[1] as WalletDomiciliarioPeriodo;
        });
      }
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _isoFecha(DateTime fecha) {
    final mm = fecha.month.toString().padLeft(2, '0');
    final dd = fecha.day.toString().padLeft(2, '0');
    return '${fecha.year}-$mm-$dd';
  }

  Future<void> _elegirRango() async {
    final elegido = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: _rango,
    );
    if (elegido == null) return;
    setState(() => _rango = elegido);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    // Fuerza repintar esta pantalla ya montada cuando se togglea modo
    // oscuro/alto contraste desde Perfil (ver AppColors.configurar en
    // main.dart) — sin este watch, Riverpod no sabría que repintar.
    ref.watch(modoOscuroProvider);
    ref.watch(modoAltoContrasteProvider);
    return Scaffold(
      backgroundColor: AppColors.fondoPagina,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.navy, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mi billetera',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.navy),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      bottomNavigationBar: const MainBottomBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: [
              if (_error != null) ...[
                AppErrorBanner(mensaje: _error!),
                const SizedBox(height: 16),
              ],
              if (_cargando && _wallet == null)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(child: CircularProgressIndicator(color: AppColors.navy)),
                )
              else ...[
                if (_wallet != null) _TarjetaBloqueado(wallet: _wallet!),
                _TarjetaBalancePeriodo(
                  rango: _rango,
                  periodo: _periodo,
                  onElegirRango: _elegirRango,
                ),
                const SizedBox(height: 24),
                Text(
                  'Acumulado histórico',
                  style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 12),
                if (_wallet != null) ..._tarjetasAcumulado(_wallet!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _tarjetasAcumulado(WalletDomiciliario wallet) {
    final progreso = wallet.topeRecaudoEfectivo > 0
        ? (wallet.deudaEfectivo / wallet.topeRecaudoEfectivo).clamp(0, 1).toDouble()
        : 0.0;

    return [
      _TarjetaMetrica(
        titulo: 'Saldo cobrado',
        subtitulo: 'Ya lo tenés en la mano: efectivo neto + lo que ya te liquidaron.',
        monto: _formatearCop(wallet.saldoCobrado),
        icono: Icons.account_balance_wallet_outlined,
      ),
      const SizedBox(height: 12),
      _TarjetaMetrica(
        titulo: 'Saldo pendiente por cobrar',
        subtitulo: 'Tarjeta/transferencia que la empresa ya cobró y todavía no te pagó.',
        monto: _formatearCop(wallet.saldoPendienteCobrar),
        icono: Icons.hourglass_empty,
      ),
      const SizedBox(height: 12),
      _TarjetaMetrica(
        titulo: 'Deuda con la empresa',
        subtitulo: 'Efectivo que cobraste y todavía debés entregar.',
        monto: _formatearCop(wallet.deudaEfectivo),
        icono: Icons.payments_outlined,
        destacar: wallet.deudaEfectivo > 0,
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: progreso,
          minHeight: 8,
          backgroundColor: AppColors.skyBlue.withValues(alpha: 0.3),
          color: AppColors.navy,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Tope antes de bloquear: ${_formatearCop(wallet.topeRecaudoEfectivo)}',
        style: TextStyle(color: AppColors.navy.withValues(alpha: 0.6), fontSize: 12),
      ),
      const SizedBox(height: 12),
      _TarjetaMetrica(
        titulo: 'Comisión acumulada',
        subtitulo: 'Total histórico generado por domicilios entregados.',
        monto: _formatearCop(wallet.comisionAcumulada),
        icono: Icons.history_outlined,
        secundaria: true,
      ),
    ];
  }
}

class _TarjetaBloqueado extends StatelessWidget {
  const _TarjetaBloqueado({required this.wallet});

  final WalletDomiciliario wallet;

  @override
  Widget build(BuildContext context) {
    if (!wallet.bloqueadoPorTope) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.skyBlue.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.navy, width: 1.2),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.navy),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Alcanzaste el tope de efectivo recaudado. No podés aceptar pedidos nuevos hasta '
                'que entregues ese dinero a la empresa y el admin lo confirme.',
                style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaBalancePeriodo extends StatelessWidget {
  const _TarjetaBalancePeriodo({
    required this.rango,
    required this.periodo,
    required this.onElegirRango,
  });

  final DateTimeRange rango;
  final WalletDomiciliarioPeriodo? periodo;
  final VoidCallback onElegirRango;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE3EFFD), Color(0xFFC0D9F5)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Balance del periodo',
                style: TextStyle(color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              InkWell(
                onTap: onElegirRango,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, color: AppColors.navy, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '${_formatearFecha(rango.start)} – ${_formatearFecha(rango.end)}',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            periodo != null ? _formatearCop(periodo!.balancePeriodo) : '…',
            style: TextStyle(color: AppColors.navy, fontSize: 32, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Neto ganado en el periodo (efectivo + tarjeta/transferencia).',
            style: TextStyle(color: AppColors.navy, fontSize: 12.5, height: 1.4),
          ),
          if (periodo != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MiniDato(
                    etiqueta: 'Cobrado en efectivo',
                    valor: _formatearCop(periodo!.cobradoEfectivoPeriodo),
                  ),
                ),
                Expanded(
                  child: _MiniDato(
                    etiqueta: 'Pendiente tarjeta/transf.',
                    valor: _formatearCop(periodo!.pendienteTarjetaTransferenciaPeriodo),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniDato extends StatelessWidget {
  const _MiniDato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: TextStyle(color: AppColors.navy.withValues(alpha: 0.7), fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(color: AppColors.navy, fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _TarjetaMetrica extends StatelessWidget {
  const _TarjetaMetrica({
    required this.titulo,
    required this.subtitulo,
    required this.monto,
    required this.icono,
    this.destacar = false,
    this.secundaria = false,
  });

  final String titulo;
  final String subtitulo;
  final String monto;
  final IconData icono;

  /// Deuda activa — mismo tratamiento visual que cualquier otra tarjeta
  /// "importante" de la app: más contraste, nunca un color fuera de la
  /// paleta oficial (navy/teal/skyBlue/beige/white).
  final bool destacar;

  /// Dato informativo de fondo (comisión histórica bruta) — un poco
  /// más discreta que el resto.
  final bool secundaria;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: destacar ? AppColors.navy.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.skyBlue.withValues(alpha: secundaria ? 0.15 : 0.3),
            ),
            child: Icon(icono, color: AppColors.teal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: TextStyle(color: AppColors.navy.withValues(alpha: 0.6), fontSize: 11.5, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            monto,
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: destacar ? FontWeight.w800 : FontWeight.w700,
              fontSize: secundaria ? 15 : 17,
            ),
          ),
        ],
      ),
    );
  }
}
