import 'package:chat_app/services/constants.dart';
import 'package:chat_app/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_pagination/firebase_pagination.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:random_avatar/random_avatar.dart';

class Conversation extends StatefulWidget {
  final roomId;
  final name;
  final svg;
  const Conversation(
      {required this.roomId, required this.svg, required this.name, super.key});

  @override
  State<Conversation> createState() => _ConversationState();
}

class _ConversationState extends State<Conversation> {
  final DatabaseMethods _databaseMethods = DatabaseMethods();
  final TextEditingController _messageController = TextEditingController();
  Stream? streamForInitialMessages;
  DateTime now = DateTime.now();

  int unreadMessages = 0;


  Widget paginate() {
    return FirestorePagination(
      reverse: true,
      isLive: true,
      query: FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(widget.roomId)
          .collection("chats")
          .orderBy("time", descending: true),
      itemBuilder: (context, docs, index) {
        final data = (docs)[index].data() as Map<String, dynamic>;
        if (data.isNotEmpty) {
          final documents = docs;
          final notSeenDocs = [];

          print(documents.length);
          for (var i = 0; i < documents.length; i++) {
            if ((((documents[i].data() as Map<String, dynamic>))["seen"] ==
                    false) &&
                (((documents[i].data() as Map<String, dynamic>))["sender"] !=
                    Constants.localUsername)) {
              notSeenDocs.add((documents[i]).id.toString());
              _databaseMethods.updateSeen(
                  widget.roomId, (documents[i]).id.toString(), true);
              _databaseMethods.updateUnreadMessages(
                  widget.roomId, 0, Constants.localUsername);
            }
            _databaseMethods.updateSeen(widget.roomId, (documents[i]).id.toString(), true);
          }
        }
        return MessageTile(
          chatId: docs[index].id,
          seen: (data["seen"] != null) ? data["seen"] : true,
          roomId: widget.roomId,
          message: data["message"],
          sentByLocalUser:
              (data["sender"].toString() == Constants.localUsername)
                  ? true
                  : false,
          time: DateTime.fromMillisecondsSinceEpoch(
              int.parse((data["time"]).toString())),
          deleted: (data["deleted"] == null) ? false : (data["deleted"]),
        );
      },
    );
  }

  // Widget chatList(){
  //   return StreamBuilder(
  //       stream: streamForInitialMessages,
  //       builder: (context, snapshot){
  //         if(snapshot.hasData){
  //           final documents = snapshot.data!.docs;
  //           final notSeenDocs = [];
  //
  //           for(var i = 0; i < documents.length; i++){
  //             if((((documents[i]).data())["seen"] == false) && (((documents[i]).data())["sender"] != Constants.localUsername)){
  //               notSeenDocs.add((documents[i] as DocumentSnapshot).id.toString());
  //               _databaseMethods.updateSeen(widget.roomId, (documents[i] as DocumentSnapshot).id.toString(), true);
  //               _databaseMethods.updateUnreadMessages(widget.roomId, 0, Constants.localUsername);
  //             }
  //
  //             //print(notSeenDocs);
  //             // _databaseMethods.updateSeen(widget.roomId, (documents[i] as DocumentSnapshot).id.toString(), true);
  //           }
  //         }
  //         return snapshot.hasData ? ListView.builder(
  //           itemCount: snapshot.data.docs.length,
  //           itemBuilder: (context, index){
  //             return MessageTile(
  //               seen: ((snapshot.data.docs[index].data())["seen"] != null) ? (snapshot.data.docs[index].data())["seen"] : true,
  //               roomId: widget.roomId,
  //               chatId: (snapshot.data!.docs[index] as DocumentSnapshot).id.toString(),
  //               message: (snapshot.data.docs[index].data())["message"],
  //               sentByLocalUser: (((snapshot.data.docs[index].data())["sender"]).toString() == Constants.localUsername ) ? true : false,
  //               time: DateTime.fromMillisecondsSinceEpoch(int.parse(
  //                   ((snapshot.data.docs[index].data())["time"]).toString()
  //               )),
  //               deleted: ((snapshot.data.docs[index].data()["deleted"]) == null )
  //               ? false : (snapshot.data.docs[index].data()["deleted"]),
  //
  //             );
  //           },
  //         ) : Center(child: CircularProgressIndicator(color: HexColor("#5953ff"),));
  //       }
  //   );
  // }

  sendMessage() async {
    // String formattedTime = DateFormat('HH:mm').format(now);
    String date = "${now.day}/${now.month}/${now.year}";
    Map<String, dynamic> userMap = {
      "message": _messageController.text.trim(),
      "sender": Constants.localUsername,
      "time": DateTime.now().millisecondsSinceEpoch,
      "date": date,
      "deleted": false,
      "seen": false
    };
    setState(() {
      _messageController.text = "";
      unreadMessages++;
      print(unreadMessages);
    });
    await _databaseMethods.conversation(widget.roomId, userMap).then((a) {
      print("done: $a");
    });
    await _databaseMethods.updateUnreadMessages(
        widget.roomId, unreadMessages, widget.name);
  }

  @override
  void initState() {
    // getInitialMessages();
    super.initState();
  }

  getInitialMessages() async {
    _databaseMethods.getConversation(widget.roomId).then((val) {
      setState(() {
        streamForInitialMessages = val;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HexColor("#131419"),
      appBar: AppBar(
        toolbarHeight: 80,
        title: Container(
          // margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              RandomAvatar(widget.svg, height: 45, width: 45),
              const SizedBox(width: 15),
              Text(
                widget.name,
                style: GoogleFonts.archivo(color: Colors.white, fontSize: 20),
              )
            ],
          ),
        ),
        leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_outlined, color: Colors.white)),
        backgroundColor: HexColor("#262630"),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            SizedBox(
                height: MediaQuery.of(context).size.height / 1.5,
                child: paginate()),
            // SizedBox(
            //   height: MediaQuery.of(context).size.height/1.5,
            //     child: chatList()
            // ),
            Container(
              alignment: Alignment.bottomCenter,
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                          color: HexColor("#262630"),
                          borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(10))),
                      child: TextFormField(
                          style: GoogleFonts.archivo(color: Colors.white),
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: "Write a message",
                            hintStyle: GoogleFonts.archivo(),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                          )),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: () {
                        sendMessage();
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                            // color: HexColor("#d7dfa3"),
                            color: HexColor("#1d1d29"),
                            // color: HexColor("#262630"),
                            borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(10))),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class MessageTile extends StatefulWidget {
  final String message;
  final bool sentByLocalUser;
  final DateTime time;
  final bool deleted;
  final String roomId;
  final String chatId;
  final bool seen;
  const MessageTile(
      {required this.chatId,
      required this.seen,
      required this.roomId,
      required this.message,
      required this.sentByLocalUser,
      required this.time,
      required this.deleted,
      super.key});

  @override
  State<MessageTile> createState() => _MessageTileState();
}

class _MessageTileState extends State<MessageTile> {
  bool onTap = false;
  final DatabaseMethods _database = DatabaseMethods();

  @override
  Widget build(BuildContext context) {
    // return Row(
    //   mainAxisAlignment: widget.sentByLocalUser ? MainAxisAlignment.end : MainAxisAlignment.start,
    //   children: [
    //     if(onTap) GestureDetector(
    //       onTap: () async{
    //         await _database.updateDeleted(widget.roomId, widget.chatId, true).then((val){
    //           print("successfully deleted");
    //           setState(() {
    //             onTap = !onTap;
    //           });
    //         });
    //       },
    //         child: const Icon(Icons.delete_forever, color: Colors.white,
    //         )),
    //     if(onTap) const SizedBox(width: 5),
    //     Column(
    //       children: [
    //         GestureDetector(
    //           onTap: (){
    //             if(widget.sentByLocalUser && !widget.deleted){
    //               setState(() {
    //                 onTap = !onTap;
    //               });
    //             }
    //           },
    //           child: Align(
    //             alignment: widget.sentByLocalUser ? Alignment.centerRight : Alignment.centerLeft,
    //             child: Container(
    //               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    //               margin: const EdgeInsets.symmetric(vertical: 5),
    //               decoration: BoxDecoration(
    //                 borderRadius: widget.sentByLocalUser ? const BorderRadius.only(
    //                     topLeft: Radius.circular(15),
    //                     topRight: Radius.circular(15),
    //                     bottomLeft: Radius.circular(15)
    //                 ) : const BorderRadius.only(
    //                     topLeft: Radius.circular(15),
    //                     topRight: Radius.circular(15),
    //                     bottomRight: Radius.circular(15)
    //                 ),
    //                   color: widget.sentByLocalUser ? HexColor("#5953ff") : HexColor("#2e333d")
    //               ),
    //               child: Column(
    //                 crossAxisAlignment: widget.sentByLocalUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
    //                 children: [
    //                   Row(
    //                     mainAxisSize: MainAxisSize.min,
    //                     children: [
    //                       if(widget.deleted) const Icon(Icons.disabled_by_default_outlined, color: Colors.white54,),
    //                       Text(
    //                         widget.deleted ?  "This message has been deleted" : widget.message,
    //                         overflow: TextOverflow.visible,
    //                         maxLines: null,
    //                         style: GoogleFonts.archivo(
    //                           color: widget.deleted ? Colors.white54 : Colors.white,
    //                           fontSize: widget.deleted ? 14 : 16,
    //                           fontStyle: widget.deleted ? FontStyle.italic : FontStyle.normal
    //                         ),
    //                       ),
    //                     ],
    //                   ),
    //                   Row(
    //                     children: [
    //                       Text(
    //                         DateFormat("HH:mm").format(widget.time),
    //                         style: GoogleFonts.archivo(
    //                           color: Colors.white,
    //                           fontSize: 10
    //                         ),
    //                       ),
    //                       const SizedBox(width: 5),
    //                       Icon(
    //                           FontAwesomeIcons.check,
    //                         color: (widget.seen == false) ? Colors.white : Colors.lightBlueAccent,
    //                         size: 12,
    //                       )
    //                     ],
    //                   ),
    //                 ],
    //               ),
    //             ),
    //           ),
    //         ),
    //         const SizedBox(height: 5)
    //       ],
    //     ),
    //   ],
    // );

    return Row(
      mainAxisAlignment: widget.sentByLocalUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (onTap)
          GestureDetector(
              onTap: () async {
                await _database
                    .updateDeleted(widget.roomId, widget.chatId, true)
                    .then((val) {
                  print("successfully deleted");
                  setState(() {
                    onTap = !onTap;
                  });
                });
              },
              child: const Icon(
                Icons.delete_forever,
                color: Colors.white,
              )),
        if (onTap) const SizedBox(width: 5),
        Column(
          children: [
            GestureDetector(
              onTap: () {
                if (widget.sentByLocalUser && !widget.deleted) {
                  setState(() {
                    onTap = !onTap;
                  });
                }
              },
              child: Align(
                alignment: widget.sentByLocalUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width *
                        0.80, // 90% of screen width
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                      borderRadius: widget.sentByLocalUser
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                              bottomLeft: Radius.circular(15))
                          : const BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                              bottomRight: Radius.circular(15)),
                      color: widget.sentByLocalUser
                          ? HexColor("#5953ff")
                          : HexColor("#2e333d")),
                  child: Column(
                    crossAxisAlignment: widget.sentByLocalUser
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    children: [
                     widget.deleted ? Row(
                       children: [
                         const Icon(Icons.disabled_by_default_outlined, color: Colors.white54,),
                         const SizedBox(width: 5),
                         Text(
                           "This message has been deleted",
                            overflow: TextOverflow.visible,
                            maxLines: null,
                            style: GoogleFonts.archivo(
                                color: Colors.white54,
                                fontSize: 13,
                                fontStyle: widget.deleted
                                    ? FontStyle.italic
                                    : FontStyle.normal),
                          ),
                       ],
                     ) : Text(
                        widget.message,
                        overflow: TextOverflow.visible,
                        maxLines: null,
                        style: GoogleFonts.archivo(
                            color:
                            widget.deleted ? Colors.white54 : Colors.white,
                            fontSize: widget.deleted ? 14 : 16,
                            fontStyle: widget.deleted
                                ? FontStyle.italic
                                : FontStyle.normal),
                      ),
                      const SizedBox(height: 3),
                      SizedBox(
                        // width: MediaQuery.of(context).size.width,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat("HH:mm").format(widget.time),
                              style: GoogleFonts.archivo(
                                  color: Colors.white, fontSize: 10),
                            ),
                            const SizedBox(width: 5),
                            Icon(
                              FontAwesomeIcons.check,
                              color: (widget.seen == false)
                                  ? Colors.white
                                  : Colors.lightBlueAccent,
                              size: 12,
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5)
          ],
        ),
      ],
    );
  }
}
