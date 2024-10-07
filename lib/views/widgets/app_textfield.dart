import 'package:chat_app/utils/app_colors.dart';
import 'package:chat_app/views/widgets/phone_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextfield extends StatelessWidget {
  final IconData icon;
  final String hintText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final bool autofocus;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final bool showPhone;
  final bool enabled;  // Added enabled property

  const AppTextfield({
    super.key,
    required this.icon,
    required this.hintText,
    required this.controller,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = false,
    this.focusNode,
    this.onTap,
    this.showPhone = false,
    this.enabled = true,  // Default value is true
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: enabled 
            ? AppColors.surfaceColor 
            : AppColors.surfaceColor.withOpacity(0.7),  // Slightly dim when disabled
        borderRadius: BorderRadius.circular(10),
        boxShadow: enabled ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ] : null,  // Remove shadow when disabled
      ),
      child: showPhone
          ? PhoneNumberTextField(
              controller: controller,
              validator: validator,
              onChanged: onChanged,
              autofocus: autofocus,
              focusNode: focusNode,
              enabled: enabled,  // Pass enabled to phone field
            )
          : TextFormField(
              style: GoogleFonts.archivo(
                color: enabled 
                    ? AppColors.primaryTextColor
                    : AppColors.primaryTextColor.withOpacity(0.6),  // Dim text when disabled
                fontSize: 16,
              ),
              controller: controller,
              obscureText: obscureText,
              validator: validator,
              onChanged: onChanged,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              maxLines: maxLines,
              minLines: minLines,
              autofocus: autofocus,
              focusNode: focusNode,
              
              onTap: enabled ? onTap : null,  // Only allow tap when enabled
              enabled: enabled,  // Enable/disable the field
              decoration: InputDecoration(
                suffixIcon: suffixIcon,
                icon: Icon(
                  icon, 
                  color: enabled 
                      ? AppColors.iconColor
                      : AppColors.iconColor.withOpacity(0.6),  // Dim icon when disabled
                  size: 24,
                ),
                hintText: hintText,
                hintStyle: GoogleFonts.archivo(
                  color: enabled
                      ? AppColors.secondaryTextColor
                      : AppColors.secondaryTextColor.withOpacity(0.6),  // Dim hint text when disabled
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