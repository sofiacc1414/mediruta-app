import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/core/network/api_exception.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_form_notice.dart';
import '../../../../shared/widgets/app_loading_button.dart';
import '../../../../shared/widgets/app_text_field_glass.dart';
import '../providers/auth_session_provider.dart';
import '../providers/usuario_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _cargando = false;
  String? _error;

  // --- Animaciones ---
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _burbujaController;
  late Animation<double> _burbujaAnimation;

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
  }

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _burbujaController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final usuario = await ref
          .read(iniciarSesionUseCaseProvider)
          .execute(
            correo: _correoController.text,
            password: _passwordController.text,
          );
      if (!mounted) return;
      ref.read(authSessionProvider.notifier).sesionIniciada(usuario);
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
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
            // --- Burbujas Animadas ---
            _buildBurbujas(),
            
            // --- Contenido Principal ---
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
                            // --- Logo CON ANIMACIÓN ---
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
                              '¡Bienvenido de nuevo!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: AppColors.navy,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            
                            const SizedBox(height: 4),
                            
                            Text(
                              'Accede para continuar cuidando tu salud.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: AppColors.teal,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // --- Error Banner ---
                            if (_error != null) ...[
                              AppFormNotice(mensaje: _error!),
                              const SizedBox(height: 12),
                            ],
                            
                            // --- Campo Correo ---
                            AppTextFieldGlass(
                              label: 'Correo electrónico',
                              icono: Icons.email_outlined,
                              controller: _correoController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              enabled: !_cargando,
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // --- Campo Contraseña ---
                            AppTextFieldGlass(
                              label: 'Contraseña',
                              icono: Icons.lock_outline,
                              esPassword: true,
                              controller: _passwordController,
                              autofillHints: const [AutofillHints.password],
                              enabled: !_cargando,
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // --- Link Olvidaste contraseña (CENTRADO) ---
                            Center(
                              child: TextButton(
                                onPressed: _cargando
                                    ? null
                                    : () => Navigator.of(context)
                                        .pushNamed('/recuperar-contrasena'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.navy.withOpacity(0.5),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // --- Botón Iniciar Sesión ---
                            _buildBotonPremium(),
                            
                            const SizedBox(height: 16),
                            
                            // --- Link Registro ---
                            Center(
                              child: TextButton(
                                onPressed: _cargando
                                    ? null
                                    : () => Navigator.of(context).pushNamed('/registro'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    text: '¿No tienes cuenta? ',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.navy.withOpacity(0.6),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Regístrate',
                                        style: GoogleFonts.poppins(
                                          color: AppColors.navy,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
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

  // --- Botón Premium ---
  Widget _buildBotonPremium() {
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
              onPressed: !_cargando ? _iniciarSesion : null,
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
                          'Iniciar sesión',
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
            // Burbuja 1
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
            // Burbuja 2
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
            // Burbuja 3
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