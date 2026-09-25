import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/core/utils/politica_contrasena.dart';
import '../../../../shared/widgets/app_checkbox_row.dart';
import '../../../../shared/widgets/app_form_notice.dart';
import '../../../../shared/widgets/app_loading_button.dart';
import '../../../../shared/widgets/app_text_field_glass.dart';
import '../../../../shared/widgets/snackbar_exito.dart';
import '../providers/auth_session_provider.dart';
import '../providers/usuario_providers.dart';
import '../widgets/selector_rol.dart';

class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  static const routeName = '/registro';

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen>
    with TickerProviderStateMixin {
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarController = TextEditingController();
  String _tipoRegistro = 'PACIENTE';
  bool _altaPaciente = false;
  bool _aceptaTerminos = false;
  bool _cargando = false;
  String? _error;
  String? _errorPassword;
  String? _errorConfirmacion;
  String? _errorCorreo;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.forward();
    _pulseController.repeat(reverse: true);
    _correoController.addListener(_refrescarValidacionVisual);
    _passwordController.addListener(_refrescarValidacionVisual);
  }

  void _refrescarValidacionVisual() {
    if (mounted) setState(() {});
  }

  bool _correoConFormato(String valor) {
    final texto = valor.trim().toLowerCase();
    return texto.contains('@') &&
        texto.contains('.com') &&
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto);
  }

  @override
  void dispose() {
    _correoController.removeListener(_refrescarValidacionVisual);
    _passwordController.removeListener(_refrescarValidacionVisual);
    _correoController.dispose();
    _passwordController.dispose();
    _confirmarController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    final errorPassword = PoliticaContrasena.validar(_passwordController.text);
    final coinciden = _confirmarController.text == _passwordController.text;
    final errorConfirmacion = coinciden
        ? null
        : 'Las contraseñas no coinciden.';
    final errorCorreo = _correoConFormato(_correoController.text)
        ? null
        : 'El correo electrónico debe contener @ y .com';
    setState(() {
      _errorPassword = errorPassword;
      _errorConfirmacion = errorConfirmacion;
      _errorCorreo = errorCorreo;
      _error = null;
    });
    if (errorPassword != null || errorConfirmacion != null || errorCorreo != null) {
      return;
    }

    setState(() => _cargando = true);
    final correo = _correoController.text;
    final password = _passwordController.text;
    try {
      await ref
          .read(registrarUsuarioUseCaseProvider)
          .execute(
            correo: correo,
            password: password,
            tipoRegistro: _tipoRegistro,
            altaPaciente: _tipoRegistro == 'DOMICILIARIO'
                ? _altaPaciente
                : null,
          );

      final usuario = await ref
          .read(iniciarSesionUseCaseProvider)
          .execute(correo: correo, password: password);
      if (!mounted) return;
      ref.read(authSessionProvider.notifier).sesionIniciada(usuario);
      ScaffoldMessenger.of(context).showSnackBar(
        snackBarExito('¡Registro exitoso! Completá tu perfil para empezar.'),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/perfil', (_) => false);
    } on ApiException catch (error) {
      // Se limpian las contraseñas (no el correo) — típicamente el error
      // acá es "correo ya registrado", no que la contraseña esté mal, así
      // que no hace falta reescribirla, pero mejor no dejarla visible.
      _passwordController.clear();
      _confirmarController.clear();
      setState(() => _error = error.message);
    } on ApiSinConexionException catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.white,
              AppColors.beige,
              AppColors.skyBlue.withOpacity(0.15),
            ],
            stops: const [0.0, 0.3, 0.85],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Logo COMPACTO ---
                    Center(
                      child: Image.asset(
                        'assets/images/logo_mediruta.png',
                        height: 40,
                        filterQuality: FilterQuality.high,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // --- Título COMPACTO ---
                    Text(
                      'Crear cuenta',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppColors.navy,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'Únete a MediRuta',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppColors.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // --- Error ---
                    if (_error != null) ...[
                      AppFormNotice(mensaje: _error!),
                      const SizedBox(height: 10),
                    ],

                    // --- Campos BEIGE FORTALECIDOS ---
                    AppTextFieldGlass(
                      label: 'Correo electrónico',
                      icono: Icons.email_outlined,
                      controller: _correoController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      enabled: !_cargando,
                      errorText: _errorCorreo,
                    ),
                    const SizedBox(height: 4),
                    _AyudaCorreo(
                      texto: _correoController.text,
                      valido: _correoConFormato(_correoController.text),
                    ),

                    const SizedBox(height: 10),

                    AppTextFieldGlass(
                      label: 'Contraseña',
                      icono: Icons.lock_outline,
                      esPassword: true,
                      controller: _passwordController,
                      autofillHints: const [AutofillHints.newPassword],
                      enabled: !_cargando,
                      errorText: _errorPassword,
                    ),

                    const SizedBox(height: 6),

                    _RequisitosContrasena(password: _passwordController.text),

                    const SizedBox(height: 10),

                    AppTextFieldGlass(
                      label: 'Confirmar contraseña',
                      icono: Icons.lock_outline,
                      esPassword: true,
                      controller: _confirmarController,
                      autofillHints: const [AutofillHints.newPassword],
                      enabled: !_cargando,
                      errorText: _errorConfirmacion,
                    ),

                    const SizedBox(height: 14),

                    // --- Selector de Rol ---
                    _buildRolSelector(),

                    // --- Checkboxes ---
                    if (_tipoRegistro == 'DOMICILIARIO') ...[
                      const SizedBox(height: 4),
                      AppCheckboxRow(
                        valor: _altaPaciente,
                        onChanged: (v) => setState(() => _altaPaciente = v),
                        label: Text(
                          'También como Paciente',
                          style: GoogleFonts.poppins(
                            color: AppColors.navy,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 4),

                    AppCheckboxRow(
                      valor: _aceptaTerminos,
                      onChanged: (v) => setState(() => _aceptaTerminos = v),
                      label: Text(
                        'Acepto Términos y Política de Privacidad',
                        style: GoogleFonts.poppins(
                          color: AppColors.navy,
                          fontSize: 11.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // --- Botón ---
                    _buildBotonPremium(),

                    const SizedBox(height: 8),

                    // --- Link ---
                    Center(
                      child: TextButton(
                        onPressed: _cargando
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '¿Ya tienes cuenta? Inicia sesión',
                          style: GoogleFonts.poppins(
                            color: AppColors.navy,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 2),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRolSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona tu rol',
          style: GoogleFonts.poppins(
            color: AppColors.navy,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _RolCardPremium(
              icon: Icons.person_outline_rounded,
              title: 'Paciente',
              subtitle: 'Solicita medicamentos',
              isSelected: _tipoRegistro == 'PACIENTE',
              onTap: () => setState(() => _tipoRegistro = 'PACIENTE'),
              color: AppColors.navy,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.navy, AppColors.navy.withOpacity(0.7)],
              ),
            ),
            const SizedBox(width: 8),
            _RolCardPremium(
              icon: Icons.delivery_dining_rounded,
              title: 'Domiciliario',
              subtitle: 'Entrega con confianza',
              isSelected: _tipoRegistro == 'DOMICILIARIO',
              onTap: () => setState(() => _tipoRegistro = 'DOMICILIARIO'),
              color: AppColors.teal,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.teal, AppColors.teal.withOpacity(0.7)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBotonPremium() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.navy,
                  const Color(0xFF3D5A73),
                  AppColors.navy.withOpacity(0.9),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _aceptaTerminos && !_cargando ? _registrar : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: _cargando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Crear cuenta',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

// --- Tarjeta de Rol Premium ---
class _RolCardPremium extends StatefulWidget {
  const _RolCardPremium({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.color,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;
  final Gradient gradient;

  @override
  State<_RolCardPremium> createState() => _RolCardPremiumState();
}

class _RolCardPremiumState extends State<_RolCardPremium>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _scaleController.forward().then((_) => _scaleController.reverse());
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  gradient: widget.isSelected
                      ? widget.gradient
                      : LinearGradient(
                          colors: [
                            AppColors.white.withOpacity(0.5),
                            AppColors.white.withOpacity(0.2),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.isSelected
                        ? widget.color
                        : AppColors.navy.withOpacity(0.06),
                    width: widget.isSelected ? 2 : 1,
                  ),
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: widget.color.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: AppColors.navy.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? AppColors.white.withOpacity(0.2)
                            : widget.color.withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.isSelected
                            ? AppColors.white
                            : widget.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: widget.isSelected
                            ? AppColors.white
                            : AppColors.navy,
                        fontSize: 12,
                        fontWeight: widget.isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: widget.isSelected
                            ? AppColors.white.withOpacity(0.85)
                            : AppColors.navy.withOpacity(0.4),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (widget.isSelected) ...[
                      const SizedBox(height: 3),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: widget.color,
                          size: 9,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AyudaCorreo extends StatelessWidget {
  const _AyudaCorreo({required this.texto, required this.valido});

  final String texto;
  final bool valido;

  @override
  Widget build(BuildContext context) {
    final cumplido = texto.trim().isNotEmpty && valido;
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Row(
        children: [
          Icon(
            cumplido ? Icons.check_box : Icons.check_box_outline_blank,
            size: 14,
            color: cumplido ? AppColors.teal : AppColors.navy.withOpacity(0.45),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'El correo electrónico debe contener @ y .com',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: cumplido ? AppColors.teal : AppColors.navy.withOpacity(0.55),
                decoration: cumplido ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequisitosContrasena extends StatelessWidget {
  const _RequisitosContrasena({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final requisitos = <(String, bool)>[
      ('Tener mínimo 8 caracteres', password.length >= PoliticaContrasena.minLength),
      ('Tener al menos 1 letra mayúscula', RegExp(r'[A-Z]').hasMatch(password)),
      ('Tener al menos 1 letra minúscula', RegExp(r'[a-z]').hasMatch(password)),
      ('Tener al menos 1 número', RegExp(r'\d').hasMatch(password)),
      ('Tener al menos 1 carácter especial', RegExp(r'[^A-Za-z0-9]').hasMatch(password)),
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final requisito in requisitos)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Icon(
                    requisito.$2 ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 14,
                    color: requisito.$2
                        ? AppColors.teal
                        : AppColors.navy.withOpacity(0.45),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      requisito.$1,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: requisito.$2
                            ? AppColors.teal
                            : AppColors.navy.withOpacity(0.55),
                        decoration: requisito.$2 ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.teal,
                      ),
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
