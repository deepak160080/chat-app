import 'package:chat_app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color primaryColor;
  final Color secondaryColor;
  final double borderRadius;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.primaryColor = AppColors.primaryColor,
    this.secondaryColor = AppColors.primaryDarkColor,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return  GestureDetector(
                    onTap: onPressed,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        // margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: secondaryColor,
                          borderRadius: BorderRadius.circular(borderRadius)
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                  borderRadius: BorderRadius.circular(10)
                              ),
                              child: Text(
                                text,
                                style: GoogleFonts.archivo(
                                  color: Colors.white,
                                  fontSize: 18
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 15),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
  }
}