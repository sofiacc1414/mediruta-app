import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

enum AppButtonVariante { primary, secondary }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variante = AppButtonVariante.primary,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariante variante;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      fontSize: 16.5,
      letterSpacing: 0.5,
    );

    if (variante == AppButtonVariante.secondary) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.teal, width: 1.8),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: textStyle,
          elevation: 0,
        ),
        child: _buildChild(textStyle),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.navy,
            AppColors.navy.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: textStyle,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: _buildChild(textStyle),
      ),
    );
  }

  Widget _buildChild(TextStyle textStyle) {
    if (isLoading) {
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            variante == AppButtonVariante.secondary 
                ? AppColors.navy 
                : AppColors.white,
          ),
        ),
      );
    }

    return Text(label);
  }
}