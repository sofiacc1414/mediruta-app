import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import 'app_form_notice.dart';

class AppTextFieldGlass extends StatefulWidget {
  const AppTextFieldGlass({
    super.key,
    required this.label,
    required this.icono,
    required this.controller,
    this.esPassword = false,
    this.keyboardType,
    this.autofillHints,
    this.enabled = true,
    this.errorText,
    this.onChanged,
  });

  final String label;
  final IconData icono;
  final TextEditingController controller;
  final bool esPassword;
  final TextInputType? keyboardType;
  final List<String>? autofillHints;
  final bool enabled;
  final String? errorText;
  final void Function(String)? onChanged;

  @override
  State<AppTextFieldGlass> createState() => _AppTextFieldGlassState();
}

class _AppTextFieldGlassState extends State<AppTextFieldGlass>
    with TickerProviderStateMixin {
  bool _obscureText = true;
  bool _isFocused = false;
  late AnimationController _iconController;
  late Animation<double> _iconAnimation;

  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _iconAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Curves.easeOutBack,
      ),
    );

  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final isFocused = _isFocused;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            color: hasError ? AppColors.skyBlue : const Color(0xFFE8DDD0),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: widget.controller,
            obscureText: widget.esPassword ? _obscureText : false,
            keyboardType: widget.keyboardType,
            autofillHints: widget.autofillHints,
            enabled: widget.enabled,
            maxLines: 1,
            textAlignVertical: TextAlignVertical.center,
            onChanged: widget.onChanged,
            onTap: () {
              setState(() {
                _isFocused = true;
                _iconController.forward();
              });
            },
            onEditingComplete: () {
              setState(() {
                _isFocused = false;
                _iconController.reverse();
              });
            },
            style: GoogleFonts.poppins(
              color: AppColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            decoration: InputDecoration(
              isDense: true,
              labelText: widget.label,
              labelStyle: GoogleFonts.poppins(
                color: isFocused
                    ? AppColors.navy
                    : AppColors.navy.withValues(alpha: 0.5),
                fontSize: isFocused ? 11 : 14,
                fontWeight: isFocused ? FontWeight.w600 : FontWeight.w400,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
                maxWidth: 40,
                maxHeight: 40,
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
                maxWidth: 40,
                maxHeight: 40,
              ),
              prefixIcon: AnimatedBuilder(
                animation: _iconAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _iconAnimation.value,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      child: Icon(
                        widget.icono,
                        color: isFocused
                            ? AppColors.navy
                            : AppColors.navy.withValues(alpha: 0.4),
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
              ),
              errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
              ),
              focusedErrorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
              ),
              suffixIcon: widget.esPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: isFocused
                            ? AppColors.navy
                            : AppColors.navy.withValues(alpha: 0.3),
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              filled: true,
              fillColor: Colors.transparent,
            ),
          ),
        ),
        if (hasError) AppFormNotice(mensaje: widget.errorText!, compact: true),
      ],
    );
  }
}
