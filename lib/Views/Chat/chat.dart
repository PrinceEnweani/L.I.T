
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lit_beta/DBC/Auth.dart';
import 'package:lit_beta/Extensions/common_widgets.dart';
import 'package:lit_beta/Models/Chat.dart';
import 'package:lit_beta/Models/User.dart';
import 'package:lit_beta/Nav/routes.dart';
import 'package:lit_beta/Providers/ChatProvider/chat_provider.dart';
import 'package:lit_beta/Styles/text_styles.dart';
import 'package:lit_beta/Styles/theme_resolver.dart';

class ChatPage extends StatefulWidget{
  final String userID;
  ChatPage({Key key , this.userID}) : super(key: key);
  @override
  _ChatState createState() => new _ChatState();

}

class _ChatState extends State<ChatPage>{

  final Auth db = Auth();
  ChatProvider cp;
  var rooms = [];
  String logo = 'assets/images/litlogolabeled.png';
  String searchUsersHint = 'find previous conversations...';
  TextEditingController searchController = TextEditingController();

  @override
  void initState(){
    cp = new ChatProvider(widget.userID);
    //getRooms();
    super.initState();
    loadAllChats();
  }
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: db.getUser(widget.userID),
      builder: (ctx , user){
        if(!user.hasData){
          return CircularProgressIndicator();
        }
        return Scaffold(
            backgroundColor: Theme.of(context).backgroundColor,
            body: chatWidget(context, user.data['username'])
        );
      },
    );
  }

  Widget chatWidget(BuildContext ctx, String username){
    return Column(
      children: [
        Container(
          child:
          searchBar(),),
        availableUsers(ctx , username),
      ],
    );
  }

  Widget noChatRoomsWidget(){
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height/2 - 100),
      child: Text("No recent messages:(\nVibe with someone to start vibing!" , style: infoValue(Theme.of(context).textSelectionColor),textAlign: TextAlign.center,),
    );
  }
  Widget availableUsers(BuildContext ctx , String username){
    if(rooms.length == 0){
      return noChatRoomsWidget();
    }else {
      return chatResultList();
    }
  }
  Widget chatResultList(){
    if(rooms.length < 1 && searchController.text.length > 1){
      return Container(
        margin: EdgeInsets.all(15),
        child: Card(
          elevation: 3,
          color: Theme.of(context).backgroundColor,
          child: ListTile(
            leading: Text("No results found...Try someone else." , style: infoLabel(Theme.of(context).textSelectionColor),),
          ),
        ),
      );
    }
    return Expanded(
        child: ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (context , idx){
            return  rooms[idx];
          },
        )
    );
  }
String parseRoomIDToUser(String roomID){
    var ids = roomID.split('_');
    if(ids[0] == widget.userID){
      return ids[1];
    }
    return ids[0];
}
  Widget chatRoomTitle(String id){
    return StreamBuilder(
      stream: cp.getChatRoom(id),
      builder: (context , party){
        if(!party.hasData || party.connectionState == ConnectionState.waiting){
          return CircularProgressIndicator();
        }
        Map data = party.data.data();
        print("WORLD ${data}");
        if(data["party"][0].toString().contains(widget.userID)){
          return usernameWidget(data["party"][1]);
        }
        return usernameWidget(data["party"][0]);
      },
    );
  }
  Widget usernameWidget(String id){
   return StreamBuilder(
      stream: cp.getUser(id),
      builder: (context , user){
        if(!user.hasData || user.connectionState == ConnectionState.waiting){
          return CircularProgressIndicator();
        }
        print("usernamewidget ${id}");
        User _user = User.fromJson(user.data.data());
        return Text( _user.username,style: infoValue(Colors.white));
      },
    );
  }
  Widget chatRoomResult(String userID , String roomID , BuildContext ctx){
    if(userID == "GROUP"){
      return Container();
    }
    if(userID != ''){
      return StreamBuilder(
        stream: db.getUser(userID),
        builder: (context , u){
          if(!u.hasData){
           return CircularProgressIndicator();
          }
          return GestureDetector(
              onTap: (){
                UserVisit v = UserVisit();
                v.visitedID = parseRoomIDToUser(roomID);
                v.visitorID = widget.userID;
                chat(u.data['username'], v, roomID);
              },
              child:  Card(
                elevation: 3,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: ListTile(
                  contentPadding: EdgeInsets.all(10),
                  leading: userProfileThumbnail(u.data['profileURL'], 'online'),
                  title:   chatRoomTitle(roomID),
                  trailing: notificationCountWidget(),
                ),
              ),
          );
        },
      );
    }
    return Container();
  }

  Widget notificationCountWidget(){
    return Stack(
      children: [
        Container(
            margin: EdgeInsets.fromLTRB(0, 0, 25, 0),
            child: new Icon(Icons.chat_bubble_outline , color: Theme.of(context).primaryColor, size: 25,)
        ),],
    );
  }

  String profileImage(String url){
    String litLogoUrl = 'https://firebasestorage.googleapis.com/v0/b/litt-a9ee1.appspot.com/o/userProfiles%2Flitlogo.png?alt=media&token=50f97adf-93d6-4087-8990-3278f6aa113b';
    if(url == null || url == ''){
      return litLogoUrl;
    }else{
      return url;
    }
  }

  void loadAllChats() async {
    var results = [];
    await cp.getUserChatRooms().then((value){
      setState(() {
        rooms.clear();
        for(var room in value){
          Map _data = room.data();
          if(!results.contains(_data['room_name'])){
            results.add(_data['room_name']);
            rooms.add(chatRoomResult(
                _data['party'][1],
                _data['roomID'], context));
          }
        }
      });
    });
  }
  Widget searchBar(){
    return Container(
      decoration:  BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomRight: Radius.circular(15),
            bottomLeft: Radius.circular(15)),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      margin: EdgeInsets.fromLTRB(15, 75, 15, 0),
      child: TextField(
        cursorColor: Theme.of(context).textSelectionColor,
        style: TextStyle(
            color: Theme.of(context).textSelectionColor),
        controller: searchController,
        decoration: InputDecoration(
            labelText: searchUsersHint,
            prefixIcon: searchController.text!=''?GestureDetector(
              child: new Icon(Icons.clear ,
                color: Theme.of(context).primaryColor,
              ),
              onTap: (){searchController.clear();},
            ):Container(width: 10),
            suffixIcon: new Icon(Icons.search ,
              color: Theme.of(context).textSelectionColor,
            ),
            labelStyle: TextStyle(color: Theme.of(context).textSelectionColor),
            enabledBorder: UnderlineInputBorder(
              borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(10),
                  bottomLeft: Radius.circular(10)),
              borderSide: BorderSide(color: Colors.transparent , width: 0),),
            focusedBorder: UnderlineInputBorder(
                borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10)),
                borderSide: BorderSide(color: Theme.of(context).buttonColor , width: 1))
        ),
        onChanged: (value) async {
          if(value == ''){
            loadAllChats();
          }
          else
            await cp.searchChatRooms(value).then((value) async {            
              rooms.clear();
              var results = [];
              for(var room in value){
                if(!results.contains(room.data()['room_name'])){
                  results.add(room.data()['room_name']);
                  rooms.add(chatRoomResult(
                      room.data()['party'][1],
                      room.data()['roomID'], context));
                }
              }
              setState((){});
            });
        },
      ),
    );
  }

  void createChatRoom(UserVisit v, String username) async {
    String chkX = v.visitorID + '_' + v.visitedID;
    String chkY = v.visitedID + '_' + v.visitorID;
    List roomIDs = [];
    db.getUserChatRooms(v.visitorID).then((value){
      for(DocumentSnapshot d in List.from(value.docs)){
        if(!roomIDs.contains(d.data()['roomID'])){
          roomIDs.add(d.data()['roomID'].toString());
        }
      }
      if(!roomIDs.contains(chkX) && !roomIDs.contains(chkY)) {
        ChatRoomModel c = new ChatRoomModel();
        c.room_id = v.visitorID + '_' + v.visitedID;
        c.room_name = username;
        c.date_created = DateTime.now();
        c.messages = [];
        c.party = [v.visitorID, v.visitedID];
        db.createChatRoom(c);
        ChatArgs args = ChatArgs();
        args.username = username;
        args.roomID = c.room_id;
        args.visitedID = v.visitedID;
        args.userID = v.visitorID;
        Navigator.pushNamed(context, ChatRoomPageRoute , arguments: args);

      }else{
        String roomID = roomIDs.contains(chkX) ? chkX : chkY;
        chat(username, v, roomID);
      }
    });

  }


  void chat(String username, UserVisit v , String roomID){
    ChatArgs args = ChatArgs();
    args.username = username;
    args.roomID = roomID;
    args.visitedID = v.visitedID;
    args.userID = v.visitorID;
    Navigator.pushNamed(context, ChatRoomPageRoute , arguments: args);
  }
}