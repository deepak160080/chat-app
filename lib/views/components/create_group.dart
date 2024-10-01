import 'package:chat_app/services/constants.dart';
import 'package:chat_app/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:random_avatar/random_avatar.dart';
import 'dart:math';

import 'gc_conversation.dart';

class CreateGroup extends StatefulWidget {
  CreateGroup({super.key});
  @override
  State<CreateGroup> createState() => _CreateGroupState();
}

List groupList = [];
List<int> selectedIndices = [];

Map tempMapToUpdateState = {};

class _CreateGroupState extends State<CreateGroup> {
  bool _isLoading = false;
  String svg = DateTime.now().toIso8601String();
  final DatabaseMethods _database = DatabaseMethods();
  final _groupNameController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  Stream? chatRoomStream;

  void initState() {
    getUserData();
    super.initState();
  }

  String generateRandomString(int length) {
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  getUserData() async {
    await Future.delayed(const Duration(seconds: 1));
    await _database.getChatRooms(Constants.localUsername).then((val) {
      setState(() {
        chatRoomStream = val;
        print(val);
      });
    });
    // print(Constants.localUsername);
  }

  createGC() async {
    // print(groupList.length)
    if (formKey.currentState!.validate() && groupList.isNotEmpty) {
      print("working");
      Map<String, dynamic> userData = {};
      List groupMembers = [];

      Map dataMap = {};
      // print(groupList);
      for (var i = 0; i < (groupList).length; i++) {
        // username and svg String
        String name = (groupList[i]["users"][1] != Constants.localUsername
            ? groupList[i]["users"][1]
            : groupList[i]["users"][0]);
        String userSvg = (groupList[i]["userSvg"][1] != Constants.localSvg
            ? groupList[i]["userSvg"][1]
            : groupList[i]["userSvg"][0]);

        //Map of "user: svg" key value pair, latter to be pushed to [data] key in userData final map.
        dataMap[name] = userSvg;
        groupMembers.add(groupList[i]["users"][1] != Constants.localUsername
            ? groupList[i]["users"][1]
            : groupList[i]["users"][0]);
      }

      dataMap[Constants.localUsername] = Constants.localSvg;
      groupMembers.add(Constants.localUsername);
      userData["data"] = dataMap;
      userData["users"] = groupMembers;
      userData["svg"] = svg;

      userData["gcName"] = _groupNameController.text.trim();
      userData["createdBy"] = Constants.localUsername;
      userData["createdAt"] = DateTime.now().millisecondsSinceEpoch;
      print(userData);
      setState(() {
        _isLoading = true;
      });

      String randomString = generateRandomString(10);

      await _database
          .createGC("${_groupNameController.text.trim()}#$randomString", userData)
          .then((_) {
        print("successfully sent data to server");
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => GCConversation(
                      createdBy: Constants.localUsername,
                      createdAt: DateTime.now().millisecondsSinceEpoch,
                      gcName: _groupNameController.text.trim(),
                      svg: svg,
                      data: dataMap,
                  gcId: "${_groupNameController.text.trim()}#$randomString",
                    )));
      }).catchError((e) {
        print(e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      appBar: AppBar(
        toolbarHeight: 60,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _isLoading ? "" : "Create Group",
            style: GoogleFonts.archivo(color: Colors.white, fontSize: 20),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: IconButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return UpdateableBottomSheet(
                        onAddUpdateState: () {
                          setState(() {
                            groupList.add(tempMapToUpdateState);
                          });
                        },
                      );
                    },
                  );
                },
                icon: const Icon(
                  Icons.search,
                  color: Colors.white,
                )),
          )
        ],
        leading: !_isLoading
            ? GestureDetector(
                onTap: () => Navigator.pop(context),
                child:
                    const Icon(Icons.arrow_back_outlined, color: Colors.white))
            : const SizedBox(),
        backgroundColor: HexColor("#262630"),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      // const SizedBox(height: 20),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Column(
                              // mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 10),
                                //for alignment
                                Opacity(
                                  opacity: 0,
                                  child: GestureDetector(
                                    onTap: changeAvatar,
                                    child: const Icon(
                                      Icons.refresh_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                RandomAvatar(svg,
                                    height:
                                        MediaQuery.of(context).size.height / 10),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: changeAvatar,
                                  child: const Icon(
                                    Icons.refresh_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
                              child: Container(
                                height: 55,
                                margin:
                                    const EdgeInsets.only(left: 20, right: 10),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                    color: HexColor("#262630"),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Form(
                                        key: formKey,
                                        child: TextFormField(
                                            validator: (val) {
                                              if (val!.isEmpty) {
                                                return "Please type a group name";
                                              }
                                              return null;
                                            },
                                            style: GoogleFonts.archivo(
                                                color: Colors.white),
                                            controller: _groupNameController,
                                            decoration: InputDecoration(
                                              hintText: "Enter group name",
                                              hintStyle: GoogleFonts.archivo(),
                                              border: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              errorBorder: InputBorder.none,
                                              disabledBorder: InputBorder.none,
                                            )),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                          height: groupList.isEmpty
                              ? MediaQuery.of(context).size.height * .60
                              : MediaQuery.of(context).size.height * .45,
                          child: chatRoomList()),
                      // const SizedBox(height: 60),
                    ],
                  ),
                ),
                //second stack widget
                groupList.isEmpty
                    ? Container()
                    : Positioned(
                        bottom: 0, // Position at the bottom
                        left: 0,
                        right: 0,
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          color: HexColor("#262630"),
                          height: 90, // Height of the bottom widget
                          width: MediaQuery.of(context).size.width * .8,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * .75,
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: groupList.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      return SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.only(
                                                  top: 10,
                                                  right: 5,
                                                  left: 5,
                                                  bottom: 5),
                                              child: Stack(
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        print(selectedIndices);
                                                        selectedIndices.remove(
                                                            groupList[index]
                                                                ["index"]);
                                                        groupList.remove(
                                                            groupList[index]);
                                                        print(selectedIndices);
                                                      });
                                                    },
                                                    child: RandomAvatar(
                                                        Constants.localSvg !=
                                                                (groupList[index])[
                                                                        "userSvg"]
                                                                    [0]
                                                            ? (groupList[
                                                                    index])[
                                                                "userSvg"][0]
                                                            : (groupList[
                                                                    index])[
                                                                "userSvg"][1],
                                                        height: 40),
                                                  ),
                                                  Transform.translate(
                                                    offset:
                                                        const Offset(20, -10),
                                                    child: Container(
                                                        decoration: BoxDecoration(
                                                            color: Colors.red,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        100)),
                                                        child: const Icon(
                                                          Icons.remove,
                                                          color: Colors.white,
                                                          size: 20,
                                                        )),
                                                  )
                                                ],
                                              ),
                                            ),
                                            Text(
                                              Constants.localSvg ==
                                                      (groupList[index])[
                                                          "users"][0]
                                                  ? (groupList[index])["users"]
                                                      [0]
                                                  : (groupList[index])["users"]
                                                      [1],
                                              style: GoogleFonts.archivo(
                                                  color: Colors.white,
                                                  fontSize: 12),
                                            )
                                          ],
                                        ),
                                      );
                                    }),
                              ),
                              GestureDetector(
                                onTap: () {
                                  // List usefulGroupList = groupList;
                                  createGC();
                                  // for(var i = 0; i < usefulGroupList.length; i++){
                                  //   usefulGroupList[i].remove("unreadMessages");
                                  //   usefulGroupList[i].remove("chatRoomId");
                                  //   usefulGroupList[i].remove("users");
                                  //   // usefulGroupList[i].remove("index");
                                  // }
                                  //
                                  // print(usefulGroupList);

                                  /*[
                        {
                          userSvg: [2024-09-08T19:37:39.258255, 2024-09-12T00:12:05.198014],
                          unreadMessages: {rishiahuja: 0, daksh: 0},
                          chatRoomId: daksh_rishiahuja,
                          users: [rishiahuja, daksh],
                          index: 2
                      },
                      {
                        userSvg: [2024-09-08T19:37:39.258255, 2024-09-09T22:05:43.549268],
                        chatRoomId: dilpreet_rishiahuja,
                        users: [rishiahuja, dilpreet],
                        index: 3}
                      ]*/

                                  // List groupMembers = [];
                                  // List memberSvg = [];
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  margin: const EdgeInsets.only(left: 15),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    color: HexColor("#5953ff"),
                                  ),
                                  child: const Icon(
                                    Icons.send_sharp,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
              ],
            ),
    );
  }

  changeAvatar() {
    setState(() {
      svg = DateTime.now().toIso8601String();
      print(svg);
    });
  }

  //chatlist

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
                'No existing chatrooms, please adds users after clicking on search button at the top',
                style: GoogleFonts.archivo(color: Colors.white60),
              )),
            );
          }
          return ListView.builder(
            shrinkWrap: false,
            itemCount: snapshot.data.docs.length,
            itemBuilder: (context, index) {
              return selectedIndices.contains(index)
                  ? Container()
                  : ExistingTiles(
                      onAdd: () {
                        setState(() {
                          if (!selectedIndices.contains(index)) {
                            // print(groupList);
                            // print(index);
                            Map tempMap = snapshot.data.docs[index].data();
                            tempMap["index"] = index;
                            groupList.add(tempMap); // Add data to groupList
                            selectedIndices.add(index); // Track selected index
                          }
                        });
                      },
                      index: index,
                      indexMap: snapshot.data.docs[index].data(),
                      unreadMessages: ((snapshot.data.docs[index]
                                  .data())["unreadMessages"] !=
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
}

class ExistingTiles extends StatefulWidget {
  final String? username;
  final String? email;
  final String? roomId;
  final String? svg;
  final int? unreadMessages;
  final Map indexMap;
  final int index;
  final VoidCallback onAdd;

  ExistingTiles(
      {required this.unreadMessages,
      required this.username,
      this.email,
      required this.roomId,
      required this.svg,
      required this.indexMap,
      required this.index,
      required this.onAdd,
      super.key});

  @override
  State<ExistingTiles> createState() => _ExistingTilesState();
}

class _ExistingTilesState extends State<ExistingTiles> {
  @override
  Widget build(BuildContext context) {
    return selectedIndices.contains(widget.index)
        ? Container()
        : Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 10),
                      margin:
                          const EdgeInsets.only(top: 3, bottom: 3, left: 30),
                      height: 50,
                      decoration: BoxDecoration(
                          color: HexColor("#262630"),
                          borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(10))),
                      child: Row(
                        children: [
                          Row(
                            children: [
                              RandomAvatar(widget.svg!, height: 50, width: 52),
                              const SizedBox(width: 8),
                              Text(
                                widget.username!.trim(),
                                style: GoogleFonts.archivo(
                                    color: Colors.white, fontSize: 20),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: () {
                        // bool userExistsInListLocal = false;
                        // setState(() {
                        //   for(var i = 0; i < groupList.length; i++){
                        //     String users = groupList[i]["users"][0] != Constants.localUsername
                        //         ? groupList[i]["users"][0] : groupList[i]["users"][1];
                        //     print(users);
                        //     if(users == widget.username){
                        //       print("exists");
                        //       setState(() {
                        //         userExistsInListLocal = true;
                        //       });
                        //       ScaffoldMessenger.of(context).showSnackBar(
                        //         SnackBar(content: Text(
                        //             "The same user can't be added to the list twice, please add a different user",
                        //           style: GoogleFonts.archivo(
                        //             color: Colors.white
                        //           ),
                        //         ))
                        //       );
                        //     }
                        //     print("userExistsInList: ${userExistsInListLocal}");
                        //     if(userExistsInListLocal == false){
                        //       setState(() {
                        //         widget.onAdd();
                        //       });
                        //       print("added to the list");
                        //     }else{
                        //       print("user already exists in list");
                        //     }
                        //   }
                        // });
                        bool userExistsInList = false;

                        for (var i = 0; i < groupList.length; i++) {
                          String users = groupList[i]["users"][0] !=
                                  Constants.localUsername
                              ? groupList[i]["users"][0]
                              : groupList[i]["users"][1];
                          // print(users);
                          if (users == widget.username) {
                            setState(() {
                              userExistsInList = true;
                            });
                            print("exists");
                          }
                        }

                        print(userExistsInList);
                        if (!userExistsInList) {
                          setState(() {
                            widget.onAdd();
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                            "The user already exists, single user can't exit twice",
                            style: GoogleFonts.archivo(color: Colors.white),
                          )));
                        }
                        // print(groupList);
                      },
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 10),
                        margin:
                            const EdgeInsets.only(top: 3, bottom: 3, right: 30),
                        decoration: BoxDecoration(
                            color: HexColor("#5953ff"),
                            borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(10))),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ],
          );
  }
}

class UpdateableBottomSheet extends StatefulWidget {
  final VoidCallback onAddUpdateState;

  UpdateableBottomSheet({required this.onAddUpdateState});
  @override
  _UpdateableBottomSheetState createState() => _UpdateableBottomSheetState();
}

class _UpdateableBottomSheetState extends State<UpdateableBottomSheet> {
  int counter = 0; // Local state for the bottom sheet
  final searchController = TextEditingController();
  final DatabaseMethods _database = DatabaseMethods();
  bool userExistsInList = false;
  QuerySnapshot? querySnapshot;

  getUserDataList() async {
    await _database.searchUsersByName(searchController.text.trim()).then((val) {
      setState(() {
        querySnapshot = val;
      });

      if (querySnapshot!.docs.isEmpty) {
        print(querySnapshot!.docs.isEmpty);
        // setState(() {
        //   noResultFound = true;
        // });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          // color: HexColor("#262630"),
          color: Constants.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      padding: const EdgeInsets.all(20),
      // height: 400,
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // search bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                      color: HexColor("#262630"),
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(10))),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                            style: GoogleFonts.archivo(color: Colors.white),
                            controller: searchController,
                            decoration: InputDecoration(
                              hintText: "Search username",
                              hintStyle: GoogleFonts.archivo(),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                            )),
                      ),
                      const SizedBox(width: 15),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // print("searched");
                  getUserDataList();
                  setState(() {
                    userExistsInList = false;
                  });
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                      color: HexColor("#1d1d29"),
                      // color: HexColor("#262630"),
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(10))),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Expanded(
            child: querySnapshot == null
                ? Center(
                    child: Text(
                    'Please Start searching',
                    style: GoogleFonts.archivo(color: Colors.white),
                  )) // Handle empty state
                : ListView.builder(
                    itemCount: querySnapshot?.docs.length,
                    itemBuilder: (context, index) {
                      // Safely access the data
                      final data = querySnapshot?.docs[index].data()
                          as Map<String, dynamic>;
                      return Row(
                        children: [
                          Expanded(
                            flex: 8,
                            child: Container(
                              height: 50,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                              decoration: BoxDecoration(
                                  color: HexColor("#262630"),
                                  borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(10))),
                              child: Row(
                                children: [
                                  RandomAvatar(data["imageSvg"], height: 30),
                                  const SizedBox(width: 15),
                                  Text(
                                    data["name"],
                                    style: GoogleFonts.archivo(
                                        color: Colors.white),
                                  ),
                                ],
                              ), // Provide a default value
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: () {
                                for (var i = 0; i < groupList.length; i++) {
                                  String users = groupList[i]["users"][0] !=
                                          Constants.localUsername
                                      ? groupList[i]["users"][0]
                                      : groupList[i]["users"][1];
                                  print(users);
                                  if (users == data["name"]) {
                                    print("exists");
                                    setState(() {
                                      userExistsInList = true;
                                    });
                                  }
                                }
                                if (!userExistsInList) {
                                  setState(() {
                                    tempMapToUpdateState = {
                                      "userSvg": [
                                        Constants.localSvg,
                                        data["imageSvg"]
                                      ],
                                      "users": [
                                        Constants.localUsername,
                                        data["name"]
                                      ]
                                    };
                                  });
                                  widget.onAddUpdateState();
                                  print({
                                    "userSvg": [
                                      Constants.localSvg,
                                      data["imageSvg"]
                                    ],
                                    "users": [
                                      Constants.localUsername,
                                      data["name"]
                                    ]
                                  });
                                  Navigator.pop(context);
                                }
                              },
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                    color: HexColor("#5953ff"),
                                    borderRadius: const BorderRadius.horizontal(
                                        right: Radius.circular(10))),
                                child: GestureDetector(
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      );
                    },
                  ),
          ),
          if (userExistsInList)
            Text(
              "The user already exists in the list, single user can't exit twice",
              style: GoogleFonts.archivo(color: Colors.white),
            )
        ],
      ),
    );
  }

  Widget userTile(String email, String username, String svg) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            margin: const EdgeInsets.symmetric(vertical: 10),
            height: 80,
            decoration: BoxDecoration(
                color: HexColor("#262630"),
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(10))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: GoogleFonts.archivo(color: Colors.white, fontSize: 18),
                ),
                Text(
                  email,
                  style: GoogleFonts.archivo(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: GestureDetector(
            // onTap: () => createChatRoom(username, svg),
            child: Container(
                height: 80,
                decoration: BoxDecoration(
                    color: HexColor("#5953ff"),
                    borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(10))),
                child: const Icon(
                  Icons.email,
                  color: Colors.white,
                )),
          ),
        ),
      ],
    );
  }
}
