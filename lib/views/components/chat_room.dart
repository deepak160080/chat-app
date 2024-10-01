import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/authenticate.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/services/helper.dart';
import 'package:chat_app/views/components/create_group.dart';
import 'package:chat_app/views/components/search.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:random_avatar/random_avatar.dart';

import '../../services/constants.dart';
import 'conversation.dart';
import 'forgotp.dart';
import 'gc_conversation.dart';

class ChatRoom extends StatefulWidget {
  const ChatRoom({super.key});

  @override
  State<ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final DatabaseMethods _database = DatabaseMethods();
  final AuthMethods _auth = AuthMethods();
  final Helper _helper = Helper();
  Stream? chatRoomStream;
  Stream? gcStream;
  String dropdownValue = "Chats";

  @override
  void initState() {
    getUserData();
    super.initState();
  }

  getUserData() async {
    String? name;
    String? email;
    String? svg;

    await _helper.getName().then((val) {
      name = val;
    });
    await _helper.getEmail().then((val) {
      email = val;
    });
    print("debugger2");
    await _helper.getSvg().then((val) {
      svg = val;
    });
    print(svg);
    Constants.localUsername = name!;
    Constants.localEmail = email!;
    Constants.localSvg = svg!;

    await _database.getChatRooms(Constants.localUsername).then((val) {
      setState(() {
        chatRoomStream = val;
        print(val);
      });
    });
    await _database.getGCs(Constants.localUsername).then((val) {
      setState(() {
        gcStream = val;
        print(val);
        print("got gc's data");
      });
    });
    // print(Constants.localUsername);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(color: HexColor("#262630")),
          child: Column(
            children: [
              const SizedBox(
                height: 30,
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                child: RandomAvatar(Constants.localSvg,
                    height: MediaQuery.of(context).size.width / 2,
                    width: MediaQuery.of(context).size.width / 2),
              ),
              Text(
                Constants.localUsername,
                style: GoogleFonts.archivo(color: Colors.white, fontSize: 25),
              ),
              Text(
                Constants.localEmail,
                style: GoogleFonts.archivo(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ForgotPassword(email: Constants.localEmail))),
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: MediaQuery.of(context).size.width / 1.5,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                        color: HexColor("#5953ff"),
                        borderRadius: BorderRadius.circular(10)),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Forgot password?",
                        style: GoogleFonts.archivo(
                            color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white, // Change the color here
        ),
        title: Text(
          "Chat Rooms",
          style: GoogleFonts.archivo(color: Colors.white, fontSize: 20),
        ),
        toolbarHeight: 70,
        backgroundColor: Constants.backgroundColor,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CreateGroup(
                        // stream: chatRoomStream,
                        ))),
            icon: const Icon(Icons.add),
            color: Colors.white,
            tooltip: "Add new group",
          ),
          GestureDetector(
            onTap: () {
              _auth.signOut();
              _helper.setLogStatus(false);
              _helper.setName("");
              _helper.setSvg("");
              _helper.setEmail("");
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const Authenticate()));
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: const Icon(
                Icons.logout,
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => const Search())),
        backgroundColor: HexColor("#5953ff"),
        child: const Icon(Icons.search, color: Colors.white),
      ),
      body: Container(
        // margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(left: 25),
              alignment: Alignment.centerLeft,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: dropdownValue,
                  icon: const Icon(Icons.arrow_drop_down),
                  dropdownColor: HexColor("#262630"),
                  style: GoogleFonts.archivo(fontSize: 14),
                  onChanged: (String? newValue) {
                    setState(() {
                      dropdownValue = newValue!;
                      print(dropdownValue);
                    });
                  },
                  items: <String>['Chats', 'GCs']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // const SizedBox(height: 10),
            SizedBox(
                height: MediaQuery.of(context).size.height * .7,
                child: dropdownValue == "Chats" ? chatRoomList() : gcList()
            )
          ],
        ),
      ),
    );
  }

  Widget chatRoomList() {
    return StreamBuilder(
        stream: chatRoomStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.archivo(color: Colors.red),
            ));
          }

          if (!snapshot.hasData) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              child: Center(
                  child: Text(
                'No chats rooms found, please create a chat room by searching for a user',
                    // : "No GCs found, please click on the + button to make a new GC",
                style: GoogleFonts.archivo(color: Colors.white60),
              )),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            itemCount: snapshot.data.docs.length,
            itemBuilder: (context, index) {
              return ChatRoomTile(
                unreadMessages:
                    ((snapshot.data.docs[index].data())["unreadMessages"] !=
                            null)
                        ? (snapshot.data.docs[index].data())["unreadMessages"]
                            [Constants.localUsername.toString()]
                        : 0,
                username: (Constants.localUsername !=
                        (snapshot.data.docs[index].data())["users"][0])
                    ? (snapshot.data.docs[index].data())["users"][0]
                    : (snapshot.data.docs[index].data())["users"][1],
                roomId: (snapshot.data.docs[index].data())["chatRoomId"],
                svg: (Constants.localSvg !=
                        (snapshot.data.docs[index].data())["userSvg"][0])
                    ? (snapshot.data.docs[index].data())["userSvg"][0]
                    : (snapshot.data.docs[index].data())["userSvg"][1],
              );
            },
          );
        });
  }





  Widget gcList() {
    return StreamBuilder(
        stream: gcStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.archivo(color: Colors.red),
            ));
          }

          if (!snapshot.hasData) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              child: Center(
                  child: Text(
                'No GCs found, please create a GC by click on the + icon',
                    // : "No GCs found, please click on the + button to make a new GC",
                style: GoogleFonts.archivo(color: Colors.white60),
              )),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            itemCount: snapshot.data.docs.length,
            itemBuilder: (context, index) {
              return GCTile(
                createdAt: (snapshot.data.docs[index].data())["createdAt"],
                createdBy: (snapshot.data.docs[index].data())["createdBy"],
                gcName: (snapshot.data.docs[index].data())["gcName"],
                svg: (snapshot.data.docs[index].data())["svg"],
                userData: (snapshot.data.docs[index].data())["data"],
                groupMembers: (snapshot.data.docs[index].data())["users"],
                gcId: (snapshot.data.docs[index].id),
              );
            },
          );
        });
  }
}

class ChatRoomTile extends StatelessWidget {
  final String? username;
  final String? email;
  final String? roomId;
  final String? svg;
  final int? unreadMessages;
  const ChatRoomTile(
      {required this.unreadMessages,
      required this.username,
      this.email,
      required this.roomId,
      required this.svg,
      super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    Conversation(roomId: roomId, name: username, svg: svg)));
      },
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  margin:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                  height: 65,
                  decoration: BoxDecoration(
                      // color: HexColor("#2b2547"),
                      color: HexColor("#262630"),
                      borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      Row(
                        children: [
                          RandomAvatar(
                            svg!,
                            height: 50,
                            width: 52,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            username!.trim(),
                            style: GoogleFonts.archivo(
                                color: Colors.white, fontSize: 20),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (unreadMessages != 0)
                        CircleAvatar(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: HexColor("#5953ff"),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                unreadMessages.toString(),
                                style: GoogleFonts.archivo(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 5),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}






class GCTile extends StatelessWidget {
  final String? gcName;
  final String? gcId;
  final String? svg;
  // final Map data;
  // final int? unreadMessages;
  final Map<String, dynamic> userData;
  final List<dynamic> groupMembers;
  final String createdBy;
  final int createdAt;
  const GCTile({
      // {required this.unreadMessages,
        required this.gcName,
        required this.gcId,
        // required this.data,
        // required this.roomId,
        required this.svg,
        required this.userData,
        required this.groupMembers,
        super.key, required this.createdBy, required this.createdAt});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    GCConversation(
                      createdBy: createdBy,
                        createdAt: createdAt,
                        svg: svg!, gcName: gcName!, data: userData, gcId: gcId!)));
      },
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  margin:
                  const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                  // height: 65,
                  decoration: BoxDecoration(
                      color: HexColor("#262630"),
                      borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            RandomAvatar(
                                  svg!,
                                  height: 50,
                                  width: 52,
                              ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    gcName!.trim(),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: GoogleFonts.archivo(
                                        color: Colors.white, fontSize: 18),
                                  ),
                                  Text(
                                    "You and ${groupMembers.length - 1} other members",
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: GoogleFonts.archivo(
                                        color: Colors.white60, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
