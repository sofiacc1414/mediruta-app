import 'dart:async';
import 'dart:math' as math; // ← IMPORTANTE: Importar math

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onComenzar,
  });

  final VoidCallback onComenzar;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
    _animationController.repeat(reverse: true);

    _autoSlideTimer = Timer(const Duration(seconds: 10), _autoSlide);
  }

  void _autoSlide() {
    if (!mounted) return;

    final nextPage = (_currentPage + 1) % 2;
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOutCubic,
    );

    setState(() {
      _currentPage = nextPage;
    });

    _autoSlideTimer = Timer(const Duration(seconds: 10), _autoSlide);
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.white,
              AppColors.beige,
              AppColors.skyBlue.withOpacity(0.3),
            ],
            stops: const [0.0, 0.4, 0.9],
          ),
        ),
        child: Stack(
          children: [
            _buildAnimatedBackground(),
            
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildSlide1(),
                _buildSlide2(),
              ],
            ),
            
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: _buildPageIndicator(),
            ),
          ],
        ),
      ),
    );
  }

  // --- SLIDE 1 ---
  Widget _buildSlide1() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 1500),
                tween: Tween<double>(begin: 0.8, end: 1.0),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Image.asset(
                  'assets/images/logo_mediruta.png',
                  height: 80,
                  filterQuality: FilterQuality.high,
                ),
              ),
              
              const SizedBox(height: 50),
              
              _buildTypewriterText(
                "Salud",
                style: GoogleFonts.poppins(
                  color: AppColors.navy,
                  fontSize: 56,
                  height: 1.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 4),
              _buildTypewriterText(
                "que llega a ti.",
                style: GoogleFonts.poppins(
                  color: AppColors.teal,
                  fontSize: 38,
                  height: 1.1,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -0.5,
                ),
                delay: const Duration(milliseconds: 500),
              ),
              
              const SizedBox(height: 20),
              
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 1200),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  "Domiciliarios de confianza,\nmedicamentos seguros,\ntranquilidad para ti.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppColors.navy.withOpacity(0.6),
                    fontSize: 15,
                    height: 1.7,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SLIDE 2 ---
  Widget _buildSlide2() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildFullScreenImage(),
          
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  AppColors.navy.withOpacity(0.6),
                  AppColors.navy.withOpacity(0.8),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 1000),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      "Tu salud,\nnuestra prioridad",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppColors.white,
                        fontSize: 32,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 1200),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      "Entrega segura y confiable\nde tus medicamentos",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppColors.white.withOpacity(0.8),
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 25),
                  
                  _buildAnimatedCards(),
                  
                  const SizedBox(height: 20),
                  
                  _buildPulsingButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Image.asset(
        'assets/images/onboarding_hero.png',
        fit: BoxFit.cover,
        alignment: Alignment.center,
      ),
    );
  }

  Widget _buildAnimatedCards() {
    return Row(
      children: [
        _AnimatedCard(
          icon: Icons.shield_rounded,
          title: "Seguro",
          subtitle: "Verificado",
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.white.withOpacity(0.95),
              AppColors.white.withOpacity(0.8),
            ],
          ),
          iconColor: AppColors.navy,
          delay: 0.1,
        ),
        const SizedBox(width: 10),
        _AnimatedCard(
          icon: Icons.verified_rounded,
          title: "Confiable",
          subtitle: "Garantizado",
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.white.withOpacity(0.95),
              AppColors.white.withOpacity(0.8),
            ],
          ),
          iconColor: AppColors.teal,
          delay: 0.3,
        ),
        const SizedBox(width: 10),
        _AnimatedCard(
          icon: Icons.timer_rounded,
          title: "Rápido",
          subtitle: "Eficiente",
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.white.withOpacity(0.95),
              AppColors.white.withOpacity(0.8),
            ],
          ),
          iconColor: AppColors.skyBlue,
          delay: 0.5,
        ),
      ],
    );
  }

  Widget _buildPulsingButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.white,
                  AppColors.white.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.white.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: widget.onComenzar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.navy,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Comenzar",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.navy.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: AppColors.navy,
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

  // --- Fondo con Ondas Animadas (CORREGIDO) ---
  Widget _buildAnimatedBackground() {
    return TweenAnimationBuilder(
      duration: const Duration(seconds: 8),
      tween: Tween<double>(begin: 0.0, end: 2 * 3.14159),
      curve: Curves.linear,
      builder: (context, value, child) {
        // 🔥 CORRECCIÓN: Usar math.sin y math.cos
        final sinValue = math.sin(value);
        final cosValue = math.cos(value);
        
        return Transform.rotate(
          angle: value * 0.01,
          child: Stack(
            children: [
              // Onda 1
              Positioned(
                top: -60 + 20 * sinValue,
                right: -80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.3, 0.3),
                      radius: 0.7,
                      colors: [
                        AppColors.skyBlue.withOpacity(0.25),
                        Colors.transparent,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              // Onda 2
              Positioned(
                bottom: 50 + 30 * cosValue,
                left: -100,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.7, 0.5),
                      radius: 0.6,
                      colors: [
                        AppColors.teal.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypewriterText(String text, {TextStyle? style, Duration delay = Duration.zero}) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: IntTween(begin: 0, end: text.length),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Text(
          text.substring(0, value),
          style: style,
        );
      },
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDot(0),
        const SizedBox(width: 10),
        _buildDot(1),
      ],
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 10,
      width: _currentPage == index ? 30 : 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: _currentPage == index 
            ? AppColors.navy 
            : AppColors.navy.withOpacity(0.2),
      ),
    );
  }
}

// --- Card con Animación ---
class _AnimatedCard extends StatefulWidget {
  const _AnimatedCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.iconColor,
    required this.delay,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final Color iconColor;
  final double delay;

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.iconColor,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    color: AppColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.subtitle,
                  style: GoogleFonts.poppins(
                    color: AppColors.navy.withOpacity(0.6),
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}