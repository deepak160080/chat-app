import 'package:chat_app/utils/app_colors.dart';
import 'package:chat_app/views/components/forgotp.dart';
import 'package:chat_app/views/widgets/app_buttons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/services/helper.dart';

import '../components/chat_room.dart';
class SignIn extends StatefulWidget {
  final VoidCallback onToggleView;
  const SignIn({super.key, required this.onToggleView});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final AuthMethods _auth = AuthMethods();
  final DatabaseMethods _database = DatabaseMethods();
  final Helper _helper = Helper();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildForm(),
                    const SizedBox(height: 15),
                    _buildActionButtons(),
                    const SizedBox(height: 30),
                    _buildSignUpPrompt(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome Back!",
          style: GoogleFonts.archivo(color: AppColors.primaryTextColor, fontSize: 35),
        ),
        Text(
          "Enter your email address and password to access your account.",
          style: GoogleFonts.archivo(color: AppColors.secondaryTextColor, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildInputField(
            icon: Icons.email_outlined,
            hintText: "Email",
            controller: _emailController,
            validator: _validateEmail,
          ),
          _buildInputField(
            icon: Icons.lock_clock_outlined,
            hintText: "Password",
            controller: _passwordController,
            validator: _validatePassword,
            obscureText: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String hintText,
    required TextEditingController controller,
    required String? Function(String?) validator,
    bool obscureText = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        style: GoogleFonts.archivo(color: AppColors.primaryTextColor),
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          icon: Icon(icon, color: AppColors.iconColor),
          hintText: hintText,
          hintStyle: GoogleFonts.archivo(color: AppColors.secondaryTextColor),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>  const ForgotPassword()),
          ),
          child: Text(
            "Forgot password?",
            style: GoogleFonts.archivo(color: AppColors.primaryTextColor, fontSize: 12),
          ),
        ),
       AppButton(text: "Login", onPressed: _handleLogin,),
      ],
    );
  }

  Widget _buildSignUpPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: GoogleFonts.archivo(color: AppColors.primaryTextColor),
        ),
        GestureDetector(
          onTap: widget.onToggleView,
          child: Text(
            "Create one!",
            style: GoogleFonts.archivo(
              color: AppColors.primaryTextColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email address';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = await _auth.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (user != null) {
          final snapshot = await _database.searchUsersByEmail(_emailController.text);
          if (snapshot != null && snapshot.docs.isNotEmpty) {
            final userData = snapshot.docs[0].data() as Map<String, dynamic>;
            await _helper.setName(userData['name']);
            await _helper.setEmail(userData['email']);
            await _helper.setLogStatus(true);
            await _helper.setSvg(userData['imageSvg']);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChatRoom()));
          }
        }
      } catch (e) {
        // Handle login errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}