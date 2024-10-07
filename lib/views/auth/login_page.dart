import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/services/helper.dart';
import 'package:chat_app/views/components/chat_room.dart';
import 'package:chat_app/views/widgets/app_buttons.dart';
import 'package:chat_app/views/widgets/app_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum UserType { teacher, student }

class LoginPage extends StatefulWidget {
  final UserType userType;

  const LoginPage({super.key, required this.userType});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Helper _helper = Helper();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

     Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Sign in with Firebase Auth
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      print('Firebase Auth successful. UID: ${userCredential.user!.uid}');

      // 2. Check user existence in both collections
      final DocumentSnapshot teacherDoc = await _firestore
          .collection('teachers')
          .doc(userCredential.user!.uid)
          .get();
      
      final DocumentSnapshot studentDoc = await _firestore
          .collection('students')
          .doc(userCredential.user!.uid)
          .get();

      print('Teacher doc exists: ${teacherDoc.exists}');
      print('Student doc exists: ${studentDoc.exists}');

      // 3. Determine user's actual role
      final bool isTeacher = teacherDoc.exists;
      final bool isStudent = studentDoc.exists;

      // 4. Handle login based on user's role and current login page
      if (isTeacher && widget.userType == UserType.teacher) {
        print('Logging in as teacher');
        await _processSuccessfulLogin(teacherDoc.data() as Map<String, dynamic>, UserType.teacher);
      } else if (isStudent && widget.userType == UserType.student) {
        print('Logging in as student');
        await _processSuccessfulLogin(studentDoc.data() as Map<String, dynamic>, UserType.student);
      } else if (isTeacher && widget.userType == UserType.student) {
        throw 'This account is registered as a teacher. Please use the teacher login.';
      } else if (isStudent && widget.userType == UserType.teacher) {
        throw 'This account is registered as a student. Please use the student login.';
      } else {
        throw 'This account is not registered. Please contact support.';
      }

    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      setState(() {
        _errorMessage = _getFirebaseErrorMessage(e.code);
      });
    } catch (e) {
      print('Unexpected error: $e');
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processSuccessfulLogin(Map<String, dynamic> userData, UserType userType) async {
    try {
      await Future.wait([
        _helper.setName(userData['name'] ?? ''),
        _helper.setEmail(userData['email'] ?? ''),
        _helper.setLogStatus(true),
        _helper.setUserType(userType == UserType.teacher ? 'teacher' : 'student'),
        if (userData['imageSvg'] != null) _helper.setSvg(userData['imageSvg']),
      ]);

      print('Local storage updated successfully');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoom(userType: userType),
          ),
        );
      }
    } catch (e) {
      print('Error in _processSuccessfulLogin: $e');
      throw 'Failed to complete login process: $e';
    }
  }
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Invalid password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      default:
        return 'An error occurred during login. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userType == UserType.teacher ? 'Teacher Login' : 'Student Login'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 40),
              Hero(
                tag: widget.userType == UserType.teacher ? 'teacherLogin' : 'studentLogin',
                child: Material(
                  color: Colors.transparent,
                  child: _buildHeading(),
                ),
              ),
              const SizedBox(height: 40),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildThoughtLine(),
                      const SizedBox(height: 40),
                      AppTextfield(
                        icon: Icons.email,
                        hintText: "Email",
                        controller: _emailController,
                        
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      AppTextfield(
                        icon: Icons.lock,
                        obscureText: true,
                        hintText: "Password",
                        controller: _passwordController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : AppButton(
                              text: "Login",
                              onPressed: _handleLogin,
                            ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: _isLoading ? null : () {
                          // Add forgot password functionality
                        },
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: _isLoading ? Colors.grey : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.userType == UserType.teacher ? "Welcome, Educator" : "Welcome, Student",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.userType == UserType.teacher
              ? "Access your teaching portal"
              : "Begin your learning journey",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[300],
              ),
        ),
      ],
    );
  }

  Widget _buildThoughtLine() {
    final String thoughtLine = widget.userType == UserType.teacher
        ? "Empowering minds, shaping futures."
        : "Unlock your potential, embrace learning.";

    return Column(
      children: [
        Icon(
          widget.userType == UserType.teacher ? Icons.school : Icons.menu_book,
          size: 60,
          color: Theme.of(context).iconTheme.color,
        ),
        const SizedBox(height: 20),
        Text(
          thoughtLine,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.grey[300],
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}