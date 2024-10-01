

import 'package:chat_app/views/auth/login_page.dart';
import 'package:chat_app/views/auth/teacher_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../animation/animation_route.dart';
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: <Widget>[
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              Lottie.network(
                "https://lottie.host/608d58e3-e90e-4cc7-aea1-8247478434af/2M2SXdurdL.json",
                height: 240,
                animate: true,
                errorBuilder: (context, error, stackTrace) =>
                    const Text('Error loading animation'),
              ),
              const Text(
                'Welcome to Chat App',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Empowering education through seamless connectivity',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              _buildLoginButton(context, UserType.teacher),
              const SizedBox(height: 20),
              _buildLoginButton(context, UserType.student),
              const SizedBox(height: 40),
              TextButton(
                onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherAuth()));
                },
                child: const Text("Create Teacher's Account"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, UserType u) {
    final String buttonText = u == UserType.teacher ? 'Login as Teacher' : 'Login as Student';
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        textStyle: const TextStyle(fontSize: 18),
      ),
      onPressed: () =>  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => LoginPage(userType: u, ),
    ),
      ),
      child: Text(buttonText),
    );
  }
  
}