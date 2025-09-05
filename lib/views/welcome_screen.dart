import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:virtualhelp_chat/utils/responsive.dart';
import 'package:virtualhelp_chat/views/auth/login_page.dart';
import 'package:virtualhelp_chat/views/auth/teacher_auth.dart';

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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: <Widget>[
          SizedBox(height: screenHeight * 0.05),
          SizedBox(
            height: screenHeight * 0.25,
            child: _buildLottieAnimation(),
          ),
          SizedBox(height: screenHeight * 0.02),
          SizedBox(
            width: screenWidth * 0.9,
            child: _buildWelcomeText(context, isMobile: true),
          ),
          SizedBox(height: screenHeight * 0.02),
          SizedBox(
            height: screenHeight * 0.08,
            child: _buildSubtitle(context),
          ),
          SizedBox(height: screenHeight * 0.1),
          SizedBox(
            height: screenHeight * 0.08,
            child: _buildLoginButton(context, UserType.teacher),
          ),
          SizedBox(height: screenHeight * 0.03),
          SizedBox(
            height: screenHeight * 0.08,
            child: _buildLoginButton(context, UserType.student),
          ),
          SizedBox(height: screenHeight * 0.03),
          SizedBox(
            height: screenHeight * 0.06,
            child: _buildCreateTeacherAccountButton(context),
          ),
        ],
      ),
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
    final screenWidth = MediaQuery.of(context).size.width;
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
          const SizedBox(width: 60),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SizedBox(
                    width: screenWidth * 0.4,
                    child: _buildWelcomeText(context, isMobile: false),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSubtitle(context),
                const SizedBox(height: 60),
                _buildLoginButton(context, UserType.teacher),
                const SizedBox(height: 20),
                _buildLoginButton(context, UserType.student),
                const SizedBox(height: 40),
                _buildCreateTeacherAccountButton(context),
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
      fit: BoxFit.contain,
      animate: true,
      errorBuilder: (context, error, stackTrace) => const Text('Error loading animation'),
    );
  }

  Widget _buildWelcomeText(BuildContext context, {required bool isMobile}) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        'Welcome to Chat App',
        style: TextStyle(
          fontSize: isMobile ? 28 : 36,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        'Empowering education through seamless connectivity',
        style: TextStyle(
          fontSize: 18,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, UserType userType) {
    final String buttonText = userType == UserType.teacher ? 'Login as Teacher' : 'Login as Student';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16),
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

  Widget _buildCreateTeacherAccountButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherAuth()));
      },
      child: const Text(
        'Create New Account',
        style: TextStyle(fontSize: 14),
      ),
    );
  }
}
