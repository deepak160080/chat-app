import 'package:chat_app/services/conversation_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods
{
  uploadUserInfo(Map<String, String> map){
    FirebaseFirestore.instance.collection("users").add(map);
  }
   Future<QuerySnapshot?> searchUsersByEmail(String email, String collectionName) async {
    return await FirebaseFirestore.instance
        .collection(collectionName)
        .where('email', isEqualTo: email)
        .get();
  }
Future<void> generateSearchKeywords(String userId, String username) async {
  // Convert the username to lowercase
  String lowercaseName = username.toLowerCase();
  
  // Generate keywords for the username
  List<String> keywords = [];
  String temp = "";
  
  // Generate substrings
  for (var i = 0; i < lowercaseName.length; i++) {
    temp = temp + lowercaseName[i];
    keywords.add(temp);
  }

Stream<Map<String, dynamic>> getLastMessage(String roomId) {
    return FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
      return {
        'lastMessage': snapshot.data()?['lastMessage'] ?? '',
        'lastMessageTime': snapshot.data()?['lastMessageTime']?.toDate() ?? DateTime.now(),
      };
    });
  }
  
  // Update the user document with the keywords
  await FirebaseFirestore.instance
      .collection('teachers')
      .doc(userId)
      .update({
    'searchKeywords': keywords,
  });
}
  searchUsersByName(String username) async{
    return await FirebaseFirestore.instance.collection("users").where("name", isEqualTo: username).get();
  }
   Future<QuerySnapshot> searchTeachersByName(String searchTerm) async {
    searchTerm = searchTerm.toLowerCase();
    return await FirebaseFirestore.instance
        .collection("teachers")
        .where("nameLower", isGreaterThanOrEqualTo: searchTerm)
        .where("nameLower", isLessThan: '${searchTerm}z')
        .get();
  }

   Future<void> conversation(String roomId, String documentName, Map<String, dynamic> userMap) async {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(roomId)
        .collection("chats")
        .doc(documentName)
        .set(userMap);
  }

   Future<void> conversationForStudent(String roomId, String documentName, Map<String, dynamic> messageMap) async {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(roomId)
        .collection("chats")
        .doc(documentName)
        .set(messageMap);
  }
   Future<void> conversationForTeacher(String roomId, String documentName, Map<String, dynamic> messageMap) async {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(roomId)
        .collection("chats")
        .doc(documentName)
        .set(messageMap);
  }

  
  
  createChatRoom(roomId, userMap) async{
    return await FirebaseFirestore.instance.collection("chatrooms").doc(roomId).set(userMap).catchError((e){
      print(e.toString());
    });
  }

  getConversation(String roomId) async{
    return FirebaseFirestore.instance.collection("chatrooms").doc(roomId).collection("chats").orderBy("time", descending: false).snapshots();
  }

  // conversation(String roomId, Map<String, dynamic> userMap) async{
  //   return await FirebaseFirestore.instance.collection("chatrooms").doc(roomId).collection("chats").add(userMap);
  // }

  gcConversation(String gcName, Map<String, dynamic> userMap) async{
    return await FirebaseFirestore.instance.collection("gc").doc(gcName).collection("chats").add(userMap);
  }

  getChatRooms(String username) async{
    return FirebaseFirestore.instance.collection("chatrooms").where("users", arrayContains: username).snapshots();
  }

  getGCs(String username) async{
    return FirebaseFirestore.instance.collection("gc").where("users", arrayContains: username).snapshots();
  }
  
  updateDeleted(String roomId, String chatId,  bool deleted) async{
    return await FirebaseFirestore.instance.collection("chatrooms").doc(roomId).collection("chats").doc(chatId).update({
      "deleted" : deleted
    });
  }

  updateSeen(String roomId, String chatId, bool seen) async{
    return await FirebaseFirestore.instance.collection("chatrooms").doc(roomId).collection("chats").doc(chatId).update({
      "seen" : seen
    });
  }

  updateUnreadMessages(String chatId, int messages, String receiver) async{
    return await FirebaseFirestore.instance.collection("chatrooms").doc(chatId).update({
      "unreadMessages.$receiver" : messages
    });
  }

  createGC(String groupName, Map<String, dynamic> userMap) async{
    return await FirebaseFirestore.instance.collection("gc").doc(groupName).set(userMap).catchError((e){
      print(e.toString());
    });
  }
}


class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get a stream of conversations for a user
  Stream<List<Conversation>> getConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: {'userId': userId})
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Conversation.fromFirestore(doc))
            .toList());
  }

  // Get a stream of messages for a conversation
  Stream<List<Message>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  // Send a new message
  Future<void> sendMessage(String conversationId, Message message) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(message.toMap());

    // Update last message and unread count
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': LastMessage(
        content: message.content,
        timestamp: message.timestamp,
        senderId: message.senderId,
      ).toMap(),
      'unreadCount.${message.senderId}': FieldValue.increment(1),
    });
  }

  // Create a new conversation
  Future<String> createConversation(Conversation conversation) async {
    DocumentReference docRef = await _firestore
        .collection('conversations')
        .add(conversation.toMap());
    return docRef.id;
  }

  // Mark messages as read
  Future<void> markAsRead(String conversationId, String userId) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'unreadCount.$userId': 0,
    });
  }
}