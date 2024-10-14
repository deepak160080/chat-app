import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/services/helper.dart';
import 'package:chat_app/views/auth/login_page.dart';
import 'package:chat_app/views/components/gc_conversation.dart';
import 'package:chat_app/views/components/search.dart';
import 'package:chat_app/views/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';

import '../../services/constants.dart';
import 'conversation.dart';
import 'forgotp.dart';

enum ChatViewType { chats, groups }

class ChatRoom extends StatefulWidget {
  final UserType userType;

  const ChatRoom({super.key, required this.userType});

  @override
  State<ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final DatabaseMethods _database = DatabaseMethods();
  final AuthMethods _auth = AuthMethods();
  final Helper _helper = Helper();

  Stream? chatRoomStream;
  Stream? gcStream;
  ChatViewType _currentView = ChatViewType.chats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    try {
      await _loadUserProfile();
      await _loadChatStreams();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize: ${e.toString()}';
      });
    }
  }

  Future<void> _loadUserProfile() async {
    final name = await _helper.getName();
    final email = await _helper.getEmail();
    final svg = await _helper.getSvg();

    if (name == null || email == null) {
      throw Exception('Failed to load user profile data');
    }

    Constants.localUsername = name;
    Constants.localEmail = email;
    Constants.localSvg = svg ?? "";
  }

  Future<void> _loadChatStreams() async {
    chatRoomStream = _database.getChatRooms(Constants.localUsername);
    gcStream = await _database.getGCs(Constants.localUsername);
  }

  Future<void> _handleSignOut() async {
    try {
      await _auth.signOut();
      await _helper.setLogStatus(false);
      await _helper.setName("");
      await _helper.setSvg("");
      await _helper.setEmail("");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const WelcomeScreen(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      drawer: _buildDrawer(context),
      appBar: _buildAppBar(context),
      floatingActionButton: widget.userType == UserType.student ? _buildFloatingActionButton(context) : null,
      body: _buildBody(),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(color: HexColor("#262630")),
        child: Column(
          children: [
            const SizedBox(height: 30),
            _buildProfileAvatar(),
            _buildProfileInfo(),
            const SizedBox(height: 30),
            _buildForgotPasswordButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child:
          //  Constants.localSvg.isNotEmpty
          //     ? RandomAvatar(
          //         Constants.localSvg,
          //         height: MediaQuery.of(context).size.width / 2,
          //         width: MediaQuery.of(context).size.width / 2,
          //       )
          //     :
          CircleAvatar(
        radius: MediaQuery.of(context).size.width / 4,
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, size: MediaQuery.of(context).size.width / 4, color: Colors.white),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        Text(
          Constants.localUsername,
          style: GoogleFonts.archivo(color: Colors.white, fontSize: 25),
        ),
        Text(
          Constants.localEmail,
          style: GoogleFonts.archivo(color: Colors.white, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ForgotPassword(email: Constants.localEmail),
        ),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width / 1.5,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: HexColor("#5953ff"),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          "Forgot password?",
          style: GoogleFonts.archivo(color: Colors.white, fontSize: 20),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(
        widget.userType == UserType.teacher ? "Teachers Chat Rooms" : "Students Chat Rooms",
        style: GoogleFonts.archivo(color: Colors.white, fontSize: 20),
      ),
      toolbarHeight: 70,
      backgroundColor: Constants.backgroundColor,
      actions: [
        if (widget.userType == UserType.teacher)
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add),
            color: Colors.white,
            tooltip: "Add new group",
          ),
        IconButton(
          onPressed: _handleSignOut,
          icon: const Icon(Icons.logout),
          color: Colors.white,
          tooltip: "Sign out",
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Search()),
      ),
      backgroundColor: HexColor("#5953ff"),
      child: const Icon(Icons.search, color: Colors.white),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: GoogleFonts.archivo(color: Colors.red),
        ),
      );
    }

    return Column(
      children: [
        _buildViewToggle(),
        Expanded(child: _currentView == ChatViewType.chats ? chatRoomList() : gcList()),
      ],
    );
  }

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.only(left: 25),
      alignment: Alignment.centerLeft,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ChatViewType>(
          value: _currentView,
          dropdownColor: HexColor("#262630"),
          style: GoogleFonts.archivo(fontSize: 14),
          onChanged: (ChatViewType? newValue) {
            if (newValue != null) {
              setState(() => _currentView = newValue);
            }
          },
          items: ChatViewType.values.map((ChatViewType type) {
            return DropdownMenuItem<ChatViewType>(
              value: type,
              child: Text(
                type == ChatViewType.chats ? 'Chats' : 'Groups',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            );
          }).toList(),
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
                  unreadMessages: ((snapshot.data.docs[index].data())["unreadMessages"] != null)
                      ? (snapshot.data.docs[index].data())["unreadMessages"][Constants.localUsername.toString()]
                      : 0,
                  username: (Constants.localUsername != (snapshot.data.docs[index].data())["users"][0])
                      ? (snapshot.data.docs[index].data())["users"][0]
                      : (snapshot.data.docs[index].data())["users"][1],
                  roomId: (snapshot.data.docs[index].data())["chatRoomId"],
                  svg: "");
            },
          );
        });
  }

  Widget _buildErrorMessage(String error) {
    return Center(
      child: Text(
        'Error: $error',
        style: GoogleFonts.archivo(color: Colors.red),
      ),
    );
  }

  Widget _buildEmptyListMessage(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.archivo(color: Colors.white60),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _getOtherUsername(List<dynamic> users) {
    return users.firstWhere(
      (user) => user != Constants.localUsername,
      orElse: () => "Unknown User",
    );
  }

  String _getOtherUserSvg(List<dynamic> userSvgs) {
    return userSvgs.firstWhere(
      (svg) => svg != Constants.localSvg,
      orElse: () => "",
    );
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
  final String username;
  final String? email;
  final String roomId;
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
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => Conversation(roomId: roomId, name: username, svg: svg ?? "")));
      },
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                  height: 65,
                  decoration: BoxDecoration(
                      // color: HexColor("#2b2547"),
                      color: HexColor("#262630"),
                      borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            username.trim(),
                            style: GoogleFonts.archivo(color: Colors.white, fontSize: 20),
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
                                style: GoogleFonts.archivo(color: Colors.white, fontSize: 16),
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
  const GCTile(
      {
      // {required this.unreadMessages,
      required this.gcName,
      required this.gcId,
      // required this.data,
      // required this.roomId,
      required this.svg,
      required this.userData,
      required this.groupMembers,
      super.key,
      required this.createdBy,
      required this.createdAt});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => GCConversation(
                    createdBy: createdBy,
                    createdAt: createdAt,
                    svg: svg!,
                    gcName: gcName!,
                    data: userData,
                    gcId: gcId!)));
      },
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                  // height: 65,
                  decoration: BoxDecoration(color: HexColor("#262630"), borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.group, color: Colors.white),
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
                                    style: GoogleFonts.archivo(color: Colors.white, fontSize: 18),
                                  ),
                                  Text(
                                    "You and ${groupMembers.length - 1} other members",
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: GoogleFonts.archivo(color: Colors.white60, fontSize: 12),
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
