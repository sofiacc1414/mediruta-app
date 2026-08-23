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
import 'cambiar_contrasena_screen.dart';

/// HU-02 — pantalla "Mi perfil". Secciones condicionales según los roles
/// de la cuenta (context.md, Parte B, sección 4.1: un usuario puede
/// tener PACIENTE y DOMICILIARIO a la vez).
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

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _cargandoPerfil = true;
      _errorCarga = null;
    });
    try {
      final perfil = await ref.read(obtenerPerfilUseCaseProvider).execute();
      if (!mounted) return;
      setState(() => _perfil = perfil);
    } on ApiException catch (error) {
      setState(() => _errorCarga = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _errorCarga = error.toString());
    } finally {
      if (mounted) setState(() => _cargandoPerfil = false);
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
                            onCambio: _cargarPerfil,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_errorCarga != null) ...[
                          AppErrorBanner(mensaje: _errorCarga!),
                          const SizedBox(height: 16),
                        ],
                        _SeccionDatosComunes(perfil: _perfil, correo: usuario?.correo),
                        if (esPaciente) ...[
                          const SizedBox(height: 24),
                          _SeccionPaciente(
                            perfil: _perfil?.paciente,
                            onCambio: _cargarPerfil,
                          ),
                        ],
                        if (esDomiciliario) ...[
                          const SizedBox(height: 24),
                          _SeccionDomiciliario(
                            perfil: _perfil?.domiciliario,
                            onCambio: _cargarPerfil,
                          ),
                        ],
                        const SizedBox(height: 32),
                        const _SeccionDesactivarCuenta(),
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

/// G02/G03/G04 — nombre y teléfono, comunes a cualquier rol.
class _SeccionDatosComunes extends ConsumerStatefulWidget {
  const _SeccionDatosComunes({required this.perfil, required this.correo});

  final Perfil? perfil;

  /// No viene de `Perfil` (`GET /perfil` no lo trae) — es de solo lectura
  /// acá, así que se toma directo de la sesión autenticada
  /// (`authSessionProvider`), que ya lo tiene desde el login.
  final String? correo;

  @override
  ConsumerState<_SeccionDatosComunes> createState() => _SeccionDatosComunesState();
}

class _SeccionDatosComunesState extends ConsumerState<_SeccionDatosComunes> {
  late final _correoController = TextEditingController(text: widget.correo ?? '');
  late final _nombreController = TextEditingController(
    text: widget.perfil?.nombreCompleto ?? '',
  );
  late final _telefonoController = TextEditingController(
    text: widget.perfil?.telefono ?? '',
  );
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _correoController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nombreController.text.trim().isEmpty ||
        _telefonoController.text.trim().isEmpty) {
      setState(() => _error = 'Completa nombre y teléfono.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ref
          .read(actualizarDatosComunesUseCaseProvider)
          .execute(
            nombreCompleto: _nombreController.text.trim(),
            telefono: _telefonoController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Datos actualizados.')));
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      children: [
        const _TituloSeccion('Datos básicos'),
        const SizedBox(height: 12),
        if (_error != null) ...[
          AppErrorBanner(mensaje: _error!),
          const SizedBox(height: 12),
        ],
        AppTextField(
          label: 'Correo',
          icono: Icons.email_outlined,
          controller: _correoController,
          enabled: false,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Nombre completo',
          icono: Icons.person_outline,
          controller: _nombreController,
          enabled: !_guardando,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Teléfono',
          icono: Icons.phone_outlined,
          controller: _telefonoController,
          keyboardType: TextInputType.phone,
          enabled: !_guardando,
        ),
        const SizedBox(height: 12),
        AppLoadingButton(
          label: 'Guardar',
          cargando: _guardando,
          onPressed: _guardar,
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

/// G01/G03/G04 — dirección, fecha de nacimiento y foto de cédula.
class _SeccionPaciente extends ConsumerStatefulWidget {
  const _SeccionPaciente({required this.perfil, required this.onCambio});

  final dynamic perfil;
  final Future<void> Function() onCambio;

  @override
  ConsumerState<_SeccionPaciente> createState() => _SeccionPacienteState();
}

class _SeccionPacienteState extends ConsumerState<_SeccionPaciente> {
  late final _direccionController = TextEditingController(
    text: widget.perfil?.direccion as String? ?? '',
  );
  DateTime? _fechaNacimiento;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final fecha = widget.perfil?.fechaNacimiento as String?;
    if (fecha != null) {
      _fechaNacimiento = DateTime.tryParse(fecha);
    }
  }

  @override
  void dispose() {
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final ahora = DateTime.now();
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(ahora.year - 25),
      firstDate: DateTime(1900),
      lastDate: ahora.subtract(const Duration(days: 1)),
    );
    if (seleccionada != null) {
      setState(() => _fechaNacimiento = seleccionada);
    }
  }

  Future<void> _guardar() async {
    if (_direccionController.text.trim().isEmpty || _fechaNacimiento == null) {
      setState(() => _error = 'Completa la dirección y la fecha de nacimiento.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ref
          .read(actualizarPerfilPacienteUseCaseProvider)
          .execute(
            direccion: _direccionController.text.trim(),
            fechaNacimiento: _isoFecha(_fechaNacimiento!),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil de Paciente actualizado.')),
      );
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      children: [
        const _TituloSeccion('Perfil de Paciente'),
        const SizedBox(height: 12),
        if (_error != null) ...[
          AppErrorBanner(mensaje: _error!),
          const SizedBox(height: 12),
        ],
        AppTextField(
          label: 'Dirección de entrega',
          icono: Icons.home_outlined,
          controller: _direccionController,
          enabled: !_guardando,
        ),
        const SizedBox(height: 12),
        _CampoFecha(
          label: 'Fecha de nacimiento',
          fecha: _fechaNacimiento,
          onTap: _guardando ? null : _elegirFecha,
        ),
        const SizedBox(height: 12),
        AppLoadingButton(
          label: 'Guardar',
          cargando: _guardando,
          onPressed: _guardar,
        ),
        const SizedBox(height: 16),
        _DocumentoUploadRow(
          label: 'Foto de cédula',
          url: widget.perfil?.fotoCedulaUrl,
          onArchivoElegido: (bytes, nombre, contentType) async {
            await ref
                .read(subirFotoCedulaPacienteUseCaseProvider)
                .execute(
                  bytes: bytes,
                  nombreArchivo: nombre,
                  contentType: contentType,
                );
            await widget.onCambio();
          },
        ),
      ],
    );
  }
}

/// G01/G03/G04 — dirección, vehículo y documentos de validación.
class _SeccionDomiciliario extends ConsumerStatefulWidget {
  const _SeccionDomiciliario({required this.perfil, required this.onCambio});

  final dynamic perfil;
  final Future<void> Function() onCambio;

  @override
  ConsumerState<_SeccionDomiciliario> createState() => _SeccionDomiciliarioState();
}

class _SeccionDomiciliarioState extends ConsumerState<_SeccionDomiciliario> {
  late final _direccionController = TextEditingController(
    text: widget.perfil?.direccion as String? ?? '',
  );
  late final _vehiculoTipoController = TextEditingController(
    text: widget.perfil?.vehiculoTipo as String? ?? '',
  );
  late final _vehiculoPlacaController = TextEditingController(
    text: widget.perfil?.vehiculoPlaca as String? ?? '',
  );
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _direccionController.dispose();
    _vehiculoTipoController.dispose();
    _vehiculoPlacaController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_direccionController.text.trim().isEmpty ||
        _vehiculoTipoController.text.trim().isEmpty ||
        _vehiculoPlacaController.text.trim().isEmpty) {
      setState(() => _error = 'Completa dirección, tipo de vehículo y placa.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ref
          .read(actualizarPerfilDomiciliarioUseCaseProvider)
          .execute(
            direccion: _direccionController.text.trim(),
            vehiculoTipo: _vehiculoTipoController.text.trim(),
            vehiculoPlaca: _vehiculoPlacaController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil de Domiciliario actualizado.')),
      );
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      children: [
        const _TituloSeccion('Perfil de Domiciliario'),
        const SizedBox(height: 12),
        if (_error != null) ...[
          AppErrorBanner(mensaje: _error!),
          const SizedBox(height: 12),
        ],
        AppTextField(
          label: 'Dirección de residencia',
          icono: Icons.home_outlined,
          controller: _direccionController,
          enabled: !_guardando,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Tipo de vehículo',
          icono: Icons.two_wheeler_outlined,
          controller: _vehiculoTipoController,
          enabled: !_guardando,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Placa',
          icono: Icons.pin_outlined,
          controller: _vehiculoPlacaController,
          enabled: !_guardando,
        ),
        const SizedBox(height: 12),
        AppLoadingButton(
          label: 'Guardar',
          cargando: _guardando,
          onPressed: _guardar,
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
