import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:chat_app/utils/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class PhoneNumberTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool autofocus;
  final FocusNode? focusNode;

  const PhoneNumberTextField({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
    this.autofocus = false,
    this.focusNode, required bool enabled,
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
      child: IntlPhoneField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Phone Number',
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
        style: GoogleFonts.archivo(
          color: AppColors.primaryTextColor,
          fontSize: 16,
        ),
        initialCountryCode: 'US',
        onChanged: (phone) {
          if (onChanged != null) {
            onChanged!(phone.completeNumber);
          }
        },
        autofocus: autofocus,
        focusNode: focusNode,
        validator: (phoneNumber) {
          if (validator != null) {
            return validator!(phoneNumber?.completeNumber);
          }
          return null;
        },
      ),
    );
  }
}