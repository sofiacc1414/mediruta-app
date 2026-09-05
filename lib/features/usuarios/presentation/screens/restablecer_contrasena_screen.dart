import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/core/utils/politica_contrasena.dart';
import '../../../../shared/widgets/app_form_notice.dart';
import '../../../../shared/widgets/app_icon_badge.dart';
import '../../../../shared/widgets/app_loading_button.dart';
import '../../../../shared/widgets/app_text_field_glass.dart';
import '../providers/usuario_providers.dart';

class RestablecerContrasenaScreen extends ConsumerStatefulWidget {
  const RestablecerContrasenaScreen({super.key, required this.correo});

  static const routeName = '/restablecer-contrasena';

  final String correo;

  @override
  ConsumerState<RestablecerContrasenaScreen> createState() =>
      _RestablecerContrasenaScreenState();
}

class _RestablecerContrasenaScreenState
    extends ConsumerState<RestablecerContrasenaScreen>
    with TickerProviderStateMixin {
  final _codigoController = TextEditingController();
  final _nuevaPasswordController = TextEditingController();
  bool _cargando = false;
  String? _error;
  String? _errorPassword;

  // --- Animaciones ---
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _burbujaController;
  late Animation<double> _burbujaAnimation;
  late AnimationController _iconController;
  late Animation<double> _iconAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    _pulseController.forward();
    _pulseController.repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutCubic,
      ),
    );
    _fadeController.forward();

    _burbujaController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    _burbujaAnimation = Tween<double>(begin: 0.0, end: 2 * 3.14159).animate(
      CurvedAnimation(
        parent: _burbujaController,
        curve: Curves.linear,
      ),
    );
    _burbujaController.forward();
    _burbujaController.repeat();

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _iconAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Curves.easeInOut,
      ),
    );
    _iconController.forward();
    _iconController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nuevaPasswordController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _burbujaController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _restablecer() async {
    final errorPassword = PoliticaContrasena.validar(
      _nuevaPasswordController.text,
    );
    setState(() {
      _errorPassword = errorPassword;
      _error = null;
    });
    if (errorPassword != null) return;

    setState(() => _cargando = true);
    try {
      await ref
          .read(restablecerContrasenaUseCaseProvider)
          .execute(
            correo: widget.correo,
            codigo: _codigoController.text,
            nuevaPassword: _nuevaPasswordController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Contraseña actualizada! Inicia sesión de nuevo.'),
          backgroundColor: AppColors.teal,
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } on ApiException catch (error) {
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
              AppColors.skyBlue.withOpacity(0.2),
            ],
            stops: const [0.0, 0.3, 0.85],
          ),
        ),
        child: Stack(
          children: [
            _buildBurbujas(),
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
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
                            // --- Logo ---
                            TweenAnimationBuilder(
                              duration: const Duration(milliseconds: 1200),
                              tween: Tween<double>(begin: 0.8, end: 1.0),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: child,
                                );
                              },
                              child: Center(
                                child: Image.asset(
                                  'assets/images/logo_mediruta.png',
                                  height: 42,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 14),
                            
                            // --- Título ---
                            Text(
                              'Restablecer contraseña',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: AppColors.navy,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // --- ICONO PREMIUM ---
                            _buildIconoPremium(),
                            
                            const SizedBox(height: 12),
                            
                            // --- Mensaje de correo ---
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.teal.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.teal.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.email_rounded,
                                    color: AppColors.teal,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Código enviado a ${widget.correo}',
                                      softWrap: true,
                                      style: GoogleFonts.poppins(
                                        color: AppColors.teal,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // --- Error Banner ---
                            if (_error != null) ...[
                              AppFormNotice(mensaje: _error!),
                              const SizedBox(height: 12),
                            ],
                            
                            // --- Campo Código ---
                            AppTextFieldGlass(
                              label: 'Código de 6 dígitos',
                              icono: Icons.pin_outlined,
                              controller: _codigoController,
                              keyboardType: TextInputType.number,
                              enabled: !_cargando,
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // --- Campo Nueva Contraseña ---
                            AppTextFieldGlass(
                              label: 'Nueva contraseña',
                              icono: Icons.lock_outline,
                              esPassword: true,
                              controller: _nuevaPasswordController,
                              autofillHints: const [AutofillHints.newPassword],
                              enabled: !_cargando,
                              errorText: _errorPassword,
                            ),
                            
                            const SizedBox(height: 4),
                            
                            Padding(
                              padding: const EdgeInsets.only(left: 14),
                              child: Text(
                                'Mínimo 8 caracteres, mayúscula, minúscula, número y símbolo.',
                                style: GoogleFonts.poppins(
                                  fontSize: 9.5,
                                  color: AppColors.navy.withOpacity(0.3),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 18),
                            
                            // --- Botón Restablecer ---
                            _buildBotonRestablecer(),
                            
                            const SizedBox(height: 14),
                            
                            // --- Link Volver ---
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
                                child: RichText(
                                  text: TextSpan(
                                    text: '← ',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.navy.withOpacity(0.4),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Volver a recuperar contraseña',
                                        style: GoogleFonts.poppins(
                                          color: AppColors.navy,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
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
            ),
          ],
        ),
      ),
    );
  }

  // --- ICONO PREMIUM ---
  Widget _buildIconoPremium() {
    return Center(
      child: AnimatedBuilder(
        animation: _iconAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _iconAnimation.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.navy.withOpacity(0.08),
                    AppColors.teal.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withOpacity(0.06),
                    blurRadius: 20,
                    spreadRadius: 4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.password_rounded,
                color: AppColors.navy,
                size: 40,
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Botón Restablecer ---
  Widget _buildBotonRestablecer() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            height: 48,
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
              onPressed: !_cargando ? _restablecer : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
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
                          'Restablecer contraseña',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
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

  // --- Burbujas Animadas ---
  Widget _buildBurbujas() {
    return AnimatedBuilder(
      animation: _burbujaController,
      builder: (context, child) {
        final double value = _burbujaAnimation.value;
        final sinVal = math.sin(value);
        final cosVal = math.cos(value);
        
        return Stack(
          children: [
            Positioned(
              top: 40 + 25 * sinVal,
              right: 10 + 15 * cosVal,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.3, 0.3),
                    radius: 0.7,
                    colors: [
                      AppColors.skyBlue.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 80 + 20 * cosVal,
              left: -15 + 15 * sinVal,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.7, 0.5),
                    radius: 0.6,
                    colors: [
                      AppColors.teal.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 200 + 15 * sinVal,
              right: -5 + 10 * cosVal,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.5, 0.5),
                    radius: 0.5,
                    colors: [
                      AppColors.beige.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}