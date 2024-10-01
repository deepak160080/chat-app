
import 'package:chat_app/views/auth/signin.dart';
import 'package:chat_app/views/auth/signup.dart';
import 'package:flutter/material.dart';

class Authenticate extends StatefulWidget {
  const Authenticate({super.key});

  @override
  State<Authenticate> createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  bool _showSignIn = true;

  void _toggleView() {
    setState(() {
      _showSignIn = !_showSignIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _showSignIn
          ? SignIn(onToggleView: _toggleView, key: const ValueKey('signIn'))
          : SignUp(onToggleView: _toggleView, key: const ValueKey('signUp')),
    );
  }
}