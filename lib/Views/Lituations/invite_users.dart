import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:lit_beta/Extensions/common_widgets.dart';
import 'package:lit_beta/Models/Lituation.dart';
import 'package:lit_beta/Models/User.dart';
import 'package:lit_beta/Nav/routes.dart';
import 'package:lit_beta/Providers/ProfileProvider/lituation_provider.dart';
import 'package:lit_beta/Strings/constants.dart';
import 'package:lit_beta/Strings/hint_texts.dart';
import 'package:lit_beta/Styles/text_styles.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class InviteView extends StatefulWidget {
  final Lituation lit;
  final String userID;

  const InviteView({Key key, this.lit, this.userID}) : super(key: key);

  @override
  _InviteViewState createState() => _InviteViewState();
}

class _InviteViewState extends State<InviteView> {
  static const double _topSectionTopPadding = 50.0;
  static const double _topSectionBottomPadding = 20.0;
  static const double _topSectionHeight = 50.0;
  GlobalKey globalKey = new GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _inputErrorText;
  final TextEditingController _textController =  TextEditingController();
  TextEditingController userSearchController;
  Lituation lit;
  List<String> prevInvites = [];
  LituationProvider lp;

  @override
  void dispose(){
    userSearchController.dispose();
    super.dispose();
  }
  void initState(){
    userSearchController = TextEditingController();
    super.initState();
    lit = widget.lit;
    prevInvites = List<String>.from(lit.invited);
    lp = LituationProvider(widget.lit.eventID , widget.userID);
  }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: _scaffoldKey,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _contentWidget(context),
    );
  }
  _contentWidget(context) {
    return  Wrap(
      children: [
        userSearchTextField()
      ]
    );
  }
  Widget userSearchTextField(){
    return Card(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Container(
            margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
            padding: EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invite users' ,style: infoLabel(Theme.of(context).textSelectionColor),),
                inviteTextField(widget.userID),
                SizedBox(height: 30,),
                invitedGuestList(),
                buttons(),                
              ],
            )
        )
    );
  }
  Widget buttons() {
    return Row(
      children: [
      RaisedButton(
          color: Colors.green,
          textColor: Theme.of(context).primaryColor,
          child: Text("Invite" , style: Theme.of(context).textTheme.button,),
          onPressed: (){
            inviteUsers();
          }, shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0))
      ),
      SizedBox(width: 10,),
      RaisedButton(
          color: Colors.red,
          textColor: Theme.of(context).primaryColor,
          child: Text("Close" , style: Theme.of(context).textTheme.button,),
          onPressed: (){
            Navigator.of(context).pop();
          }, shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0))
      )
    ],);
  }
  Widget inviteTextField(String u){
    return  TypeAheadField(
      textFieldConfiguration: TextFieldConfiguration(
          cursorColor: Theme.of(context).primaryColor,
          controller: userSearchController,
          autofocus: false,
          style: infoValue(Theme.of(context).textSelectionColor),
          decoration: InputDecoration(
            labelText: "Select friends you'd like to invite...",
            hintText: invite_hint,
            hintStyle: TextStyle(color: Theme.of(context).primaryColor , fontSize: 12 , decoration: TextDecoration.none),
            labelStyle: TextStyle(color: Theme.of(context).primaryColor , fontSize: 14 ,decoration: TextDecoration.none),
            border: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor , width: 2)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor , width: 1)),
            suffixIcon: IconButton(icon: Icon(Icons.clear, color: Theme.of(context).primaryColor,),
              onPressed: (){
                setState(() {
                  userSearchController.text = '';
                });
              },
            ),

          )
      ),
      suggestionsBoxDecoration: SuggestionsBoxDecoration(
        color: Theme.of(context).accentColor
      ),
      suggestionsCallback: (pattern) async {
        if (pattern == "") return [];
        return await lp.queryUsers(pattern).then((value) {
          List<User> users = List<User>.from(value);
          return users.where((element) => !lit.invited.contains(element.userID));
        });
      }
      ,
      itemBuilder: (context, suggestion) {
        return Material(
            color: Theme.of(context).backgroundColor,
            child:  userResultTile(suggestion.username,suggestion.profileURL, context)
        );
      },
      onSuggestionSelected: (suggestion) {
        User u = suggestion;
        setState(() {
          userSearchController.text = u.username;
          if (lit.invited.contains(u.userID) == false)
            lit.invited.add(u.userID);          
        });
      },
      noItemsFoundBuilder: (context){
        return Container(
          padding: EdgeInsets.all(5),
          child :Text("No users...", style: infoValue(Theme.of(context).textSelectionColor),)
        );
      },
    );
  }
  Widget invitedGuestList(){
    return Container(
      margin: EdgeInsets.fromLTRB(10, 15, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Invited vibes...", style: infoValue(Theme.of(context).primaryColor),),
          Container(
            margin: EdgeInsets.only(top: 10),
            height: 75,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: lit.invited.length,
              itemBuilder: (ctx, idx) {
                return invitedCircularProfileWidget(
                    lit.invited[idx]);
              },
            ),
          )
        ],
      ),
    );
  }
  Widget invitedCircularProfileWidget(String userID){
    return StreamBuilder(
      stream: lp.getUserStreamByID(userID),
      builder: (ctx , user){
        if(!user.hasData){
          return CircularProgressIndicator();
        }
        return GestureDetector(
          onTap: (){
            if(userID !=  widget.userID){
              _viewProfile(userID , user.data['username']);
            }
          },
          child: Container(
              child: Row(
                children: [
                  // approveButton(userID),
                  Column(
                    children: [
                      userProfileThumbnail(user.data['profileURL'] , user.data['status']['status']),
                      Container(
                          margin: EdgeInsets.fromLTRB(0, 5, 0, 0),
                          child: new Text(user.data['username'],
                            style: Theme.of(context).textTheme.headline3,textAlign: TextAlign.center,textScaleFactor: 0.9,)
                      ),
                    ],
                  ),
                  removeInvitedButton(userID),
                ],
              )
          ),
        );
      },
    );
  }
  void _viewProfile(String id , String username){
    UserVisit v = UserVisit();
    v.visitorID = widget.userID;
    v.visitedID = id;
    v.visitNote = username;
    print(v.visitNote);
    Navigator.pushNamed(context, VisitProfilePageRoute , arguments: v);
  }
  Widget removeInvitedButton(String userID){
    return Container(
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: (){
            removeInvited(userID);
          },
          child:  Icon(Ionicons.ios_close_circle_outline, size: 20, color: Colors.red,),
        )
    );
  }

  String removeInvited(String id){
    setState(() {
      lit.invited.remove(id);
    });
  }
  void inviteUsers() {
    lit.invited.forEach((element) async {
      if (prevInvites.contains(element) == false) {
        await lp.db.addToUserInvitation(element, lit.eventID, widget.userID);
      }
    });
    prevInvites.forEach((element) async {
      if (lit.invited.contains(element) == false) {
        await lp.db.removeInvitationLituation(element, lit.eventID, widget.userID);
      }
    });
    Alert(
      context:_scaffoldKey.currentContext, 
      title: "Success",
      desc: "Invite users",
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
}