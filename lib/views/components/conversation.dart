import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:virtualhelp_chat/services/constants.dart';
import 'package:virtualhelp_chat/services/database.dart';

class Conversation extends StatefulWidget {
  final String roomId;
  final String svg;
  final String name;
  final String receiverId;

  const Conversation({
    super.key,
    required this.roomId,
    required this.svg,
    required this.name,
    required this.receiverId,
  });

  @override
  State<Conversation> createState() => _ConversationState();
}

class _ConversationState extends State<Conversation> {
  final DatabaseMethods _databaseMethods = DatabaseMethods();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // final NotificationService _notificationService = NotificationService();
  XFile? _selectedImage;
  final List<String> _restrictedWords = [
    'address',
    'phone',
    'email',
    'social security',
    'ssn',
    'bank account',
    'credit card',
    'debit card',
    'PIN',
    'password',
    'username',
    'login',
    'passport',
    'ID',
    'driver\'s license',
    'birthdate',
    'birthday',
    'first name',
    'last name',
    'full name',
    'home address',
    'work address',
    'school address',
    'city',
    'state',
    'country',
    'zip code',
    'postal code',
    'mobile number',
    'landline',
    'street',
    'apartment',
    'user ID',
    'IP address',
    'security question',
    'mother\'s maiden name',
    'medical record',
    'health info',
    'insurance number',
    'social media',
    'Facebook',
    'Instagram',
    'Twitter',
    'TikTok',
    'LinkedIn',
    'Snapchat',
    'YouTube',
    'WhatsApp',
    'Telegram',
    'Discord'
  ];

  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // _initializeNotifications();
  }

  // void _initializeNotifications() async {
  //   // Request notification permissions
  //   await FirebaseMessaging.instance.requestPermission(
  //     alert: true,
  //     badge: true,
  //     sound: true,
  //   );

  //   // Save the user's FCM token
  //   await NotificationService.saveUserFCMToken(Constants.localId);

  //   // Handle incoming messages when app is in foreground
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     _notificationService.showLocalNotification(
  //       title: message.notification?.title ?? '',
  //       body: message.notification?.body ?? '',
  //     );
  //   });
  // }

  void _loadMessages() {
    FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(widget.roomId)
        .collection("chats")
        .orderBy("time", descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _messages = snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
      });
      _scrollToBottom();
      _updateUnseenMessages();
    });
  }

  Future<void> _updateMessageSeen(String messageId, String senderId) async {
    try {
      if (senderId != Constants.localId) {
        await FirebaseFirestore.instance
            .collection("chatrooms")
            .doc(widget.roomId)
            .collection("chats")
            .doc(messageId)
            .update({"seen": true});
      }
    } catch (e) {
      print('Error updating message seen status: $e');
    }
  }

  void _updateUnseenMessages() {
    for (var message in _messages) {
      _updateMessageSeen(message['id'], message['senderId']);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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

  // Add RegExp patterns for email and links
  final RegExp _emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
  final RegExp _linkRegex = RegExp(r'https?:\/\/(?!meet\.google\.com)[^\s]+');
  final RegExp _mobileNumberRegex = RegExp(r'\b\d{10}\b');

  String _filterContent(String content) {
    // Filter restricted words
    for (String word in _restrictedWords) {
      content = content.replaceAll(RegExp(r'\b' + word + r'\b', caseSensitive: false), '*' * word.length);
    }

    // Filter email addresses
    content = content.replaceAllMapped(_emailRegex, (match) => '*' * match.group(0)!.length);

    // Filter links except Google Meet
    content = content.replaceAllMapped(_linkRegex, (match) => '*' * match.group(0)!.length);

    // Filter mobile numbers
    content = content.replaceAllMapped(_mobileNumberRegex, (match) => '*' * match.group(0)!.length);

    return content;
  }

  Future<void> _sendMessage(String messageText,
      {String? fileUrl, String? fileName, bool isImage = false, bool isFile = false}) async {
    try {
      // Show loading indicator while sending
      if (isImage || isFile) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sending...')));
      }

      // Create the base message map
      final messageMap = {
        "message": messageText,
        "sender": Constants.localUsername,
        "senderId": Constants.localId,
        "receiver": widget.name,
        "receiverId": widget.receiverId,
        "time": DateTime.now().millisecondsSinceEpoch,
        "date": "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
        "deleted": false,
        "seen": false,
      };

      // Add file-related fields if a file is being sent
      if (fileUrl != null) {
        messageMap.addAll({
          "isFile": !isImage,
          "isImage": isImage,
          "fileUrl": fileUrl,
          "fileName": fileName!,
        });
      }

      await _databaseMethods.conversation(widget.roomId, messageMap);

      // Hide loading indicator
      if (isImage || isFile) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
    }
  }

  Future<File> _compressImage(File file) async {
    final img.Image? image = img.decodeImage(await file.readAsBytes());
    if (image == null) return file;

    final img.Image compressedImage = img.copyResize(
      image,
      width: 800, // Max width
      height: (800 * image.height / image.width).round(), // Maintain aspect ratio
    );

    final String dir = (await getTemporaryDirectory()).path;
    final String path = '$dir/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final File result = File(path)..writeAsBytesSync(img.encodeJpg(compressedImage, quality: 85));

    return result;
  }

  Future<String?> _generateThumbnail(String imageUrl) async {
    try {
      final File file = await _downloadFile(imageUrl);
      final File thumbnail = await _compressImage(file);
      return await _uploadFile(thumbnail, 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg');
    } catch (e) {
      print('Error generating thumbnail: $e');
      return null;
    }
  }

  Future<File> _downloadFile(String url) async {
    try {
      // Get temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = tempDir.path;

      // Create a unique filename
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.tmp';
      final String filePath = '$tempPath/$fileName';

      // Download the file
      final http.Response response = await http.get(Uri.parse(url));

      // Save to temporary file
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      return file;
    } catch (e) {
      print('Error downloading file: $e');
      rethrow;
    }
  }

  final List<String> _allowedDocumentExtensions = [
    'pdf',
    'doc',
    'docx',
    'txt',
    'rtf',
    'odt',
    'xls',
    'xlsx',
    'csv',
    'ppt',
    'pptx',
    'pages',
    'numbers',
    'key',
    'md'
  ];

// Add this validation function
  bool _isValidDocumentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return _allowedDocumentExtensions.contains(extension);
  }

  void _handleAttachmentPressed() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedDocumentExtensions,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileSize = await file.length();
        final fileSizeInMB = fileSize / (1024 * 1024);

        // Check file size (limit to 10MB)
        if (fileSizeInMB > 10) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size must be less than 10MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (!_isValidDocumentType(fileName)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select only document files. Audio, video, and other file types are not allowed.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Show file preview dialog
        if (mounted) {
          final bool? shouldSend = await showDialog<bool>(
            context: context,
            builder: (context) => _buildFilePreviewDialog(fileName, fileSizeInMB),
          );

          if (shouldSend == true) {
            // Show loading indicator
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Uploading document...')),
              );
            }

            final fileUrl = await _uploadFile(file, fileName);
            if (fileUrl != null) {
              await _sendMessage('', fileUrl: fileUrl, fileName: fileName, isFile: true);

              // Show success message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Document uploaded successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading document: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildFilePreviewDialog(String fileName, double fileSizeInMB) {
    return AlertDialog(
      title: Text('Send File?', style: GoogleFonts.archivo()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _getDocumentIcon(fileName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: GoogleFonts.archivo(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${fileSizeInMB.toStringAsFixed(2)} MB',
                      style: GoogleFonts.archivo(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ElevatedButton(
          child: const Text('Send'),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }

  Widget _getDocumentIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      case 'doc':
      case 'docx':
      case 'txt':
      case 'rtf':
      case 'odt':
        return const Icon(Icons.description, color: Colors.blue);
      case 'xls':
      case 'xlsx':
      case 'csv':
        return const Icon(Icons.table_chart, color: Colors.green);
      case 'ppt':
      case 'pptx':
        return const Icon(Icons.slideshow, color: Colors.orange);
      default:
        return const Icon(Icons.insert_drive_file, color: Colors.grey);
    }
  }

  void _handleImageSelection() async {
    final result = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      setState(() {
        _selectedImage = result;
      });

      // Show preview dialog
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => _buildImagePreviewDialog(result),
        );
      }
    }
  }

  Widget _buildImagePreviewDialog(XFile image) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text('Preview Image', style: GoogleFonts.archivo()),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(
                  File(image.path),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _uploadAndSendImage(image);
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadAndSendImage(XFile image) async {
    try {
      final file = File(image.path);
      final fileName = image.name;

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sending image...')),
        );
      }

      final imageUrl = await _uploadFile(file, fileName);
      if (imageUrl != null) {
        await _sendMessage('', fileUrl: imageUrl, fileName: fileName, isImage: true);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name, style: GoogleFonts.archivo()),

        // backgroundColor: Colors.blueGrey[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage("assets/images/bg.png"), fit: BoxFit.contain)),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final DateTime messageDate = DateTime.fromMillisecondsSinceEpoch(message["time"]);

                    // Show date header if it's the first message or if the date changes
                    bool showDateHeader = index == _messages.length - 1 ||
                        !_isSameDay(
                          DateTime.fromMillisecondsSinceEpoch(_messages[index + 1]["time"]),
                          messageDate,
                        );

                    return Column(
                      children: [
                        if (showDateHeader) _buildDateHeader(messageDate),
                        MessageBubble(
                          message: message["message"],
                          isMe: message["sender"] == Constants.localUsername,
                          timestamp: messageDate,
                          isImage: message["isImage"] ?? false,
                          isFile: message["isFile"] ?? false,
                          fileUrl: message["fileUrl"],
                          fileName: message["fileName"],
                          seen: message["seen"] ?? false,
                          id: message["id"],
                        ),
                      ],
                    );
                  },
                ),
              ),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _handleAttachmentPressed,
          ),
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _handleImageSelection,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "Type a message",
                border: InputBorder.none,
                filled: true,
                // fillColor: Colors.transparent,
              ),
              onChanged: (value) {
                final filteredText = _filterContent(value);
                if (filteredText != value) {
                  setState(() {
                    _messageController.text = filteredText;
                    _messageController.selection = TextSelection.fromPosition(
                      TextPosition(offset: filteredText.length),
                    );
                  });
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              final filteredMessage = _filterContent(_messageController.text);
              // Only send message if it's not empty after trimming whitespace
              if (filteredMessage.trim().isNotEmpty) {
                _sendMessage(filteredMessage);
              }
            },
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  Widget _buildDateHeader(DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            // color: Colors.black54,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getDateText(date),
            style: GoogleFonts.archivo(
              // color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _getDateText(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == DateTime(now.year, now.month, now.day)) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }
}

class MessageBubble extends StatefulWidget {
  final String message;
  final bool isMe;
  final DateTime timestamp;
  final bool isImage;
  final bool isFile;
  final String? fileUrl;
  final String? fileName;
  final bool seen;
  final String? id;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
    this.isImage = false,
    this.isFile = false,
    this.fileUrl,
    this.fileName,
    this.seen = false,
    required this.id,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isDownloading = false;
  final _transformationController = TransformationController();
  late TapDownDetails _doubleTapDetails;

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails.localPosition;
      _transformationController.value = Matrix4.identity()
        ..translate(-position.dx * 2, -position.dy * 2)
        ..scale(3.0);
    }
  }

  Widget _buildImagePreview(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImagePreview(context),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 200,
          maxHeight: 200,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            widget.fileUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200,
                height: 150,
                alignment: Alignment.center,
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 150,
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              child: GestureDetector(
                onDoubleTapDown: _handleDoubleTapDown,
                onDoubleTap: _handleDoubleTap,
                child: Image.network(
                  widget.fileUrl!,
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () {
                  _transformationController.value = Matrix4.identity();
                  Navigator.pop(context);
                },
              ),
            ),
            Positioned(
              bottom: 40,
              right: 20,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white, size: 30),
                    onPressed: _downloadAndOpenFile,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getDocumentIcon() {
    if (widget.fileName == null) return const Icon(Icons.insert_drive_file, color: Colors.white);

    final extension = widget.fileName!.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, color: Colors.white);
      case 'doc':
      case 'docx':
      case 'txt':
      case 'rtf':
      case 'odt':
        return const Icon(Icons.description, color: Colors.white);
      case 'xls':
      case 'xlsx':
      case 'csv':
        return const Icon(Icons.table_chart, color: Colors.white);
      case 'ppt':
      case 'pptx':
        return const Icon(Icons.slideshow, color: Colors.white);
      default:
        return const Icon(Icons.insert_drive_file, color: Colors.white);
    }
  }

  Future<void> _downloadAndOpenFile() async {
    if (_isDownloading) return;

    try {
      setState(() {
        _isDownloading = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading file...')),
      );

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String fileName = widget.fileName ?? 'downloaded_file';
      final String filePath = '${appDocDir.path}/$fileName';

      final response = await http.get(Uri.parse(widget.fileUrl!));
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      setState(() {
        _isDownloading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File downloaded to: $filePath'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading file: $e')),
      );
    }
  }

  Widget _buildContent() {
    if (widget.isImage && widget.fileUrl != null) {
      return _buildImagePreview(context);
    } else if (widget.isFile && widget.fileUrl != null) {
      return GestureDetector(
        onTap: _downloadAndOpenFile,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _isDownloading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : _getDocumentIcon(),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.fileName ?? 'Document',
                      style: GoogleFonts.archivo(),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Tap to download',
                      style: GoogleFonts.archivo(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Text(widget.message, style: GoogleFonts.archivo(color: Colors.white));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: widget.isMe ? const Color(0xff5953ff) : const Color(0xff12744f),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildContent(),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('h:mm a').format(widget.timestamp),
                    style: GoogleFonts.archivo(fontSize: 10, color: Colors.grey[100]),
                  ),
                  if (widget.isMe) ...[
                    const SizedBox(width: 4),
                    Text(
                      widget.seen ? "seen" : "sent",
                      style: GoogleFonts.archivo(
                        fontSize: 10,
                        color: Colors.blue[100],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}
