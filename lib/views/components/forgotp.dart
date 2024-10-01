import 'package:chat_app/services/auth.dart';
import 'package:chat_app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
class ForgotPassword extends StatefulWidget {
  final String? email;

  const ForgotPassword({super.key, this.email});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthMethods();

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      emailController.text = widget.email!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.surfaceColor,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            children: [
              Text(
                "Forgot Password?",
                style: GoogleFonts.archivo(
                  color: Colors.white,
                  fontSize: 35,
                ),
              ),
              Text(
                "Please enter your valid email to receive an email to reset your password.",
                style: GoogleFonts.archivo(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 30),
              Form(
                key: _formKey,
                child: Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextFormField(
                    validator: (value) {
                      String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
                      RegExp regex = RegExp(pattern);
                      return regex.hasMatch(value ?? '') ? null : "Provide a valid email";
                    },
                    style: GoogleFonts.archivo(color: Colors.white),
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: "Enter your email",
                      hintStyle: GoogleFonts.archivo(),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      await _auth.sendResetPasswordEmail(emailController.text.trim());
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Password reset email has been sent to your email",
                            style: GoogleFonts.archivo(color: Colors.white),
                          ),
                        ),
                      );
                    } catch (e) {
                      print(e);
                      ScaffoldMessenger.of(context).showSnackBar( SnackBar(
                        content: Text(
                          e.toString(),
                          style: GoogleFonts.archivo(color: Colors.white),
                        ),
                      ));
                    }
                  }
                },
                child: Container(
                  width: MediaQuery.of(context).size.width / 2,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Send Email",
                    style: GoogleFonts.archivo(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}