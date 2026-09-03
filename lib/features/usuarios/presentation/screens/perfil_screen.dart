import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_banner.dart';
import '../../../../shared/widgets/app_loading_button.dart';
import '../../domain/entities/perfil.dart';
import '../../domain/value-objects/lado_documento.dart';
import '../../domain/value-objects/tipo_documento_domiciliario.dart';
import '../providers/auth_session_provider.dart';
import '../providers/perfil_providers.dart';
import '../providers/usuario_providers.dart';
import '../widgets/main_bottom_bar.dart';
import 'cambiar_contrasena_screen.dart';

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
  bool _notificacionesActivas = true;
  bool _modoAdultoMayor = false;

  @override
  void initState() {
    super.initState();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Completa: ${faltantes.join('; ')}.')),
      );
      return;
    }

    setState(() {
      _guardandoCambios = true;
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
      
      Navigator.of(context).pop(); 
      await _recargarSoloPerfil();
      
      // SNACKBAR PERSONALIZADO: Fondo blanco, letra azul
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Guardado exitosamente',
            style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 4,
        ),
      );
      
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } on ApiSinConexionException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _guardandoCambios = false);
    }
  }

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
    final modo = ref.watch(modoActivoProvider) ?? (roles.isNotEmpty ? roles.first.codigo : null);
    final esPaciente = modo == 'PACIENTE';
    final esDomiciliario = modo == 'DOMICILIARIO';
    final tienePaciente = roles.any((r) => r.codigo == 'PACIENTE');
    final tieneDomiciliario = roles.any((r) => r.codigo == 'DOMICILIARIO');
    final rolesDomiciliario = roles.where((r) => r.codigo == 'DOMICILIARIO');
    final estadoRolDomiciliario = rolesDomiciliario.isEmpty ? null : rolesDomiciliario.first.estado;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tu perfil',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.navy,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      bottomNavigationBar: const MainBottomBar(),
      body: _cargandoPerfil
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado con fondo BLANCO (sin degradado azul)
                      _ProfileHeaderMinimalista(
                        fotoPerfilUrl: _perfil?.fotoPerfilUrl,
                        nombre: _perfil?.nombreCompleto ?? '',
                        correo: _correoController.text,
                        onCambio: _recargarSoloPerfil,
                      ),
                      const SizedBox(height: 32),

                      // SECCIÓN: CUENTA
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Cuenta',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      
                      // LISTA DE ROLES (SIN CAJÓN GRIS)
                      if (roles.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Mis roles',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: roles.map((rol) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.skyBlue.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                rol.codigo,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navy,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                      ],

                      _CardAccion(
                        icon: Icons.person_outline,
                        iconColor: AppColors.navy,
                        titulo: 'Información personal',
                        subtitulo: 'Nombre, teléfono, correo',
                        onTap: () => _showPersonalInfoDialog(),
                      ),
                      const SizedBox(height: 12),
                      if (esPaciente)
                        _CardAccion(
                          icon: Icons.health_and_safety_outlined,
                          iconColor: AppColors.navy,
                          titulo: 'Datos de Paciente',
                          subtitulo: 'Dirección, documentos',
                          onTap: () => _showPacienteDialog(),
                        ),
                      if (esPaciente) const SizedBox(height: 12),
                      if (esDomiciliario)
                        _CardAccion(
                          icon: Icons.delivery_dining_outlined,
                          iconColor: AppColors.navy,
                          titulo: 'Datos de Domiciliario',
                          subtitulo: _getDomiciliarioStatus(estadoRolDomiciliario),
                          onTap: () => _showDomiciliarioDialog(),
                        ),
                      if (esDomiciliario) const SizedBox(height: 12),
                      // Botón para agregar otro rol solo si falta alguno
                      if (!tienePaciente || !tieneDomiciliario) ...[
                        _CardAccion(
                          icon: Icons.add_circle_outline,
                          iconColor: AppColors.navy,
                          titulo: 'Agregar otro rol',
                          subtitulo: 'Usá la misma cuenta para ambos roles',
                          onTap: () => _showAgregarRolDialog(),
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      const SizedBox(height: 40),

                      // SECCIÓN: NOTIFICACIONES
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Notificaciones',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      _CardSwitch(
                        icon: Icons.notifications_none_rounded,
                        iconColor: AppColors.navy,
                        titulo: 'Notificaciones',
                        subtitulo: 'Avisos de entregas',
                        valor: _notificacionesActivas,
                        onChanged: (val) => setState(() => _notificacionesActivas = val),
                      ),
                      
                      const SizedBox(height: 40),

                      // SECCIÓN: ACCESIBILIDAD
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Accesibilidad',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      _CardSwitch(
                        icon: Icons.accessibility_new_rounded,
                        iconColor: AppColors.navy,
                        titulo: 'Modo adulto mayor',
                        subtitulo: 'Texto y botones más grandes',
                        valor: _modoAdultoMayor,
                        onChanged: (val) => setState(() => _modoAdultoMayor = val),
                      ),
                      
                      const SizedBox(height: 40),

                      // SECCIÓN: SEGURIDAD
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Seguridad',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      _CardAccion(
                        icon: Icons.lock_outline,
                        iconColor: AppColors.navy,
                        titulo: 'Seguridad',
                        subtitulo: 'Cambiar contraseña',
                        onTap: () => Navigator.of(context).pushNamed(CambiarContrasenaScreen.routeName),
                      ),
                      const SizedBox(height: 12),
                      _CardAccion(
                        icon: Icons.help_outline,
                        iconColor: AppColors.navy,
                        titulo: 'Ayuda',
                        subtitulo: 'Soporte y preguntas frecuentes',
                        onTap: () => _showHelpDialog(),
                      ),
                      const SizedBox(height: 12),
                      _CardAccion(
                        icon: Icons.logout,
                        iconColor: AppColors.navy,
                        titulo: 'Cerrar sesión',
                        subtitulo: 'Salir de tu cuenta',
                        onTap: () => _cerrarSesion(context),
                      ),
                      const SizedBox(height: 12),
                      _CardAccion(
                        icon: Icons.warning_amber_rounded,
                        iconColor: AppColors.navy,
                        titulo: 'Desactivar cuenta',
                        subtitulo: 'Esta acción es permanente',
                        onTap: () => _showDesactivarCuentaDialog(),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _showPersonalInfoDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditarPerfilBottomSheet(
        title: 'Información personal',
        children: [
          _CampoPerfil(
            label: 'Correo electrónico',
            icono: Icons.email_outlined,
            controller: _correoController,
            enabled: false,
          ),
          const SizedBox(height: 12),
          _CampoPerfil(
            label: 'Nombre completo',
            icono: Icons.person_outline,
            controller: _nombreController,
            enabled: !_guardandoCambios,
          ),
          const SizedBox(height: 12),
          _CampoPerfil(
            label: 'Teléfono',
            icono: Icons.phone_outlined,
            controller: _telefonoController,
            keyboardType: TextInputType.phone,
            enabled: !_guardandoCambios,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: AppLoadingButton(
              label: 'Guardar cambios',
              cargando: _guardandoCambios,
              onPressed: () => _guardarCambios(
                esPaciente: false,
                esDomiciliario: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPacienteDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditarPerfilBottomSheet(
        title: 'Datos de Paciente',
        children: [
          _CampoPerfil(
            label: 'Dirección de entrega',
            icono: Icons.home_outlined,
            controller: _pacienteDireccionController,
            enabled: !_guardandoCambios,
          ),
          const SizedBox(height: 12),
          _CampoPerfil(
            label: 'Departamento',
            icono: Icons.map_outlined,
            controller: _pacienteDepartamentoController,
            enabled: !_guardandoCambios,
          ),
          const SizedBox(height: 12),
          _CampoPerfil(
            label: 'Ciudad',
            icono: Icons.location_city_outlined,
            controller: _pacienteCiudadController,
            enabled: !_guardandoCambios,
          ),
          const SizedBox(height: 12),
          _CampoFechaPerfil(
            label: 'Fecha de nacimiento',
            fecha: _pacienteFechaNacimiento,
            onTap: !_guardandoCambios ? _elegirFechaNacimiento : null,
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.skyBlue, height: 1),
          const SizedBox(height: 12),
          const Text(
            'Documentos',
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _DocumentoUploadRow(
            label: 'Cédula (frente)',
            url: _perfil?.paciente?.fotoCedulaFrenteUrl,
            onArchivoElegido: (bytes, nombre, contentType) async {
              await ref
                  .read(subirFotoCedulaPacienteUseCaseProvider)
                  .execute(
                    lado: LadoDocumento.frente,
                    bytes: bytes,
                    nombreArchivo: nombre,
                    contentType: contentType,
                  );
              await _recargarSoloPerfil();
            },
          ),
          const SizedBox(height: 8),
          _DocumentoUploadRow(
            label: 'Cédula (reverso)',
            url: _perfil?.paciente?.fotoCedulaReversoUrl,
            onArchivoElegido: (bytes, nombre, contentType) async {
              await ref
                  .read(subirFotoCedulaPacienteUseCaseProvider)
                  .execute(
                    lado: LadoDocumento.reverso,
                    bytes: bytes,
                    nombreArchivo: nombre,
                    contentType: contentType,
                  );
              await _recargarSoloPerfil();
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: AppLoadingButton(
              label: 'Guardar cambios',
              cargando: _guardandoCambios,
              onPressed: () => _guardarCambios(
                esPaciente: true,
                esDomiciliario: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDomiciliarioDialog() {
    final estado = _getDomiciliarioStatusRaw();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditarPerfilBottomSheet(
        title: 'Datos de Domiciliario',
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: estado == 'habilitado'
                  ? AppColors.teal.withValues(alpha: 0.1)
                  : estado == 'pendiente_validacion'
                      ? Colors.orange.withValues(alpha: 0.1)
                      : estado == 'rechazado'
                          ? Colors.red.withValues(alpha: 0.1)
                          : AppColors.skyBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  estado == 'habilitado'
                      ? Icons.check_circle
                      : estado == 'pendiente_validacion'
                          ? Icons.hourglass_empty
                          : estado == 'rechazado'
                              ? Icons.cancel
                              : Icons.info_outline,
                  color: estado == 'habilitado'
                      ? AppColors.teal
                      : estado == 'pendiente_validacion'
                          ? Colors.orange
                          : estado == 'rechazado'
                              ? Colors.red
                              : AppColors.teal,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getDomiciliarioStatus(estado),
                    style: TextStyle(
                      color: estado == 'habilitado'
                          ? AppColors.teal
                          : estado == 'pendiente_validacion'
                              ? Colors.orange
                              : estado == 'rechazado'
                                  ? Colors.red
                                  : AppColors.teal,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CampoPerfil(
            label: 'Dirección de residencia',
            icono: Icons.home_outlined,
            controller: _domiciliarioDireccionController,
            enabled: !_guardandoCambios,
          ),
          const SizedBox(height: 12),
          _CampoPerfil(
            label: 'Tipo de vehículo',
            icono: Icons.two_wheeler_outlined,
            controller: _vehiculoTipoController,
            enabled: !_guardandoCambios,
          ),
          const SizedBox(height: 12),
          _CampoPerfil(
            label: 'Placa',
            icono: Icons.pin_outlined,
            controller: _vehiculoPlacaController,
            enabled: !_guardandoCambios,
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.skyBlue, height: 1),
          const SizedBox(height: 12),
          const Text(
            'Documentos de validación',
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _DocumentoUploadRow(
            label: 'Cédula (frente)',
            url: _perfil?.domiciliario?.cedulaFrenteUrl,
            onArchivoElegido: (b, n, c) =>
                _subirDocumentoDomiciliario(TipoDocumentoDomiciliario.cedulaFrente, b, n, c),
          ),
          const SizedBox(height: 8),
          _DocumentoUploadRow(
            label: 'Cédula (reverso)',
            url: _perfil?.domiciliario?.cedulaReversoUrl,
            onArchivoElegido: (b, n, c) =>
                _subirDocumentoDomiciliario(TipoDocumentoDomiciliario.cedulaReverso, b, n, c),
          ),
          const SizedBox(height: 8),
          _DocumentoUploadRow(
            label: 'Licencia de conducción',
            url: _perfil?.domiciliario?.licenciaUrl,
            onArchivoElegido: (b, n, c) =>
                _subirDocumentoDomiciliario(TipoDocumentoDomiciliario.licencia, b, n, c),
          ),
          const SizedBox(height: 8),
          _DocumentoUploadRow(
            label: 'SOAT',
            url: _perfil?.domiciliario?.soatUrl,
            onArchivoElegido: (b, n, c) =>
                _subirDocumentoDomiciliario(TipoDocumentoDomiciliario.soat, b, n, c),
          ),
          const SizedBox(height: 8),
          _DocumentoUploadRow(
            label: 'Tecnomecánica',
            url: _perfil?.domiciliario?.tecnicomecanicaUrl,
            onArchivoElegido: (b, n, c) =>
                _subirDocumentoDomiciliario(TipoDocumentoDomiciliario.tecnicomecanica, b, n, c),
          ),
          if (estado == 'borrador') ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: AppLoadingButton(
                label: 'Enviar solicitud de validación',
                cargando: _guardandoCambios,
                onPressed: () => _enviarSolicitudDomiciliario(),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: AppLoadingButton(
              label: 'Guardar cambios',
              cargando: _guardandoCambios,
              onPressed: () => _guardarCambios(
                esPaciente: false,
                esDomiciliario: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDomiciliarioStatus(String? estado) {
    switch (estado) {
      case 'pendiente_validacion':
        return 'Tu solicitud está en revisión';
      case 'habilitado':
        return 'Ya estás validado como Domiciliario';
      case 'rechazado':
        return 'Solicitud rechazada';
      default:
        return 'Completa tus datos y envía la solicitud';
    }
  }

  String? _getDomiciliarioStatusRaw() {
    final roles = ref.read(authSessionProvider);
    final usuario = roles is AuthAutenticado ? roles.usuario : null;
    final rolesDomiciliario = usuario?.roles.where((r) => r.codigo == 'DOMICILIARIO') ?? [];
    return rolesDomiciliario.isEmpty ? null : rolesDomiciliario.first.estado;
  }

  Future<void> _subirDocumentoDomiciliario(
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
    await _recargarSoloPerfil();
  }

  Future<void> _enviarSolicitudDomiciliario() async {
    setState(() => _guardandoCambios = true);
    try {
      final mensaje = await ref.read(enviarSolicitudDomiciliarioUseCaseProvider).execute();
      final usuarioActualizado = await ref.read(obtenerSesionActualUseCaseProvider).execute();
      ref.read(authSessionProvider.notifier).sesionIniciada(usuarioActualizado);
      await _recargarSoloPerfil();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
    } on ApiException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _guardandoCambios = false);
    }
  }

  void _showAgregarRolDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditarPerfilBottomSheet(
        title: 'Agregar otro rol',
        children: [
          const Text(
            'Usá la misma cuenta para ambos roles',
            style: TextStyle(color: AppColors.teal, fontSize: 14),
          ),
          const SizedBox(height: 16),
          _RolOption(
            icon: Icons.health_and_safety_outlined,
            title: 'Solicitar ser Paciente',
            subtitle: 'Accede a servicios de salud',
            onTap: () async {
              await _solicitarRol('PACIENTE');
            },
          ),
          const SizedBox(height: 12),
          _RolOption(
            icon: Icons.delivery_dining_outlined,
            title: 'Solicitar ser Domiciliario',
            subtitle: 'Realiza entregas de medicamentos',
            onTap: () async {
              await _solicitarRol('DOMICILIARIO');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _solicitarRol(String rol) async {
    try {
      final mensaje = rol == 'PACIENTE'
          ? await ref.read(solicitarRolPacienteUseCaseProvider).execute()
          : await ref.read(solicitarRolDomiciliarioUseCaseProvider).execute();
      final usuarioActualizado = await ref.read(obtenerSesionActualUseCaseProvider).execute();
      ref.read(authSessionProvider.notifier).sesionIniciada(usuarioActualizado);
      ref.read(modoActivoProvider.notifier).state = rol;
      await _onRolAgregado(rol);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
    } on ApiException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _showHelpDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditarPerfilBottomSheet(
        title: 'Ayuda y soporte',
        children: [
          _HelpOption(
            icon: Icons.question_answer_outlined,
            title: 'Preguntas frecuentes',
            subtitle: 'Respuestas a dudas comunes',
          ),
          const SizedBox(height: 12),
          _HelpOption(
            icon: Icons.chat_outlined,
            title: 'Contactar soporte',
            subtitle: 'Habla con nuestro equipo',
          ),
          const SizedBox(height: 12),
          _HelpOption(
            icon: Icons.description_outlined,
            title: 'Términos y condiciones',
            subtitle: 'Políticas de uso',
          ),
        ],
      ),
    );
  }

  void _showDesactivarCuentaDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditarPerfilBottomSheet(
        title: 'Desactivar cuenta',
        isDestructive: true,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Esta acción es permanente y no se puede deshacer. '
                    'Tu cuenta pasará a estado inactivo y se cerrará tu sesión.',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: AppLoadingButton(
              label: 'Confirmar desactivación',
              variante: AppButtonVariante.secondary,
              cargando: _guardandoCambios,
              onPressed: _desactivarCuenta,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _desactivarCuenta() async {
    setState(() => _guardandoCambios = true);
    try {
      await ref.read(desactivarCuentaUseCaseProvider).execute();
      await ref.read(authSessionProvider.notifier).cerrarSesion();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } on ApiException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _guardandoCambios = false);
    }
  }
}

// ==================== WIDGETS MINIMALISTAS ====================

class _ProfileHeaderMinimalista extends ConsumerStatefulWidget {
  const _ProfileHeaderMinimalista({
    required this.fotoPerfilUrl,
    required this.nombre,
    required this.correo,
    required this.onCambio,
  });

  final String? fotoPerfilUrl;
  final String nombre;
  final String correo;
  final Future<void> Function() onCambio;

  @override
  ConsumerState<_ProfileHeaderMinimalista> createState() => _ProfileHeaderMinimalistaState();
}

class _ProfileHeaderMinimalistaState extends ConsumerState<_ProfileHeaderMinimalista> {
  bool _subiendo = false;

  Future<void> _elegirYSubir() async {
    final origen = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.skyBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.beige,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_camera_outlined, color: AppColors.teal),
                ),
                title: const Text('Tomar foto', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.beige,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: AppColors.teal),
                ),
                title: const Text('Elegir de la galería', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (origen == null) return;

    final archivo = await ImagePicker().pickImage(source: origen, imageQuality: 85);
    if (archivo == null || !mounted) return;

    setState(() => _subiendo = true);
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
    // Fondo BLANCO PURO con borde fino para que sea casi invisible
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // Fondo blanco
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)), // Borde gris muy suave
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.2), width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.fotoPerfilUrl != null
                    ? Image.network(
                        widget.fotoPerfilUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person, size: 40, color: AppColors.teal),
                      )
                    : const Icon(Icons.person, size: 40, color: AppColors.teal),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: GestureDetector(
                  onTap: _subiendo ? null : _elegirYSubir,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.skyBlue, width: 1.5),
                    ),
                    child: _subiendo
                        ? const Padding(
                            padding: EdgeInsets.all(4),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt_outlined, size: 12, color: AppColors.navy),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nombre.isEmpty ? 'Usuario' : widget.nombre,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.correo,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardSwitch extends StatelessWidget {
  const _CardSwitch({
    required this.icon,
    required this.iconColor,
    required this.titulo,
    required this.subtitulo,
    required this.valor,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String titulo;
  final String subtitulo;
  final bool valor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: valor,
            onChanged: onChanged,
            activeColor: AppColors.teal,
            activeTrackColor: AppColors.teal.withValues(alpha: 0.5),
            inactiveTrackColor: Colors.grey.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}

class _CardAccion extends StatelessWidget {
  const _CardAccion({
    required this.icon,
    required this.iconColor,
    required this.titulo,
    required this.onTap,
    this.subtitulo,
    this.esDestructivo = false, // Parámetro conservado
  });

  final IconData icon;
  final Color iconColor;
  final String titulo;
  final String? subtitulo;
  final VoidCallback onTap;
  final bool esDestructivo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          child: Icon(
            icon, 
            color: AppColors.navy,
            size: 22,
          ),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
        subtitle: subtitulo != null
            ? Text(
                subtitulo!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              )
            : null,
        trailing: const Icon(
          Icons.chevron_right_rounded, 
          color: Colors.grey, 
          size: 24
        ),
      ),
    );
  }
}

class _EditarPerfilBottomSheet extends StatelessWidget {
  const _EditarPerfilBottomSheet({
    required this.title,
    required this.children,
    this.isDestructive = false,
  });

  final String title;
  final List<Widget> children;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.skyBlue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      color: isDestructive ? Colors.red : AppColors.teal,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDestructive ? Colors.red : AppColors.navy,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RolOption extends StatelessWidget {
  const _RolOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, color: AppColors.navy, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.teal,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Solicitar',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpOption extends StatelessWidget {
  const _HelpOption({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        onTap: () {},
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, color: AppColors.navy, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
          size: 20,
        ),
      ),
    );
  }
}

class _CampoPerfil extends StatelessWidget {
  const _CampoPerfil({
    required this.label,
    required this.icono,
    required this.controller,
    required this.enabled,
    this.keyboardType,
  });

  final String label;
  final IconData icono;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.navy,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icono, color: AppColors.teal, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.teal, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
          ),
        ),
      ),
    );
  }
}

class _CampoFechaPerfil extends StatelessWidget {
  const _CampoFechaPerfil({
    required this.label,
    required this.fecha,
    required this.onTap,
  });

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
            labelStyle: TextStyle(
              color: onTap != null ? AppColors.teal : Colors.grey.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              Icons.cake_outlined,
              color: onTap != null ? AppColors.teal : Colors.grey.withValues(alpha: 0.5),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          child: Text(
            fecha != null ? _isoFecha(fecha!) : 'Selecciona una fecha',
            style: TextStyle(
              color: fecha != null ? AppColors.navy : Colors.grey.withValues(alpha: 0.6),
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

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
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.skyBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_camera_outlined, color: AppColors.teal),
                ),
                title: const Text('Tomar foto', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () => Navigator.of(context).pop(_OrigenDocumento.camara),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: AppColors.teal),
                ),
                title: const Text('Elegir de la galería', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () => Navigator.of(context).pop(_OrigenDocumento.galeria),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.teal),
                ),
                title: const Text('Elegir PDF', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () => Navigator.of(context).pop(_OrigenDocumento.pdf),
              ),
              const SizedBox(height: 8),
            ],
          ),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              _Miniatura(url: widget.url),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: yaSubido ? FontWeight.w500 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
              TextButton(
                onPressed: _subiendo ? null : _elegirYSubir,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: _subiendo
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        yaSubido ? 'Reemplazar' : 'Subir',
                        style: TextStyle(
                          color: yaSubido ? AppColors.teal : AppColors.teal,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          AppErrorBanner(mensaje: _error!),
        ],
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

class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.url});

  final String? url;

  bool get _esPdf =>
      url != null && url!.split('?').first.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    const tamano = 40.0;

    if (url == null) {
      return Container(
        width: tamano,
        height: tamano,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 2),
        ),
        child: const Icon(Icons.add, color: AppColors.teal, size: 16),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: tamano,
        height: tamano,
        color: Colors.white,
        child: _esPdf
            ? const Icon(
                Icons.picture_as_pdf_outlined,
                color: AppColors.navy,
                size: 20,
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.navy,
                  size: 18,
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
