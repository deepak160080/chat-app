import 'package:chat_app/views/widgets/app_buttons.dart';
import 'package:chat_app/views/widgets/app_textfield.dart';
import 'package:flutter/material.dart';

enum UserType { teacher, student }
class LoginPage extends StatefulWidget {
  final UserType userType;

  const LoginPage({super.key, required this.userType,});

  @override
  State<LoginPage> createState() => _LoginPageState();
}
 

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();late String heroTag;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _email = '';
  String _password = '';
  
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
    super.dispose();
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
                        hintText: widget.userType == UserType.teacher ? "Email or Phone Number" : "Email",
                        controller: _emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                        onSaved: (value) => _email = value!,
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
                          return null;
                        },
                        onSaved: (value) => _password = value!,
                      ),
                      const SizedBox(height: 40),
                      AppButton(
                        text: "Login",
                        onPressed: (){},
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          // Implement forgot password functionality
                        },
                        child: Text(widget.userType == UserType.teacher
                            ? "Forgot Password?"
                            : "If you forget details, contact your teacher"),
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

//  Future<void> _handleLogin() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() => _isLoading = true);
//       try {
//         final user = await _auth.signInWithEmailAndPassword(
//           _emailController.text.trim(),
//           _passwordController.text.trim(),
//         );
//         if (user != null) {
//           final snapshot = await _database.searchUsersByEmail(_emailController.text);
//           if (snapshot != null && snapshot.docs.isNotEmpty) {
//             final userData = snapshot.docs[0].data() as Map<String, dynamic>;
//             await _helper.setName(userData['name']);
//             await _helper.setEmail(userData['email']);
//             await _helper.setLogStatus(true);
//             await _helper.setSvg(userData['imageSvg']);
//             Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChatRoom()));
//           }
//         }
//       } catch (e) {
//         // Handle login errors
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Login failed: ${e.toString()}')),
//         );
//       } finally {
      
//       }
//     }
//   }
  // }
}