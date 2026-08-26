import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_icon_badge.dart';
import '../../../../shared/widgets/app_loading_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/perfil.dart';
import '../../domain/value-objects/tipo_documento_domiciliario.dart';
import '../providers/auth_session_provider.dart';
import '../providers/perfil_providers.dart';
import '../providers/usuario_providers.dart';
import 'cambiar_contrasena_screen.dart';

/// HU-02 — pantalla "Mi perfil". Secciones condicionales según los roles
/// de la cuenta (context.md, Parte B, sección 4.1: un usuario puede
/// tener PACIENTE y DOMICILIARIO a la vez).
///
/// Un solo botón "Guardar cambios" al pie guarda datos comunes + el
/// perfil del rol activo a la vez (antes cada tarjeta tenía su propio
/// "Guardar" — confuso, varios botones casi idénticos en una pantalla
/// corta). Por eso los controllers de texto viven acá, no en cada
/// sub-sección — así el botón único puede leerlos a todos. Documentos y
/// avatar quedan aparte: son acciones inmediatas al elegir el archivo,
/// no datos de formulario que tenga sentido "guardar" después. "Enviar
/// solicitud" (validación de Domiciliario) también queda aparte — es
/// una acción distinta a guardar los datos, mismo criterio que HU-03.
class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  static const routeName = '/perfil';

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  bool _cargandoPerfil = true;
  Perfil? _perfil;
  String? _errorCarga;

  late final TextEditingController _correoController;
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();

  final _pacienteDireccionController = TextEditingController();
  final _pacienteDepartamentoController = TextEditingController();
  final _pacienteCiudadController = TextEditingController();
  DateTime? _pacienteFechaNacimiento;

  final _domiciliarioDireccionController = TextEditingController();
  final _vehiculoTipoController = TextEditingController();
  final _vehiculoPlacaController = TextEditingController();

  bool _guardandoCambios = false;
  String? _errorGuardar;

  @override
  void initState() {
    super.initState();
    // No se puede `ref.watch` en initState — se lee una sola vez. El
    // correo no cambia mientras esta pantalla está abierta (no hay
    // funcionalidad para editarlo).
    final estadoInicial = ref.read(authSessionProvider);
    final usuarioInicial = estadoInicial is AuthAutenticado ? estadoInicial.usuario : null;
    _correoController = TextEditingController(text: usuarioInicial?.correo ?? '');
    _cargarPerfil();
  }

  @override
  void dispose() {
    _correoController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    _pacienteDireccionController.dispose();
    _pacienteDepartamentoController.dispose();
    _pacienteCiudadController.dispose();
    _domiciliarioDireccionController.dispose();
    _vehiculoTipoController.dispose();
    _vehiculoPlacaController.dispose();
    super.dispose();
  }

  /// Carga completa: pisa TODOS los controllers con lo que devuelve la
  /// API. Solo es seguro usarla cuando no hay riesgo de perder algo que
  /// la persona esté tipeando sin guardar todavía — el primer arranque
  /// (nada tipeado aún) y el pull-to-refresh explícito (la persona pidió
  /// recargar a propósito, mismo criterio que cualquier otra pantalla
  /// con `RefreshIndicator`). Para refrescos disparados por OTRA acción
  /// (subir avatar/documento, pedir un rol) usar `_recargarSoloPerfil`
  /// o `_onRolAgregado` — NUNCA esta, o se pierde texto sin guardar
  /// (bug real: pasó justo así con la foto de perfil).
  Future<void> _cargarPerfil() async {
    setState(() {
      _cargandoPerfil = true;
      _errorCarga = null;
    });
    try {
      final perfil = await ref.read(obtenerPerfilUseCaseProvider).execute();
      if (!mounted) return;
      setState(() {
        _perfil = perfil;
        _nombreController.text = perfil.nombreCompleto ?? '';
        _telefonoController.text = perfil.telefono ?? '';
        _pacienteDireccionController.text = perfil.paciente?.direccion ?? '';
        _pacienteDepartamentoController.text = perfil.paciente?.departamento ?? '';
        _pacienteCiudadController.text = perfil.paciente?.ciudad ?? '';
        final fechaNacimiento = perfil.paciente?.fechaNacimiento;
        _pacienteFechaNacimiento =
            fechaNacimiento != null ? DateTime.tryParse(fechaNacimiento) : null;
        _domiciliarioDireccionController.text = perfil.domiciliario?.direccion ?? '';
        _vehiculoTipoController.text = perfil.domiciliario?.vehiculoTipo ?? '';
        _vehiculoPlacaController.text = perfil.domiciliario?.vehiculoPlaca ?? '';
      });
    } on ApiException catch (error) {
      setState(() => _errorCarga = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _errorCarga = error.toString());
    } finally {
      if (mounted) setState(() => _cargandoPerfil = false);
    }
  }

  /// Refresco "silencioso": solo actualiza `_perfil` (para que se vea
  /// la URL nueva de un avatar/documento recién subido) — nunca toca un
  /// controller de texto ni el spinner de pantalla completa. Es lo que
  /// corresponde después de subir el avatar o un documento: son
  /// acciones aparte de "Guardar cambios", no deberían poder pisar lo
  /// que la persona esté tipeando en otro campo de la misma pantalla.
  Future<void> _recargarSoloPerfil() async {
    try {
      final perfil = await ref.read(obtenerPerfilUseCaseProvider).execute();
      if (!mounted) return;
      setState(() => _perfil = perfil);
    } on ApiException catch (error) {
      setState(() => _errorCarga = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _errorCarga = error.toString());
    }
  }

  /// Tras "Solicitar ser Paciente/Domiciliario", la API puede devolver
  /// dirección/cédula ya copiadas del otro perfil (ver
  /// `20260823110000_solicitar_rol_reusa_datos.sql`) — hay que
  /// mostrarlas sin esperar un pull-to-refresh manual. Pero a
  /// diferencia de `_cargarPerfil`, solo toca los controllers del rol
  /// recién otorgado (antes vacíos, nadie pudo haber tipeado nada ahí
  /// todavía) — nunca los de Datos básicos ni los del otro rol, que sí
  /// podrían tener texto sin guardar.
  Future<void> _onRolAgregado(String rolNuevo) async {
    try {
      final perfil = await ref.read(obtenerPerfilUseCaseProvider).execute();
      if (!mounted) return;
      setState(() {
        _perfil = perfil;
        if (rolNuevo == 'PACIENTE') {
          _pacienteDireccionController.text = perfil.paciente?.direccion ?? '';
          _pacienteDepartamentoController.text = perfil.paciente?.departamento ?? '';
          _pacienteCiudadController.text = perfil.paciente?.ciudad ?? '';
          final fechaNacimiento = perfil.paciente?.fechaNacimiento;
          _pacienteFechaNacimiento =
              fechaNacimiento != null ? DateTime.tryParse(fechaNacimiento) : null;
        } else if (rolNuevo == 'DOMICILIARIO') {
          _domiciliarioDireccionController.text = perfil.domiciliario?.direccion ?? '';
          _vehiculoTipoController.text = perfil.domiciliario?.vehiculoTipo ?? '';
          _vehiculoPlacaController.text = perfil.domiciliario?.vehiculoPlaca ?? '';
        }
      });
    } on ApiException catch (error) {
      setState(() => _errorCarga = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _errorCarga = error.toString());
    }
  }

  Future<void> _elegirFechaNacimiento() async {
    final ahora = DateTime.now();
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _pacienteFechaNacimiento ?? DateTime(ahora.year - 25),
      firstDate: DateTime(1900),
      lastDate: ahora.subtract(const Duration(days: 1)),
    );
    if (seleccionada != null) {
      setState(() => _pacienteFechaNacimiento = seleccionada);
    }
  }

  Future<void> _guardarCambios({
    required bool esPaciente,
    required bool esDomiciliario,
  }) async {
    final faltantes = <String>[];
    if (_nombreController.text.trim().isEmpty || _telefonoController.text.trim().isEmpty) {
      faltantes.add('nombre y teléfono');
    }
    if (esPaciente &&
        (_pacienteDireccionController.text.trim().isEmpty ||
            _pacienteDepartamentoController.text.trim().isEmpty ||
            _pacienteCiudadController.text.trim().isEmpty ||
            _pacienteFechaNacimiento == null)) {
      faltantes.add('dirección, departamento, ciudad y fecha de nacimiento de Paciente');
    }
    if (esDomiciliario &&
        (_domiciliarioDireccionController.text.trim().isEmpty ||
            _vehiculoTipoController.text.trim().isEmpty ||
            _vehiculoPlacaController.text.trim().isEmpty)) {
      faltantes.add('dirección, tipo de vehículo y placa de Domiciliario');
    }
    if (faltantes.isNotEmpty) {
      setState(() => _errorGuardar = 'Completa: ${faltantes.join('; ')}.');
      return;
    }

    setState(() {
      _guardandoCambios = true;
      _errorGuardar = null;
    });
    try {
      await ref
          .read(actualizarDatosComunesUseCaseProvider)
          .execute(
            nombreCompleto: _nombreController.text.trim(),
            telefono: _telefonoController.text.trim(),
          );
      if (esPaciente) {
        await ref
            .read(actualizarPerfilPacienteUseCaseProvider)
            .execute(
              direccion: _pacienteDireccionController.text.trim(),
              fechaNacimiento: _isoFecha(_pacienteFechaNacimiento!),
              departamento: _pacienteDepartamentoController.text.trim(),
              ciudad: _pacienteCiudadController.text.trim(),
            );
      }
      if (esDomiciliario) {
        await ref
            .read(actualizarPerfilDomiciliarioUseCaseProvider)
            .execute(
              direccion: _domiciliarioDireccionController.text.trim(),
              vehiculoTipo: _vehiculoTipoController.text.trim(),
              vehiculoPlaca: _vehiculoPlacaController.text.trim(),
            );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cambios guardados.')));
    } on ApiException catch (error) {
      setState(() => _errorGuardar = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _errorGuardar = error.toString());
    } finally {
      if (mounted) setState(() => _guardandoCambios = false);
    }
  }

  /// Mudado acá desde Home (v3 lo tenía en el menú "Cuenta") — Perfil
  /// es ahora el destino directo de la barra inferior donde vive todo
  /// lo relacionado a la cuenta, cerrar sesión incluido.
  Future<void> _cerrarSesion(BuildContext context) async {
    await ref.read(authSessionProvider.notifier).cerrarSesion();
    ref.invalidate(modoActivoProvider);
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(authSessionProvider);
    final usuario = estado is AuthAutenticado ? estado.usuario : null;
    final roles = usuario?.roles ?? const [];
    // Mismo "modo" activo que se elige en home_screen.dart — si la cuenta
    // es multirol, acá solo se muestra la tarjeta del rol activo, no la de
    // todos los roles que tenga la cuenta (para cambiar de tarjeta hay que
    // cambiar el modo en Inicio).
    final modo = ref.watch(modoActivoProvider) ?? (roles.isNotEmpty ? roles.first.codigo : null);
    final esPaciente = modo == 'PACIENTE';
    final esDomiciliario = modo == 'DOMICILIARIO';
    // Distinto de esPaciente/esDomiciliario (que reflejan el "modo"
    // activo, no qué roles tiene realmente la cuenta) — acá sí importa
    // la existencia real del rol, para ofrecer "Solicitar ser X" solo
    // cuando de verdad falta.
    final tienePaciente = roles.any((r) => r.codigo == 'PACIENTE');
    final tieneDomiciliario = roles.any((r) => r.codigo == 'DOMICILIARIO');
    final rolesDomiciliario = roles.where((r) => r.codigo == 'DOMICILIARIO');
    final estadoRolDomiciliario = rolesDomiciliario.isEmpty ? null : rolesDomiciliario.first.estado;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: _cargandoPerfil
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: RefreshIndicator(
                  onRefresh: _cargarPerfil,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: _AvatarPerfil(
                            fotoPerfilUrl: _perfil?.fotoPerfilUrl,
                            onCambio: _recargarSoloPerfil,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_errorCarga != null) ...[
                          AppErrorBanner(mensaje: _errorCarga!),
                          const SizedBox(height: 16),
                        ],
                        _SeccionDatosComunes(
                          correoController: _correoController,
                          nombreController: _nombreController,
                          telefonoController: _telefonoController,
                          enabled: !_guardandoCambios,
                        ),
                        if (esPaciente) ...[
                          const SizedBox(height: 24),
                          _SeccionPaciente(
                            perfil: _perfil?.paciente,
                            direccionController: _pacienteDireccionController,
                            departamentoController: _pacienteDepartamentoController,
                            ciudadController: _pacienteCiudadController,
                            fechaNacimiento: _pacienteFechaNacimiento,
                            onElegirFecha: _elegirFechaNacimiento,
                            enabled: !_guardandoCambios,
                            onCambio: _recargarSoloPerfil,
                          ),
                        ],
                        if (esDomiciliario) ...[
                          const SizedBox(height: 24),
                          _SeccionDomiciliario(
                            perfil: _perfil?.domiciliario,
                            estadoRol: estadoRolDomiciliario,
                            direccionController: _domiciliarioDireccionController,
                            vehiculoTipoController: _vehiculoTipoController,
                            vehiculoPlacaController: _vehiculoPlacaController,
                            enabled: !_guardandoCambios,
                            onCambio: _recargarSoloPerfil,
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (_errorGuardar != null) ...[
                          AppErrorBanner(mensaje: _errorGuardar!),
                          const SizedBox(height: 12),
                        ],
                        AppLoadingButton(
                          label: 'Guardar cambios',
                          cargando: _guardandoCambios,
                          onPressed: () => _guardarCambios(
                            esPaciente: esPaciente,
                            esDomiciliario: esDomiciliario,
                          ),
                        ),
                        if (!tienePaciente || !tieneDomiciliario) ...[
                          const SizedBox(height: 24),
                          _SeccionAgregarRol(
                            ofrecerPaciente: !tienePaciente,
                            ofrecerDomiciliario: !tieneDomiciliario,
                            onAgregado: _onRolAgregado,
                          ),
                        ],
                        const SizedBox(height: 32),
                        const _SeccionDesactivarCuenta(),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => _cerrarSesion(context),
                            icon: const Icon(Icons.logout, color: AppColors.teal),
                            label: const Text(
                              'Cerrar sesión',
                              style: TextStyle(color: AppColors.teal),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Avatar del usuario, en la cabecera de la pantalla — muestra la foto de
/// perfil ya subida (URL firmada) o el badge por defecto, con un botón de
/// cámara superpuesto para subir/reemplazar.
class _AvatarPerfil extends ConsumerStatefulWidget {
  const _AvatarPerfil({required this.fotoPerfilUrl, required this.onCambio});

  final String? fotoPerfilUrl;
  final Future<void> Function() onCambio;

  @override
  ConsumerState<_AvatarPerfil> createState() => _AvatarPerfilState();
}

class _AvatarPerfilState extends ConsumerState<_AvatarPerfil> {
  bool _subiendo = false;
  String? _error;

  Future<void> _elegirYSubir() async {
    final origen = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (origen == null) return;

    final archivo = await ImagePicker().pickImage(source: origen, imageQuality: 85);
    if (archivo == null || !mounted) return;

    setState(() {
      _subiendo = true;
      _error = null;
    });
    try {
      final bytes = await archivo.readAsBytes();
      await ref
          .read(subirFotoPerfilUseCaseProvider)
          .execute(
            bytes: bytes,
            nombreArchivo: archivo.name,
            contentType: _contentTypeDesde(archivo.name),
          );
      await widget.onCambio();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on ApiSinConexionException catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  String _contentTypeDesde(String nombreArchivo) {
    final minuscula = nombreArchivo.toLowerCase();
    if (minuscula.endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ClipOval(
              child: widget.fotoPerfilUrl != null
                  ? Image.network(
                      widget.fotoPerfilUrl!,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const SizedBox(
                          width: 96,
                          height: 96,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const AppIconBadge(icono: Icons.badge_outlined),
                    )
                  : const AppIconBadge(icono: Icons.badge_outlined),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: InkWell(
                onTap: _subiendo ? null : _elegirYSubir,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    shape: BoxShape.circle,
                  ),
                  child: _subiendo
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Icon(
                          Icons.photo_camera_outlined,
                          color: AppColors.white,
                          size: 18,
                        ),
                ),
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          AppErrorBanner(mensaje: _error!),
        ],
      ],
    );
  }
}

/// Encabezado de sección — mismo estilo en las 3 tarjetas.
class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: AppColors.navy,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.skyBlue),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

/// G02/G03/G04 — nombre y teléfono, comunes a cualquier rol. Los
/// controllers los posee `PerfilScreen` (guardado unificado) — esta
/// sección solo muestra los campos y "Cambiar contraseña" (acción
/// aparte, no un dato de formulario).
class _SeccionDatosComunes extends StatelessWidget {
  const _SeccionDatosComunes({
    required this.correoController,
    required this.nombreController,
    required this.telefonoController,
    required this.enabled,
  });

  final TextEditingController correoController;
  final TextEditingController nombreController;
  final TextEditingController telefonoController;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      children: [
        const _TituloSeccion('Datos básicos'),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Correo',
          icono: Icons.email_outlined,
          controller: correoController,
          enabled: false,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Nombre completo',
          icono: Icons.person_outline,
          controller: nombreController,
          enabled: enabled,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Teléfono',
          icono: Icons.phone_outlined,
          controller: telefonoController,
          keyboardType: TextInputType.phone,
          enabled: enabled,
        ),
        const SizedBox(height: 16),
        AppButton(
          variante: AppButtonVariante.secondary,
          label: 'Cambiar contraseña',
          onPressed: () =>
              Navigator.of(context).pushNamed(CambiarContrasenaScreen.routeName),
        ),
      ],
    );
  }
}

/// G01/G03/G04 — dirección, fecha de nacimiento y foto de cédula. El
/// controller de dirección y la fecha los posee `PerfilScreen`
/// (guardado unificado); la foto de cédula sigue siendo una subida
/// inmediata al elegir el archivo, no pasa por "Guardar cambios".
class _SeccionPaciente extends ConsumerWidget {
  const _SeccionPaciente({
    required this.perfil,
    required this.direccionController,
    required this.departamentoController,
    required this.ciudadController,
    required this.fechaNacimiento,
    required this.onElegirFecha,
    required this.enabled,
    required this.onCambio,
  });

  final dynamic perfil;
  final TextEditingController direccionController;
  final TextEditingController departamentoController;
  final TextEditingController ciudadController;
  final DateTime? fechaNacimiento;
  final VoidCallback onElegirFecha;
  final bool enabled;
  final Future<void> Function() onCambio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Tarjeta(
      children: [
        const _TituloSeccion('Perfil de Paciente'),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Dirección de entrega',
          icono: Icons.home_outlined,
          controller: direccionController,
          enabled: enabled,
        ),
        const SizedBox(height: 12),
        // HU-09: departamento/ciudad se usan para geolocalizar la
        // dirección al crear un pedido (asignación por cercanía) — sin
        // esto la API no puede calcular la distancia al domiciliario.
        AppTextField(
          label: 'Departamento',
          icono: Icons.map_outlined,
          controller: departamentoController,
          enabled: enabled,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Ciudad',
          icono: Icons.location_city_outlined,
          controller: ciudadController,
          enabled: enabled,
        ),
        const SizedBox(height: 12),
        _CampoFecha(
          label: 'Fecha de nacimiento',
          fecha: fechaNacimiento,
          onTap: enabled ? onElegirFecha : null,
        ),
        const SizedBox(height: 16),
        _DocumentoUploadRow(
          label: 'Foto de cédula',
          url: perfil?.fotoCedulaUrl,
          onArchivoElegido: (bytes, nombre, contentType) async {
            await ref
                .read(subirFotoCedulaPacienteUseCaseProvider)
                .execute(
                  bytes: bytes,
                  nombreArchivo: nombre,
                  contentType: contentType,
                );
            await onCambio();
          },
        ),
      ],
    );
  }
}

/// G01/G03/G04 — dirección, vehículo y documentos de validación. Los
/// controllers de dirección/vehículo los posee `PerfilScreen` (guardado
/// unificado). Documentos y "Enviar solicitud" quedan aparte — acciones
/// propias, no datos de "Guardar cambios".
class _SeccionDomiciliario extends ConsumerStatefulWidget {
  const _SeccionDomiciliario({
    required this.perfil,
    required this.estadoRol,
    required this.direccionController,
    required this.vehiculoTipoController,
    required this.vehiculoPlacaController,
    required this.enabled,
    required this.onCambio,
  });

  final dynamic perfil;

  /// Estado de `usuario_roles` para DOMICILIARIO — a diferencia de
  /// `perfil` (los datos en sí), esto dice en qué parte del flujo de
  /// validación está la cuenta: `borrador` (recién ahora se completa,
  /// todavía no se envió), `pendiente_validacion` (ya enviada, un admin
  /// la está revisando), `habilitado` (aprobada) o `rechazado`.
  final String? estadoRol;
  final TextEditingController direccionController;
  final TextEditingController vehiculoTipoController;
  final TextEditingController vehiculoPlacaController;
  final bool enabled;
  final Future<void> Function() onCambio;

  @override
  ConsumerState<_SeccionDomiciliario> createState() => _SeccionDomiciliarioState();
}

class _SeccionDomiciliarioState extends ConsumerState<_SeccionDomiciliario> {
  bool _enviando = false;
  String? _error;

  Future<void> _subirDocumento(
    TipoDocumentoDomiciliario tipo,
    List<int> bytes,
    String nombre,
    String contentType,
  ) async {
    await ref
        .read(subirDocumentoDomiciliarioUseCaseProvider)
        .execute(
          tipo: tipo,
          bytes: bytes,
          nombreArchivo: nombre,
          contentType: contentType,
        );
    await widget.onCambio();
  }

  /// Mismos 7 campos obligatorios que ya exige `app.enviar_solicitud_
  /// domiciliario`/`app.aprobar_domiciliario` — se deshabilita "Enviar
  /// solicitud" preventivamente en vez de depender de chocar con el 422.
  /// A propósito lee `widget.perfil` (lo ya guardado en el servidor), no
  /// los controllers (lo que se está tipeando pero todavía no se
  /// guardó) — enviar la solicitud es sobre lo que el servidor ya tiene.
  List<String> _calcularFaltantes() {
    final p = widget.perfil;
    final faltantes = <String>[];
    if ((p?.direccion as String?)?.trim().isNotEmpty != true) {
      faltantes.add('Dirección de residencia');
    }
    if ((p?.vehiculoTipo as String?)?.trim().isNotEmpty != true) {
      faltantes.add('Tipo de vehículo');
    }
    if ((p?.vehiculoPlaca as String?)?.trim().isNotEmpty != true) {
      faltantes.add('Placa');
    }
    if (p?.cedulaUrl == null) faltantes.add('Cédula');
    if (p?.licenciaUrl == null) faltantes.add('Licencia de conducción');
    if (p?.soatUrl == null) faltantes.add('SOAT');
    if (p?.tecnicomecanicaUrl == null) faltantes.add('Tecnomecánica');
    return faltantes;
  }

  Future<void> _enviarSolicitud() async {
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final mensaje =
          await ref.read(enviarSolicitudDomiciliarioUseCaseProvider).execute();
      // El estado del rol pasa de borrador a pendiente_validacion — no
      // viaja en el JWT ni en GET /perfil, vive en la sesión
      // (authSessionProvider). Sin refrescarla acá, "estadoRol" seguía
      // mostrando "borrador" (y el botón "Enviar solicitud" seguía
      // habilitado) hasta cerrar y volver a entrar a la pantalla.
      final usuarioActualizado = await ref.read(obtenerSesionActualUseCaseProvider).execute();
      ref.read(authSessionProvider.notifier).sesionIniciada(usuarioActualizado);
      await widget.onCambio();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      children: [
        const _TituloSeccion('Perfil de Domiciliario'),
        const SizedBox(height: 4),
        Text(
          switch (widget.estadoRol) {
            'pendiente_validacion' => 'Tu solicitud está en revisión por un administrador.',
            'habilitado' => 'Ya estás validado como Domiciliario.',
            'rechazado' => 'Tu solicitud fue rechazada.',
            _ => 'Completá tus datos y enviá la solicitud para que un administrador te valide.',
          },
          style: const TextStyle(color: AppColors.teal, fontSize: 13),
        ),
        const SizedBox(height: 12),
        if (_error != null) ...[
          AppErrorBanner(mensaje: _error!),
          const SizedBox(height: 12),
        ],
        AppTextField(
          label: 'Dirección de residencia',
          icono: Icons.home_outlined,
          controller: widget.direccionController,
          enabled: widget.enabled,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Tipo de vehículo',
          icono: Icons.two_wheeler_outlined,
          controller: widget.vehiculoTipoController,
          enabled: widget.enabled,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Placa',
          icono: Icons.pin_outlined,
          controller: widget.vehiculoPlacaController,
          enabled: widget.enabled,
        ),
        const SizedBox(height: 16),
        const Text(
          'Documentos de validación',
          style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _DocumentoUploadRow(
          label: 'Cédula',
          url: widget.perfil?.cedulaUrl,
          onArchivoElegido: (b, n, c) => _subirDocumento(TipoDocumentoDomiciliario.cedula, b, n, c),
        ),
        const SizedBox(height: 8),
        _DocumentoUploadRow(
          label: 'Licencia de conducción',
          url: widget.perfil?.licenciaUrl,
          onArchivoElegido: (b, n, c) => _subirDocumento(TipoDocumentoDomiciliario.licencia, b, n, c),
        ),
        const SizedBox(height: 8),
        _DocumentoUploadRow(
          label: 'SOAT',
          url: widget.perfil?.soatUrl,
          onArchivoElegido: (b, n, c) => _subirDocumento(TipoDocumentoDomiciliario.soat, b, n, c),
        ),
        const SizedBox(height: 8),
        _DocumentoUploadRow(
          label: 'Tecnomecánica',
          url: widget.perfil?.tecnicomecanicaUrl,
          onArchivoElegido: (b, n, c) =>
              _subirDocumento(TipoDocumentoDomiciliario.tecnicomecanica, b, n, c),
        ),
        if (widget.estadoRol == 'borrador') ...[
          const SizedBox(height: 16),
          AppLoadingButton(
            label: 'Enviar solicitud',
            cargando: _enviando,
            onPressed: _calcularFaltantes().isEmpty ? _enviarSolicitud : null,
          ),
          if (_calcularFaltantes().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Para enviar falta: ${_calcularFaltantes().join(', ')}.',
              style: const TextStyle(color: AppColors.teal, fontSize: 13),
            ),
          ],
        ],
      ],
    );
  }
}

/// Ofrece pedir el rol que le falta a la cuenta (PACIENTE y/o
/// DOMICILIARIO) sin pasar por un registro nuevo. Al agregarse, refresca
/// los roles de la sesión (`authSessionProvider.sesionIniciada` — los
/// roles no viven en el JWT, hay que volver a pedirlos), el perfil (los
/// datos recién copiados del otro rol) y cambia el "Modo" al rol nuevo
/// para que la persona vea de una el formulario que acaba de pedir.
class _SeccionAgregarRol extends ConsumerStatefulWidget {
  const _SeccionAgregarRol({
    required this.ofrecerPaciente,
    required this.ofrecerDomiciliario,
    required this.onAgregado,
  });

  final bool ofrecerPaciente;
  final bool ofrecerDomiciliario;

  /// Recarga el perfil del padre — el rol nuevo puede llegar con
  /// dirección/foto de cédula ya copiadas del otro perfil (API), y sin
  /// esto no se verían hasta un pull-to-refresh manual. Recibe qué rol se
  /// acaba de otorgar para que el padre actualice solo los controllers de
  /// ESE rol (recién otorgado, nadie pudo haber tipeado nada ahí todavía)
  /// y no pise datos sin guardar de Datos básicos ni del otro rol.
  final Future<void> Function(String rolNuevo) onAgregado;

  @override
  ConsumerState<_SeccionAgregarRol> createState() => _SeccionAgregarRolState();
}

class _SeccionAgregarRolState extends ConsumerState<_SeccionAgregarRol> {
  bool _procesando = false;
  String? _error;

  Future<void> _solicitar(String rolNuevo, Future<String> Function() ejecutar) async {
    setState(() {
      _procesando = true;
      _error = null;
    });
    try {
      final mensaje = await ejecutar();
      final usuarioActualizado = await ref.read(obtenerSesionActualUseCaseProvider).execute();
      ref.read(authSessionProvider.notifier).sesionIniciada(usuarioActualizado);
      // Cambia el "Modo" al rol recién otorgado para que la persona vea
      // de una la pantalla que le corresponde (Perfil de Paciente/
      // Domiciliario) — sin esto, con más de un rol ahora en la cuenta,
      // tendría que ir a Inicio y cambiar de modo a mano para encontrar
      // el formulario que acaba de pedir.
      ref.read(modoActivoProvider.notifier).state = rolNuevo;
      await widget.onAgregado(rolNuevo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      children: [
        const _TituloSeccion('Otro rol'),
        const SizedBox(height: 4),
        const Text(
          'Podés usar la misma cuenta para los dos roles.',
          style: TextStyle(color: AppColors.teal, fontSize: 13),
        ),
        const SizedBox(height: 12),
        if (_error != null) ...[
          AppErrorBanner(mensaje: _error!),
          const SizedBox(height: 12),
        ],
        if (widget.ofrecerPaciente) ...[
          AppLoadingButton(
            variante: AppButtonVariante.secondary,
            label: 'Solicitar ser Paciente',
            cargando: _procesando,
            onPressed: () => _solicitar(
              'PACIENTE',
              () => ref.read(solicitarRolPacienteUseCaseProvider).execute(),
            ),
          ),
          if (widget.ofrecerDomiciliario) const SizedBox(height: 8),
        ],
        if (widget.ofrecerDomiciliario)
          AppLoadingButton(
            variante: AppButtonVariante.secondary,
            label: 'Solicitar ser Domiciliario',
            cargando: _procesando,
            onPressed: () => _solicitar(
              'DOMICILIARIO',
              () => ref.read(solicitarRolDomiciliarioUseCaseProvider).execute(),
            ),
          ),
      ],
    );
  }
}

/// G05 — desactivar cuenta, con confirmación explícita.
class _SeccionDesactivarCuenta extends ConsumerStatefulWidget {
  const _SeccionDesactivarCuenta();

  @override
  ConsumerState<_SeccionDesactivarCuenta> createState() =>
      _SeccionDesactivarCuentaState();
}

class _SeccionDesactivarCuentaState extends ConsumerState<_SeccionDesactivarCuenta> {
  bool _procesando = false;
  String? _error;

  Future<void> _confirmarYDesactivar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar cuenta'),
        content: const Text(
          'Tu cuenta pasará a estado inactivo y se cerrará tu sesión. '
          '¿Querés continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    setState(() {
      _procesando = true;
      _error = null;
    });
    try {
      await ref.read(desactivarCuentaUseCaseProvider).execute();
      await ref.read(authSessionProvider.notifier).cerrarSesion();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          AppErrorBanner(mensaje: _error!),
          const SizedBox(height: 12),
        ],
        AppLoadingButton(
          label: 'Desactivar cuenta',
          variante: AppButtonVariante.secondary,
          cargando: _procesando,
          onPressed: _confirmarYDesactivar,
        ),
      ],
    );
  }
}

/// Fila reutilizable para elegir (cámara/galería) y subir un documento —
/// muestra una miniatura real (o un ícono de PDF) del archivo ya subido en
/// vez de solo un check, usando la URL firmada que devuelve la API.
class _DocumentoUploadRow extends StatefulWidget {
  const _DocumentoUploadRow({
    required this.label,
    required this.url,
    required this.onArchivoElegido,
  });

  final String label;
  final String? url;
  final Future<void> Function(List<int> bytes, String nombre, String contentType)
  onArchivoElegido;

  @override
  State<_DocumentoUploadRow> createState() => _DocumentoUploadRowState();
}

enum _OrigenDocumento { camara, galeria, pdf }

/// Resultado uniforme de elegir un archivo, venga de la cámara/galería
/// (`image_picker`) o de un PDF del dispositivo (`file_picker`) — muchos
/// documentos de validación (SOAT, tecnomecánica) existen como PDF
/// original y no tiene sentido forzar a fotografiarlos.
class _ArchivoElegido {
  const _ArchivoElegido({
    required this.bytes,
    required this.nombre,
    required this.contentType,
  });

  final List<int> bytes;
  final String nombre;
  final String contentType;
}

class _DocumentoUploadRowState extends State<_DocumentoUploadRow> {
  bool _subiendo = false;
  String? _error;

  Future<void> _elegirYSubir() async {
    final origen = await showModalBottomSheet<_OrigenDocumento>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(context).pop(_OrigenDocumento.camara),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.of(context).pop(_OrigenDocumento.galeria),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Elegir PDF'),
              onTap: () => Navigator.of(context).pop(_OrigenDocumento.pdf),
            ),
          ],
        ),
      ),
    );
    if (origen == null) return;

    final elegido = origen == _OrigenDocumento.pdf
        ? await _elegirPdf()
        : await _elegirImagen(origen);
    if (elegido == null || !mounted) return;

    setState(() {
      _subiendo = true;
      _error = null;
    });
    try {
      await widget.onArchivoElegido(
        elegido.bytes,
        elegido.nombre,
        elegido.contentType,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on ApiSinConexionException catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  Future<_ArchivoElegido?> _elegirImagen(_OrigenDocumento origen) async {
    final archivo = await ImagePicker().pickImage(
      source: origen == _OrigenDocumento.camara ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );
    if (archivo == null) return null;

    return _ArchivoElegido(
      bytes: await archivo.readAsBytes(),
      nombre: archivo.name,
      contentType: _contentTypeDesde(archivo.name),
    );
  }

  Future<_ArchivoElegido?> _elegirPdf() async {
    final archivo = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (archivo == null) return null;

    return _ArchivoElegido(
      bytes: await archivo.readAsBytes(),
      nombre: archivo.name,
      contentType: 'application/pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final yaSubido = widget.url != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Miniatura(url: widget.url),
            const SizedBox(width: 12),
            Expanded(
              child: Text(widget.label, style: const TextStyle(color: AppColors.navy)),
            ),
            TextButton(
              onPressed: _subiendo ? null : _elegirYSubir,
              child: Text(
                _subiendo ? 'Subiendo…' : (yaSubido ? 'Reemplazar' : 'Subir'),
              ),
            ),
          ],
        ),
        if (_error != null) AppErrorBanner(mensaje: _error!),
      ],
    );
  }

  String _contentTypeDesde(String nombreArchivo) {
    final minuscula = nombreArchivo.toLowerCase();
    if (minuscula.endsWith('.png')) return 'image/png';
    if (minuscula.endsWith('.pdf')) return 'application/pdf';
    return 'image/jpeg';
  }
}

/// Miniatura 44x44 de un documento ya subido: imagen real si es
/// jpg/png, ícono de PDF si corresponde, círculo vacío si no hay nada
/// subido todavía.
class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.url});

  final String? url;

  bool get _esPdf =>
      url != null && url!.split('?').first.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    const tamano = 44.0;

    if (url == null) {
      return Container(
        width: tamano,
        height: tamano,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.teal),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: tamano,
        height: tamano,
        color: AppColors.beige,
        child: _esPdf
            ? const Icon(
                Icons.picture_as_pdf_outlined,
                color: AppColors.navy,
                size: 22,
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.navy,
                  size: 20,
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
      borderRadius: BorderRadius.circular(28),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.cake_outlined, color: AppColors.teal),
          filled: true,
          fillColor: AppColors.beige,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
        child: Text(fecha != null ? _isoFecha(fecha!) : 'Selecciona una fecha'),
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
