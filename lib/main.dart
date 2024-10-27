import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualhelp_chat/firebase_options.dart';
import 'package:virtualhelp_chat/provider/theme_provider.dart';
import 'package:virtualhelp_chat/services/helper.dart';
import 'package:virtualhelp_chat/views/auth/login_page.dart';
import 'package:virtualhelp_chat/views/components/chat_room.dart';
import 'package:virtualhelp_chat/views/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // NotificationService.initialize();
  runApp(ChangeNotifierProvider(create: (_) => ThemeProvider(), child: const MyApp()));
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
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Virtual Help ChatApp',
        theme: themeProvider.themeData,
        home: isLoggedIn && userType != null ? ChatRoom(userType: userType!) : const WelcomeScreen(),
      );
    });
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
