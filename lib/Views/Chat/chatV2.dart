import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat/dash_chat.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lit_beta/DBC/Auth.dart';
import 'package:lit_beta/Models/Chat.dart';
import 'package:lit_beta/Utils/Common.dart';
import 'package:lit_beta/Views/Chat/video_player.dart';
import 'package:uuid/uuid.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:flutter/services.dart';

class ChatPageV2 extends StatefulWidget{
  final ChatArgs args;
  ChatPageV2({this.args});
  @override
  _ChatPageStateV2 createState() => new _ChatPageStateV2();

}

class _ChatPageStateV2 extends State<ChatPageV2>{
  final GlobalKey<DashChatState> _chatKey = GlobalKey<DashChatState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ChatUser user = ChatUser();
  final Auth db = Auth();
  static const int NUM_ELEMENTS = 50;
  static const int ON_SCREEN = 10;
  bool loading = false;

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
  void uploadImage() async {
    setState(() {
      loading = true;
    });
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
      String ext = result.path.split(".").last;
      String id = Uuid().v4().toString();
      final StorageRef = db.dbMediaRef.ref().child(widget.args.roomID).child("images/$id.$ext");
      await StorageRef.putFile(result);
      String url = await StorageRef.getDownloadURL();
      ChatMessage msg = ChatMessage(text: "", user: user, image: url,);
      db.sendMessageToRoom(widget.args.roomID, msg);
    }
    setState(() {
      loading = false;
    });
  }
  Future<String> uploadThumbnail(String videoPath) async {    
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.PNG,
        maxHeight: 300, // specify the height of the thumbnail, let the width auto-scaled to keep the source aspect ratio
        quality: 75,
      );
      File result = File(thumbnail);
      String id = Uuid().v4().toString();
      final StorageRef = db.dbMediaRef.ref().child(widget.args.roomID).child("images/$id.png");
      await StorageRef.putFile(result);
      String url = await StorageRef.getDownloadURL();
      return url;
  }
  void uploadVideo() async {
    setState(() {
      loading = true;
    });
    File result;
    final picker = ImagePicker();
    final pickedMedia = await picker.getVideo(source: ImageSource.gallery);
    if(pickedMedia != null){
      result = File(pickedMedia.path);
    }else{
      print('no media selected');
      return;
    }
  
    if(result != null){
      String thumbnail = await uploadThumbnail(pickedMedia.path);
      String ext = result.path.split(".").last;
      String id = Uuid().v4().toString();
      final StorageRef = db.dbMediaRef.ref().child(widget.args.roomID).child("images/$id.$ext");
      await StorageRef.putFile(result);
      String url = await StorageRef.getDownloadURL();
      ChatMessage msg = ChatMessage(text: "", user: user, image: thumbnail, video: url);
      db.sendMessageToRoom(widget.args.roomID, msg);
    }
    setState(() {
      loading = false;
    });
  }
  void uploadMedia() async {    
    Alert(
      context: context,
      title: "Select upload method",
      buttons: [
        DialogButton(
          child: Text(
            "Image",
            style: TextStyle(color: Theme.of(context).textSelectionColor, fontSize: 18),
          ),
          onPressed: () {
            Navigator.pop(context);
            uploadImage();
          },
          color: Theme.of(context).primaryColor,
        ),
        DialogButton(
          child: Text(
            "Video",
            style: TextStyle(color: Theme.of(context).textSelectionColor, fontSize: 18),
          ),
          onPressed: () {
            Navigator.pop(context);
            uploadVideo();
          },
          color: Theme.of(context).primaryColor,
        )
      ],
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: topbar(),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LoadingOverlay(child: Container(
       child: chatLog()
     ), isLoading: loading),
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
          messageImageBuilder: messageImageBuilder,
          trailing: <Widget>[
            IconButton(icon: Icon(Icons.perm_media , color: Colors.black,), onPressed:()async{uploadMedia();}),
          ],
          onLongPressMessage: onLongPressMessage
        );
      }
    }
  );
  }

  Widget messageImageBuilder(String str, [ChatMessage msg]) {
    if (msg.video == null)
      return Image.network(str);
    else
      return InkWell(
        onTap: (){
          print("touch");
          showDialog(context: context,
            builder: (BuildContext context){
            return VideoPlayer(
              video: msg.video,
            );
            }
          );
        },
        child: Stack(
        alignment: Alignment.center,
        children: [
          Image.network(str),
          Image(image: AssetImage('assets/images/video_play.png'))
      ],));
  }

  void onLongPressMessage(ChatMessage msg) {
    bool isMedia = msg.image != null || msg.video != null;
    showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context) {
              return Material(
                    child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      isMedia ? ListTile(
                        title: Text('Download'),
                        leading: Icon(Icons.download),
                        onTap: () async {
                          Navigator.of(context).pop();
                          setState(() {
                            loading = true;
                          });
                          String savePath = await downloadFile(msg.video ?? msg.image, (await getExternalStorageDirectory()).path, msg.video != null ? "mp4" : "png");                          
                          setState(() {
                            loading = false;
                          });
                          Alert(
                            context:_scaffoldKey.currentContext, 
                            title: "File saved to",
                            desc: savePath,
                            type: AlertType.success,
                            buttons: [
                              DialogButton(
                                child: Text(
                                  "OK",
                                  style: TextStyle(color: Theme.of(_scaffoldKey.currentContext).textSelectionColor, fontSize: 18),
                                ),
                                onPressed: () {
                                  Navigator.pop(_scaffoldKey.currentContext);
                                },
                                color: Theme.of(_scaffoldKey.currentContext).primaryColor,
                              ),
                            ],                            
                          ).show();
                        }
                      ) : ListTile(
                          title: Text('Copy'),
                          leading: Icon(Icons.content_copy),
                          onTap: (){
                            Clipboard.setData(ClipboardData(text: msg.text));
                            Navigator.of(context).pop();
                          }
                      ),
                    ],
                  ),
                ));
            },
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
            .textSelectionColor),);
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
            .textSelectionColor,),
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



