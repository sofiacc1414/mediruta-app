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
    final esPaciente = usuario?.tieneRol('PACIENTE') ?? false;
    final esDomiciliario = usuario?.tieneRol('DOMICILIARIO') ?? false;

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
                        const Center(
                          child: AppIconBadge(icono: Icons.badge_outlined),
                        ),
                        const SizedBox(height: 20),
                        if (_errorCarga != null) ...[
                          AppErrorBanner(mensaje: _errorCarga!),
                          const SizedBox(height: 16),
                        ],
                        _SeccionDatosComunes(perfil: _perfil),
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
  const _SeccionDatosComunes({required this.perfil});

  final Perfil? perfil;

  @override
  ConsumerState<_SeccionDatosComunes> createState() => _SeccionDatosComunesState();
}

class _SeccionDatosComunesState extends ConsumerState<_SeccionDatosComunes> {
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
          yaSubido: widget.perfil?.fotoCedulaPath != null,
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
          label: 'Dirección',
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
          yaSubido: widget.perfil?.cedulaPath != null,
          onArchivoElegido: (b, n, c) => _subirDocumento(TipoDocumentoDomiciliario.cedula, b, n, c),
        ),
        const SizedBox(height: 8),
        _DocumentoUploadRow(
          label: 'Licencia de conducción',
          yaSubido: widget.perfil?.licenciaPath != null,
          onArchivoElegido: (b, n, c) => _subirDocumento(TipoDocumentoDomiciliario.licencia, b, n, c),
        ),
        const SizedBox(height: 8),
        _DocumentoUploadRow(
          label: 'SOAT',
          yaSubido: widget.perfil?.soatPath != null,
          onArchivoElegido: (b, n, c) => _subirDocumento(TipoDocumentoDomiciliario.soat, b, n, c),
        ),
        const SizedBox(height: 8),
        _DocumentoUploadRow(
          label: 'Tecnomecánica',
          yaSubido: widget.perfil?.tecnicomecanicaPath != null,
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

/// Fila reutilizable para elegir (cámara/galería) y subir un documento.
class _DocumentoUploadRow extends StatefulWidget {
  const _DocumentoUploadRow({
    required this.label,
    required this.yaSubido,
    required this.onArchivoElegido,
  });

  final String label;
  final bool yaSubido;
  final Future<void> Function(List<int> bytes, String nombre, String contentType)
  onArchivoElegido;

  @override
  State<_DocumentoUploadRow> createState() => _DocumentoUploadRowState();
}

class _DocumentoUploadRowState extends State<_DocumentoUploadRow> {
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
    if (archivo == null) return;

    setState(() {
      _subiendo = true;
      _error = null;
    });
    try {
      final bytes = await archivo.readAsBytes();
      await widget.onArchivoElegido(bytes, archivo.name, _contentTypeDesde(archivo.name));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } on ApiSinConexionException catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              widget.yaSubido ? Icons.check_circle : Icons.radio_button_unchecked,
              color: widget.yaSubido ? AppColors.navy : AppColors.teal,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(widget.label, style: const TextStyle(color: AppColors.navy)),
            ),
            TextButton(
              onPressed: _subiendo ? null : _elegirYSubir,
              child: Text(
                _subiendo
                    ? 'Subiendo…'
                    : (widget.yaSubido ? 'Reemplazar' : 'Subir'),
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
