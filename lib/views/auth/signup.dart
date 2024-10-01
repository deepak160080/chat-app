import 'package:chat_app/utils/app_colors.dart';
import 'package:chat_app/views/widgets/app_buttons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/database.dart';
import '../components/avatar.dart';

class SignUp extends StatefulWidget {
  final VoidCallback onToggleView;
  const SignUp({super.key, required this.onToggleView});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _database = DatabaseMethods();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading:  IconButton(onPressed: (){
         
      Navigator.pop(context);
    
  }, icon: const Icon(Icons.arrow_back,color: AppColors.iconColor,)),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildForm(),
            const SizedBox(height: 15),
            _buildSignUpButton(),
            const SizedBox(height: 30),
            _buildLoginPrompt(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Create Account!",
          style: GoogleFonts.archivo(color: AppColors.primaryTextColor, fontSize: 35),
        ),
        Text(
          "Please enter valid information to create your account.",
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
            icon: Icons.person,
            hintText: "Name",
            controller: _nameController,
            validator: _validateName,
          ),
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

  Widget _buildSignUpButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: AppButton(text: "create", onPressed: _handleSignUp),
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: GoogleFonts.archivo(color: AppColors.primaryTextColor),
        ),
        GestureDetector(
          onTap: widget.onToggleView,
          child: Text(
            "Login!",
            style: GoogleFonts.archivo(
              color: AppColors.primaryTextColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    } else if (value.length < 3) {
      return 'Name must be at least 3 characters long';
    } else if (value.contains(" ")) {
      return 'Spaces are not allowed';
    }
    return null;
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
    } else if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      try {
        final snapshot = await _database.searchUsersByName(name);
        if (snapshot.docs.isEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Avatar(
                email: email,
                password: password,
                name: name,
              ),
            ),
          );
        } else {
          _showErrorDialog("This username is already in use, please use another username");
        }
      } catch (e) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceColor,
          title: Text(
            "Error",
            style: GoogleFonts.archivo(color: AppColors.primaryTextColor, fontSize: 25),
          ),
          content: Text(
            message,
            style: GoogleFonts.archivo(color: AppColors.primaryTextColor, fontSize: 15),
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}