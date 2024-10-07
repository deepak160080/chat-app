import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/constants.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/views/auth/login_page.dart';
import 'package:chat_app/views/components/chat_room.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:random_avatar/random_avatar.dart';

import '../../services/helper.dart';
class Avatar extends StatefulWidget {
   final UserType userType;
  final String email;
  final String password;
  final String name;

  const Avatar({super.key, required this.email, required this.password, required this.name, required this.userType});

  @override
  State<Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<Avatar> {
  String svg = DateTime.now().toIso8601String();
  final AuthMethods _auth = AuthMethods();
  final DatabaseMethods _database = DatabaseMethods();
  final Helper _helper = Helper();
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_outlined, color: Colors.white)),
        backgroundColor: Constants.backgroundColor,
        title: isLoading ? const SizedBox() : Text(
          "Choose your Avatar",
          style: GoogleFonts.archivo(
            color: Colors.white
          ),
        ),
      ),

      backgroundColor: Constants.backgroundColor,
      body: isLoading ? Center(
        child: CircularProgressIndicator(
          color: HexColor("#5953ff"),
        ),
      ) : SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          alignment: Alignment.center,
          child: Column(
            children: [
              RandomAvatar(
                svg,
                height: MediaQuery.of(context).size.height/3
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: changeAvatar,
                child: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () => _signUp(widget.email, widget.password, widget.name),
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: MediaQuery.of(context).size.width/2,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                        color: HexColor("#5953ff"),
                        borderRadius: BorderRadius.circular(10)
                    ),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Continue",
                        style: GoogleFonts.archivo(
                            color: Colors.white,
                            fontSize: 24
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  changeAvatar() {
    setState(() {
      svg = DateTime.now().toIso8601String();
    });
  }

  void _signUp(String email, String password, String name) async{

    setState(() {
      isLoading = true;
    });
    Map<String, String> userInfo = {
      "name" : name,
      "email" : email,
      "password" : password,
      "imageSvg" : svg
    };

    await _auth.signUpWithEmailAndPassword(email, password).then((val){
      _helper.setLogStatus(true);
      _helper.setEmail(email);
      _helper.setName(name);
      _helper.setSvg(svg);
      _database.uploadUserInfo(userInfo);
      print("email: ${val?.email}");
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>  ChatRoom(userType:widget.userType,)));
    }).catchError((e){
      print(e);
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          )
      );
    });


  }
}
