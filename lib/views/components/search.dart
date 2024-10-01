import 'package:chat_app/services/constants.dart';
import 'package:chat_app/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';

import 'conversation.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final searchController = TextEditingController();
  bool noResultFound = false;
  final DatabaseMethods _database = DatabaseMethods();
  QuerySnapshot? querySnapshot;
  Widget searchList() {
    return querySnapshot == null ? Container() : ListView.builder(
      shrinkWrap: true,
        itemCount: querySnapshot?.docs.length,
        itemBuilder: (context, index) {

          return userTile(
              ((querySnapshot?.docs[index].data()
                  as Map<String, dynamic>)["email"]),
              (querySnapshot?.docs[index].data()
                  as Map<String, dynamic>)["name"],
              (querySnapshot?.docs[index].data()
                  as Map<String, dynamic>)["imageSvg"]
          );

        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HexColor("#131419"),
      appBar: AppBar(
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_outlined, color: Colors.white)),
          backgroundColor: HexColor("#131419")),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 70,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                          color: HexColor("#262630"),
                          borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(10))),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: TextFormField(
                                style: GoogleFonts.archivo(color: Colors.white),
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: "Search username",
                                  hintStyle: GoogleFonts.archivo(),
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                )),
                          ),
                          const SizedBox(width: 15),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      getUserDataList();
                    },
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                          color: HexColor("#1d1d29"),
                          // color: HexColor("#262630"),
                          borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(10))),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // searchList()
              querySnapshot == null ? Text(
                noResultFound ? 'No user with username "${searchController.text.trim()}" found, try to search again or check for typos' : "Start typing to find users",
                style: GoogleFonts.archivo(
                  color: Colors.white,
                ),
              ) : searchList(),
            ],
          ),
        ),
      ),
    );
  }

  getUserDataList() async{
    await _database.searchUsersByName(searchController.text.trim()).then((val) {

      setState(() {
        querySnapshot = val;
      });
      // Map<String, dynamic> data =
      //     querySnapshot?.docs[0].data() as Map<String, dynamic>;
      // print(querySnapshot?.docs.isEmpty);
      if(querySnapshot!.docs.isEmpty){
        print(querySnapshot!.docs.isEmpty);
        setState(() {
          noResultFound = true;
        });
      }
    });
  }

  createChatRoom(String searchUserName, String svg) async{
    String roomId = getChatRoomId(searchUserName, Constants.localUsername);
    List<String> users = [searchUserName, Constants.localUsername];
    List<String> usersSvg = [
      svg,
      Constants.localSvg
    ];
    Map<String, dynamic> chatRoomMap = {
      "chatRoomId": roomId,
      "users": users,
      "userSvg": usersSvg,
      "unreadMessages" : {
        searchUserName : 0,
        Constants.localUsername : 0
      }
    };
    await _database.createChatRoom(roomId, chatRoomMap).then((a){
      print(a);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Conversation(roomId: roomId, svg: svg, name: searchUserName,)));
    });
  }

  //still need to find explanation:

  String getChatRoomId(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "${b}_$a";
    } else {
      return "${a}_$b";
    }
  }

  Widget userTile(String email, String username, String svg){
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            margin: const EdgeInsets.symmetric(vertical: 10),
            height: 80,
            decoration: BoxDecoration(
                color: HexColor("#262630"),
                borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(10))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: GoogleFonts.archivo(color: Colors.white, fontSize: 18),
                ),
                Text(
                  email,
                  style: GoogleFonts.archivo(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: () => createChatRoom(username, svg),
            child: Container(
                height: 80,
                decoration: BoxDecoration(
                    color: HexColor("#5953ff"),
                    borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(10))),
                child: const Icon(
                  Icons.email,
                  color: Colors.white,
                )),
          ),
        ),
      ],
    );
  }

}


// class UserTile extends StatelessWidget {
//   final String username;
//   final String email;
//
//   UserTile({required this.email, required this.username, super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           flex: 3,
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//             margin: const EdgeInsets.symmetric(vertical: 10),
//             height: 80,
//             decoration: BoxDecoration(
//                 color: HexColor("#262630"),
//                 borderRadius:
//                     const BorderRadius.horizontal(left: Radius.circular(10))),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   username,
//                   style: GoogleFonts.archivo(color: Colors.white, fontSize: 18),
//                 ),
//                 Text(
//                   email,
//                   style: GoogleFonts.archivo(color: Colors.white, fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//         ),
//
//           Expanded(
//             flex: 1,
//             child: Container(
//                 height: 80,
//                 decoration: BoxDecoration(
//                     color: HexColor("#5953ff"),
//                     borderRadius: const BorderRadius.horizontal(
//                         right: Radius.circular(10))),
//                 child: const Icon(
//                   Icons.email,
//                   color: Colors.white,
//                 )),
//           ),
//       ],
//     );
//   }
// }
