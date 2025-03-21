
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:lit_beta/DBC/Auth.dart';
import 'package:lit_beta/Extensions/common_functions.dart';
import 'package:lit_beta/Extensions/common_widgets.dart';
import 'package:lit_beta/Models/Chat.dart';
import 'package:lit_beta/Models/User.dart';
import 'package:lit_beta/Nav/routes.dart';
import 'package:lit_beta/Providers/ProfileProvider/profile_provider.dart';
import 'package:lit_beta/Providers/ProfileProvider/view_profile_provider.dart';
import 'package:lit_beta/Strings/hint_texts.dart';
import 'package:lit_beta/Strings/settings.dart';
import 'package:lit_beta/Styles/text_styles.dart';

class VisitProfilePage extends StatefulWidget {
  VisitProfilePage({Key key , this.visit}) : super(key: key);
  final UserVisit visit;


  @override
  _VisitProfileState createState() => _VisitProfileState();
}

class _VisitProfileState extends State<VisitProfilePage>{ 

  final Auth db = Auth();
  ViewProfileProvider provider;
  int _tabIdx = 0;

  @override
  void dispose(){
    super.dispose();
  }

  @override
  void initState() {
    provider = ViewProfileProvider(widget.visit.visitedID);
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return profileWidget(context);

  }

  //Silverbar usage
  Widget profileWidget(BuildContext c) {
    if (widget.visit.visitedID == null) {
      return Container();
    }
    return StreamBuilder(
        stream: provider.userSettingsStream(),
        builder: (context , settings){
          if(!settings.hasData){
            return CircularProgressIndicator();
          }
          return StreamBuilder(
            stream: provider.userStream(),
            builder: (context , u){
              if(!u.hasData){
                return Container();
              }
              String username = u.data['username'];
              String profileUrl = u.data['profileURL'];
              String clout = u.data['userVibe']['clout'];

              print(profileUrl);
              return Scaffold(
                appBar: topNav(backButton(), userThumbnailAppbar(profileUrl), [Container()], Theme.of(context).scaffoldBackgroundColor),
                backgroundColor: Theme.of(context).backgroundColor,
                body: SingleChildScrollView(
                  padding: EdgeInsets.all(0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(padding: EdgeInsets.all(5)),
                      userThumbnail(profileUrl , username),
                      vibeAndChatRow(username),
                      statsRow(getUserStats(clout)),
                      profileIndexedStackProvider(u)
                    ],
                  ),
                ),
              );
            },
          );
        }

    );
  }
  profileIndexedStackProvider( AsyncSnapshot u){
    return Column(
      children: [
        indexedStackTabBar(),
        indexedStack(u)
      ],
    );
  }

  Widget indexedStack(AsyncSnapshot u){
    return IndexedStack(
      index: _tabIdx,
      children: [
        userVibeTabProvider(u),
        userLituationTabProvider(u),
        Container()
        //userActivityTab(context , u),

        //aboutList(u),
        //viewUserLituation(u , context),
        //activityList(u)
      ],
    );
  }
  Widget userLituationTabProvider(AsyncSnapshot u){
    return StreamBuilder(
      stream: provider.userSettingsStream(),
      builder: (context , settings){
        if(!settings.hasData || settings.connectionState == ConnectionState.waiting){
          return CircularProgressIndicator();
        }
        return userLituationTabWithPrivacy(u, settings.data['lituation_visibility']);
      },
    );
  }
  Widget userVibeTabProvider(AsyncSnapshot u){
    return StreamBuilder(
        stream: provider.userSettingsStream(),
        builder: (context , settings){
          if(!settings.hasData || settings.connectionState == ConnectionState.waiting){
            return CircularProgressIndicator();
          }
          return userVibeTabWithPrivacy(u, settings.data['vibe_visibility'] , settings.data['location_visibility']);
    },
    );
  }
  Widget userVibeTabWithPrivacy(AsyncSnapshot u , String setting , String location_visibility){
    Color  bg = Theme.of(context).scaffoldBackgroundColor;
    Color btnC = Theme.of(context).primaryColor;
    Color textCol = Theme.of(context).textSelectionColor;
    String email = u.data['email'];
    String username = u.data['username'].toString();
    String gender = u.data["userVibe"]["gender"];
    String birthday = u.data["userVibe"]["birthday"];
    String prefs = u.data["userVibe"]["preference"];
    String lituations = u.data["userVibe"]["lituationPrefs"];
    String location = u.data["userLocation"];
    switch(setting){
      case PrivacySettings.PUBLIC:
        return userVibeTab(u , location_visibility);
      case PrivacySettings.HIDDEN:
        return userTabPrivate(1);
      case PrivacySettings.PRIVATE:
        return checkPrivacy(userVibeTab(u ,location_visibility), userTabPrivate(1));
      default:
        return userTabPrivate(0);
    }
  }
  Widget userLituationTabWithPrivacy(AsyncSnapshot u , String lituation_visibility){
    Color  bg = Theme.of(context).scaffoldBackgroundColor;
    Color btnC = Theme.of(context).primaryColor;
    Color textCol = Theme.of(context).textSelectionColor;
    String email = u.data['email'];
    String username = u.data['username'].toString();
    String gender = u.data["userVibe"]["gender"];
    String birthday = u.data["userVibe"]["birthday"];
    String prefs = u.data["userVibe"]["preference"];
    String lituations = u.data["userVibe"]["lituationPrefs"];
    String location = u.data["userLocation"];
    switch(lituation_visibility){
      case PrivacySettings.PUBLIC:
        return userLituationTab(u);
      case PrivacySettings.HIDDEN:
        return userTabPrivate(1);
      case PrivacySettings.PRIVATE:
        return checkPrivacy(userLituationTab(u), userTabPrivate(1));
      default:
        return userTabPrivate(0);
    }
  }
  Widget userLituationTab(AsyncSnapshot u){
    String username = u.data['username'];

    return StreamBuilder(
        stream: provider.userLituationsStream(),
        builder: (context, userLituations){
          if(!userLituations.hasData || userLituations.connectionState == ConnectionState.waiting){
            return CircularProgressIndicator();
          }
          return Column(
            children: [
              infoSectionHeader(username+'\'s Lituations', Theme.of(context).textSelectionColor),
              lituationList(context, username, 'upcoming lituations', userLituations.data['upcomingLituations']),
              //lituationList(c, username,'pending lituations', userLituations.data['pendingLituations']),
              lituationList(context, username,'past lituations', userLituations.data['pastLituations']),
              //lituationList(c, username,'draft lituations', userLituations.data['drafts']),
              //lituationList(c, username,'watched lituations', userLituations.data['observedLituations']),
            ],
          );
        }
    );
  }
  Widget lituationList(BuildContext c, String username ,String listname , List lituationIDs){
    Color bg = Theme.of(context).textSelectionColor;
    return Card(
      elevation: 3,
      margin: EdgeInsets.fromLTRB(0, 15, 0, 0),
      child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: EdgeInsets.all(5.0),
          height: 250,
          child: StreamBuilder<QuerySnapshot>(
              stream: provider.allLituationsStream(), //db.getLituations
              builder: (ctx , lituations){
                if(!lituations.hasData){
                  return CircularProgressIndicator();
                }
                List lList = List.from(lituations.data.docs);
                List data = List();
                for(var l in lList){
                  if(lituationIDs.contains(l.id.toString())){
                    data.add(l);
                  }
                }
                if(data.length > 0) {
                  return viewListVisitor(c , widget.visit.visitorID, data , [Container()],listname , bg);
                }
                return nullList(username, listname , bg);
              }
          )
      ),
    );
  }
  Widget userVibeTab(AsyncSnapshot u , String location_visibility){
    Color  bg = Theme.of(context).scaffoldBackgroundColor;
    Color btnC = Theme.of(context).primaryColor;
    Color textCol = Theme.of(context).textSelectionColor;
    String email = u.data['email'];
    String username = u.data['username'].toString();
    String gender = u.data["userVibe"]["gender"];
    String birthday = u.data["userVibe"]["birthday"];
    String prefs = u.data["userVibe"]["preference"];
    String lituations = u.data["userVibe"]["lituationPrefs"];
    String location = u.data["userLocation"];
    return Column(
      children: [
        infoSectionHeader(info_about_hint + u.data['username'], Theme.of(context).textSelectionColor),
        bioCard(bioLabelWidget(u.data['username'] , Container()), Text(u.data['userVibe']['bio'] , style: infoValue(Theme.of(context).textSelectionColor),), Theme.of(context).scaffoldBackgroundColor),
        infoSectionHeader(username + '\'s vibe', Theme.of(context).textSelectionColor),
        infoCard(info_attendance_hint, prefs, Icons.email, bg , btnC , textCol),
        infoCard(info_preference_hint, lituations==''?update_hint:lituations, Ionicons.ios_heart, bg , btnC , textCol),
        userPrivateLocationTile(location_visibility, infoCard(info_location_hint, location==''?update_hint:location, Icons.my_location, bg , btnC , textCol),)
      ],
    );
  }
  Widget userPrivateLocationTile(String setting , Widget locationTile){
    switch(setting){
      case PrivacySettings.PUBLIC:
        return locationTile;
      case PrivacySettings.HIDDEN:
        return Container();
      case PrivacySettings.PRIVATE:
          return checkPrivacy(locationTile , Container());
      default:
          return Container();
    }
  }
  Widget checkPrivacy(Widget w , Widget privateWidget){
    return StreamBuilder(
      stream: provider.vibingStream(),
      builder: (context , v){
        if(!v.hasData || v.connectionState == ConnectionState.waiting){
          return CircularProgressIndicator();
        }
        if(List.from(v.data['vibing']).contains(widget.visit.visitorID)){
         return w;
        }
        return privateWidget;
      },
    );
  }
  Widget userTabPrivate(int hidden){
    if(hidden == 1){
        return Container(
        height: 250,
        child: Center(
          child: Text("Private\n(vibing only)", textAlign: TextAlign.center , style: infoLabel(Theme.of(context).textSelectionColor),),
        ),
      );
    }
    return Container(
      height: 250,
      child: Center(
        child: Text("Unavailable :(", textAlign: TextAlign.center , style: infoLabel(Theme.of(context).textSelectionColor),),
      ),
    );
  }
  List<Widget> bioLabelWidget(String username , Widget button){
    List<Widget> w = [];
    w.add(Text(username +'\'s bio' ,style: infoLabel(Theme.of(context).primaryColor),));
    w.add(button);
    return w;
  }
  Widget indexedStackTabBar(){
    return Container(
      height: 75,
      margin: EdgeInsets.only(top: 25 , left: 50 , right: 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              child: GestureDetector(
                onTap:(){
                  if(_tabIdx != 0) {
                    setState(() {
                      _tabIdx = 0;
                    });
                  }
                },
                //TODO Replace with vibe icon
                child: indexedStackTab(vibe_label, Icons.person , 0),
              )
          ),
          Expanded(
              child: GestureDetector(
                onTap:(){
                  if(_tabIdx != 1) {
                    setState(() {
                      _tabIdx = 1;
                    });
                  }
                },
                //TODO Replace with lituation icon
                child: indexedStackTab(lituation_label, Icons.location_on_rounded , 1),
              )
          )
          ,
          Expanded(
              child: GestureDetector(
                onTap:(){
                  if(_tabIdx != 2) {
                    setState(() {
                      _tabIdx = 2;
                    });
                  }
                },
                //TODO Replace with activity icon
                child: indexedStackTab(activity_label, Ionicons.ios_notifications , 2),
              )
          ),
        ],
      ),
    );
  }
  Widget indexedStackTab(String title ,IconData icon , int idx){
    Color c = Theme.of(context).textSelectionColor;
    Color tc = Theme.of(context).buttonColor;
    Widget indicator = Container();
    if(idx == _tabIdx){
      c = Theme.of(context).primaryColor;
      tc = Theme.of(context).textSelectionColor;
      indicator = selectedIndicator(tc);
    }
    return Container(
      height: 75,
      child: Column(
        children: [
          Expanded(child: Icon(icon , color: c, size: 35,),),
          Expanded(
              child: Container(
                margin: EdgeInsets.only(top: 10),
                child: Text(
                    title ,
                    style: TextStyle(color: tc),
                    textAlign: TextAlign.center),)
          ),
          indicator
        ],
      ),
    );
  }
  Widget vibeAndChatRow(String username){
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
         vibeButton(),
        chatButton(username),
      ],
    );
  }
  Widget vibeButton(){
    return StreamBuilder(
      stream: provider.vibingStream(),
      builder: (context , vibing){
        if(!vibing.hasData){
          return Container();
        }
        String val = 'vibe';
        Color btnColor = Theme.of(context).primaryColor;
        int status = 0; //0 vibe , 1 vibed , 2 pending
        if(List.from(vibing.data['vibing']).contains(widget.visit.visitorID)){
          val = 'vibed';
          btnColor = Colors.green;
          status = 1;
        }
        if(List.from(vibing.data['pendingVibing']).contains(widget.visit.visitorID)){
          val = 'cancel';
          btnColor = Colors.red;
          status = 2;
        }

        return Container( //lo
            height: 35,// in button
            margin: EdgeInsets.fromLTRB(15, 25, 0, 0),
            child: RaisedButton(
                color: btnColor,
                textColor: Theme.of(context).textSelectionColor,
                child: Text(val , style: infoValue(Theme.of(context).textSelectionColor),),                
                onPressed: () {
                  if(val == 'vibe')
                    provider.sendVibeRequest(widget.visit.visitorID);
                  else if(val == 'cancel')
                    provider.cancelVibeRequest(widget.visit.visitorID);

                }, shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0))
            )
        );

      },
    );
  }

  Widget chatButton(String username){
    return StreamBuilder(
      stream: provider.getVisitorVibedStream(widget.visit.visitorID),
      builder: (context , vibed){
        if(!vibed.hasData){
          return Container();
        }
        String val = 'chat';
        Color btnColor = Theme.of(context).primaryColor;
        int status = 0; //0 vibe , 1 vibed , 2 pending
        if(List.from(vibed.data['vibed']).contains(widget.visit.visitedID)){
          return Container( //lo
              height: 35,// in button
              margin: EdgeInsets.fromLTRB(15, 25, 0, 0),
              child: RaisedButton(
                  color: btnColor,
                  child: Text(val , style: infoValue(Theme.of(context).textSelectionColor),),
                  onPressed: (){
                    UserVisit v = UserVisit();
                    v.visitedID = widget.visit.visitedID;
                    v.visitorID = widget.visit.visitorID;
                    createChatRoom(v, username);/*
                    setState(() {
                      //TODO open chat with user
                      //chatWithUser(status);
                    });*/
                  }, shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0))
              )
          );
        }
      return Container();


      },
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
        args.visitedID = widget.visit.visitedID;
        Navigator.pushNamed(context, ChatRoomPageRoute , arguments: args);

      }else{
        String roomID = roomIDs.contains(chkX) ? chkX : chkY;
        chat(username, v.visitorID, roomID);
      }
    });

  }


  void chat(String username, String userID , String roomID){
    ChatArgs args = ChatArgs();
    args.username = username;
    args.roomID = roomID;
    args.visitedID = widget.visit.visitedID;
    args.userID = userID;
    Navigator.pushNamed(context, ChatRoomPageRoute , arguments: args);
  }


  void showVibeSnackBar(BuildContext context, String username, String userID , int msgID){
    String msg = '';
    switch(msgID){
      case 0:{
        msg = 'you\'ve asked to vibe with $username!';
        break;
      }
      case 1:{
        msg = 'pending vibe with $username cancelled.';
        break;
      }
      case 2:{
        msg = 'chat pending until you vibe with $username';
        break;
      }
    }
  showSnackBar(context, sBar(msg));

  }
  SnackBar sBar(String text){
    return SnackBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        content: Text(text , style: TextStyle(color: Theme.of(context).textSelectionColor),));
  }
  Widget userThumbnail(String url , String username){
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 200,
          width: 150,
          child: Stack(
            children: [
              Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CachedNetworkImage(
                        height: 150,
                        width: 150,
                        imageUrl: url,
                        imageBuilder: (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        placeholder: (context, url) => CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Theme.of(context).splashColor),),
                        errorWidget: (context, url, error) => Container(),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: usernameWidget(username),
                      )
                    ],
                  )
              )
            ],
          ),
        )
      ],
    );
  }
  List<Widget> getUserStats(String clout){
    List<Widget> s = [];
    s.add(vibingTabProvider());
    s.add(divider(Theme.of(context).textSelectionColor));
    s.add(cloutTabProvider(clout));
    s.add(divider(Theme.of(context).textSelectionColor));
    s.add(vibedTabProvider());
    return s;
  }

  Widget vibingTabProvider(){
    return StreamBuilder(
        stream: provider.vibingStream(),
        builder: (context , v){
          if(!v.hasData || v.connectionState == ConnectionState.waiting){
            return statsRowTab(vibed_label, CircularProgressIndicator());
          }
          String vibing = parseVibes(List.from(v.data['vibing']).length.toString());
          return GestureDetector(
            child: statsRowTab(vibing_label, statData(vibing)),
            onTap: (){
              _viewVibes('vibing');
            },
          );
        }

    );
  }
  Widget cloutTabProvider(String clout){
    return GestureDetector(
      //TODO add clout icon
      child: statsRowTab(clout_label, statData(clout)),
      onTap: (){
        //TODO Show clout description
      },
    );
  }
  Widget vibedTabProvider(){
    return StreamBuilder(
        stream: provider.vibedStream(),
        builder: (context , v){
          if(!v.hasData || v.connectionState == ConnectionState.waiting){
            return statsRowTab(vibed_label, CircularProgressIndicator());
          }
          String vibed = parseVibes(List.from(v.data['vibed']).length.toString());
          return GestureDetector(
            child: statsRowTab(vibed_label, statData(vibed)),
            onTap: (){
              _viewVibes('vibed');
            },
          );
        }

    );
  }
  void _viewVibes(String note){
    UserVisit v = UserVisit(visitedID: widget.visit.visitedID ,visitorID:widget.visit.visitorID, visitNote: note);
    Navigator.of(context).pushNamed(VibesPageRoute , arguments: v);
  }
  Widget usernameWidget(String val){
    return Container(
      margin: EdgeInsets.only(top: 15),
      child: Text(val ,  style: infoLabel(Theme.of(context).textSelectionColor), textScaleFactor: 1.2,),
    );
  }
  Widget statIcon(IconData ic){
    return Icon(ic , color: Theme.of(context).primaryColor,);
  }
  Widget statData(String val){
    return Text(val , style: infoValue(Theme.of(context).primaryColor),textScaleFactor: 1.2,);
  }
  Widget statsRow(List<Widget> stats){
    return Container(
      height: 75,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: stats
      ),
    );
  }

  Widget statsRowTab(String stat, Widget data){
    return Container(
      margin: EdgeInsets.only(top: 25),
      child: Column(
        children: [
          Expanded(child: data ,),
          Padding(padding: EdgeInsets.all(5)),
          Expanded(child: Text(stat , style: TextStyle(color: Theme.of(context).textSelectionColor), textScaleFactor: 1,),),
        ],
      ),
    );
  }

  Widget backButton(){
    return GestureDetector(
      onTap: (){Navigator.of(context).pop();},
      child: Icon(Icons.arrow_back , color: Theme.of(context).buttonColor,),
    );
  }
}
