import 'package:chat_app/services/constants.dart';
import 'package:chat_app/services/database.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class Conversation extends StatefulWidget {
  final String roomId;
  final String svg;
  final String name;

  const Conversation({
    super.key,
    required this.roomId,
    required this.svg,
    required this.name,
  });

  @override
  _ConversationState createState() => _ConversationState();
}

class _ConversationState extends State<Conversation> {
  final DatabaseMethods _databaseMethods = DatabaseMethods();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  List<types.Message> _messages = [];
  late types.User _user;

  @override
  void initState() {
    super.initState();
    _user = types.User(id: Constants.localUsername);
    _loadMessages();
  }

  void _loadMessages() {
    FirebaseFirestore.instance
        .collection("conversations")
        .doc("${Constants.localUsername}_chat")
        .collection("chats")
        .orderBy("time", descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _messages = snapshot.docs.map((doc) {
          final data = doc.data();
          if (data['isImage'] == true) {
            return types.ImageMessage(
              author: types.User(id: data['sender']),
              id: doc.id,
              uri: data['imageUrl'],
              size: data['size'] ?? 0,
              name: data['fileName'] ?? '',
              createdAt: data['time'],
            );
          } else if (data['isFile'] == true) {
            return types.FileMessage(
              author: types.User(id: data['sender']),
              id: doc.id,
              name: data['fileName'] ?? '',
              size: data['size'] ?? 0,
              uri: data['fileUrl'],
              createdAt: data['time'],
            );
          } else {
            return types.TextMessage(
              author: types.User(id: data['sender']),
              id: doc.id,
              text: data['message'],
              createdAt: data['time'],
            );
          }
        }).toList();
      });
    });
  }

  Future<String?> _uploadFile(File file, String fileName) async {
    try {
      final ref = _storage.ref().child('chat_files/${DateTime.now().millisecondsSinceEpoch}_$fileName');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  void _handleSendPressed(types.PartialText message) {
    _sendMessage(message.text);
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: SizedBox(
            height: 144,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleImageSelection();
                  },
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Photo'),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleFileSelection();
                  },
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('File'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final fileSize = result.files.single.size;
      final fileUrl = await _uploadFile(file, fileName);

      if (fileUrl != null) {
        final message = types.PartialFile(
          name: fileName,
          size: fileSize,
          uri: fileUrl,
        );
        _sendMessage('', file: message);
      }
    }
  }

  void _handleImageSelection() async {
    final result = await _imagePicker.pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final file = File(result.path);
      final fileName = result.name;
      final imageUrl = await _uploadFile(file, fileName);

      if (imageUrl != null) {
        final bytes = await file.readAsBytes();
        final image = await decodeImageFromList(bytes);
        final message = types.PartialImage(
          height: image.height.toDouble(),
          name: fileName,
          size: bytes.length,
          uri: imageUrl,
          width: image.width.toDouble(),
        );
        _sendMessage('', image: message);
      }
    }
  }
String _sanitizeMessage(String message) {
    // Regular expressions for detecting sensitive information
    final phoneRegex = RegExp(r'\b\d{10}\b|\b\d{3}[-.]?\d{3}[-.]?\d{4}\b');
    final emailRegex = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    final linkRegex = RegExp(r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})');
    
    // List of abusive words (this list should be more comprehensive in a real application)
    final abuseWords = ['address', 'phone', 'email', 'social security', 'ssn', 'bank account', 'credit card', 'debit card', 'PIN', 'password', 'username', 'login', 'passport', 'ID', 'driver\'s license', 'birthdate', 'birthday', 'first name', 'last name', 'full name', 'home address', 'work address', 'school address', 'city', 'state', 'country', 'zip code', 'postal code', 'mobile number', 'landline', 'street', 'apartment', 'user ID', 'IP address', 'security question', 'mother\'s maiden name', 'medical record', 'health info', 'insurance number', 'social media', 'Facebook', 'Instagram', 'Twitter', 'TikTok', 'LinkedIn', 'Snapchat', 'YouTube', 'WhatsApp', 'Telegram', 'Discord']
;

    // Replace phone numbers
    message = message.replaceAllMapped(phoneRegex, (match) => '*' * match.group(0)!.length);

    // Replace email addresses
    message = message.replaceAllMapped(emailRegex, (match) => '*' * match.group(0)!.length);

    // Replace links, except Google Meet links
    message = message.replaceAllMapped(linkRegex, (match) {
      final link = match.group(0)!;
      if (link.contains('meet.google.com')) {
        return link;
      }
      return '*' * link.length;
    });

    // Replace abusive words
    for (final word in abuseWords) {
      final regex = RegExp(r'\b' + word + r'\b', caseSensitive: false);
      message = message.replaceAllMapped(regex, (match) => '*' * match.group(0)!.length);
    }

    return message;
  }

  void _sendMessage(String messageText, {types.PartialImage? image, types.PartialFile? file}) async {
    // Sanitize the message text
    final sanitizedMessageText = _sanitizeMessage(messageText);

    final messageMap = {
      "message": sanitizedMessageText,
      "sender": Constants.localUsername,
      "receiver": widget.name,
      "time": DateTime.now().millisecondsSinceEpoch,
      "date": "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
      "deleted": false,
      "seen": false,
    };

    if (image != null) {
      messageMap.addAll({
        "isImage": true,
        "imageUrl": image.uri,
        "fileName": image.name,
        "size": image.size,
      });
    } else if (file != null) {
      messageMap.addAll({
        "isFile": true,
        "fileUrl": file.uri,
        "fileName": file.name,
        "size": file.size,
      });
    }

    // Save in sender's conversation
    await FirebaseFirestore.instance
        .collection("conversations")
        .doc("${Constants.localUsername}_chat")
        .collection("chats")
        .add(messageMap);

    // Save in receiver's conversation
    await FirebaseFirestore.instance
        .collection("conversations")
        .doc("${widget.name}_chat")
        .collection("chats")
        .add(messageMap);

    await _databaseMethods.updateUnreadMessages(widget.roomId, 1, widget.name);
  }
  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (!message.uri.startsWith('file://')) {
        final client = http.Client();
        final request = await client.get(Uri.parse(message.uri));
        final bytes = request.bodyBytes;
        final documentsDir = (await getApplicationDocumentsDirectory()).path;
        localPath = '$documentsDir/${message.name}';

        if (!File(localPath).existsSync()) {
          final file = File(localPath);
          await file.writeAsBytes(bytes);
        }
      }

      await OpenFile.open(localPath);
    }
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            RandomAvatar(widget.svg, height: 40, width: 40),
            const SizedBox(width: 12),
            Text(widget.name),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/bg.png"),
            fit: BoxFit.contain,
          ),
        ),
        child: Chat(
          messages: _messages,
          onSendPressed: _handleSendPressed,
          user: _user,
          onAttachmentPressed: _handleAttachmentPressed,
          onMessageTap: _handleMessageTap,
          theme: DefaultChatTheme(
            backgroundColor: Colors.transparent,
            inputBackgroundColor: Colors.grey[800]!,
            
            secondaryColor: Colors.grey[700]!,
           
          ),
          customMessageBuilder: (types.Message message, {required int messageWidth}) {
            if (message is types.FileMessage) {
              return _buildFileMessagePreview(message);
            }
            if (message is types.CustomMessage) {
              // Handle custom messages if needed
              return _buildCustomMessagePreview(message);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildFileMessagePreview(types.FileMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${(message.size / 1024 / 1024).toStringAsFixed(2)} MB',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () => _handleMessageTap(context, message),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomMessagePreview(types.CustomMessage message) {
    // Handle custom messages if needed
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Custom Message',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
class MessageTile extends StatelessWidget {
  final String message;
  final bool sentByLocalUser;
  final DateTime time;
  final bool deleted;
  final String roomId;
  final String chatId;
  final bool seen;
  final bool isFile;
  final bool isImage;
  final String? fileName;
  final String? fileUrl;
  final String? imageUrl;
  final Function(String, String, bool) onDelete;

  const MessageTile({
    super.key,
    required this.chatId,
    required this.seen,
    required this.roomId,
    required this.message,
    required this.sentByLocalUser,
    required this.time,
    required this.deleted,
    required this.onDelete,
    this.isFile = false,
    this.isImage = false,
    this.fileName,
    this.fileUrl,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: sentByLocalUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        child: Card(
          color: sentByLocalUser ? HexColor("#5953ff") : HexColor("#2e333d"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(15),
              topRight: const Radius.circular(15),
              bottomLeft: Radius.circular(sentByLocalUser ? 15 : 5),
              bottomRight: Radius.circular(sentByLocalUser ? 5 : 15),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMessageContent(context),
                const SizedBox(height: 4),
                _buildMessageMeta(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    if (deleted) {
      return _buildDeletedMessage();
    } else if (isImage && imageUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl!,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      );
    } else {
      return _buildRegularMessage();
    }
  }

  Widget _buildDeletedMessage() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.disabled_by_default_outlined, color: Colors.white54, size: 16),
        const SizedBox(width: 5),
        Text(
          "This message has been deleted",
          style: GoogleFonts.archivo(
            color: Colors.white54,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

 Widget _buildRegularMessage() {
    return GestureDetector(
      onLongPress: sentByLocalUser && !deleted ? _showDeleteDialog : null,
      child: isFile
          ? Row(
              children: [
                const Icon(Icons.file_present, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message,
                    style: GoogleFonts.archivo(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            )
          : Text(
              message,
              style: GoogleFonts.archivo(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
    );
  }


  Widget _buildMessageMeta() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat("HH:mm").format(time),
          style: GoogleFonts.archivo(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 5),
        if (sentByLocalUser) _buildSeenIndicator(),
      ],
    );
  }

  Widget _buildSeenIndicator() {
    return Icon(
      FontAwesomeIcons.check,
      color: seen ? Colors.lightBlueAccent : Colors.white70,
      size: 12,
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: GlobalKey<NavigatorState>().currentState!.context,
      builder: (context) => AlertDialog(
        title: Text('Delete Message', style: GoogleFonts.archivo()),
        content: Text('Are you sure you want to delete this message?', style: GoogleFonts.archivo()),
        actions: [
          TextButton(
            child: Text('Cancel', style: GoogleFonts.archivo()),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Delete', style: GoogleFonts.archivo(color: Colors.red)),
            onPressed: () {
              onDelete(roomId, chatId, true);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}