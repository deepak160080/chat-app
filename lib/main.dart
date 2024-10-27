import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:virtualhelp_chat/services/helper.dart';
import 'package:virtualhelp_chat/services/notification_services.dart';
import 'package:virtualhelp_chat/utils/app_theme.dart';
import 'package:virtualhelp_chat/views/auth/login_page.dart';
import 'package:virtualhelp_chat/views/components/chat_room.dart';
import 'package:virtualhelp_chat/views/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  NotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoggedIn = false;
  UserType? userType;
  final Helper _helper = Helper();

  @override
  void initState() {
    getLogStatus();
    getUserType();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Virtual Help ChatApp',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: isLoggedIn && userType != null ? ChatRoom(userType: userType!) : const WelcomeScreen(),
    );
  }

  getLogStatus() async {
    await _helper.getLogStatus().then((a) {
      print("LogStatus: $a");
      setState(() {
        if (a != null) {
          isLoggedIn = a;
        }
      });
    });
  }

  getUserType() async {
    await _helper.getUserType().then((type) {
      setState(() {
        if (type != null) {
          userType = type == 'teacher' ? UserType.teacher : UserType.student;
        }
      });
    });
  }
}
