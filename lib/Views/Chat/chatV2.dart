import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat/dash_chat.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lit_beta/DBC/Auth.dart';
import 'package:lit_beta/Models/Chat.dart';
import 'package:uuid/uuid.dart';

class ChatPageV2 extends StatefulWidget{
  final ChatArgs args;
  ChatPageV2({this.args});
  @override
  _ChatPageStateV2 createState() => new _ChatPageStateV2();

}

class _ChatPageStateV2 extends State<ChatPageV2>{
  final GlobalKey<DashChatState> _chatKey = GlobalKey<DashChatState>();
  ChatUser user = ChatUser();
  final Auth db = Auth();

  @override
  void dispose(){
    super.dispose();
  }

  @override
  void initState() {
    user.name = widget.args.username;
    user.uid = widget.args.userID;
    super.initState();
  }

  void onSendMessage(ChatMessage msg) async{
    print(msg.toJson());
    print(widget.args.roomID);
    await db.sendMessageToRoom(widget.args.roomID, msg);
  }
  void uploadMedia() async {
    File result;
    final picker = ImagePicker();
    final pickedMedia = await picker.getImage(source: ImageSource.gallery , imageQuality: 80 , maxHeight: 400 , maxWidth: 400);
    if(pickedMedia != null){
      result = File(pickedMedia.path);
    }else{
      print('no media selected');
      return;
    }

    if(result != null){
      String id = Uuid().v4.toString();
      final StorageRef = db.dbMediaRef.ref().child(widget.args.roomID).child("images/$id.jpg");
      await StorageRef.putFile(result);
      String url = await StorageRef.getDownloadURL();
      ChatMessage msg = ChatMessage(text: "", user: user, image: url);
      db.sendMessageToRoom(widget.args.roomID, msg);

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: topbar(),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: chatLog(),
    );
    }

    //TODO ADD upload prompt to select source
  Widget chatLog(){
  return StreamBuilder(
    stream: db.getMessages(widget.args.roomID),
    builder: (context , log){
      if(!log.hasData){
        return progressIndicator();
      }else{
        List<DocumentSnapshot> messageSnapshots = log.data.docs;
        var messages = messageSnapshots.map((e) => ChatMessage.fromJson(e.data())).toList();
        return DashChat(
          inputToolbarPadding: EdgeInsets.all(5),
          inputCursorColor: Colors.black87,
          showInputCursor: true,
          user: user,
          messages: messages,
          showUserAvatar: true,
          showAvatarForEveryMessage: true,
          scrollToBottom: true,
          inputTextStyle: TextStyle(color: Colors.black),
          inputDecoration: InputDecoration(
            labelText: 'Say something...',
            hintText: "Say something...",
            border: InputBorder.none,
              labelStyle: TextStyle(
                  color: Colors.black87
              ),
          ),
          showTraillingBeforeSend: false,
         onSend: onSendMessage,
          sendButtonBuilder: (onSendMessage){
           return sendButtonBuilder(onSendMessage);
          },
          trailing: <Widget>[
            IconButton(icon: Icon(Icons.perm_media , color: Colors.black,), onPressed:()async{uploadMedia();}),
          ],
        );
      }
    }
  );
  }

  sendButtonBuilder(Function onSend) {
    return IconButton(
        icon: Icon(
            Icons.send,
            color: Colors.black
        ),
        onPressed: onSend
    );
  }
  Widget chatRoomTitle(String id){
    print(widget.args.visitedID);
    return StreamBuilder(
      stream: db.getUser(widget.args.visitedID),
      builder: (ctx , user){
        if(!user.hasData){
        return CircularProgressIndicator();
        }
        return Text(user.data['username'], style: TextStyle(color: Theme
            .of(context)
            .buttonColor),);
        },
    );
  }
  Widget topbar() {
    return AppBar(
      backgroundColor: Theme
          .of(context)
          .primaryColor,
      title: chatRoomTitle(widget.args.visitedID),
      leading: GestureDetector(
        child: Icon(Icons.arrow_back, color: Theme
            .of(context)
            .buttonColor,),
        onTap: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
Future<bool> _onBackPressed() {
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).secondaryHeaderColor,
          title: Text('Are you sure?' ,style: TextStyle(color: Theme.of(context).primaryColor),),
          content: Text('Do you want to exit LIT?' ,style: TextStyle(color: Theme.of(context).primaryColor)),
          actions: <Widget>[
            FlatButton(
              child: Text('No, of course not' ,style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            FlatButton(
              child: Text('Yes, bye' ,style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      });
}

Widget progressIndicator(){
  return Center(
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).primaryColor),
    ),
  );
}
}



