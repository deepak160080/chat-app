import 'package:chat_app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextfield extends StatelessWidget {
  final IconData icon;
  final String hintText;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final void Function(String?)? onSaved;
  final bool obscureText;

  const AppTextfield({
    super.key,
    required this.icon,
    required this.hintText,
    required this.controller,
    required this.validator,
    this.onSaved,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        style: GoogleFonts.archivo(
          color: AppColors.primaryTextColor,
          fontSize: 16,
        ),
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        onSaved: onSaved,
        decoration: InputDecoration(
          icon: Icon(icon, color: AppColors.iconColor, size: 24),
          hintText: hintText,
          hintStyle: GoogleFonts.archivo(
            color: AppColors.secondaryTextColor,
            fontSize: 16,
          ),
          border: InputBorder.none,
          errorStyle: GoogleFonts.archivo(
            color: Colors.red,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}