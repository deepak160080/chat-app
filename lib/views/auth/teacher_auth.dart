import 'package:chat_app/views/widgets/app_buttons.dart';
import 'package:chat_app/views/widgets/app_textfield.dart';
import 'package:flutter/material.dart';

class TeacherAuth extends StatefulWidget {
  const TeacherAuth({super.key});

  @override
  State<TeacherAuth> createState() => _TeacherAuthState();
}

class _TeacherAuthState extends State<TeacherAuth> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _otpcontroller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
      elevation: 0,
      title: const Text("New Teacher's Create Account"),
    ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0,vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                AppTextfield(
                  controller: _nameController,
                  icon: Icons.person,
                  hintText: "Teacher's Name",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                AppTextfield(
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  hintText: "Email and Phone Number",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                AppTextfield(
                  controller: _otpcontroller,
                  icon: Icons.password_outlined,
                  hintText: "OTP",
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                AppTextfield(
                  controller: _passwordController,
                  icon: Icons.password_outlined,
                  hintText: "Password",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                 const SizedBox(height: 20),
                AppTextfield(
                  controller: _schoolController,
                  icon: Icons.school_outlined,
                  hintText: "School Name",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your school name';
                    }
                    
                    return null;
                  },
                ),
                 const SizedBox(height: 20),
                AppTextfield(
                  controller: _classController,
                  icon: Icons.class_outlined,
                  hintText: "Class Name",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your Class name';
                    }
                    
                    return null;
                  },
                ),
                const SizedBox(height: 30),
               AppButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Handle successful account creation
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Account Created Successfully')),
                      );
                    }
                  },
                 text:
                    'Create Account',
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
