import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:chat_app/services/helper.dart';
import 'package:chat_app/utils/app_theme.dart';
import 'package:chat_app/views/auth/login_page.dart';
import 'package:chat_app/views/components/chat_room.dart';
import 'package:chat_app/views/welcome_screen.dart';
import 'firebase_options.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
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
      title: 'Android chat app',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: isLoggedIn && userType != null
          ? ChatRoom(userType: userType!)
          : const WelcomeScreen(),
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