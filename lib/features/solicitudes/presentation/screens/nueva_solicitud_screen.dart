import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_loading_button.dart';
import '../../../../shared/widgets/sugerencias_direccion.dart';
import '../../../usuarios/presentation/providers/perfil_providers.dart'
    hide autocompletarDireccionUseCaseProvider;
import '../../../usuarios/presentation/widgets/main_bottom_bar.dart';
import '../../domain/entities/datos_solicitud.dart';
import '../../domain/entities/medicamento.dart';
import '../../domain/entities/precio_pedido.dart';
import '../providers/solicitud_providers.dart';
import '../widgets/campos_solicitud.dart';
import '../widgets/tarjeta_precio_pedido.dart';

/// G01/G04 — HU-03. Crear una solicitud nueva o editar una existente en Borrador.
class NuevaSolicitudScreen extends ConsumerStatefulWidget {
  const NuevaSolicitudScreen({super.key, this.solicitudId});

  static const routeName = '/solicitudes/nueva';

  final String? solicitudId;

  @override
  ConsumerState<NuevaSolicitudScreen> createState() => _NuevaSolicitudScreenState();
}

class _NuevaSolicitudScreenState extends ConsumerState<NuevaSolicitudScreen> {
  final List<Medicamento> _medicamentos = [];
  final _direccionEntrega = TextEditingController();
  final _direccionFarmacia = TextEditingController();
  final _focusDireccionEntrega = FocusNode();
  final _focusDireccionFarmacia = FocusNode();
  DateTime? _recetaFechaVencimiento;

  String? _recetaUrlServidor;
  List<int>? _recetaBytesPendiente;
  String? _recetaNombrePendiente;
  String? _recetaContentTypePendiente;

  bool get _editandoExistente => widget.solicitudId != null;
  String? _solicitudIdRemoto;
  DatosSolicitud? _datosOriginales;

  bool _cargandoInicial = true;
  bool _guardando = false;
  String? _error;

  // Estimado en vivo del precio (copago + domicilio) mientras se arma
  // el pedido — antes, el paciente solo se enteraba del costo después
  // de haberlo enviado.
  //
  // Bug real reportado ("la app está super lenta"): antes esto
  // escuchaba cambios de TEXTO con un debounce de 900ms — es decir,
  // disparaba un estimado (2 geocodificaciones contra Nominatim) 900ms
  // después de CADA pausa al escribir, mientras los dos campos no
  // estuvieran vacíos, sin importar si la dirección estaba completa o
  // a mitad de escribir. Del lado de la API, Nominatim tiene un
  // rate-limit global de 1 request/segundo COMPARTIDO entre todos los
  // usuarios (ver NominatimGeocodificacionAdapter) — cada tecla de
  // cada paciente escribiendo una dirección iba a esa misma cola.
  //
  // Ahora escucha el FOCO de cada campo, no el texto: dispara como
  // mucho una vez cuando se termina de escribir esa dirección (el
  // campo pierde el foco), no una vez por pausa mientras se tipea.
  PrecioPedido? _precioEstimado;
  bool _cargandoPrecio = false;
  String? _ultimaFarmaciaEstimada;
  String? _ultimaEntregaEstimada;
  // Para qué texto exacto `_precioEstimado` ya tiene una respuesta
  // real de Nominatim — ver `_estimarPrecio`.
  String? _farmaciaConfirmadaPara;
  String? _entregaConfirmadaPara;

  @override
  void initState() {
    super.initState();
    _solicitudIdRemoto = widget.solicitudId;
    _direccionEntrega.addListener(_onCambioCampo);
    _direccionFarmacia.addListener(_onCambioCampo);
    // Refresca el mensaje de confirmación bajo cada campo apenas el
    // texto cambia — sin esto, una confirmación vieja seguía mostrada
    // mientras el paciente reescribía la dirección, hasta el próximo
    // blur (que es cuando de verdad se vuelve a geocodificar).
    _direccionEntrega.addListener(_refrescarUI);
    _direccionFarmacia.addListener(_refrescarUI);
    _focusDireccionFarmacia.addListener(_onFocoCambioDireccion);
    _focusDireccionEntrega.addListener(_onFocoCambioDireccion);
    _inicializar();
  }

  @override
  void dispose() {
    _direccionEntrega.dispose();
    _direccionFarmacia.dispose();
    _focusDireccionFarmacia.dispose();
    _focusDireccionEntrega.dispose();
    super.dispose();
  }

  Future<void> _inicializar() async {
    if (_editandoExistente) {
      try {
        final solicitud = await ref
            .read(obtenerSolicitudUseCaseProvider)
            .execute(widget.solicitudId!);
        final datos = DatosSolicitud(
          medicamentos: solicitud.medicamentos,
          recetaFechaVencimiento: solicitud.recetaFechaVencimiento,
          direccionEntrega: solicitud.direccionEntrega,
          direccionFarmacia: solicitud.direccionFarmacia,
        );
        _rellenar(datos);
        _recetaUrlServidor = solicitud.recetaUrl;
        _datosOriginales = datos;
      } on ApiException catch (error) {
        setState(() => _error = error.message);
      } on ApiSinConexionException catch (error) {
        setState(() => _error = error.toString());
      }
    } else {
      final borrador = await ref.read(borradorLocalRepositoryProvider).leer();
      if (borrador != null) {
        _rellenar(borrador);
      } else {
        try {
          final perfil = await ref.read(obtenerPerfilUseCaseProvider).execute();
          _direccionEntrega.text = perfil.paciente?.direccion ?? '';
        } catch (_) {}
      }
    }

    if (mounted) setState(() => _cargandoInicial = false);
    // Por si se precargaron ambas direcciones (editando un borrador, o
    // la dirección de entrega vino sola del perfil) — sin esto, el
    // estimado recién aparecía tras la primera tecla que se tocara.
    _onCambioDireccionParaPrecio();
  }

  void _rellenar(DatosSolicitud datos) {
    _medicamentos.addAll(datos.medicamentos);
    _direccionEntrega.text = datos.direccionEntrega ?? '';
    _direccionFarmacia.text = datos.direccionFarmacia ?? '';
    if (datos.recetaFechaVencimiento != null) {
      _recetaFechaVencimiento = DateTime.tryParse(datos.recetaFechaVencimiento!);
    }
  }

  Future<void> _abrirDialogoMedicamento({int? indice}) async {
    final resultado = await showDialog<Medicamento>(
      context: context,
      builder: (context) => DialogoMedicamento(
        inicial: indice != null ? _medicamentos[indice] : null,
      ),
    );
    if (resultado == null) return;

    setState(() {
      if (indice != null) {
        _medicamentos[indice] = resultado;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Medicamento editado exitosamente',
              style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            elevation: 4,
          ),
        );
      } else {
        _medicamentos.add(resultado);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Medicamento registrado con éxito',
              style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            elevation: 4,
          ),
        );
      }
    });
    _onCambioCampo();
  }

  void _quitarMedicamento(int indice) {
    setState(() => _medicamentos.removeAt(indice));
    _onCambioCampo();
  }

  DatosSolicitud _datosActuales() {
    return DatosSolicitud(
      medicamentos: List<Medicamento>.from(_medicamentos),
      recetaFechaVencimiento: _recetaFechaVencimiento != null ? _isoFecha(_recetaFechaVencimiento!) : null,
      direccionEntrega: vacioComoNulo(_direccionEntrega.text),
      direccionFarmacia: vacioComoNulo(_direccionFarmacia.text),
    );
  }

  void _onCambioCampo() {
    if (_editandoExistente || _cargandoInicial) return;
    ref.read(borradorLocalRepositoryProvider).guardar(_datosActuales());
  }

  void _refrescarUI() {
    if (mounted) setState(() {});
  }

  /// Se dispara cuando CUALQUIERA de los dos campos de dirección
  /// pierde el foco — no en cada cambio de foco (eso incluiría también
  /// cuando un campo lo GANA), y no en cada tecla mientras se escribe.
  void _onFocoCambioDireccion() {
    // Mientras cualquiera de los dos siga enfocado, el paciente sigue
    // trabajando en la dirección — no hay "campo recién completado"
    // todavía.
    if (_focusDireccionFarmacia.hasFocus || _focusDireccionEntrega.hasFocus) {
      return;
    }
    _onCambioDireccionParaPrecio();
  }

  /// Separado de `_onCambioCampo()` a propósito: ese solo corre para un
  /// borrador nuevo (no editando uno existente), mientras que el
  /// estimado de precio tiene que funcionar en los dos casos.
  void _onCambioDireccionParaPrecio() {
    if (_cargandoInicial) return;

    final farmacia = _direccionFarmacia.text.trim();
    final entrega = _direccionEntrega.text.trim();
    if (farmacia.isEmpty || entrega.isEmpty) {
      if (_precioEstimado != null) setState(() => _precioEstimado = null);
      return;
    }

    // Ninguna de las dos direcciones cambió desde el último estimado
    // (ej. el paciente solo tocó un campo para revisarlo y volvió a
    // salir) — no tiene sentido volver a geocodificar el mismo texto.
    if (farmacia == _ultimaFarmaciaEstimada && entrega == _ultimaEntregaEstimada) {
      return;
    }

    _estimarPrecio(farmacia, entrega);
  }

  Future<void> _estimarPrecio(String farmacia, String entrega) async {
    // Se marca ANTES de pedir el estimado (no solo al tener éxito) —
    // así, si vuelve a perder el foco sin cambiar el texto (ej. la API
    // falló y el paciente solo tocó el campo de nuevo), no se repite
    // el mismo request.
    _ultimaFarmaciaEstimada = farmacia;
    _ultimaEntregaEstimada = entrega;
    setState(() => _cargandoPrecio = true);
    try {
      final precio = await ref
          .read(estimarPrecioPedidoUseCaseProvider)
          .execute(direccionFarmacia: farmacia, direccionEntrega: entrega);
      if (!mounted) return;
      // El usuario pudo haber seguido escribiendo mientras este
      // request estaba en vuelo — no pisar un cambio más nuevo con una
      // respuesta vieja.
      if (_direccionFarmacia.text.trim() != farmacia ||
          _direccionEntrega.text.trim() != entrega) {
        return;
      }
      setState(() {
        _precioEstimado = precio;
        // Distinto de `_ultimaXEstimada` (que se marca ANTES del
        // request, para no duplicar llamadas) — esto marca para qué
        // texto exacto `_precioEstimado` ya tiene una respuesta real,
        // así el mensaje bajo cada campo no muestra una confirmación
        // vieja mientras el otro campo se re-verifica.
        _farmaciaConfirmadaPara = farmacia;
        _entregaConfirmadaPara = entrega;
      });
    } on ApiException {
      // Un estimado que falla (ej. Nominatim caído) no debe
      // interrumpir armar el pedido — simplemente no se muestra.
    } on ApiSinConexionException {
      // ídem
    } finally {
      if (mounted) setState(() => _cargandoPrecio = false);
    }
  }

  /// `true` cuando las dos direcciones ya tienen una confirmación real
  /// (no null) para el texto que está escrito ahora mismo — ver
  /// `_onEnviar`, que exige esto antes de dejar enviar el pedido.
  bool get _direccionesConfirmadas {
    final farmacia = _direccionFarmacia.text.trim();
    final entrega = _direccionEntrega.text.trim();
    if (farmacia.isEmpty || entrega.isEmpty) return false;
    if (_farmaciaConfirmadaPara != farmacia || _entregaConfirmadaPara != entrega) {
      return false;
    }
    return _precioEstimado?.direccionFarmaciaResuelta != null &&
        _precioEstimado?.direccionEntregaResuelta != null;
  }

  /// Ronda 14 — bug real reportado: aunque el estimado en vivo ya
  /// hubiera confirmado la dirección, "Enviar solicitud" la volvía a
  /// geocodificar desde cero al final — un segundo viaje a Nominatim
  /// que podía fallar aunque el primero hubiera funcionado, dejando el
  /// pedido enviado pero SIN ubicación, en silencio. Se mandan acá las
  /// coordenadas que el estimado ya confirmó, para el texto exacto que
  /// las confirmó — si el paciente lo volvió a editar después, el
  /// servidor lo nota (el texto ya no coincide) y geocodifica de
  /// nuevo solo.
  VerificacionDireccionPrevia? get _farmaciaVerificada {
    final precio = _precioEstimado;
    if (precio == null ||
        _farmaciaConfirmadaPara == null ||
        precio.direccionFarmaciaLat == null ||
        precio.direccionFarmaciaLng == null) {
      return null;
    }
    return VerificacionDireccionPrevia(
      direccionVerificadaPara: _farmaciaConfirmadaPara!,
      lat: precio.direccionFarmaciaLat!,
      lng: precio.direccionFarmaciaLng!,
    );
  }

  VerificacionDireccionPrevia? get _entregaVerificada {
    final precio = _precioEstimado;
    if (precio == null ||
        _entregaConfirmadaPara == null ||
        precio.direccionEntregaLat == null ||
        precio.direccionEntregaLng == null) {
      return null;
    }
    return VerificacionDireccionPrevia(
      direccionVerificadaPara: _entregaConfirmadaPara!,
      lat: precio.direccionEntregaLat!,
      lng: precio.direccionEntregaLng!,
    );
  }

  /// Ronda 13 — sugerencias mientras se escribe, no solo al perder el
  /// foco. Compartido entre farmacia y entrega — mismo endpoint,
  /// acotado con la ciudad/departamento del perfil del lado de la API.
  Future<List<SugerenciaDireccion>> _buscarSugerencias(String texto) async {
    final candidatos =
        await ref.read(autocompletarDireccionUseCaseProvider).execute(texto);
    return candidatos
        .map(
          (c) => SugerenciaDireccion(
            lat: c.lat,
            lng: c.lng,
            direccionResuelta: c.direccionResuelta,
            precisa: c.precisa,
          ),
        )
        .toList();
  }

  Widget _mensajeConfirmacionFarmacia() {
    final texto = _direccionFarmacia.text.trim();
    if (texto.isEmpty) return const SizedBox.shrink();
    final vigente = _farmaciaConfirmadaPara == texto && _precioEstimado != null;
    final List<CandidatoDireccion> candidatos =
        vigente ? _precioEstimado!.direccionFarmaciaCandidatos : const [];
    return MensajeConfirmacionDireccion(
      cargando: _cargandoPrecio && !vigente,
      resuelta: vigente ? _precioEstimado!.direccionFarmaciaResuelta : null,
      precisa: vigente ? _precioEstimado!.direccionFarmaciaPrecisa : true,
      fallo: vigente && _precioEstimado!.direccionFarmaciaResuelta == null,
      candidatos: candidatos,
      onVerAlternativas: candidatos.isEmpty
          ? null
          : () => _elegirCandidato(_direccionFarmacia, candidatos),
    );
  }

  Widget _mensajeConfirmacionEntrega() {
    final texto = _direccionEntrega.text.trim();
    if (texto.isEmpty) return const SizedBox.shrink();
    final vigente = _entregaConfirmadaPara == texto && _precioEstimado != null;
    final List<CandidatoDireccion> candidatos =
        vigente ? _precioEstimado!.direccionEntregaCandidatos : const [];
    return MensajeConfirmacionDireccion(
      cargando: _cargandoPrecio && !vigente,
      resuelta: vigente ? _precioEstimado!.direccionEntregaResuelta : null,
      precisa: vigente ? _precioEstimado!.direccionEntregaPrecisa : true,
      fallo: vigente && _precioEstimado!.direccionEntregaResuelta == null,
      candidatos: candidatos,
      onVerAlternativas: candidatos.isEmpty
          ? null
          : () => _elegirCandidato(_direccionEntrega, candidatos),
    );
  }

  /// Ronda 11 — bug real reportado: un Paciente registrado en un
  /// municipio (ej. Amagá) puede estar pidiendo desde otro (ej. San
  /// Antonio de Prado, ya en Medellín) — el primer resultado de
  /// Nominatim no siempre es el correcto. Al elegir un candidato, se
  /// reemplaza el texto del campo por la dirección tal como Nominatim
  /// la reconoce (más específica que lo que el Paciente escribió), lo
  /// que dispara una nueva geocodificación de esa dirección puntual al
  /// perder el foco — mismo camino que cualquier otra edición manual,
  /// sin necesidad de pasarle lat/lng directo a la API.
  Future<void> _elegirCandidato(
    TextEditingController controller,
    List<CandidatoDireccion> candidatos,
  ) async {
    final elegido = await mostrarSelectorDireccion(
      context,
      direccionElegida: controller.text,
      candidatos: candidatos,
    );
    if (elegido == null || !mounted) return;
    controller.text = elegido.direccionResuelta;
    _onCambioCampo();
    _onCambioDireccionParaPrecio();
  }

  bool _huboCambiosSinGuardar() {
    final hayRecetaPendiente = _recetaBytesPendiente != null;
    if (!_editandoExistente) {
      final datos = _datosActuales();
      final hayMedicamento = datos.medicamentos.any((m) => !m.estaVacio);
      return hayMedicamento ||
          hayRecetaPendiente ||
          datos.recetaFechaVencimiento != null ||
          datos.direccionEntrega != null ||
          datos.direccionFarmacia != null;
    }
    final actuales = _datosActuales();
    final originales = _datosOriginales;
    return hayRecetaPendiente ||
        originales == null ||
        actuales.toJson().toString() != originales.toJson().toString();
  }

  Future<String> _persistir() async {
    final datos = _datosActuales();
    String id;
    if (_solicitudIdRemoto == null) {
      id = await ref.read(crearSolicitudUseCaseProvider).execute(datos);
      _solicitudIdRemoto = id;
      await ref.read(borradorLocalRepositoryProvider).limpiar();
    } else {
      id = _solicitudIdRemoto!;
      await ref.read(actualizarSolicitudUseCaseProvider).execute(id, datos);
    }

    if (_recetaBytesPendiente != null) {
      await ref
          .read(subirRecetaUseCaseProvider)
          .execute(
            solicitudId: id,
            bytes: _recetaBytesPendiente!,
            nombreArchivo: _recetaNombrePendiente!,
            contentType: _recetaContentTypePendiente!,
          );
      _recetaBytesPendiente = null;
    }

    return id;
  }

  Future<void> _onGuardarBorrador() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await _persistir();
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _onEnviar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final id = await _persistir();
      final codigoPedido = await ref.read(enviarSolicitudUseCaseProvider).execute(
            id,
            farmaciaVerificada: _farmaciaVerificada,
            entregaVerificada: _entregaVerificada,
          );
      if (mounted) await _mostrarPedidoConfirmado(codigoPedido);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _mostrarPedidoConfirmado(String codigoPedido) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '¡Tu solicitud fue exitosa!',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Guarda este código de pedido:'),
            const SizedBox(height: 12),
            Text(
              codigoPedido,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Entendido', style: TextStyle(color: AppColors.navy)),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmarSalida() async {
    if (!_huboCambiosSinGuardar()) return true;

    if (_editandoExistente) {
      final decision = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Cambios sin guardar'),
          content: const Text('¿Guardás los cambios antes de salir?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Seguir editando', style: TextStyle(color: AppColors.navy)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Descartar', style: TextStyle(color: AppColors.navy)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Guardar', style: TextStyle(color: AppColors.teal)),
            ),
          ],
        ),
      );
      if (decision == null) return false;
      if (decision) await _persistir();
      return true;
    }

    final decision = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Continuar con este pedido más tarde?'),
        content: const Text(
          'Podés guardar lo que ya cargaste para retomarlo después, o descartarlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Seguir editando', style: TextStyle(color: AppColors.navy)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Descartar', style: TextStyle(color: AppColors.navy)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Guardar para después', style: TextStyle(color: AppColors.teal)),
          ),
        ],
      ),
    );
    if (decision == null) return false;
    if (decision) {
      await _persistir();
    } else {
      await ref.read(borradorLocalRepositoryProvider).limpiar();
    }
    return true;
  }

  Future<void> _elegirFechaReceta() async {
    final ahora = DateTime.now();
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _recetaFechaVencimiento ?? ahora,
      firstDate: DateTime(ahora.year - 2),
      lastDate: DateTime(ahora.year + 5),
    );
    if (seleccionada != null) {
      setState(() => _recetaFechaVencimiento = seleccionada);
      _onCambioCampo();
    }
  }

  Future<void> _elegirFotoReceta() async {
    final elegido = await mostrarSelectorArchivo(context);
    if (elegido == null) return;

    setState(() {
      _recetaBytesPendiente = elegido.bytes;
      _recetaNombrePendiente = elegido.nombre;
      _recetaContentTypePendiente = elegido.contentType;
    });
    _onCambioCampo();
  }

  @override
  Widget build(BuildContext context) {
    final datosActuales = _datosActuales();
    final faltantes = datosActuales.calcularFaltantes(
      tieneRecetaSubida: _recetaBytesPendiente != null || _recetaUrlServidor != null,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final debeSalir = await _confirmarSalida();
        if (debeSalir && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Nueva solicitud',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.navy,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.navy, size: 20),
            onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
          ),
        ),
        bottomNavigationBar: const MainBottomBar(),
        body: _cargandoInicial
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ====== IMAGEN SOLA ======
                        Align(
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/images/hero_medicamentos.png',
                            height: 180,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.medication_outlined,
                              color: AppColors.navy,
                              size: 60,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (_error != null) ...[
                          AppErrorBanner(mensaje: _error!),
                          const SizedBox(height: 16),
                        ],

                        // ====== SECCIÓN: MEDICAMENTOS ======
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Medicamentos',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Una fórmula puede traer más de uno',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.teal, fontSize: 13),
                              ),
                              const Text(
                                'Agrega una línea por cada uno',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.teal, fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              for (var i = 0; i < _medicamentos.length; i++) ...[
                                FilaResumenMedicamento(
                                  medicamento: _medicamentos[i],
                                  enabled: !_guardando,
                                  onEditar: () => _abrirDialogoMedicamento(indice: i),
                                  onQuitar: () => _quitarMedicamento(i),
                                ),
                                const SizedBox(height: 8),
                              ],
                              // Botón gris claro con letra azul oscuro
                              Center(
                                child: InkWell(
                                  onTap: _guardando ? null : () => _abrirDialogoMedicamento(),
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2F4F7),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      _medicamentos.isEmpty ? 'Agregar medicamento' : 'Agregar otro medicamento',
                                      style: const TextStyle(
                                        color: AppColors.navy,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ====== SECCIÓN: RECETA ======
                        const TituloSeccionSolicitud('Receta médica'),
                        const SizedBox(height: 12),
                        FilaFotoReceta(
                          tieneArchivo: _recetaBytesPendiente != null || _recetaUrlServidor != null,
                          bytesLocal: _recetaBytesPendiente,
                          esPdfLocal: _recetaContentTypePendiente == 'application/pdf',
                          urlServidor: _recetaUrlServidor,
                          onElegir: _guardando ? null : _elegirFotoReceta,
                        ),
                        const SizedBox(height: 12),
                        _CampoFecha(
                          label: 'Fecha de vencimiento de la receta',
                          fecha: _recetaFechaVencimiento,
                          onTap: _guardando ? null : _elegirFechaReceta,
                        ),
                        const SizedBox(height: 24),

                        // ====== SECCIÓN: FARMACIA ======
                        const TituloSeccionSolicitud('Farmacia'),
                        const SizedBox(height: 4),
                        const Text(
                          'Dónde el domiciliario retira el medicamento.',
                          style: TextStyle(color: AppColors.teal, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        CampoTextoBlanco(
                          label: 'Dirección de la farmacia',
                          icono: Icons.local_pharmacy_outlined,
                          controller: _direccionFarmacia,
                          focusNode: _focusDireccionFarmacia,
                          enabled: !_guardando,
                        ),
                        SugerenciasDireccion(
                          controller: _direccionFarmacia,
                          focusNode: _focusDireccionFarmacia,
                          buscar: _buscarSugerencias,
                          onSeleccionar: (_) => _onCambioDireccionParaPrecio(),
                        ),
                        _mensajeConfirmacionFarmacia(),
                        const SizedBox(height: 24),

                        // ====== SECCIÓN: ENTREGA ======
                        const TituloSeccionSolicitud('Entrega'),
                        const SizedBox(height: 12),
                        CampoTextoBlanco(
                          label: 'Dirección de entrega',
                          icono: Icons.home_outlined,
                          controller: _direccionEntrega,
                          focusNode: _focusDireccionEntrega,
                          enabled: !_guardando,
                        ),
                        SugerenciasDireccion(
                          controller: _direccionEntrega,
                          focusNode: _focusDireccionEntrega,
                          buscar: _buscarSugerencias,
                          onSeleccionar: (_) => _onCambioDireccionParaPrecio(),
                        ),
                        _mensajeConfirmacionEntrega(),
                        const SizedBox(height: 24),

                        // Estimado en vivo — recién aparece cuando hay
                        // algo que calcular (ambas direcciones
                        // completas); mientras se está geocodificando,
                        // un indicador chico en vez de tapar la
                        // tarjeta anterior con un spinner.
                        if (_cargandoPrecio && _precioEstimado == null) ...[
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ] else if (_precioEstimado != null) ...[
                          TarjetaPrecioPedido(
                            precio: _precioEstimado!,
                            titulo: 'Precio estimado',
                            mensajeSinUbicaciones:
                                'No pudimos ubicar alguna de las dos direcciones — revisalas.',
                          ),
                          const SizedBox(height: 24),
                        ],

                        AppLoadingButton(
                          label: 'Guardar borrador',
                          variante: AppButtonVariante.secondary,
                          cargando: _guardando,
                          onPressed: _onGuardarBorrador,
                        ),
                        const SizedBox(height: 8),
                        AppLoadingButton(
                          label: 'Enviar solicitud',
                          cargando: _guardando,
                          onPressed: faltantes.isEmpty && _direccionesConfirmadas
                              ? _onEnviar
                              : null,
                        ),
                        if (faltantes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Para enviar falta: ${faltantes.join(', ')}.',
                            style: const TextStyle(color: AppColors.teal, fontSize: 13),
                          ),
                        ] else if (!_direccionesConfirmadas) ...[
                          // Bug real reportado: antes se dejaba enviar
                          // el pedido aunque Nominatim no hubiera
                          // podido confirmar ninguna de las dos
                          // direcciones — el domiciliario terminaba
                          // sin ubicación real para navegar.
                          const SizedBox(height: 8),
                          const Text(
                            'Para enviar, esperá a que las dos direcciones queden confirmadas arriba.',
                            style: TextStyle(color: AppColors.teal, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}


class _CampoFecha extends StatelessWidget {
  const _CampoFecha({required this.label, required this.fecha, required this.onTap});

  final String label;
  final DateTime? fecha;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: AppColors.teal, fontSize: 13),
            prefixIcon: const Icon(Icons.event_outlined, color: AppColors.teal),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
          child: Text(
            fecha != null ? _isoFecha(fecha!) : 'Selecciona una fecha',
            style: const TextStyle(color: AppColors.navy),
          ),
        ),
      ),
    );
  }
}

String _isoFecha(DateTime fecha) {
  final anio = fecha.year.toString().padLeft(4, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  final dia = fecha.day.toString().padLeft(2, '0');
  return '$anio-$mes-$dia';
}