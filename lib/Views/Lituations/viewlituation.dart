
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_pro/carousel_pro.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lit_beta/DBC/Auth.dart';
import 'package:lit_beta/Extensions/common_functions.dart';
import 'package:lit_beta/Models/Lituation.dart';
import 'package:lit_beta/Models/User.dart';
import 'package:lit_beta/Nav/routes.dart';
import 'package:lit_beta/Strings/constants.dart';
import 'package:lit_beta/Utils/Common.dart';
import 'package:lit_beta/Views/Lituations/invite_users.dart';
import 'package:lit_beta/Views/Lituations/qr_viewer.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:permission_handler/permission_handler.dart';

Color primaryColor = Colors.deepOrange;
Color secondaryColor = Colors.black;

class ViewLituation extends StatefulWidget{
  final LituationVisit lituationVisit;
  ViewLituation({Key key , this.lituationVisit}) : super(key: key);

  @override
  _ViewLituationState createState() => new _ViewLituationState();

}

class _ViewLituationState extends State<ViewLituation>{
  
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  //INPUT CONTROLLERS
  final TextEditingController titleController = TextEditingController();
  final TextEditingController feeController = TextEditingController();
  final TextEditingController capController = TextEditingController();
  final TextEditingController themesController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  TextEditingController tec = new TextEditingController();
  TextEditingController tec2 = new TextEditingController();
  //MAP VARIABLES
  GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: MAPS_KEY);
  final Set<Marker> _markers = {};
  MapType _mapType = MapType.normal;
  Completer<GoogleMapController> _controller = Completer();
  List<PlacesSearchResult> places = [];
  List<String> addressResults = [];
  BitmapDescriptor myIcon;
  Uint8List locationIcon;
  double zoom = 12.0;
  LatLng lituationLatLng = LatLng(0 , 0);
  bool minimizeRSVPS = false;

  //DB VARIABLES
  final Auth db = Auth();
  bool _editMode = false;
  List<Widget> thumbnails = [];

  @override
  void dispose(){
    disposeControllers();
    super.dispose();
  }
  Lituation updatedLituation = new Lituation();
  @override
  void initState() {
    super.initState();
  }


  void disposeControllers(){
    titleController.dispose();
    feeController.dispose();
    capController.dispose();
    themesController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    tec.dispose();
    tec2.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop:(){
        //TODO Implement back press
      },
      child: StreamBuilder(
        stream: db.getLituationByID(widget.lituationVisit.lituationID),
        builder: (context , l){
          if(!l.hasData){
            return CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Theme.of(context).splashColor),);
          }
          List<String> tempThumbnails = List.from(l.data['thumbnail']);
          List<String> mediaURLs = [];
          Lituation lit = Lituation.fromJson(l.data.data());
          thumbnails.clear();
          for(String nail in tempThumbnails){
            if(!mediaURLs.contains(nail)){
              mediaURLs.add(nail);
              thumbnails.add(new CachedNetworkImage(
                  imageUrl: nail,
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: imageProvider,
                    )
                  ),
                ),

              )
              );
            }
          }
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: viewLituationNav(context, lit),
            bottomNavigationBar: widget.lituationVisit.action == "edit" ? bottomButtons(l) : null,
            body:  ListView(
                padding: EdgeInsets.fromLTRB(0,0, 0, 50),
                children: <Widget>[
                  SizedBox(
                      height: MediaQuery.of(context).size.height * 0.40,
                      width: MediaQuery.of(context).size.width,
                      child: Carousel(
                        images: thumbnails,
                        dotSize: 1.0,
                        dotSpacing: 15.0,
                        dotColor: Theme.of(context).buttonColor,
                        indicatorBgPadding: 5.0,
                        dotBgColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
                        borderRadius: true,
                        autoplay: false,
                        moveIndicatorFromBottom: 180.0,
                        noRadiusForIndicator: true,
                      )
                  ),
                  aboutRow(l.data['entry'], dateTimeToTimeStamp(l.data['date']), List.from(l.data['vibes']).length.toString()),
                  ratingRow(lit.likes, lit.dislikes),
                  pendingWidgetProvider(l),
                  lituationTitleWidget(l),
                  hostInfoProvider(l.data['hostID']),
                  attendeesWidgetProvider(l),
                  lituationTimeProvider(l),
                  lituationInfo("Entry" , l.data['entry'] , MaterialCommunityIcons.door),
                  lituationCapacityProvider(l),
                  lituationAddressInfo(l , Icons.location_on),
                  observersWidget(l),
                ],
              ),
          );
        },
      )
    );
  }

  List<Widget> thumbnailsProvider(){
    if(thumbnails.length < 1 || thumbnails.length == null){
      return noThumbnailWidget();
    }
    return thumbnails;
  }
  Widget lituationCapacityProvider(AsyncSnapshot l){
    if(_editMode){
      return capacityPicker(l, Icons.people, 'Capacity' , 'entry');
    }
    return  lituationInfo('Capacity' , capacityChecker(l.data['capacity']) , Icons.person);
  }
  //Handles time edit
  Widget lituationTimeProvider(AsyncSnapshot l){
    if(_editMode){
      return editableStartEndTimeWidget(l);
    }
    return Column(
      children: [
        lituationInfo("Date" , DateFormat.yMEd().format(dateTimeToTimeStamp(l.data['date'])),MaterialCommunityIcons.calendar),
    lituationInfo("Time:", parseDate(l.data['date'], l.data['end_date'])  , Icons.access_time),
      ],
    );
  }
  Widget editableStartEndTimeWidget(AsyncSnapshot l){
    String str;
    if(l.data['date'] == null){
      str = 'TBD';
    }else{
      str = DateFormat.yMd().addPattern('\n').format(dateTimeToTimeStamp(l.data['date']));
    }

    return Column(
      children: [
        datePicker(Icons.calendar_today_outlined, 'Date' , showDate('New Date', str),cupertinoDatePicker(l)),
        datePicker(Icons.access_time, 'Start Time' , showDate('New Start time', parseTime(l.data['date'])) ,cupertinoStartTimePicker(l)),
      datePicker(Icons.cancel, 'End Time' , showDate('New End time',  parseTime(l.data['end_date'])) ,cupertinoEndTimePicker(l)),
      ],
    );
  }
  Widget cupertinoDatePicker(AsyncSnapshot l){
    // List<String> capacityOptions = ['N/A','max'];
    return
      Container(
        margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
        height: 50,
        width: 250,
        child: CupertinoTheme(
          data: CupertinoThemeData(
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: TextStyle(color: Theme.of(context).dividerColor , fontSize: 12 , fontWeight: FontWeight.w400),
              )
          ),
          child: CupertinoDatePicker(
            minimumDate: dateTimeToTimeStamp(l.data['date']).add(new Duration(days: 1)),
            mode: CupertinoDatePickerMode.date,
            initialDateTime:dateTimeToTimeStamp(l.data['date']).add(new Duration(days: 2)),
            onDateTimeChanged: (DateTime c) {
              setState(() {
                updatedLituation.date = c;
              });
            },
          ),
        )
        ,
      );
  }
  Widget showDate(String hint , String date){
    return Container( //login button
      margin: EdgeInsets.fromLTRB(10, 25, 0, 15),
      padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
      child: Text(hint + "\n" + date, style: TextStyle(color: Theme.of(context).buttonColor , fontSize: 14),textAlign: TextAlign.left,),
    );
  }
  List<Widget> noThumbnailWidget(){
    List<Widget> nullThumbnails = [];
    nullThumbnails.add(new CachedNetworkImage(
      imageUrl: 'gs://litt-a9ee1.appspot.com/userProfiles/litlogo.png',
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              image: imageProvider,
            )
        ),
      ),
    ));
    return nullThumbnails;
  }
  Widget datePicker(IconData descIcon , String title , Widget display ,Widget picker){
    return Card(
      margin: EdgeInsets.all(10),
      elevation: 10,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: new Container(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            display,
            new Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                new Container(
                    padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                    child: Icon(descIcon , color: Theme.of(context).buttonColor,)),
                new Container(
                    width: 75,
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: new Text(title,)),
                new Expanded(
                  //width: 175,
                  child: picker,
                ),
              ],
            ),
            Padding( padding: EdgeInsets.fromLTRB(15, 10, 15, 10),)
          ],
        ),
      ),
    );
  }
  Widget pendingWidgetProvider(AsyncSnapshot l){

    if(!l.hasData){
      return Align( alignment: Alignment.center,
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Theme.of(context).splashColor)),);
    }
    if(l.data['hostID'] == widget.lituationVisit.userID) {
      List<String> pendingIDs = List.from(l.data['pending']);
      List pending = [];
      return StreamBuilder<QuerySnapshot>(
        stream: db.getAllUsers(),
        builder: (context, u) {
          if (!u.hasData) {
            return CircularProgressIndicator();
          }
          for (var user in u.data.docs) {
            if (pendingIDs.contains(user.data()['userID'])) {
              if (!pending.contains(user)) {
                pending.add(user);
              }
            }
          }
          if (pending.length > 0) {
            return Container(
              padding: EdgeInsets.fromLTRB(0, 15, 0, 5),
              color: Theme
                  .of(context)
                  .primaryColor,
              child: Column(
                children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                GestureDetector(
                  onTap: (){
                    showGuestList();
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: EdgeInsets.fromLTRB(15, 5, 0, 10),
                        child: Text(
                          'Pending RSVPs (' + pendingIDs.length.toString()+ ')',
                          style: TextStyle(color: Theme
                              .of(context)
                              .buttonColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w900),),),
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: EdgeInsets.fromLTRB(15, 0, 0, 5),
                        child: Text(
                          '(tap for guest-list)',
                          style: TextStyle(color: Theme
                              .of(context)
                              .dividerColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w200),),),
                    ],
                  ),
                ),
                    GestureDetector(
                      onTap: (){
                      setState(() {
                        minimizeRSVPS = !minimizeRSVPS;
                      });
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: 25),
                        child: Icon(minimizeRSVPS?Icons.add_circle_outline:Icons.remove_circle_outline, color: Theme
                            .of(context)
                            .buttonColor,),
                      )

                    ),
                  ],
                ),

                 minimizeableList( Container(
                   margin: EdgeInsets.fromLTRB(0, 15, 15, 0),
                   height: 75,
                   child: ListView.builder(
                       scrollDirection: Axis.horizontal,
                       itemCount: pendingIDs.length,
                       itemBuilder: (context, idx) {
                         return pendingCircularProfileWidget(pending[idx]
                             .data()['profileURL'], pending[idx].data()['userID'],
                             pending[idx].data()['username'], pending[idx].data()['status']['status']);
                       }
                   ),
                 ), minimizeRSVPS)
                ],
              ),
            );
          } else {
            return Container();
          }
        },
      );
    }
    return Container();
  }
  Widget minimizeableList(Widget listWidget , bool minimize){
    if(minimize){
      return Container();
    }else{
      return listWidget;
    }
  }

  void showGuestList(){
    Navigator.pushNamed(context, GuestListPageRoute, arguments: widget.lituationVisit);
  }

  Widget observersWidget(AsyncSnapshot l){
    if(!l.hasData){
      return Align( alignment: Alignment.center,
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Theme.of(context).splashColor)),);
    }
    List<String> observerIDs = List.from(l.data['observers']);
    List observers = [];
    List<String> addedObservers = [];
    return StreamBuilder<QuerySnapshot>(
      stream: db.getAllUsers(),
      builder: (context , u){
        if(!u.hasData){
          return CircularProgressIndicator();
        }
        for(var user in u.data.docs){
          if(observerIDs.contains(user.data()['userID'])){
            if(!addedObservers.contains(user.data()['userID'].toString())){
              observers.add(user);
              addedObservers.add(user.data()['userID'].toString());
            }
          }
        }
        if(observers.length > 0){
          return Container(
            margin: EdgeInsets.fromLTRB(5, 5, 5, 5),
            padding: EdgeInsets.fromLTRB(0, 15, 0, 5),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                Container(
                  alignment:  Alignment.centerLeft,
                  margin: EdgeInsets.fromLTRB(15, 5, 0, 5),
                  child: Text('observers (' + addedObservers.length.toString() + ')' , style: TextStyle(color: Theme.of(context).textSelectionColor, fontSize: 16 ,fontWeight: FontWeight.w900),),),
                Container(
                  margin: EdgeInsets.fromLTRB(0, 15, 15, 0) ,
                  height: 90,
                  child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: addedObservers.length,
                      itemBuilder: (context , idx){
                        return circularProfileWidget(observers[idx].data()['profileURL'],observers[idx].data()['userID'], observers[idx].data()['username'], observers[idx].data()['status']['status']);
                      }
                  ),
                ),
              ],
            ),
          );
        }else{
          return Container();
        }
      },
    );
  }

  Widget attendButton(bool going ,bool rsvpd, String entry){
    print(entry);
    if(entry.toLowerCase().contains('invite')){
      String val = 'RSVP';
      Color col = Colors.red;
      if(rsvpd){
        col = Colors.green;
        val = 'RSVP\'d';
      }
      return RaisedButton(
          color: col,
          textColor: Theme.of(context).primaryColor,
          child: Text(val , style: Theme.of(context).textTheme.button,),
          onPressed: (){
            rsvp();
          }, shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0))
      );
    }
    String val = 'attend';
    Color col = Colors.red;
    if(going){
      col = Colors.green;
      val = 'attending';
    }
    return RaisedButton(
        color: col,
        textColor: Theme.of(context).primaryColor,
        child: Text(val , style: Theme.of(context).textTheme.button,),
        onPressed: (){
          attend();
        }, shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0))
    );
  }

  Widget closeButton(){
    Color col = Colors.red;
    return RaisedButton(
        color: col,
        textColor: Theme.of(context).primaryColor,
        child: Text('close' , style: Theme.of(context).textTheme.button,),
        onPressed: (){
          print('aye');          
          Navigator.pushReplacementNamed(context, HomePageRoute);
        }, shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0))
    );
  }

  Widget observeButton(bool already){
    String val = 'watch';
    Color col = Colors.red;
    if(already){
      val = 'watching';
      col = Colors.green;
    }
    return RaisedButton(
        color: col,
        textColor: Theme.of(context).primaryColor,
        child: Text(val , style: Theme.of(context).textTheme.button,),
        onPressed: (){
         observe();
        }, shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0))
    );
  }

  Widget updateButton(AsyncSnapshot l){
    return RaisedButton(
        color: _editMode==true?Colors.green:Theme.of(context).buttonColor,
        textColor: Theme.of(context).primaryColor,
        child: Text(_editMode == true?'save':'update' , style: Theme.of(context).textTheme.button,),
        onPressed: (){
              _editMode?_updateLituation(l, updatedLituation):update();
        }, shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0))
    );
  }
  void update(){
    setState(() {
      _editMode = !_editMode;
    });
  }
  Future<void> _updateLituation(AsyncSnapshot l , Lituation update) async {
    setState(() {
    if(update.title != null && update.title != l.data['title']){
      print(update.title);
      db.updateLituationTitle(widget.lituationVisit.lituationID, update.title);
    }
    if(update.description != null && update.description != l.data['description']){
      db.updateLituationDescription(widget.lituationVisit.lituationID, update.description);
    }
    if(update.date != null && update.date != dateTimeToTimeStamp(l.data['date'])){
      db.updateLituationDate(widget.lituationVisit.lituationID, update.date);
    }
    if(update.end_date != null && update.end_date != dateTimeToTimeStamp(l.data['end_date'])){
      db.updateLituationEndDate(widget.lituationVisit.lituationID, update.end_date);
    }
    if(update.capacity != null && update.capacity != l.data['capacity']){
      db.updateLituationCapacity(widget.lituationVisit.lituationID, update.capacity);
    }
    if(update.location != null && update.location != l.data['location']){
      db.updateLituationLocation(widget.lituationVisit.lituationID, update.location);
    }
    if(update.locationLatLng != null && update.locationLatLng != l.data['locationLatLng']){
      db.updateLituationLocationLatLng(widget.lituationVisit.lituationID, update.locationLatLng);
    }

      _editMode = !_editMode;
    });
  }
  Widget hostBottomButtons(AsyncSnapshot l){
    return Container(
      padding: EdgeInsets.fromLTRB(5, 15, 5, 15),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 45,
              margin: EdgeInsets.fromLTRB(5, 0, 5, 0),
              child: updateButton(l),
            )
          ),
          Expanded(
              child: Container(
                height: 45,
                margin: EdgeInsets.fromLTRB(5, 0, 5, 0),
                child: closeButton(),
              )
          ),
        ],
      ),
    );
  }

  Widget visitorButtons(bool already, bool going,bool rsvp, String entry){
    return Container(
      padding: EdgeInsets.fromLTRB(5, 15, 5, 15),
      child: Row(
        children: [
          Expanded(
              child: Container(
                height: 45,
                margin: EdgeInsets.fromLTRB(5, 0, 5, 0),
                child: attendButton(going ,rsvp, entry),
              )
          ),
          Expanded(
              child: Container(
                height: 45,
                margin: EdgeInsets.fromLTRB(5, 0, 5, 0),
                child: observeButton(already),
              )
          ),
        ],
      ),
    );
  }
  void checkInButton(){}
  void observe(){
    db.watchLituation(widget.lituationVisit.userID, widget.lituationVisit.lituationID);
  }
  void attend(){
    db.attendLituation(widget.lituationVisit.userID, widget.lituationVisit.lituationID);
  }
  void approveUser(String userID){
    db.approveUser(userID, widget.lituationVisit.lituationID);
  }
  void removeUser(String userID){
    //todo ask are u sure?
    db.removeUserFromLituation(userID, widget.lituationVisit.lituationID);
  }
  //cancels user rsvp
  void cancelUser(String userID){
    db.cancelRSVP(userID, widget.lituationVisit.lituationID);
  }
  void rsvp(){
    db.rsvpToLituation(widget.lituationVisit.userID, widget.lituationVisit.lituationID);
  }
  Widget bottomButtons(AsyncSnapshot l){
   List<String> vibingIDS = List.from(l.data['vibes']);
   bool already = false;
   bool going = false;
   bool rsvpd = false;
   if(l.data['hostID'] == widget.lituationVisit.userID){
      return hostBottomButtons(l);
   }
   if(vibingIDS.contains(widget.lituationVisit.userID))
     {
       going = true;
     }
   if(List.from(l.data['observers']).contains(widget.lituationVisit.userID)){
     already = true;
   }
   if(List.from(l.data['pending']).contains(widget.lituationVisit.userID)){
     rsvpd = true;
   }
   return visitorButtons(already ,going,rsvpd, l.data['entry']);
  }
  String parseDate(Timestamp sd , Timestamp ed){
    int c = 1000;
    DateTime sdate = DateTime.fromMicrosecondsSinceEpoch(sd.millisecondsSinceEpoch * c);
    DateTime edate = DateTime.fromMicrosecondsSinceEpoch(ed.millisecondsSinceEpoch * c);
    return DateFormat.jm().format(sdate) + " - " + DateFormat.jm().format(edate);
  }
  String parseTime(Timestamp sd){
    int c = 1000;
    DateTime sdate = DateTime.fromMicrosecondsSinceEpoch(sd.millisecondsSinceEpoch * c);
    return DateFormat.jm().format(sdate);
  }
  DateTime dateTimeToTimeStamp(Timestamp d){
    return  DateTime.fromMicrosecondsSinceEpoch(d.millisecondsSinceEpoch * 1000);
  }
  Widget lituationTitleWidget(AsyncSnapshot l){
    if(_editMode){
      return editableLituationTitleWidget(l);
    }
    return lituationDescription(l);
  }
  Widget editableLituationTitleWidget(l){
    if(tec.text == ''){ tec = new TextEditingController(text: l.data['title']);}
    if(tec2.text == ''){ tec2 = new TextEditingController(text: l.data['description']);}
    return Card(
      elevation: 5,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Container(
        padding: EdgeInsets.fromLTRB(0, 15, 0, 50),
        child:  Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  child: Container(
                      padding: EdgeInsets.fromLTRB(15 , 10 , 0 , 0),
                      child:  TextField(
                        maxLines: null,
                        autofocus: false,
                        maxLength: 35,
                        cursorColor: Theme.of(context).buttonColor,
                        controller: tec,
                        style: TextStyle(color: Theme.of(context).buttonColor , fontSize: 24),
                        onChanged: (input){
                          setState(() {
                            updatedLituation.title = input;
                          });
                        },
                      )
                  )
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.all(15.0),
            alignment: Alignment.topLeft,
            child: Text("Description:" ,style: TextStyle(color: Theme.of(context).buttonColor,fontSize: 16 ,fontWeight: FontWeight.w900),textAlign: TextAlign.left,),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  child: Container(
                      padding: EdgeInsets.fromLTRB(15 , 10 , 0 , 0),
                      child:  TextField(
                        maxLines: null,
                        autofocus: false,
                        maxLength: 500,
                        cursorColor: Theme.of(context).buttonColor,
                        controller: tec2,
                        style: TextStyle(color: Theme.of(context).dividerColor , fontSize: 14),
                        onChanged: (input){
                          setState(() {
                            updatedLituation.description = input;
                          });
                        },
                      )
                  )
              ),
            ],
          ),
        ],),
      ),
    );
  }

  SnackBar sBar(String text){
    return SnackBar(
        backgroundColor: Theme.of(context).primaryColor,
        content: Text(text , style: TextStyle(color: Theme.of(context).textSelectionColor),));
  }
  Widget ratingRow(List<String> likes , List<String> dislikes){
    String up = "${likes != null? likes.length : 0} lit";
    String down = "${dislikes != null? dislikes.length : 0} nope";

    return Card(
      elevation: 5,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [      
          Expanded( //lo
            child:    GestureDetector(
                onTap: (){
                  if (likes.contains(widget.lituationVisit.userID)) {
                    return _scaffoldKey.currentState.showSnackBar(sBar('You already lit!'));
                  }
                  if (dislikes.contains(widget.lituationVisit.userID)) {
                    return _scaffoldKey.currentState.showSnackBar(sBar('You already nope!'));
                  }
                  db.addLikeLituation(widget.lituationVisit.userID, widget.lituationVisit.lituationID);
                },
                child: Container(
                    padding: EdgeInsets.all(10.0),
                    child:  Column(
                      children: [
                        Icon(Icons.local_fire_department , color: Theme.of(context).primaryColor,),
                        Text(up, style: TextStyle(color: Theme.of(context).textSelectionColor , fontSize: 14)),
                      ],
                    )
                )
            ),
          ), 
          Expanded( //lo
            child:    GestureDetector(
                onTap: (){
                  if (likes.contains(widget.lituationVisit.userID)) {
                    return _scaffoldKey.currentState.showSnackBar(sBar('You already lit!'));
                  }
                  if (dislikes.contains(widget.lituationVisit.userID)) {
                    return _scaffoldKey.currentState.showSnackBar(sBar('You already nope!'));
                  }
                  db.addDislikeLituation(widget.lituationVisit.userID, widget.lituationVisit.lituationID);
                },
                child: Container(
                    padding: EdgeInsets.all(10.0),
                    child:  Column(
                      children: [
                        Icon(Icons.fire_extinguisher , color: Theme.of(context).primaryColor,),
                        Text(down, style: TextStyle(color: Theme.of(context).textSelectionColor , fontSize: 14)),
                      ],
                    )
                )
            ),
          ),
        ],
      ),
    );
  }
  Widget aboutRow(String entry , DateTime date , String vibing){
    String str;
    if(date == null){
      str = 'TBD';
    }else{
      str = DateFormat.yMd().addPattern('\n').format(date);
    }

    return Card(
      elevation: 5,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded( //lo
            child:    GestureDetector(
                onTap: (){

                },
                child: Container(
                    padding: EdgeInsets.all(10.0),
                    child:  Column(
                      children: [
                        Icon(MaterialCommunityIcons.door , color: Theme.of(context).primaryColor,),
                        Text(entry, style: TextStyle(color: Theme.of(context).textSelectionColor , fontSize: 14)),
                      ],
                    )
                )
            ),
          ),
          calendarWidget(str),
          Expanded( //lo
            child:    GestureDetector(
                onTap: (){

                },
                child: Container(
                    padding: EdgeInsets.all(10.0),
                    child:  Column(
                      children: [
                        Icon(Icons.people , color: Theme.of(context).primaryColor,),
                        Text(vibing + ' vibed', style: TextStyle(color: Theme.of(context).textSelectionColor , fontSize: 14), textAlign: TextAlign.center,),
                      ],
                    )
                )
            ),
          ),
        ],
      ),
    );
  }
  Widget calendarWidget(String date){
    return Expanded( //lo
        child:    GestureDetector(
            onTap: (){},
            child: Container(
                margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                padding: EdgeInsets.all(10.0),
                child:  Column(
                  children: [
                    Icon(Icons.calendar_today , color: Theme.of(context).primaryColor,),
                    Text(date, style: TextStyle(color: Theme.of(context).textSelectionColor , fontSize: 14)),
                  ],
                )
            )
        )
    );
  }
  String capacityChecker(String capacity){
    if(capacity == null || capacity == ''){
      return 'N/A';
    }else{
      return capacity;
    }
  }

  String checkTBD(String val){
    if(val ==""){
      return "TBD";
    }
    return val;
  }


  Widget attendeesWidgetProvider(AsyncSnapshot l){
    if(!l.hasData){
      return Align( alignment: Alignment.center,
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Theme.of(context).splashColor)),);
    }
   if(l.data['hostID'].toString() == widget.lituationVisit.userID){
     return hostAttendeesWidget(l);
   }else{
     return attendeesWidget(l);
   }
  }

  Widget attendeesWidget(AsyncSnapshot l){
   if(!l.hasData){
     return Align( alignment: Alignment.center,
     child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Theme.of(context).splashColor)),);
   }
   List<String> attendeesIDs = List.from(l.data['vibes']);
   List attendees = [];
   List<String> addedIDs = [];
   return StreamBuilder<QuerySnapshot>(
     stream: db.getAllUsers(),
     builder: (context , u){
       if(!u.hasData){
         return CircularProgressIndicator();
       }
       for(var user in u.data.docs){
         if(attendeesIDs.contains(user.data()['userID'])){
             if(!addedIDs.contains(user.data()['userID'].toString())){
               attendees.add(user);
               addedIDs.add(user.data()['userID'].toString());
             }
           }
       }
       if(attendees.length > 0){
         return Container(
           padding: EdgeInsets.fromLTRB(0, 15, 0, 5),
           color: Theme.of(context).scaffoldBackgroundColor,
           child: Column(
             children: [
               Container(
                 alignment:  Alignment.centerLeft,
                 margin: EdgeInsets.fromLTRB(15, 5, 0, 5),
                 child: Text('vibes (' + addedIDs.length.toString() + ')'  , style: TextStyle(color: Theme.of(context).textSelectionColor, fontSize: 16 ,fontWeight: FontWeight.w900),),),
               Container(
                 margin: EdgeInsets.fromLTRB(0, 15, 15, 0) ,
                 height: 75,
                 child: ListView.builder(
                     scrollDirection: Axis.horizontal,
                     itemCount: attendees.length,
                     itemBuilder: (context , idx){
                       return circularProfileWidget(attendees[idx].data()['profileURL'],attendees[idx].data()['userID'], attendees[idx].data()['username'], attendees[idx].data()['status']['status']);
                     }
                 ),
               ),
             ],
           ),
         );
       }else{
         return Container();
       }
     },
   );
  }
  Widget hostAttendeesWidget(AsyncSnapshot l){
    if(!l.hasData){
      return Align( alignment: Alignment.center,
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Theme.of(context).splashColor)),);
    }
    List<String> attendeesIDs = List.from(l.data['vibes']);
    List attendees = [];
    return StreamBuilder<QuerySnapshot>(
      stream: db.getAllUsers(),
      builder: (context , u){
        if(!u.hasData){
          return CircularProgressIndicator();
        }
        for(var user in u.data.docs){
          if(attendeesIDs.contains(user.data()['userID'])){
            if(!attendees.contains(user)){
              attendees.add(user);
            }
          }
        }
        if(attendees.length > 0){
          return Container(
            padding: EdgeInsets.fromLTRB(0, 15, 0, 5),
            color: Theme.of(context).primaryColor,
            child: Column(
              children: [
                Container(
                  alignment:  Alignment.centerLeft,
                  margin: EdgeInsets.fromLTRB(15, 5, 0, 5),
                  child: Text('attending vibes (' + attendeesIDs.length.toString() + ')' , style: TextStyle(color: Theme.of(context).buttonColor, fontSize: 16 ,fontWeight: FontWeight.w900),),),
                Container(
                  margin: EdgeInsets.fromLTRB(0, 15, 15, 0) ,
                  height: 75,
                  child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: attendeesIDs.length,
                      itemBuilder: (context , idx){
                        return cancelableCircularProfileWidget(attendees[idx].data()['profileURL'],attendees[idx].data()['userID'], attendees[idx].data()['username'], attendees[idx].data()['status']['status']);
                      }
                  ),
                ),
              ],
            ),
          );
        }else{
          return Container();
        }
      },
    );
  }
  Widget hostInfoProvider(String hostID){
    return  StreamBuilder(
      stream:db.getUser(hostID),
      builder: (ctx, u){
        return !u.hasData
            ?new Text("loading" , style: TextStyle(color: Theme.of(context).buttonColor),)
            : hostInfo(u.data['userID'], u.data['username'], u.data['profileURL'], ctx);
      },
    );
  }
  Future<bool> _onBackPressed() {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).primaryColor,
            title: Text('Discard your changes?' ,style: TextStyle(color: Theme.of(context).buttonColor),),
            actions: <Widget>[
              FlatButton(
                child: Text('No' ,style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              FlatButton(
                child: Text('Yes' ,style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        });
  }

  Widget viewLituationNav(BuildContext ctx, Lituation lit){
    return AppBar(
      leading: Container(
        padding: EdgeInsets.all(10),
        child:  IconButton(
          icon: Icon(Icons.arrow_back_ios,color: Theme.of(context).textSelectionColor,size: 25,
          ),
          onPressed: (){Navigator.of(ctx).pop();},
        ),
      ) ,
      backgroundColor: Theme.of(context).primaryColor,
      centerTitle: true,
      title: Container(
          padding: EdgeInsets.fromLTRB(25, 10, 25, 0),
          child: Text(widget.lituationVisit.lituationName, style: TextStyle(color: Theme.of(context).textSelectionColor),)
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.share),
          onSelected: (String result) async {
            switch (result) {
              case 'invite':
                print('filter 1 clicked');       
                showDialog(context: context,
                  builder: (BuildContext context){
                  return InviteView(
                    lit: lit,
                    userID: widget.lituationVisit.userID
                  );
                  }
                );
                break;
              case 'share':
                sendEmail(lit);         
                break;
              default:
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'invite',
              child: Text('Invite'),
            ),
            const PopupMenuItem<String>(
              value: 'share',
              child: Text('Share'),
            ),            
          ],
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert),
          onSelected: (String result) async {
            switch (result) {
              case 'calendar':
                print('filter 1 clicked');
                addEvent2Calendar(lit);
                break;
              case 'ticket_check':
                print('filter 2 clicked');
                await checkTicket(lit);               
                break;
              case 'ticket_generate':
                print('Clear filters');                
                showDialog(context: context,
                  builder: (BuildContext context){
                  return QRViewer(
                    lit: lit,
                    userID: widget.lituationVisit.userID
                  );
                  }
                );
                break;
              default:
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'calendar',
              child: Text('Add to calendar'),
            ),
            const PopupMenuItem<String>(
              value: 'ticket_check',
              child: Text('Ticket Check'),
            ),
            const PopupMenuItem<String>(
              value: 'ticket_generate',
              child: Text('Ticket Generate'),
            ),
          ],
        ),
      ],
    );
  }

  checkTicket(Lituation lit) async {    
    try {
      await Permission.camera.request();
      String barcode = await scanner.scan();
      List<String> codes = barcode.split(":");
      if (codes[0] == QR_ID && codes.length >= 3) {
        if(codes[1] == lit.eventID /*&& lit.invited.contains(codes[2])*/) {
          return Alert(
            context:_scaffoldKey.currentContext, 
            title: "Success",
            desc: "This user can attend.",
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
      Alert(
          context:_scaffoldKey.currentContext, 
          title: "Failed",
          desc: "This user can't attend.",
          type: AlertType.error,
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
      print(barcode);
    } catch (e) {

    }
  }

  void _toProfile(String uID){
    Navigator.pushReplacementNamed(context, HomePageRoute , arguments: uID);
  }

  String parseThemes(AsyncSnapshot l){
    List<String> themes = l.data['themes'].split(',');
    List<String> themes2 = [];
    String themesStr = "";
    for(String t in themes){
      if(!themes2.contains('@'+t)) {
        t = '@' + t;
        themes2.add(t);
      }
    }
    themesStr = themes2.toString().replaceAll('[', '').replaceAll(']', '');
    return themesStr;
  }
  Widget lituationDescription(AsyncSnapshot l){
    return Card(
      elevation: 5,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Container(
        padding: EdgeInsets.fromLTRB(0, 15, 0, 50),
        child:  Column(children: [
          Container(
            margin: EdgeInsets.fromLTRB(15,0, 0, 5),
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.fromLTRB(0,0, 0, 0),
            child: Text(l.data['title'], style: TextStyle(decoration: TextDecoration.underline,color: Theme.of(context).textSelectionColor , fontSize: 24),textAlign: TextAlign.center, ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(15,10, 0, 15),
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.fromLTRB(0,0, 0, 0),
            child:      Text(parseThemes(l)  ,style: TextStyle(color: Colors.blue , fontSize: 12))
          ),
          Container(
            padding: EdgeInsets.only(top: 10.0 , left: 15 , bottom: 10),
            alignment: Alignment.topLeft,
            child: Text("Description:" ,style: TextStyle(color: Theme.of(context).textSelectionColor,fontSize: 16 ,fontWeight: FontWeight.w900),textAlign: TextAlign.left,),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(15 , 10 , 15 , 0),
                    child: Text(l.data['description'],style: TextStyle(color: Theme.of(context).textSelectionColor , fontSize: 14),textAlign: TextAlign.left,),
                  )
              ),
            ],
          ),
        ],),
      ),
    );
  }
  LatLng latLngFromGeoPoint(GeoPoint gp){
    LatLng l = new LatLng(gp.latitude, gp.longitude);
    return l;
  }
  GeoPoint geoPointFromLatLng(LatLng l){
    GeoPoint gp = new GeoPoint(l.latitude, l.longitude);
    return gp;
  }
  Future<void> initLituationLocation(AsyncSnapshot l) async {
    final GoogleMapController ctrl = await _controller.future;
    locationIcon = await getBytesFromAssetFile('assets/images/litlocationicon.png' ,250);
    if(l.hasData && l.data['location'] != null) {
      setState(() {
        lituationLatLng = latLngFromGeoPoint(l.data["locationLatLng"]);
        _markers.clear();
        _markers.add(Marker(markerId: MarkerId('It\'s lit'),
            position: lituationLatLng,
            icon: BitmapDescriptor.fromBytes(locationIcon)
        )
        );

      });
      ctrl.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            bearing: 0,
            target: lituationLatLng,
            zoom: 16.0,
          )
      ));
    }
  }
  Future<Uint8List> getBytesFromAssetFile(String path , int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    return( await frameInfo.image.toByteData(format: ui.ImageByteFormat.png)).buffer.asUint8List();
  }
  Widget lituationAddressInfo(AsyncSnapshot l, IconData icon){
    if(_editMode){
      return editableLituationAddressInfo(l, icon);
    }
    String title = 'Address';
    String value = checkTBD(l.data['location']);
    if(lituationLatLng == LatLng(0 , 0)){
      initLituationLocation(l);
    }
    return Card(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 10,
      child:  Container(
          margin: EdgeInsets.fromLTRB(10 ,10 , 10 , 0),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(10.0 , 10 , 25, 25),
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                          child: Text(title ,style: TextStyle(color: Theme.of(context).textSelectionColor,fontSize: 16 ,fontWeight: FontWeight.w900),textAlign: TextAlign.left,),),
                        Container(
                          padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                          margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                          child:Text(value ,style: TextStyle(color: Theme.of(context).textSelectionColor),textAlign: TextAlign.start,),),
                      ],
                    ),),

                    Container(
                        padding: EdgeInsets.fromLTRB(0, 25, 0, 0),
                        child:  Icon(icon, color: Theme.of(context).primaryColor, size: 25,)
                    ),
                  ],
                ),
              ),
              mapsWidget(),
            ],
          )
      ),
    );
  }
  Widget editableLituationAddressInfo(AsyncSnapshot l, IconData icon){
    String title = 'New Address';
    String value = checkTBD(l.data['location']);
    return Card(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 10,
      child:  Container(
          margin: EdgeInsets.fromLTRB(10 ,10 , 10 , 0),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(10.0 , 10 , 25, 25),
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                          child: Text(title ,style: TextStyle(color: Theme.of(context).textSelectionColor,fontSize: 16 ,fontWeight: FontWeight.w900),textAlign: TextAlign.left,),),
                        Container(
                          padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                          margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                          child:Text(updatedLituation.location!=null?updatedLituation.location:value ,style: TextStyle(color: Theme.of(context).textSelectionColor),textAlign: TextAlign.start,),),
                      ],
                    ),),

                    Container(
                        padding: EdgeInsets.fromLTRB(0, 25, 0, 0),
                        child:  Icon(icon, color: Theme.of(context).primaryColor, size: 25,)
                    ),
                  ],
                ),
              ),
              mapsWidget(),
              addressSearchBar(),
            ],
          )
      ),
    );
  }
  Widget addressSearchBar(){
    return Container(
      margin: EdgeInsets.only(top: 25 , left: 15 , right: 15 , bottom: 15),
      child: TypeAheadField(
        textFieldConfiguration: TextFieldConfiguration(
            cursorColor: Theme.of(context).buttonColor,
            controller: addressController,
            autofocus: false,
            style: TextStyle(color: Theme.of(context).dividerColor),
            decoration: InputDecoration(
                labelText: 'Select the new address',
                hintText: "e.g 123 MyAddress Rd, City 54321, United States",
                hintStyle: TextStyle(color: Theme.of(context).textSelectionColor , fontSize: 12 , decoration: TextDecoration.none),
                labelStyle: TextStyle(color: Theme.of(context).textSelectionColor , fontSize: 14 ,decoration: TextDecoration.none),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).textSelectionColor , width: 1),),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).textSelectionColor , width: 2))

            )
        ),
        suggestionsCallback: (pattern) async {
          var locationIcon = await getBytesFromAssetFile('assets/images/litlocationicon.png' ,225);
          return searchAddress(pattern).then((value){
            List<Marker> resultMarkers = [];
            if(value.length > 0) {
              moveCamera(CameraPosition(
                bearing: 0,
                zoom: 16,
                target: LatLng(value[0].geometry.location.lat,
                    value[0].geometry.location.lng),
              ));
              for(PlacesSearchResult place in places){
                LatLng pos = LatLng(place.geometry.location.lat , place.geometry.location.lng);
                resultMarkers.add(googleMapMarker(place.name, BitmapDescriptor.fromBytes(locationIcon), pos));
              }
              drawMarkers(resultMarkers);
            }
            return value;
          });
        }
        ,
        itemBuilder: (context, PlacesSearchResult suggestion) {
          return Material(
              color: Theme.of(context).primaryColor,
              child: Card(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: ListTile(
                  contentPadding: EdgeInsets.all(5),
                  leading: Image.asset('assets/images/litlocationicon.png'),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(suggestion.name , style: TextStyle(color: Theme.of(context).textSelectionColor, decoration: TextDecoration.none , fontSize: 14)),
                      Padding(padding: EdgeInsets.only(bottom: 10)),
                      Text(suggestion.formattedAddress , style: TextStyle(color: Theme.of(context).textSelectionColor , decoration: TextDecoration.none , fontSize: 12.5)),

                    ],
                  ),
                ),
              )
          );
        },
        onSuggestionSelected: (PlacesSearchResult suggestion) {
          setState(() {
            updatedLituation.location = suggestion.formattedAddress;
            lituationLatLng = LatLng(suggestion.geometry.location.lat , suggestion.geometry.location.lng);
            updatedLituation.locationLatLng = lituationLatLng;
            addressController.text = suggestion.name;
            drawMarker(googleMapMarker(suggestion.name, myIcon, LatLng(suggestion.geometry.location.lat , suggestion.geometry.location.lng)));
          });
          moveCamera(CameraPosition(
            bearing: 0,
            zoom: 16,
            target: updatedLituation.locationLatLng,
          ));
        },
      ),
    );
  }
  Marker googleMapMarker(String title , BitmapDescriptor icon , LatLng pos){
    return Marker(
      markerId: MarkerId(title),
      position: pos,
      icon: icon,
    );
  }
  Future<List<PlacesSearchResult>> searchAddress(String query) async {
    final result = await _places.searchByText(query);
    _markers.clear();
    addressResults.clear();
    if(result.status == "OK"){
      places = result.results;
      result.results.forEach((a){
        print(a.formattedAddress);
      });
    }
    return places;
  }
  Future<void> moveCamera(CameraPosition cameraPosition) async {
    final GoogleMapController ctrl = await _controller.future;
    ctrl.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }
  Future<void> drawMarkers(List<Marker> newMarkers) async {
    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
    });
    return;
  }
  Future<void> drawMarker(Marker n) async {
    var locationIcon = await getBytesFromAssetFile('assets/images/litlocationicon.png' ,250);
    Marker k = Marker(markerId: n.markerId , position: n.position , icon: BitmapDescriptor.fromBytes(locationIcon));
    setState(() {
      _markers.clear();
      _markers.add(k);
      print(k.markerId);
    });
    return;
  }
  Widget lituationInfo(String title , String value , IconData icon){
    return Card(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 10,
      child:  Container(
          margin: EdgeInsets.fromLTRB(10 ,10 , 10 , 0),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(10.0 , 10 , 25, 25),
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                          child: Text(title ,style: TextStyle(color: Theme.of(context).textSelectionColor,fontSize: 16 ,fontWeight: FontWeight.w900),textAlign: TextAlign.left,),),
                        Container(
                          padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                          margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                          child:Text(value ,style: TextStyle(color: Theme.of(context).textSelectionColor),textAlign: TextAlign.start,),),
                      ],
                    ),),

                    Container(
                        padding: EdgeInsets.fromLTRB(0, 25, 0, 0),
                        child:  Icon(icon, color: Theme.of(context).primaryColor, size: 25,)
                    ),
                  ],
                ),

              ),
            ],
          )
      ),
    );
  }
  Widget mapsWidget(){
    return Container(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
      height: 350,
      child: GoogleMap(
        markers: _markers,
        mapType: _mapType,
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
            target: lituationLatLng,
            zoom: zoom
        ),
      )
      ,);
  }
  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      if(!_controller.isCompleted)
        _controller.complete(controller);
    });
  }
  Widget nullProfileUrl(){
    return Container(
      padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
      width: 125.0,
      height: 125.0,
      decoration: BoxDecoration(
        border: Border.all(color: primaryColor),
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
  void _viewProfile(String visitorID , String visitedID , BuildContext context){
    UserVisit u = UserVisit(visitorID: visitorID , visitedID: visitedID);
    Navigator.pushNamed(context, VisitProfilePageRoute, arguments: u);
  }

  Widget hostInfo(String hostID, String username, String url , BuildContext ctx){
    if(hostID == widget.lituationVisit.userID){
      return Container();
    }
    return Container(
      child: Card(
            elevation: 5,
            child:  Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: EdgeInsets.fromLTRB(5, 15, 15, 15),
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.fromLTRB(0, 0, 0, 15),
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                      child: Text('host:' ,style: TextStyle(color: Theme.of(context).buttonColor,fontSize: 16 ,fontWeight: FontWeight.w900),textAlign: TextAlign.left,),),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                              child: CachedNetworkImage(
                                height: 50,
                                width: 50,
                                imageUrl: url,
                                imageBuilder: (context, imageProvider) => Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Theme.of(context).splashColor),
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                placeholder: (context, url) => CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Theme.of(context).splashColor),),
                                errorWidget: (context, url, error) => nullProfileUrl(),
                              ),
                            ),
                            Container(
                                margin: EdgeInsets.fromLTRB(15, 0, 0, 0),
                                child: new Text(username ,
                                  style: TextStyle(color: Theme.of(context).dividerColor , fontFamily: 'sans-serif'),textAlign: TextAlign.center,textScaleFactor: 1.2,)
                            ),],
                        ),
                        Container(
                          height: 35,
                          width: 75,
                          child: RaisedButton(
                            onPressed: (){_viewProfile(widget.lituationVisit.userID , hostID, ctx);},
                            color: Theme.of(context).buttonColor,
                            textColor: Theme.of(context).primaryColor,
                            child: Text('visit' , style: Theme.of(context).textTheme.button,),
                          ),)
                      ],

                    )
                  ],
                )),
          )

    );
  }



  bool getStatusAsBool(String status){
    //Online , Live , etc
    if(status.contains('online') || status.contains('live')){
      return true;
    }
    return false;
  }
  Widget cancelableCircularProfileWidget(String url ,String userID , String username , String status){
    bool online = getStatusAsBool(status);
    return GestureDetector(
      onTap: (){if(userID != widget.lituationVisit.userID){
        _viewProfile(widget.lituationVisit.userID, userID, context);
      }
      },
      child: Container(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                    child: CachedNetworkImage(
                      height: 45,
                      width: 45,
                      imageUrl: url,
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: statusRingColor(online)),
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      placeholder: (context, url) => CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Theme.of(context).splashColor),),
                      errorWidget: (context, url, error) => nullProfileUrl(),
                    ),
                  ),
                  Container(
                      margin: EdgeInsets.fromLTRB(15, 0, 0, 0),
                      child: new Text(username ,
                        style: Theme.of(context).primaryTextTheme.headline4,textAlign: TextAlign.center,textScaleFactor: 0.9,)
                  ),
                ],
              ),
              removeButton(userID),
            ],
          )
      ),
    );
  }
  Widget showCap(AsyncSnapshot l){
    return Container( //login button
      margin: EdgeInsets.fromLTRB(10, 25, 0, 15),
      padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
      child: Text('Change Capacity:' + "\n" + capacityChecker(l.data['capacity']), style: TextStyle(color: Theme.of(context).buttonColor , fontSize: 14),textAlign: TextAlign.left,),
    );
  }
  Widget capacityInput() {
    bool hasCapacity;
    if(updatedLituation.capacity != null && updatedLituation.capacity.toLowerCase().contains('max')){
      hasCapacity = true;
    }else{
      hasCapacity = false;
    }
    if (hasCapacity) {
      return Container(
        margin: EdgeInsets.fromLTRB(5, 15, 15, 0),
        width: 125,
        child: TextField(
          controller: capController,
          maxLengthEnforced: true,
          textAlign: TextAlign.center,
          onSubmitted: (input) {
            if (input
                .trim()
                .isEmpty) {
              return 'please enter a valid number';
            }
            if (input == '0') {
              return 'set to N/A';
            }
          },
          onChanged: (input) {

              updatedLituation.capacity = input.toString();
              print(updatedLituation.capacity);

          },
          keyboardType: TextInputType.number,
          maxLines: 1,
          maxLength: 9,
          style: TextStyle(color: Theme.of(context).dividerColor),
          cursorColor: Theme.of(context).buttonColor,
          decoration: InputDecoration(
              suffixIcon: Icon(Icons.person , color: Theme.of(context).buttonColor,),
              labelText: 'Cap: ' + updatedLituation.capacity != null?updatedLituation.capacity : 'is 0',
              labelStyle: TextStyle(color: Theme.of(context).buttonColor , fontSize: 14 , fontWeight: FontWeight.w900),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).buttonColor, width: 1),),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).buttonColor, width: 2))
          ),
        ),
      );
    }else{
      return Container();
    }
  }
  Widget capacityPicker(AsyncSnapshot l ,IconData descIcon , String title , String value){
    return Card(
      margin: EdgeInsets.all(10),
      elevation: 10,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: new Container(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            showCap(l),
            new Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                new Container(
                    padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                    child: Icon(descIcon , color: Theme.of(context).buttonColor,)),
                new Container(
                    width: 75,
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: new Text(title)),
                new Expanded(
                  //width: 175,
                  child: capacityPickerOptions(),
                ),
                new Expanded(
                  //width: 175,
                  child: capacityInput(),
                )
              ],
            ),
            Padding( padding: EdgeInsets.fromLTRB(15, 10, 15, 10),)
          ],
        ),
      ),
    );
  }

  Widget capacityPickerOptions(){
    List<String> capacityOptions = ['N/A','max'];
    return
      CupertinoPicker(
          magnification: 1,
          //backgroundColor: Theme.of(context).primaryColor,
          children: <Widget>[
            pickerButton(capacityOptions[0]),
            pickerButton(capacityOptions[1]),
          ],
          itemExtent: 50, //height of each item
          looping: true,
          onSelectedItemChanged: (int index) {
            setState(() {
              updatedLituation.capacity = capacityOptions[index];
            });
          }
      );
  }
  Widget pendingCircularProfileWidget(String url ,String userID , String username , String status){
    bool online = getStatusAsBool(status);
    return GestureDetector(
      onTap: (){if(userID != widget.lituationVisit.userID){
        _viewProfile(widget.lituationVisit.userID, userID, context);
      }
      },
      child: Container(
          child:
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      approveButton(userID),
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: CachedNetworkImage(
                      height: 45,
                      width: 45,
                      imageUrl: url,
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: statusRingColor(online)),
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      placeholder: (context, url) => CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Theme.of(context).splashColor),),
                      errorWidget: (context, url, error) => nullProfileUrl(),
                    ),
                  ),
                      cancelButton(userID),
                    ],
                  ),
                  Container(
                      margin: EdgeInsets.fromLTRB(15, 5, 0, 0),
                      child: new Text(username ,
                        style: Theme.of(context).primaryTextTheme.headline4,textAlign: TextAlign.center,textScaleFactor: 0.9,)
                  ),
                ],
              ),

      ),
    );
  }
  Widget cancelButton(String userID){
    if(userID == widget.lituationVisit.userID){
      return Container();
    }
    return Container(
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: (){cancelUser(userID);},
          child:  Icon(Ionicons.ios_close_circle_outline, size: 20, color: Colors.red,),
        )
    );
  }
  Widget removeButton(String userID){
    if(userID == widget.lituationVisit.userID){//check if user is host
      return Container();
    }
    return Container(
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: (){removeUser(userID);},
          child:  Icon(Ionicons.ios_close_circle_outline, size: 20, color: Colors.red,),
        )
    );
  }
  Widget approveButton(String userID){
    if(userID == widget.lituationVisit.userID){
      return Container();
    }
    return Container(
      margin: EdgeInsets.fromLTRB(15, 0, 0, 0),
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: (){approveUser(userID);},
          child:  Icon(Ionicons.ios_checkmark_circle_outline, size: 20, color: Colors.green,),
        )
    );
  }
  Widget circularProfileWidget(String url ,String userID , String username , String status){
    bool online = getStatusAsBool(status);
    return GestureDetector(
      onTap: (){if(userID != widget.lituationVisit.userID){
        _viewProfile(widget.lituationVisit.userID, userID, context);
      }
      },
      child: Container(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                  child: CachedNetworkImage(
                    height: 45,
                    width: 45,
                    imageUrl: url,
                    imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: statusRingColor(online)),
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    placeholder: (context, url) => CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Theme.of(context).splashColor),),
                    errorWidget: (context, url, error) => nullProfileUrl(),
                  ),
                ),
                Container(
                    margin: EdgeInsets.fromLTRB(15, 0, 0, 0),
                    child: new Text(username ,
                      style: Theme.of(context).primaryTextTheme.headline4,textAlign: TextAlign.center,textScaleFactor: 0.9,)
                ),
              ],
            ),
          ],
        )
      ),
    );
  }
  Widget cupertinoStartTimePicker(AsyncSnapshot l){
    return
      Container(
        margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
        height: 50,
        width: 250,
        child: CupertinoTheme(
          data: CupertinoThemeData(
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: TextStyle(color: Theme.of(context).dividerColor , fontSize: 12 , fontWeight: FontWeight.w400),
              )
          ),
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            initialDateTime: dateTimeToTimeStamp(l.data['date']),
            onDateTimeChanged: (DateTime c) {
              setState(() {
                DateTime _date = dateTimeToTimeStamp(l.data['date']);
                DateTime d = DateTime(
                    _date.year, _date.month, _date.day, c.hour,
                    c.minute);
                updatedLituation.date = d;
              });
            },
          ),
        )
        ,
      );
  }
  Widget cupertinoEndTimePicker(AsyncSnapshot l){
    // List<String> capacityOptions = ['N/A','max'];
    return
      Container(
        margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
        height: 50,
        width: 250,
        child: CupertinoTheme(
          data: CupertinoThemeData(
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: TextStyle(color: Theme.of(context).dividerColor , fontSize: 12 , fontWeight: FontWeight.w400),
              )
          ),
          child: CupertinoDatePicker(
            minimumDate: tommorow().add(new Duration(hours:1, minutes:0, seconds:0)),
            mode: CupertinoDatePickerMode.time,
            initialDateTime: dateTimeToTimeStamp(l.data['end_date']),
            onDateTimeChanged: (DateTime c) {
              setState(() {
                DateTime _date = dateTimeToTimeStamp(l.data['end_date']);
                DateTime d = DateTime(
                    _date.year, _date.month, _date.day, c.hour,
                    c.minute);
                updatedLituation.end_date = d;
              });
            },
          ),
        )
        ,
      );
  }



  Widget pickerButton(String val){
    return
      MaterialButton(
        onPressed: (){},
        child: Text(
          val,textAlign: TextAlign.center,
          style: Theme.of(context).primaryTextTheme.headline4,
        ),
      );
  }


  DateTime tommorow(){
    var today = DateTime.now();
    return new DateTime(today.year , today.month , today.day + 1);
  }
  //TODO Migrate to StatusHandlerClass
  Color statusRingColor(bool online){
    if(online){
      return Colors.green;
    }
    return Colors.red;
  }

}
