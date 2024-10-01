import 'package:chat_app/services/constants.dart';
import 'package:chat_app/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_pagination/firebase_pagination.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:random_avatar/random_avatar.dart';

import 'chat_room.dart';

class GCConversation extends StatefulWidget {
  final String gcName;
  final String svg;
  final Map data;
  final String gcId;
  final int createdAt;
  final String createdBy;
  const GCConversation({super.key, required this.gcId, required this.svg, required this.gcName, required this.data, required this.createdAt, required this.createdBy});

  @override
  State<GCConversation> createState() => _GCConversationState();
}

class _GCConversationState extends State<GCConversation> {
  final DatabaseMethods _databaseMethods = DatabaseMethods();
  final TextEditingController _messageController = TextEditingController();
  Stream? streamForInitialMessages;
  DateTime now = DateTime.now();

  Widget paginate() {
    return FirestorePagination(
      reverse: true,
      isLive: true,
      query: FirebaseFirestore.instance
          .collection("gc")
          .doc(widget.gcId)
          .collection("chats")
          .orderBy("time", descending: true),
      itemBuilder: (context, docs, index) {
        final data = (docs)[index].data() as Map<String, dynamic>;
        return GCMessagTile(
          gcId: widget.gcId,
          userSvg: (widget.data)[data["sender"]],
          chatId: docs[index].id,
          gcName: widget.gcName,
          message: data["message"],
          sender: data["sender"],
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


  sendMessage() async {
    String date = "${now.day}/${now.month}/${now.year}";
    Map<String, dynamic> userMap = {
      "message": _messageController.text.trim(),
      "sender": Constants.localUsername,
      "time": DateTime.now().millisecondsSinceEpoch,
      "date": date,
      "deleted": false,
      "seen": [Constants.localUsername]
    };
    setState(() {
      _messageController.text = "";
    });
    await _databaseMethods.gcConversation(widget.gcId, userMap).then((a) {
      print("done: $a");
    });
  }

  Widget groupInfo(){
    return Container(
    decoration: BoxDecoration(
        color: HexColor("#262630"),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20))
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            child: Text(
              "Created by",
              style: GoogleFonts.archivo(
                  color: Colors.white,
                  fontSize: 20
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            child: Text(
              "At ${
                  DateFormat('yyyy-MM-dd, kk:mm').format(
                      DateTime.fromMillisecondsSinceEpoch(widget.createdAt)
                  )
              }",
              style: GoogleFonts.archivo(
                  color: Colors.white,
                  fontWeight: FontWeight.w100,
                  fontSize: 12
              ),
            ),
          ),
          const SizedBox(height: 5),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              RandomAvatar(
                  (widget.data)[widget.createdBy],
                  height: 30
              ),
              // const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  widget.createdBy,
                  style: GoogleFonts.archivo(
                      color: Colors.white,
                      fontSize: 18
                  ),
                ),
              )
            ],
          ),
        ),
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            child: Text(
              "Group Members",
              style: GoogleFonts.archivo(
                  color: Colors.white,
                  fontSize: 20
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: ((widget.data).keys).toList().length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      RandomAvatar(
                          ((widget.data).values).toList()[index],
                        height: 30
                      ),
                      // const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Text(
                          (((widget.data).keys).toList())[index].toString(),
                          style: GoogleFonts.archivo(
                              color: Colors.white,
                            fontSize: 18
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      appBar: AppBar(
        toolbarHeight: 80,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: IconButton(onPressed: (){
              showModalBottomSheet(
                context: context,
                backgroundColor: HexColor("#262630"),
                builder: (BuildContext context) {
                  return groupInfo();
                },
              );
              },
                icon: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                )),
          )
        ],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            RandomAvatar(widget.svg, height: 40, width: 40),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                widget.gcName,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.archivo(color: Colors.white, fontSize: 20),
              ),
            )
          ],
        ),
        leading: GestureDetector(
            onTap: () => Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const ChatRoom())),
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
            // const SizedBox(height: 10),
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





class GCMessagTile extends StatefulWidget {
  final String message;
  final bool sentByLocalUser;
  final bool deleted;
  final DateTime time;
  // final bool deleted;
  final String gcName;
  final String chatId;
  final String sender;
  final String userSvg;
  final String gcId;
  const GCMessagTile(
      {required this.chatId,
      required this.gcId,
        // required this.seen,
        required this.gcName,
        required this.message,
        required this.sentByLocalUser,
        required this.time,
        required this.deleted,
        required this.sender,
        required this.userSvg,
        // required this.deleted,
        super.key});

  @override
  State<GCMessagTile> createState() => _GCMessagTileState();
}

class _GCMessagTileState extends State<GCMessagTile> {
  bool onTap = false;
  final DatabaseMethods _database = DatabaseMethods();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: widget.sentByLocalUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if(!widget.sentByLocalUser) Column(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 10),
              child: RandomAvatar(
                  widget.userSvg,
                height: 30
              ),
            ),
            const SizedBox(height: 10)
          ],
        ),
        Column(
          crossAxisAlignment: !widget.sentByLocalUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: widget.sentByLocalUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (onTap)
                  GestureDetector(
                      onTap: () async {
                        await FirebaseFirestore.instance.collection("gc").doc(widget.gcId).collection("chats").doc(widget.chatId).update({
                          "deleted" : true
                        })
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
                                0.60, // 90% of screen width
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
                                    "message unavailable",
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
                              // Text(widget.deleted.toString())
                              // SizedBox(
                              //   // width: MediaQuery.of(context).size.width,
                              //   child: Row(
                              //     mainAxisSize: MainAxisSize.min,
                              //     children: [
                              //
                              //       const SizedBox(width: 5),
                              //       // Icon(
                              //       //   FontAwesomeIcons.check,
                              //       //   color: (widget.seen == false)
                              //       //       ? Colors.white
                              //       //       : Colors.lightBlueAccent,
                              //       //   size: 12,
                              //       // )
                              //     ],
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // const SizedBox(height: 5)
                  ],
                ),
              ],
            ),
            Align(
              alignment: widget.sentByLocalUser
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Text(
                widget.sentByLocalUser ? "${DateFormat("HH:mm").format(widget.time)} · ${widget.sender}" : "${widget.sender} · ${DateFormat("HH:mm").format(widget.time)}",
                style: GoogleFonts.archivo(
                    color: Colors.white, fontSize: 10),
              ),
            )
          ],
        ),
      ],
    );
  }
}
