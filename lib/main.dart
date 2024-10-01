
import 'package:chat_app/services/helper.dart';
import 'package:chat_app/utils/app_theme.dart';
import 'package:chat_app/views/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async{
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
  // This widget is the root of your application.
  bool isLoggedIn = false;
  final Helper _helper = Helper();
  @override
  void initState(){
    getLogStatus();
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
      home: const WelcomeScreen(),
    );
  }

  getLogStatus() async{
    await _helper.getLogStatus().then((a){
      print("LogStatus: $a");
      setState(() {
        if(a!=null){
          isLoggedIn = a;
        }
      });
    });
  }
}