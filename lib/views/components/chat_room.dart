import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:virtualhelp_chat/provider/theme_provider.dart';
import 'package:virtualhelp_chat/services/auth.dart';
import 'package:virtualhelp_chat/services/constants.dart';
import 'package:virtualhelp_chat/services/database.dart';
import 'package:virtualhelp_chat/services/helper.dart';
import 'package:virtualhelp_chat/views/auth/login_page.dart';
import 'package:virtualhelp_chat/views/components/search.dart';
import 'package:virtualhelp_chat/views/welcome_screen.dart';

import 'conversation.dart';

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
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool darkmode = false;
  Stream? chatRoomStream;
  Stream? gcStream;
  final ChatViewType _currentView = ChatViewType.chats;
  bool _isLoading = true;
  String? _errorMessage;
  String? currentUserId;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    try {
      // Get current user
      final User? user = _firebaseAuth.currentUser;
      if (user != null) {
        currentUserId = user.uid;

        // First try to get user from students collection
        var studentDoc = await FirebaseFirestore.instance.collection('students').doc(currentUserId).get();

        if (studentDoc.exists) {
          userRole = 'student';
        } else {
          // If not found in students, check teachers collection
          var teacherDoc = await FirebaseFirestore.instance.collection('teachers').doc(currentUserId).get();

          if (teacherDoc.exists) {
            userRole = 'teacher';
          }
        }

        final name = await _helper.getName();
        final email = await _helper.getEmail();
        final svg = await _helper.getSvg();

        if (mounted) {
          setState(() {
            Constants.localUsername = name ?? "";
            Constants.localEmail = email ?? "";
            Constants.localSvg = svg ?? "";
            Constants.localUserId = currentUserId ?? "";
            Constants.localRole = userRole ?? "";
          });
        }

        await _loadChatStreams();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to initialize: ${e.toString()}';
        });
      }
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
    // gcStream = await _database.getGCs(Constants.localUsername);
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
      drawer: _buildDrawer(context),
      appBar: _buildAppBar(context),
      floatingActionButton: widget.userType == UserType.student ? _buildFloatingActionButton(context) : null,
      body: RefreshIndicator(
        onRefresh: () async => await _initializeUserData(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return _buildResponsiveBody(constraints);
          },
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor
              // color: HexColor("#262630"),
              ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildProfileAvatar(),
                  const SizedBox(height: 10),
                  _buildProfileInfo(),
                ],
              ),
              // ListTile(
              //   leading: const Icon(
              //     Icons.person,
              //   ),
              //   title: Text(
              //     'Profile',
              //     style: GoogleFonts.archivo(),
              //   ),
              //   onTap: () {
              //     // Handle profile navigation
              //     Navigator.pop(context);
              //   },
              // ),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return ListTile(
                    leading: Icon(
                      themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    ),
                    title: Text(
                      'Theme',
                      style: GoogleFonts.archivo(
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                    ),
                  );
                },
              ),
              // ListTile(
              //   leading: const Icon(Icons.settings, color: Colors.white),
              //   title: Text(
              //     'Settings',
              //     style: GoogleFonts.archivo(color: Colors.white),
              //   ),
              //   onTap: () {
              //     // Handle settings navigation
              //     Navigator.pop(context);
              //   },
              // ),
              // ListTile(
              //   leading: const Icon(Icons.lock_reset, color: Colors.white),
              //   title: Text(
              //     'Reset Password',
              //     style: GoogleFonts.archivo(color: Colors.white),
              //   ),
              //   onTap: () {
              //     Navigator.pop(context);
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (context) => ForgotPassword(email: Constants.localEmail),
              //       ),
              //     );
              //   },
              // ),
              ListTile(
                leading: const Icon(
                  Icons.logout,
                ),
                title: Text(
                  'Sign Out',
                  style: GoogleFonts.archivo(),
                ),
                onTap: _handleSignOut,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    if (currentUserId == null || userRole == null) {
      return const CircleAvatar(
        backgroundColor: Colors.grey,
        radius: 40,
        child: Icon(
          Icons.person,
          size: 40,
          color: Colors.white,
        ),
      );
    }

    return Hero(
      tag: 'profileAvatar',
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection(userRole == 'teacher' ? 'teachers' : 'students')
              .doc(currentUserId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const CircleAvatar(
                // backgroundColor: Colors.grey,
                child: Icon(
                  Icons.error_outline,
                  // color: Colors.white,
                ),
              );
            }

            if (snapshot.hasData && snapshot.data!.exists) {
              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final profileImage = userData['svg'] as String?;

              if (profileImage != null && profileImage.isNotEmpty) {
                return ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: profileImage,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                          // color: Colors.white,
                          ),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.person,
                      size: 40,
                      // color: Colors.white,
                    ),
                  ),
                );
              }
            }

            return const CircleAvatar(
              // backgroundColor: Colors.grey,
              child: Icon(
                Icons.person,
                size: 40,
                // color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResponsiveBody(BoxConstraints constraints) {
    // Desktop layout (width > 900)
    if (constraints.maxWidth > 900) {
      return Row(
        children: [
          // Side panel (30% width)
          Container(
            width: constraints.maxWidth * 0.3,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                _buildViewToggle(),
                Expanded(child: _currentView == ChatViewType.chats ? chatRoomList() : const SizedBox.shrink()),
              ],
            ),
          ),
          // Main content area (70% width)
          Expanded(
            child: Center(
              child: Text(
                'Select a chat to start messaging',
                style: GoogleFonts.archivo(
                  fontSize: 18,
                  color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                ),
              ),
            ),
          ),
        ],
      );
    }
    // Tablet layout (600 < width <= 900)
    else if (constraints.maxWidth > 600) {
      return Column(
        children: [
          _buildViewToggle(),
          Expanded(
            child: _currentView == ChatViewType.chats
                ? GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemBuilder: (context, index) {
                      if (_isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return StreamBuilder<QuerySnapshot>(
                        stream: chatRoomStream as Stream<QuerySnapshot>?,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          final sortedDocs = snapshot.data!.docs.toList()..sort((a, b) => _compareChats(a, b));
                          if (index >= sortedDocs.length) return const SizedBox();
                          return _buildChatRoomTile(sortedDocs[index]);
                        },
                      );
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      );
    }
    // Mobile layout (width <= 600)
    else {
      return Column(
        children: [
          _buildViewToggle(),
          Expanded(child: _currentView == ChatViewType.chats ? chatRoomList() : const SizedBox.shrink()),
        ],
      );
    }
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        Text(
          Constants.localUsername,
          style: GoogleFonts.archivo(
            color: Theme.of(context).textTheme.bodyLarge?.decorationColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          Constants.localEmail,
          style: GoogleFonts.archivo(
            // color: Colors.white70,
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

        // Sort documents by unread count and last message time
        final sortedDocs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            // First sort by unread count
            final aUnread =
                (a.data() as Map<String, dynamic>)['unreadCount']?[FirebaseAuth.instance.currentUser?.uid] ?? 0;
            final bUnread =
                (b.data() as Map<String, dynamic>)['unreadCount']?[FirebaseAuth.instance.currentUser?.uid] ?? 0;

            if (aUnread != bUnread) {
              return bUnread.compareTo(aUnread); // Higher unread count first
            }

            // Then sort by last message time
            final aTime = (a.data() as Map<String, dynamic>)['lastMessageTime'] ?? 0;
            final bTime = (b.data() as Map<String, dynamic>)['lastMessageTime'] ?? 0;
            return bTime.compareTo(aTime); // Most recent first
          });

        return ListView.builder(
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            return _buildChatRoomTile(sortedDocs[index]);
          },
        );
      },
    );
  }

  // Widget _buildForgotPasswordButton(BuildContext context) {
  //   return GestureDetector(
  //     onTap: () => Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => ForgotPassword(email: Constants.localEmail),
  //       ),
  //     ),
  //     child: Container(
  //       width: MediaQuery.of(context).size.width / 1.5,
  //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  //       decoration: BoxDecoration(
  //         color: HexColor("#5953ff"),
  //         borderRadius: BorderRadius.circular(10),
  //       ),
  //       child: Text(
  //         "Forgot password?",
  //         style: GoogleFonts.archivo(color: Colors.white, fontSize: 20),
  //         textAlign: TextAlign.center,
  //       ),
  //     ),
  //   );
  // }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        widget.userType == UserType.teacher ? "Teachers Chat Rooms" : "Students Chat Rooms",
        style: GoogleFonts.archivo(fontSize: 20),
      ),
      toolbarHeight: 70,
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Search()),
      ),
      child: const Icon(
        Icons.search,
      ),
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
        child: Text(
          'Chats',
          style: GoogleFonts.poppins(),
        ));
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

  @override
  Widget _buildChatRoomTile(DocumentSnapshot doc) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final isTablet = MediaQuery.of(context).size.width > 600 && MediaQuery.of(context).size.width <= 900;

    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    String chatRoomId = data['chatRoomId'] as String;

    Map<String, dynamic>? otherUserData;
    String? otherUserId;

    if (widget.userType == UserType.student) {
      otherUserData = data['teacherData'] as Map<String, dynamic>?;
      otherUserId = data['teacherId'] as String?;
    } else {
      otherUserData = data['studentData'] as Map<String, dynamic>?;
      otherUserId = data['studentId'] as String?;
    }

    if (otherUserData == null || otherUserId == null) {
      List<dynamic> users = data['users'] as List<dynamic>;
      String otherUsername = users.firstWhere(
        (user) => user != Constants.localUsername,
        orElse: () => "Unknown User",
      ) as String;

      String otherUserCollection = widget.userType == UserType.student ? 'teachers' : 'students';

      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(otherUserCollection)
            .where('name', isEqualTo: otherUsername)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return ChatRoomTile(
              username: otherUsername,
              roomId: chatRoomId,
              svg: null,
              unreadMessages: _getUnreadCount(doc),
              receiverId: null,
              lastMessageTime: DateTime.fromMillisecondsSinceEpoch(_getLastMessageTime(doc)),
              isHighlighted: _getUnreadCount(doc) > 0,
              isDesktop: isDesktop,
              isTablet: isTablet,
            );
          }

          Map<String, dynamic> userData = snapshot.data!.docs.first.data() as Map<String, dynamic>;

          return ChatRoomTile(
            username: userData['name'] as String? ?? otherUsername,
            roomId: chatRoomId,
            svg: userData['svg'] as String?,
            unreadMessages: _getUnreadCount(doc),
            receiverId: snapshot.data!.docs.first.id,
            lastMessageTime: DateTime.fromMillisecondsSinceEpoch(_getLastMessageTime(doc)),
            isHighlighted: _getUnreadCount(doc) > 0,
            isDesktop: isDesktop,
            isTablet: isTablet,
          );
        },
      );
    }

    return ChatRoomTile(
      username: otherUserData['name'] as String? ?? 'Unknown User',
      roomId: chatRoomId,
      svg: otherUserData['svg'] as String?,
      unreadMessages: _getUnreadCount(doc),
      receiverId: otherUserId,
      lastMessageTime: DateTime.fromMillisecondsSinceEpoch(_getLastMessageTime(doc)),
      isHighlighted: _getUnreadCount(doc) > 0,
      isDesktop: isDesktop,
      isTablet: isTablet,
    );
  }
}

String _getOtherUsername(List<dynamic> users) {
  return users.firstWhere(
    (user) => user != Constants.localUsername,
    orElse: () => "Unknown User",
  ) as String;
}

Future<void> updateUnreadCount(String roomId, String userId, {bool reset = false}) async {
  try {
    final docRef = FirebaseFirestore.instance.collection("chatrooms").doc(roomId).collection("unreadCount").doc(userId);

    if (reset) {
      await docRef.set({'count': 0});
    } else {
      // Increment unread count
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          transaction.set(docRef, {'count': 1});
        } else {
          final currentCount = (snapshot.data() as Map<String, dynamic>)['count'] ?? 0;
          transaction.update(docRef, {'count': currentCount + 1});
        }
      });
    }

    // Update last message time for sorting
    await FirebaseFirestore.instance.collection("chatrooms").doc(roomId).update({
      'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
    });
  } catch (e) {
    debugPrint('Error updating unread count: $e');
  }
}

// Add this method to your ChatRoom class
void resetUnreadCounter(String roomId) async {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId != null) {
    await updateUnreadCount(roomId, currentUserId, reset: true);
  }
}

Widget _buildErrorMessage(String error) {
  return Center(
    child: Text('Error: $error', style: GoogleFonts.archivo(color: Colors.red)),
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
  final bool isDesktop;
  final bool isTablet;

  const ChatRoomTile({
    super.key,
    required this.username,
    required this.roomId,
    required this.svg,
    this.isHighlighted = false,
    required this.unreadMessages,
    required this.receiverId,
    required this.lastMessageTime,
    required this.isDesktop,
    required this.isTablet,
  });

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildMessageCounter(int count) {
    return Container(
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(
        minWidth: 24,
        minHeight: 24,
      ),
      decoration: BoxDecoration(color: HexColor("#5953ff"), shape: BoxShape.circle),
      child: Center(
        child: Text(
          count >= 10 ? '9+' : count.toString(),
          style: GoogleFonts.archivo(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: svg != null && svg!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: svg!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    color: Colors.white,
                  ),
                ),
                errorWidget: (context, url, error) => CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.person, color: Colors.white, size: 30),
                ),
              )
            : CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, color: Colors.white, size: 30),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(roomId)
          .collection("chats")
          .orderBy("time", descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        String lastMessage = "";
        DateTime messageTime = lastMessageTime;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final latestMessage = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          messageTime = DateTime.fromMillisecondsSinceEpoch(latestMessage['time']);

          if (latestMessage['isImage'] == true) {
            lastMessage = "📷 Image";
          } else if (latestMessage['isFile'] == true) {
            lastMessage = "📎 File";
          } else {
            lastMessage = latestMessage['message'] ?? "";
          }
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("chatrooms")
              .doc(roomId)
              .collection("unreadCount")
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .snapshots(),
          builder: (context, unreadSnapshot) {
            int unreadCount = 0;
            if (unreadSnapshot.hasData && unreadSnapshot.data!.exists) {
              unreadCount = (unreadSnapshot.data!.data() as Map<String, dynamic>)['count'] ?? 0;
            }

            return Container(
              margin: EdgeInsets.symmetric(
                vertical: 4,
                horizontal: isTablet ? 8 : 16,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? HexColor("#262630") : Colors.white,
                borderRadius: BorderRadius.circular(isTablet ? 15 : 20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 8 : 16,
                  vertical: isTablet ? 4 : 8,
                ),
                onTap: () {
                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                  if (currentUserId != null) {
                    updateUnreadCount(roomId, currentUserId, reset: true);
                  }

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
                leading: SizedBox(
                  width: isTablet ? 40 : 48,
                  height: isTablet ? 40 : 48,
                  child: _buildProfileImage(),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        username,
                        style: GoogleFonts.archivo(
                          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                          fontSize: isTablet ? 14 : 16,
                        ),
                      ),
                    ),
                    Text(
                      _getTimeAgo(messageTime),
                      style: GoogleFonts.archivo(
                        color: Colors.grey,
                        fontSize: isTablet ? 10 : 12,
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  lastMessage,
                  style: GoogleFonts.archivo(
                    color: Colors.grey,
                    fontSize: isTablet ? 10 : 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: unreadCount > 0 ? _buildMessageCounter(unreadCount) : null,
              ),
            );
          },
        );
      },
    );
  }
}
