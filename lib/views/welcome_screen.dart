import 'package:chat_app/utils/responsive.dart';
import 'package:chat_app/views/auth/login_page.dart';
import 'package:chat_app/views/auth/teacher_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Responsive(
          mobile: _buildMobileLayout(context),
          tablet: _buildTabletLayout(context),
          desktop: _buildDesktopLayout(context),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: <Widget>[
          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
          _buildLottieAnimation(),
          const SizedBox(height: 20),
          _buildWelcomeText(),
          const SizedBox(height: 20),
          _buildSubtitle(),
          const SizedBox(height: 60),
          _buildLoginButton(context, UserType.teacher),
          const SizedBox(height: 20),
          _buildLoginButton(context, UserType.student),
          const SizedBox(height: 40),
           _buildCreateTeacherAccountButton(context),
        ],
      ),
    );
  }

  Widget _buildCreateTeacherAccountButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherAuth()));
      },
      child: const Text('Create Teacher Account'),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 600,
        child: _buildMobileLayout(context),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 80),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: _buildLottieAnimation(),
            ),
          ),
          const SizedBox(width: 60),  // Add space between animation and content
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,  // Align content to the left
              children: [
                _buildWelcomeText(),
                const SizedBox(height: 20),
                _buildSubtitle(),
                const SizedBox(height: 60),
                _buildLoginButton(context, UserType.teacher),
                const SizedBox(height: 20),
                _buildLoginButton(context, UserType.student),
                const SizedBox(height: 40),
                // _buildCreateTeacherAccountButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLottieAnimation() {
    return Lottie.network(
      "https://lottie.host/608d58e3-e90e-4cc7-aea1-8247478434af/2M2SXdurdL.json",
      height: 300,  // Increased height for better visibility
      animate: true,
      errorBuilder: (context, error, stackTrace) =>
          const Text('Error loading animation'),
    );
  }

  Widget _buildWelcomeText() {
    return const Text(
      'Welcome to Chat App',
      style: TextStyle(
        fontSize: 36,  
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSubtitle() {
    return const Text(
      'Empowering education through seamless connectivity',
      style: TextStyle(
        fontSize: 18,  // Increased font size for desktop
        color: Colors.white70,
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, UserType userType) {
    final String buttonText =
        userType == UserType.teacher ? 'Login as Teacher' : 'Login as Student';

    return SizedBox(
      width: Responsive.doubleR(
        context,
        mobile: MediaQuery.of(context).size.width * 0.8,
        desktop: 300,  
        tablet: 400, 
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
          textStyle: const TextStyle(fontSize: 18),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LoginPage(userType: userType),
          ),
        ),
        child: Text(buttonText),
      ),
    );
  }

  // Widget _buildCreateTeacherAccountButton(BuildContext context) {
  //   return TextButton(
  //     onPressed: () {
  //       Navigator.push(context,
  //           MaterialPageRoute(builder: (context) => const TeacherAuth()));
  //     },
  //     child:  Text(
  //       "Create Teacher's Account",
  //       style:GoogleFonts.archivo(fontSize: 16),  
  //     ),
  //   );
  // }
}