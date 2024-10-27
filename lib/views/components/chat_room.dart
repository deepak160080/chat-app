import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:virtualhelp_chat/services/auth.dart';
import 'package:virtualhelp_chat/services/constants.dart';
import 'package:virtualhelp_chat/services/database.dart';
import 'package:virtualhelp_chat/services/helper.dart';
import 'package:virtualhelp_chat/views/auth/login_page.dart';
import 'package:virtualhelp_chat/views/components/search.dart';
import 'package:virtualhelp_chat/views/welcome_screen.dart';

import 'conversation.dart';
import 'forgotp.dart';

enum ChatViewType { chats, groups }

class ChatRoom extends StatefulWidget {
  final UserType userType;
  final String? receiverId;
  const ChatRoom({super.key, required this.userType, this.receiverId});

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
      body: RefreshIndicator(onRefresh: () async => await _initializeUserData(), child: _buildBody()),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          color: HexColor("#262630"),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: HexColor("#5953ff"),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildProfileAvatar(),
                  const SizedBox(height: 10),
                  _buildProfileInfo(),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white),
              title: Text(
                'Profile',
                style: GoogleFonts.archivo(color: Colors.white),
              ),
              onTap: () {
                // Handle profile navigation
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: Text(
                'Settings',
                style: GoogleFonts.archivo(color: Colors.white),
              ),
              onTap: () {
                // Handle settings navigation
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset, color: Colors.white),
              title: Text(
                'Reset Password',
                style: GoogleFonts.archivo(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ForgotPassword(email: Constants.localEmail),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: Text(
                'Sign Out',
                style: GoogleFonts.archivo(color: Colors.white),
              ),
              onTap: _handleSignOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Hero(
      tag: 'profileAvatar',
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Constants.localSvg.isNotEmpty
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: Constants.localSvg,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              )
            : const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        Text(
          Constants.localUsername,
          style: GoogleFonts.archivo(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          Constants.localEmail,
          style: GoogleFonts.archivo(
            color: Colors.white70,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget chatRoomList() {
    return StreamBuilder<QuerySnapshot>(
      stream: chatRoomStream as Stream<QuerySnapshot>?,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorMessage(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyListMessage('No chat rooms found');
        }

        List<DocumentSnapshot> docs = snapshot.data!.docs;

        // Sort by unread messages first, then by last message time
        docs.sort((a, b) {
          int aUnread = _getUnreadCount(a);
          int bUnread = _getUnreadCount(b);

          if (aUnread != bUnread) {
            return bUnread.compareTo(aUnread);
          }

          int aTime = _getLastMessageTime(a);
          int bTime = _getLastMessageTime(b);
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            return _buildChatRoomTile(docs[index]);
          },
        );
      },
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
        Expanded(child: _currentView == ChatViewType.chats ? chatRoomList() : const SizedBox.shrink()),
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

  int _compareChats(DocumentSnapshot a, DocumentSnapshot b) {
    int aUnread = _getUnreadCount(a);
    int bUnread = _getUnreadCount(b);

    if (aUnread != bUnread) {
      return bUnread.compareTo(aUnread);
    }

    int aLastMessageTime = _getLastMessageTime(a);
    int bLastMessageTime = _getLastMessageTime(b);
    return bLastMessageTime.compareTo(aLastMessageTime);
  }

  int _getUnreadCount(DocumentSnapshot doc) {
    try {
      return (doc.get('unreadMessages') as Map<String, dynamic>)[Constants.localUsername] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  int _getLastMessageTime(DocumentSnapshot doc) {
    try {
      return doc.get('lastMessageTime') as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Widget _buildChatRoomTile(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String otherUsername = _getOtherUsername(data['users'] as List<dynamic>);
    int unreadCount = _getUnreadCount(doc);
    DateTime lastMessageTime = DateTime.fromMillisecondsSinceEpoch(_getLastMessageTime(doc));

    return ChatRoomTile(
      username: otherUsername,
      roomId: data['chatRoomId'] as String,
      svg: data['svg'] as String? ?? "",
      unreadMessages: unreadCount,
      receiverId: widget.receiverId,
      lastMessageTime: lastMessageTime,
      isHighlighted: unreadCount > 0,
    );
  }
}

String _getOtherUsername(List<dynamic> users) {
  return users.firstWhere(
    (user) => user != Constants.localUsername,
    orElse: () => "Unknown User",
  ) as String;
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

class ChatRoomTile extends StatelessWidget {
  final String username;
  final String roomId;
  final String? svg;
  final int unreadMessages;
  final String? receiverId;
  final DateTime lastMessageTime;
  final bool isHighlighted;

  const ChatRoomTile({
    super.key,
    required this.username,
    required this.roomId,
    required this.svg,
    this.isHighlighted = false,
    required this.unreadMessages,
    required this.receiverId,
    required this.lastMessageTime,
  });
  Widget _buildProfileImage() {
    if (svg == null || svg!.isEmpty) {
      return const CircleAvatar(
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, color: Colors.white),
      );
    }

    return CachedNetworkImage(
      imageUrl: svg!,
      imageBuilder: (context, imageProvider) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: HexColor("#262630"),
        highlightColor: Colors.grey[700]!,
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
      errorWidget: (context, url, error) => const CircleAvatar(
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      decoration: BoxDecoration(
        color: isHighlighted ? HexColor("#2A2A35") : HexColor("#262630"),
        // borderRadius: isHighlighted  ? Border.all(color: HexColor("#5953ff"), width: 1)
        //     : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Conversation(
                roomId: roomId,
                name: username,
                svg: svg ?? "",
                receiverId: receiverId ?? "",
              ),
            ),
          );
        },
        leading: _buildAvatar(),
        title: Text(
          username,
          style: GoogleFonts.archivo(
            color: Colors.white,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Row(
          children: [
            if (unreadMessages > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: HexColor("#5953ff"),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadMessages new',
                  style: GoogleFonts.archivo(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                DateFormat('MMM d, HH:mm').format(lastMessageTime),
                style: GoogleFonts.archivo(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.white60,
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (svg == null || svg!.isEmpty) {
      return const CircleAvatar(
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, color: Colors.white),
      );
    }

    return CachedNetworkImage(
      imageUrl: svg!,
      imageBuilder: (context, imageProvider) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: HexColor("#262630"),
        highlightColor: Colors.grey[700]!,
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
      errorWidget: (context, url, error) => const CircleAvatar(
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, color: Colors.white),
      ),
    );
  }
}
