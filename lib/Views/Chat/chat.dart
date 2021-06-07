
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lit_beta/DBC/Auth.dart';
import 'package:lit_beta/Models/Chat.dart';
import 'package:lit_beta/Models/User.dart';
import 'package:lit_beta/Nav/routes.dart';
import 'package:lit_beta/Styles/theme_resolver.dart';

class ChatPage extends StatefulWidget{
  final String userId;
  ChatPage({Key key , this.userId}) : super(key: key);
  @override
  _ChatState createState() => new _ChatState();

}

class _ChatState extends State<ChatPage>{

  final Auth db = Auth();
  List<DocumentSnapshot> rooms = List();
  String logo = 'assets/images/litlogolabeled.png';
  String searchUsersHint = 'find previous conversations...';
  TextEditingController searchController = TextEditingController();
  Color primaryColor = Colors.deepOrange;
  Color secondaryColor = Colors.black;

  @override
  void initState(){
    getRooms();
    super.initState();
  }
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: db.getUser(widget.userId),
      builder: (ctx , user){
        if(!user.hasData){
          return CircularProgressIndicator();
        }
        return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: chatWidget(context, user.data['username'])
        );
      },
    );
  }

  Widget chatWidget(BuildContext ctx, String username){
    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(10.0 , 5 , 10.0 , 0),
          child:
          searchBar(),),
        availableUsers(ctx , username),
      ],
    );
  }

  Widget availableUsers(BuildContext ctx , String username){
    if(rooms.length == null){
      return Container();
    }else {
      return Expanded(
          child: ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, idx) {
              var r = rooms[idx];
              String id = List.from(r.data()['party'])[1].toString();
              String url = '';
              print(id);
              return chatRoomResult(
                  id, username ,r.data()['room_name'],
                  r.data()['roomID'], context);
            },
          ));
    }
  }
String parseRoomIDToUser(String roomID){
    var ids = roomID.split('_');
    if(ids[0] == widget.userId){
      return ids[1];
    }
    return ids[0];
}
  Widget chatRoomTitle(String id){
    return StreamBuilder(
      stream: db.getUser(id),
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
  Widget chatRoomResult(String userID , String username, String roomname , String roomID , BuildContext ctx){
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
                v.visitorID = widget.userId;
                chat(username, v, roomID);
              },
              child:  Card(elevation: 5,
              child: Container(
                  color: Theme.of(context).primaryColor,
                  padding: EdgeInsets.only(top:5.0 , left: 15 , right:0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CachedNetworkImage(
                            height: 75,
                            width: 75,
                            imageUrl: u.data['profileURL'],
                            imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            placeholder: (context, url) => CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Theme.of(context).buttonColor),),
                            errorWidget: (context, url, error) => nullProfileUrl(),
                          ),
                          Padding(padding: EdgeInsets.all(5)),
                          chatRoomTitle(parseRoomIDToUser(roomID)),
                          ],
                      ),


                      Stack(
                        children: [
                          Container(
                              margin: EdgeInsets.fromLTRB(0, 0, 50, 0),
                              child: new Icon(Icons.chat_bubble_outline , color: Theme.of(context).buttonColor, size: 25,)
                          ),],
                      ),
                    ],

                  )),),
          );
        },
      );
    }
  }

  Widget nullProfileUrl(){
    return Container(
      padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
      width: 125.0,
      height: 125.0,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).buttonColor),
        borderRadius: BorderRadius.circular(75),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.8,
            child: Image.asset('assets/images/litlogo.png'),
          )
        ],
      ),
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
  Widget searchBar(){
    return Container(
      decoration:  BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomRight: Radius.circular(15),
            bottomLeft: Radius.circular(15)),
        color: Theme.of(context).primaryColor,
      ),
      margin: EdgeInsets.fromLTRB(0, 50, 0, 0),
      child: TextField(
        cursorColor: Theme.of(context).buttonColor,
        style: Theme.of(context).textTheme.headline3,
        controller: searchController,
        decoration: InputDecoration(
            labelText: searchUsersHint,
            prefixIcon: searchController.text!=''?GestureDetector(
              child: new Icon(Icons.clear ,
                color: Theme.of(context).buttonColor,
              ),
              onTap: (){searchController.clear();},
            ):Container(width: 10),
            suffixIcon: new Icon(Icons.search ,
              color: Theme.of(context).buttonColor,
            ),
            labelStyle: TextStyle(color: Theme.of(context).buttonColor),
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
        onChanged: (value){
          queryChat(value);
        },
      ),
    );
  }
  void getRooms() async {
     db.getUserChatRooms(widget.userId).then((value){
        for(DocumentSnapshot r in List.from(value.docs)) {
            if (!rooms.contains(r)) {
              setState(() {
                rooms.add(r);
              });
            }
          }

    });
  }
  void queryChat(String query) async {
    rooms.clear();
    db.getUserChatRooms(widget.userId).then((value){
      List<DocumentSnapshot> rL = List.from(value.docs);
      if(query == ''){
        for(DocumentSnapshot r in rL){
          if(!rooms.contains(r) && r != null){
            setState(() {
              rooms.add(r);
            });
          }
        }
        return;
      }else{
          rooms.clear();
        for(DocumentSnapshot r in rL) {
          if (r.data()['room_name'].toString().toLowerCase().contains(query.toLowerCase()) && List.from(r.data()['party']).contains(widget.userId)){
            if (!rooms.contains(r)) {
              setState(() {
                rooms.add(r);
              });
            }
          }
        }
      }
    });

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
        chat(username, v,v.visitorID + '_' + v.visitedID);
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