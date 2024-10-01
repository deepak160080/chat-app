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
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final bool showPhone;

  const AppTextfield({
    super.key,
    required this.icon,
    required this.hintText,
    required this.controller,
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
      child: showPhone
          ? PhoneNumberTextField(
              controller: controller,
              validator: validator,
              onChanged: onChanged,
              autofocus: autofocus,
              focusNode: focusNode,
            )
          : TextFormField(
              style: GoogleFonts.archivo(
                color: AppColors.primaryTextColor,
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
              onTap: onTap,
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