import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/services/helper.dart';
import 'package:chat_app/views/auth/login_page.dart';
import 'package:chat_app/views/components/search.dart';
import 'package:chat_app/views/welcome_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:random_avatar/random_avatar.dart';

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

    if (name == null || email == null || svg == null) {
      throw Exception('Failed to load user profile data');
    }

    Constants.localUsername = name;
    Constants.localEmail = email;
    Constants.localSvg = svg;
  }

  Future<void> _loadChatStreams() async {
    chatRoomStream = await _database.getChatRooms(Constants.localUsername);
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
      child: Constants.localSvg.isNotEmpty
          ? RandomAvatar(
              Constants.localSvg,
              height: MediaQuery.of(context).size.width / 2,
              width: MediaQuery.of(context).size.width / 2,
            )
          : CircleAvatar(
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
        widget.userType == UserType.teacher
            ? "Teachers Chat Rooms"
            : "Students Chat Rooms",
        style: GoogleFonts.archivo(color: Colors.white, fontSize: 20),
      ),
      toolbarHeight: 70,
      backgroundColor: Constants.backgroundColor,
      actions: [
        if (widget.userType == UserType.teacher)
          IconButton(
            onPressed: (){},
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
        Expanded(
          child: _buildChatList()
        ),
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

  Widget _buildChatList() {
    return StreamBuilder(
      stream: chatRoomStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorMessage(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
          return _buildEmptyListMessage(
            "No chat rooms found. Create a chat room by searching for a user.",
          );
        }

        return ListView.builder(
  itemCount: snapshot.data.docs.length,
  itemBuilder: (context, index) => ChatRoomTile(
    unreadMessages: snapshot.data.docs[index].data()["unreadMessages"]
        ?[Constants.localUsername.toString()] ?? 0,
    username: _getOtherUsername(
      snapshot.data.docs[index].data()["users"],
    ),
    roomId: snapshot.data.docs[index].data()["chatRoomId"],
    svg: _getOtherUserSvg(
      snapshot.data.docs[index].data()["userSvg"],
    ),
    userType: widget.userType, // Add this line
  ),
);
      },
    );
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
}

class ChatRoomTile extends StatelessWidget {
  final String? username;
  final String? roomId;
  final String? svg;
  final int? unreadMessages;
  final UserType userType;

  const ChatRoomTile({
    super.key,
    required this.unreadMessages,
    required this.username,
    required this.roomId,
    required this.svg,
    required this.userType,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("conversations")
          .doc("${Constants.localUsername}_chat")
          .collection("chats")
          .where("receiver", whereIn: [username, Constants.localUsername])
          .orderBy("time", descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        return GestureDetector(
          onTap: () => _navigateToConversation(context),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                height: 75,
                decoration: BoxDecoration(
                  color: HexColor("#262630"),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    _buildAvatar(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                username!.trim(),
                                style: GoogleFonts.archivo(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty)
                                Text(
                                  _formatTime(snapshot.data!.docs.first["time"]),
                                  style: GoogleFonts.archivo(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: _buildLatestMessage(snapshot),
                              ),
                              if (unreadMessages != 0)
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: HexColor("#5953ff"),
                                  child: Text(
                                    unreadMessages.toString(),
                                    style: GoogleFonts.archivo(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar() {
    return RandomAvatar(
      svg!,
      height: 50,
      width: 52,
    );
  }

  Widget _buildLatestMessage(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
      final latestMessage = snapshot.data!.docs.first;
      String messageText = '';

      if (latestMessage["deleted"] == true) {
        messageText = "This message was deleted";
      } else if (latestMessage["isFile"] == true) {
        messageText = "Sent a file: ${latestMessage["fileName"]}";
      } else if (latestMessage["isImage"] == true) {
        messageText = "Sent an image";
      } else {
        messageText = latestMessage["message"];
      }

      return Text(
        messageText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.archivo(
          color: Colors.white60,
          fontSize: 14,
        ),
      );
    }
    return Text(
      "No messages yet",
      style: GoogleFonts.archivo(
        color: Colors.white60,
        fontSize: 14,
      ),
    );
  }

  String _formatTime(int timestamp) {
    final DateTime messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(messageTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(messageTime);
    } else if (difference.inDays > 0) {
      return DateFormat('E').format(messageTime);
    } else {
      return DateFormat('HH:mm').format(messageTime);
    }
  }

  void _navigateToConversation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Conversation(
          roomId: roomId!,
          svg: svg!,
          name: username!,
        ),
      ),
    );
  }
}

