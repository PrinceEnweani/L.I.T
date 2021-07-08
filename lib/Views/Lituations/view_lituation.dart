
import 'dart:async';
import 'dart:typed_data';

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
import 'package:intl/intl.dart';
import 'package:lit_beta/Extensions/common_functions.dart';
import 'package:lit_beta/Extensions/common_widgets.dart';
import 'package:lit_beta/Models/Lituation.dart';
import 'package:lit_beta/Models/User.dart';
import 'package:lit_beta/Nav/routes.dart';
import 'package:lit_beta/Providers/ProfileProvider/lituation_provider.dart';
import 'package:lit_beta/Strings/constants.dart';
import 'package:lit_beta/Styles/text_styles.dart';
import 'dart:ui' as ui;
class ViewLituation extends StatefulWidget{
  final LituationVisit lituationVisit;
  ViewLituation({Key key, this.lituationVisit}) : super(key: key);

  @override
  _ViewLituationState createState() => new _ViewLituationState();

}


class _ViewLituationState extends State<ViewLituation>{
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
   TextEditingController titleController;
   TextEditingController capacityController;
   TextEditingController descriptionController;
   TextEditingController themesController;
   TextEditingController addressController;
   TextEditingController tec;
   TextEditingController tec2;
   BitmapDescriptor myIcon;
   GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: MAPS_KEY);
   final Set<Marker> _markers = {};
   MapType _mapType = MapType.normal;
   Completer<GoogleMapController> _controller = Completer();
   List<PlacesSearchResult> places = [];
   List<String> addressResults = [];
   BitmapDescriptor locationBitmap;
   Uint8List locationIcon;
   double zoom = 8;
   LatLng lituationLatLng = LatLng(0 , 0);
   bool minimizeRSVPS = false;
   bool editMode;
   LituationProvider lp;
   Lituation updatedLituation;
   Color likeColor = Colors.amber;
   Color dislikeColor = Colors.red;
   bool popUpMenu;
   bool invited = false;
  String PRIVATE_ENTRY = 'private';
  String INVITE_ONLY = 'invite';
  @override
  void initState(){
    titleController = new TextEditingController();
    descriptionController = new TextEditingController();
    themesController = new TextEditingController();
    addressController = new TextEditingController();
    capacityController = new TextEditingController();
    updatedLituation = Lituation();
    tec = new TextEditingController();
    tec2 = new TextEditingController();
    lp = LituationProvider(widget.lituationVisit.lituationID, widget.lituationVisit.userID);
    editMode = false;
    popUpMenu = false;
    super.initState();

  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    themesController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      return lituationDetailPage(context);
  }

  Widget lituationDetailPage(BuildContext context) {
    return StreamBuilder(
      stream: lp.lituationStream(),
      builder: (context , lituation){
        if(!lituation.hasData){
          return loadingWidget(context);
        }
        return lituationDetailsProvider(lituation);
      },
    );
  }

  Widget lituationDetailsProvider(AsyncSnapshot l){
    Lituation lit = Lituation.fromJson(l.data.data());
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: topNav(backButton(), pageTitle(l.data['title'], Theme.of(context).textSelectionColor), [shareButton()], Theme.of(context).scaffoldBackgroundColor),
      bottomNavigationBar: bottomButtonsProvider(l),
      body:  Builder(
        builder: (context){
          return Stack(
            children: [
              ListView(
                padding: EdgeInsets.fromLTRB(0,0, 0, 50),
                children: <Widget>[
                  lituationCarousel(l),
                  lituationAboutRowProvider(l),
                  ratingRow(context , lit.likes, lit.dislikes),
                  pendingVibesWidgetProvider(l),
                  lituationTitleWidget(l),
                  attendeesWidgetProvider(l),
                  lituationTimeProvider(l),
                  lituationInfoCard("Entry" , l.data['entry'] , MaterialCommunityIcons.door),
                  lituationCapacityProvider(l),
                  lituationAddressInfo(l , Icons.location_on),
                  observersWidget(l),
                ],
              ),
            ],
          );
        },
      )
    );
  }
  SnackBar sBar(String text){
    return SnackBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        content: Text(text , style: infoValue(Theme.of(context).textSelectionColor),));
  }

   Widget ratingRow(BuildContext context , List<String> likes , List<String> dislikes){
     String up = "${likes != null? likes.length : 0} voted lit";
     String down = "${dislikes != null? dislikes.length : 0} voted nope";

     return Card(
       elevation: 5,
       color: Theme.of(context).scaffoldBackgroundColor,
       child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
         children: [
           Expanded( //lo
             child: GestureDetector(
                 onTap: (){
                   if (likes.contains(widget.lituationVisit.userID)) {
                     showSnackBar(context , sBar('You already voted!'));
                   }
                   if (dislikes.contains(widget.lituationVisit.userID)) {
                     showSnackBar(context , sBar('You already voted!'));
                   }
                   lp.likeLituation();
                 },
                 child: Container(
                     padding: EdgeInsets.all(10.0),
                     child:  Column(
                       children: [
                         Icon(Icons.local_fire_department , color: likeColor,size: 35,),
                         Text(up, style: TextStyle(color: Theme.of(context).textSelectionColor , fontSize: 14)),
                       ],
                     )
                 )
             ),
           ),
           Expanded( //lo
             child: GestureDetector(
                 onTap: (){
                   if (likes.contains(widget.lituationVisit.userID)) {
                     return showSnackBar(context ,sBar('You already voted!'));
                   }
                   if (dislikes.contains(widget.lituationVisit.userID)) {
                     return showSnackBar(context ,sBar('You already voted!'));
                   }
                   lp.dislikeLituation();
                 },
                 child: Container(
                     padding: EdgeInsets.all(10.0),
                     child:  Column(
                       children: [
                         Icon(Icons.fire_extinguisher , color: dislikeColor,size: 35,),
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
  Widget lituationPopUpMenu(){
      return Container(
        height: 200,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            shareLituationButton(),
            inviteToLituationButton(),
          ],
        ),
      );
  }
  Widget shareLituationButton(){
    return Container(
        height: 50,
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.only(top: 5 , bottom: 5 , left: 75 , right: 75),
        child: RaisedButton(
          color: Colors.blueAccent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
               Expanded(flex: 7,child: Text("share lituation" ,style: infoValue(Theme.of(context).textSelectionColor) ,textAlign: TextAlign.center,),),
                seperator(),
               Expanded(flex: 2,child: Icon(Icons.share , color: Theme.of(context).textSelectionColor,)),

              ],
            ),
            onPressed: (){
              //TODO show share options
            },
            shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0))
        )
    );
  }
  Widget inviteToLituationButton(){
    return StreamBuilder(
      stream: lp.lituationStream(),
      builder: (context , l){
       if(!l.hasData){
         return Container();
       }
       bool attending = l.data['vibes'].contains(widget.lituationVisit.userID);
       return Container(
            height: 50,
            width: MediaQuery.of(context).size.width,
            margin: EdgeInsets.only(top: 5 , bottom: 5 , left: 75 , right: 75),
            child: RaisedButton(
                color: Theme.of(context).primaryColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(flex: 7,child: Text("send invite" ,style: infoValue(Theme.of(context).textSelectionColor) ,textAlign: TextAlign.center,),),
                    seperator(),
                    Expanded(flex: 2,child: Icon(Icons.add , color: Theme.of(context).textSelectionColor,)),

                  ],
                ),
                onPressed: (){
                  sendInvite(l.data['entry'], attending);
                },
                shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0))
            )
        );
      },
    );
  }

  void _viewVibes(String note){
    UserVisit v = UserVisit(visitedID: widget.lituationVisit.userID ,visitorID:widget.lituationVisit.userID, visitNote: note);
    Navigator.of(context).pushNamed(VibesPageRoute , arguments: v);
  }

  Widget seperator(){
    return Container(
      color: Theme.of(context).dividerColor,
      width: 1.5,
      height: 35,
      margin: EdgeInsets.only(left: 5 , right: 5),
    );
  }
   Widget bottomButtonsProvider(AsyncSnapshot l){
      if(popUpMenu){
        return lituationPopUpMenu();
      }
     return Container(
       height: invited?120:100,
       child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
         children: [
           invitedNotifier(l),
           bottomButtons(l)
         ],
       ),
     );
   }
   Widget invitedNotifier(AsyncSnapshot l){
          return StreamBuilder(
            stream: lp.userLituationsStream(),
            builder: (context , ul){
              if(!ul.hasData){
                return Container(height: 0,);
              }
              for(String id in ul.data['invitations']){
                if(id.contains(":${widget.lituationVisit.lituationID}:${widget.lituationVisit.userID}")){
                  invited = true;
                  return  youWereInvitedProvider(id);
                }
              }
              return Container(height: 0,);
            },
          );
   }
   Widget youWereInvitedProvider(String id){
      return StreamBuilder(
        stream: lp.getUserStreamByID(getSenderIdFromInvitation(id)),
        builder: (context , u){
          if(!u.hasData){
            return Container(height: 0,);
          }
          return  Container(
            height: 50,
            padding: EdgeInsets.all(15),
            child: RichText(
                text: TextSpan(
                    text: parseVibes('You were invited by '),style: infoValue(Theme.of(context).textSelectionColor),
                    children: [
                      TextSpan(text: u.data['username'] , style: infoValue(Theme.of(context).primaryColor))
                    ]
                )
            ),
          );
        },
      );
   }


   Widget bottomButtons(AsyncSnapshot l){
     List<String> vibingIDS = List.from(l.data['vibes']);
     bool already = false;
     bool going = false;
     bool rsvpd = false;
     bool invited = false;
     if(l.data['hostID'] == widget.lituationVisit.userID){
       return hostBottomButtons(l);
     }
     going = vibingIDS.contains(widget.lituationVisit.userID);
     already = l.data['observers'].contains(widget.lituationVisit.userID);
     rsvpd = l.data['pending'].contains(widget.lituationVisit.userID);
     invited = l.data['invited'].contains(widget.lituationVisit.userID);
     return visitorButtons(already ,going,rsvpd, l.data['entry'] , invited);
   }
   Widget attendButton(bool going ,bool rsvpd, String entry , bool invited){
     print(entry);
     String val = 'attend';
     Color col = Colors.green;
     if(entry.toLowerCase().contains(INVITE_ONLY) || entry.toLowerCase().contains(PRIVATE_ENTRY)){
       String val = 'RSVP';
       Color col = Colors.green;
       if(rsvpd){
         col = Colors.red;
         val = 'RSVP\'d';
       }
       return RaisedButton(
           color: col,
           child: Text(val , style: infoValue(Theme.of(context).textSelectionColor),),
           onPressed: (){
             lp.sendRSVPToLituation();
           }, shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0))
       );
     }
     if (invited)
     {
       return acceptInviteButtonProvider();
     }
     if(going){
       col = Colors.red;
       val = 'attending';
     }

     return RaisedButton(
         color: col,
         child: Text(val , style: infoValue(Theme.of(context).textSelectionColor),),
         onPressed: (){
           lp.attendLituation();
         }, shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0))
     );
   }

  Widget acceptInviteButtonProvider(){
    return StreamBuilder(
      stream: lp.userLituationsStream(),
      builder: (context , ul){
        if(!ul.hasData){
          return Container();
        }
        String inviteID;
        for(String id in ul.data['invitations']){
          if(id.contains(":${widget.lituationVisit.lituationID}:${widget.lituationVisit.userID}")){
            return acceptInviteButton(id);
          }
        }
        return Container();
      },
    );
  }
  Widget acceptInviteButton(String id){
    return StreamBuilder(
      stream: lp.getUserStreamByID(getSenderIdFromInvitation(id)),
      builder: (context , u){
        if(!u.hasData){
          return Container(height: 0,);
        }
        return Container(
          height: 45,
          child:  RaisedButton(
              color: Colors.red,
              child: Text('accept invitation' , style: infoValue(Theme.of(context).textSelectionColor),),
              onPressed: (){
                lp.acceptInvitation(Invitation.fromId(id));
              }, shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0))
          ),
        );
      },
    );
  }
  
   Widget visitorButtons(bool already, bool going,bool rsvp, String entry , bool invited){
     return Container(
       padding: EdgeInsets.fromLTRB(10, 5, 10, 15),
       child: Row(
         children: [
           Expanded(
               child: Container(
                 height: 45,
                 margin: EdgeInsets.fromLTRB(5, 0, 5, 0),
                 child: attendButton(going ,rsvp, entry, invited),
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
   Widget observeButton(bool already){
     String val = 'observe';
     Color col = Colors.green;
     if(already){
       val = 'stop observing';
       col = Colors.red;
     }
     return RaisedButton(
         color: col,
         child: Text(val , style: infoValue(Theme.of(context).textSelectionColor),),
         onPressed: (){
           lp.observeLituation();
         }, shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0))
     );
   }
   Widget updateButton(AsyncSnapshot l){
     return RaisedButton(
         color: editMode==true?Colors.green:Theme.of(context).buttonColor,
         child: Text(editMode == true?'save':'update' , style: infoValue(Theme.of(context).textSelectionColor),),
         onPressed: (){
           editMode?_updateLituation(l, updatedLituation):update();
         }, shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0))
     );
   }
   void update(){
     setState(() {
       editMode = !editMode;
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
   Widget closeButton(){
     Color col = Colors.red;
     return RaisedButton(
         color: col,
         child: Text('close lituation' , style: infoValue(Theme.of(context).textSelectionColor),),
         onPressed: (){
           //TODO Implement end lituation
           print('aye');
         }, shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0))
     );
   }
   Widget lituationCapacityProvider(AsyncSnapshot l){
     if(editMode){
       return capacityPicker(l, Icons.people, 'Capacity' , 'entry');
     }
     return  lituationInfoCard('Capacity' , capacityChecker(l.data['capacity']) , Icons.person);
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
       stream: lp.usersStream(),
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
             padding: EdgeInsets.fromLTRB(0, 15, 0, 5),
             color: Theme.of(context).scaffoldBackgroundColor,
             child: Column(
               children: [
                 Container(
                   alignment:  Alignment.centerLeft,
                   margin: EdgeInsets.fromLTRB(15, 5, 0, 5),
                   child: Text('(' + addedObservers.length.toString() + ') vibes are observing' , style: infoLabel(Theme.of(context).primaryColor),),),
                 Container(
                   margin: EdgeInsets.fromLTRB(0, 15, 15, 0) ,
                   height: 75,
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
   Future<void> _updateLituation(AsyncSnapshot l , Lituation update) async {

       if(update.title != null && update.title != l.data['title']){
         print(update.title);
         lp.updateLituationTitle(update.title);
       }
       if(update.description != null && update.description != l.data['description']){
         lp.updateLituationDescription(update.description);
       }
       if(update.date != null && update.date != dateTimeToTimeStamp(l.data['date'])){
         lp.updateLituationDate(update.date);
       }
       if(update.end_date != null && update.end_date != dateTimeToTimeStamp(l.data['end_date'])){
         lp.updateLituationEndDate(update.end_date);
       }
       if(update.capacity != null && update.capacity != l.data['capacity']){
         lp.updateLituationCapacity(update.capacity);
       }
       if(update.location != null && update.location != l.data['location']){
         lp.updateLituationLocation(update.location);
       }
       if(update.locationLatLng != null && update.locationLatLng != l.data['locationLatLng']){
         lp.updateLituationLocationLatLng(update.locationLatLng);
       }
       setState(() {
       editMode = !editMode;
     });
   }
   Widget lituationAddressInfo(AsyncSnapshot l, IconData icon){
     if(editMode){
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
                           child: Text(title ,style: infoLabel(Theme.of(context).primaryColor),textAlign: TextAlign.left,),),
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
   String checkTBD(String val){
     if(val ==""){
       return "TBD";
     }
     return val;
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
   Future<Uint8List> getBytesFromAssetFile(String path , int width) async {
     ByteData data = await rootBundle.load(path);
     ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
     ui.FrameInfo frameInfo = await codec.getNextFrame();
     return( await frameInfo.image.toByteData(format: ui.ImageByteFormat.png)).buffer.asUint8List();
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
   void _onMapCreated(GoogleMapController controller) {
       if(!_controller.isCompleted) {
         setState(() {
           _controller.complete(controller);
         });
       }
   }
   Widget showCap(AsyncSnapshot l){
     return Container( //login button
       margin: EdgeInsets.fromLTRB(10, 25, 0, 15),
       padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
       child: Text('Change Capacity:' + "\n" + capacityChecker(l.data['capacity']), style: infoValue(Theme.of(context).textSelectionColor),textAlign: TextAlign.left,),
     );
   }
   String capacityChecker(String capacity){
     if(capacity == null || capacity == ''){
       return 'N/A';
     }else{
       return capacity;
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
                     child: Icon(descIcon , color: Theme.of(context).primaryColor,)),
                 new Container(
                     width: 75,
                     margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                     child: new Text(title , style: infoValue(Theme.of(context).textSelectionColor))),
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
           controller: capacityController,
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
           style: infoValue(Theme.of(context).textSelectionColor),
           cursorColor: Theme.of(context).primaryColor,
           decoration: InputDecoration(
               suffixIcon: Icon(Icons.person , color: Theme.of(context).primaryColor,),
               labelText: 'Cap: ' + updatedLituation.capacity != null?updatedLituation.capacity : 'is 0',
               labelStyle: infoLabel(Theme.of(context).textSelectionColor),
               enabledBorder: UnderlineInputBorder(
                 borderSide: BorderSide(color: Theme.of(context).textSelectionColor, width: 1),),
               focusedBorder: UnderlineInputBorder(
                   borderSide: BorderSide(color: Theme.of(context).textSelectionColor, width: 2))
           ),
         ),
       );
     }else{
       return Container();
     }
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

   Widget pickerButton(String val){
     return
       MaterialButton(
         onPressed: (){},
         child: Text(
           val,textAlign: TextAlign.center,
           style: infoValue(Theme.of(context).textSelectionColor),
         ),
       );
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
       stream: lp.usersStream(),
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
                   child: Text(addedIDs.length == 1?'(' + addedIDs.length.toString() + ') is going':'(' + addedIDs.length.toString() + ') are going'  , style: infoLabel(Theme.of(context).primaryColor),),),
                 Row(
                   children: [
                     circularProfileInviteWidget(),
                     Expanded(flex: 8, child:
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
                     ),)
                   ],
                 )
               ],
             ),
           );
         }else{
           return noAttendeesWidget();
         }
       },
     );
   }
   Widget lituationTimeProvider(AsyncSnapshot l){
     if(editMode){
       return editableStartEndTimeWidget(l);
     }
     return Column(
       children: [
         lituationInfoCard("Date" , DateFormat.yMEd().format(dateTimeToTimeStamp(l.data['date'])),MaterialCommunityIcons.calendar),
         lituationInfoCard("Time:", parseDateToEndDate(l.data['date'], l.data['end_date'])  , Icons.access_time),
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
         datePicker(Icons.calendar_today_outlined, 'Date' , showDate('New Date', str),editableDatePicker(l)),
         datePicker(Icons.access_time, 'Start Time' , showDate('New Start time', parseTime(l.data['date'])) ,cupertinoStartTimePicker(l)),
         datePicker(Icons.cancel, 'End Time' , showDate('New End time',  parseTime(l.data['end_date'])) ,cupertinoEndTimePicker(l)),
       ],
     );
   }
   Widget editableDatePicker(AsyncSnapshot l){
     // List<String> capacityOptions = ['N/A','max'];
     return
       Container(
         margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
         height: 50,
         width: 250,
         child: CupertinoTheme(
           data: CupertinoThemeData(
               textTheme: CupertinoTextThemeData(
                 dateTimePickerTextStyle: TextStyle(color: Theme.of(context).textSelectionColor , fontSize: 12 , fontWeight: FontWeight.w400),
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
   Widget cupertinoStartTimePicker(AsyncSnapshot l){
     return
       Container(
         margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
         height: 50,
         width: 250,
         child: CupertinoTheme(
           data: CupertinoThemeData(
               textTheme: CupertinoTextThemeData(
                 dateTimePickerTextStyle: TextStyle(color: Theme.of(context).textSelectionColor , fontSize: 12 , fontWeight: FontWeight.w400),
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
                 dateTimePickerTextStyle: TextStyle(color: Theme.of(context).textSelectionColor , fontSize: 12 , fontWeight: FontWeight.w400),
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

   DateTime tommorow(){
     var today = DateTime.now();
     return new DateTime(today.year , today.month , today.day + 1);
   }
   Widget showDate(String hint , String date){
     return Container( //login button
       margin: EdgeInsets.fromLTRB(10, 25, 0, 15),
       padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
       child: Text(hint + "\n" + date, style: infoValue(Theme.of(context).textSelectionColor),textAlign: TextAlign.left,),
     );
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
   Widget lituationInfoCard(String title , String value , IconData icon){
     return Card(
       color: Theme.of(context).scaffoldBackgroundColor,
       elevation: 3,
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
                           child: Text(title ,style: TextStyle(color: Theme.of(context).primaryColor,fontSize: 16 ,fontWeight: FontWeight.w900),textAlign: TextAlign.left,),),
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
  Widget circularProfileInviteWidget(){
    return StreamBuilder(
      stream: lp.lituationStream(),
      builder:(context , l){
        if(!l.hasData){
          return Container();
        }
        bool attending = l.data['vibes'].contains(widget.lituationVisit.userID);
        return GestureDetector(
          onTap: (){
            sendInvite(l.data['entry'] , attending);
          }
          ,
          child: roundInviteButton()
        );
      },
    );
  }


  void sendInvite(String entry , bool attending){
    if(entry.contains(PRIVATE_ENTRY)){
      showSnackBar(context , sBar('This lituation is private, reach out to the host.'));
      return;
    }
    if(entry.contains(INVITE_ONLY)){
      if(attending){
        String visit_note = "invite:"+widget.lituationVisit.lituationID;
        _viewVibes(visit_note);
        return;
      } else {
        showSnackBar(context , sBar('You must be attending to send an invite.'));
        return;
      }
    }
    String visit_note = "invite:"+widget.lituationVisit.lituationID;
    _viewVibes(visit_note);
  }

  Widget roundInviteButton(){
    return Container(
        height: 50,
        width: 50 ,
        margin: EdgeInsets.fromLTRB(15, 0, 0, 15) ,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                  margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                  child: Icon(Icons.add , color: Theme.of(context).textSelectionColor,)
              ),
            )
          ],
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.amber),
          borderRadius: BorderRadius.circular(50),
        )
    );
  }
   Widget circularProfileWidget(String url ,String userID , String username , String status){
     bool online = getStatusAsBool(status);
     return GestureDetector(
       onTap: (){if(userID != widget.lituationVisit.userID){
         _viewProfile(widget.lituationVisit.userID, userID);
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
                           border: Border.all(color: getStatusRingColor(online)),
                           shape: BoxShape.circle,
                           image: DecorationImage(
                             image: imageProvider,
                             fit: BoxFit.cover,
                           ),
                         ),
                       ),
                       placeholder: (context, url) => CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Theme.of(context).splashColor),),
                       errorWidget: (context, url, error) => nullProfileUrl(context),
                     ),
                   ),
                   Container(
                       margin: EdgeInsets.fromLTRB(15, 0, 0, 0),
                       child: new Text(username ,
                         style: infoValue(Theme.of(context).textSelectionColor),textAlign: TextAlign.center,textScaleFactor: 0.9,)
                   ),
                 ],
               ),
             ],
           )
       ),
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
       stream: lp.usersStream(),
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
             color: Theme.of(context).scaffoldBackgroundColor,
             child: Column(
               children: [
                 Container(
                   alignment:  Alignment.centerLeft,
                   margin: EdgeInsets.fromLTRB(15, 5, 0, 5),
                   child: Text('attending vibes (' + attendeesIDs.length.toString() + ')' , style: infoLabelMedium(Theme.of(context).textSelectionColor),),),
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
           return noAttendeesWidget();
         }
       },
     );
   }
   
   Widget noAttendeesWidget(){
    return Card(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Container(
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            inviteUserButton()
          ],
        ),
      ),
    );
   }
   Widget inviteUserButton(){
     return Container(
         height: 50,
         width: MediaQuery.of(context).size.width,
         margin: EdgeInsets.only(top: 5 , bottom: 5 , left: 15 , right: 15),
         child: RaisedButton(
             child: Text("invite friends +" ,style: infoValue(Theme.of(context).textSelectionColor)),
             onPressed: (){
               String visit_note = "invite:"+widget.lituationVisit.lituationID;
               _viewVibes(visit_note);
             },
             shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(25.0))
         )
     );
   }
   Widget cancelableCircularProfileWidget(String url ,String userID , String username , String status){
     bool online = getStatusAsBool(status);
     return GestureDetector(
       onTap: (){if(userID != widget.lituationVisit.userID){
         _viewProfile(userID , username);
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
                           border: Border.all(color: getStatusRingColor(online)),
                           shape: BoxShape.circle,
                           image: DecorationImage(
                             image: imageProvider,
                             fit: BoxFit.cover,
                           ),
                         ),
                       ),
                       placeholder: (context, url) => CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Theme.of(context).splashColor),),
                       errorWidget: (context, url, error) => nullProfileUrl(context),
                     ),
                   ),
                   Container(
                       margin: EdgeInsets.fromLTRB(15, 0, 0, 0),
                       child: new Text(username ,
                         style: infoValue(Theme.of(context).textSelectionColor),textAlign: TextAlign.center,textScaleFactor: 0.9,)
                   ),
                 ],
               ),
               removeButton(userID),
             ],
           )
       ),
     );
   }
   Widget lituationHostInfoProvider(String hostID){
     return  StreamBuilder(
       stream:lp.getUserStreamByID(hostID),
       builder: (ctx, u){
         return !u.hasData
             ?new Text("loading" , style: TextStyle(color: Theme.of(context).buttonColor),)
             : hostInfo(u.data['userID'], u.data['username'], u.data['profileURL'], ctx);
       },
     );
   }


   Widget hostInfo(String hostID, String username, String url , BuildContext ctx){
     if(hostID == widget.lituationVisit.userID){
       return Container();
     }
     return Container(
         child: Container(
               color: Theme.of(context).scaffoldBackgroundColor,
               padding: EdgeInsets.fromLTRB(5, 0, 15, 15),
               child: Column(
                 children: [
                   Container(
                     margin: EdgeInsets.fromLTRB(0, 0, 0, 15),
                     alignment: Alignment.centerLeft,
                     padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                     child: Text('hosted by:' ,style: infoValue(Theme.of(context).textSelectionColor),textAlign: TextAlign.left,),),
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
                               errorWidget: (context, url, error) => nullProfileUrl(context),
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
                           onPressed: (){
                             if(hostID != widget.lituationVisit.userID){
                               _viewProfile(hostID, username);
                             }
                           },
                           color: Theme.of(context).buttonColor,
                           child: Text('visit' , style: infoValue(Theme.of(context).textSelectionColor),),
                         ),)
                     ],

                   )
                 ],
               )),


     );
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
             child: Text(l.data['title'], style: TextStyle(color: Theme.of(context).textSelectionColor , fontSize: 24),textAlign: TextAlign.center, ),
           ),
           lituationHostInfoProvider(l.data['hostID']),
           Container(
             padding: EdgeInsets.only(top: 10.0 , left: 15 , bottom: 10),
             alignment: Alignment.topLeft,
             child: Text("Description:" ,style: TextStyle(color: Theme.of(context).primaryColor,fontSize: 16 ,fontWeight: FontWeight.w900),textAlign: TextAlign.left,),
           ),
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Flexible(
                   child: Container(
                     padding: EdgeInsets.fromLTRB(15 , 10 , 15 , 0),
                     child: Text(l.data['description'],style: TextStyle(color: Theme.of(context).dividerColor , fontSize: 14),textAlign: TextAlign.left,),
                   )
               ),
             ],
           ),
           Container(
               margin: EdgeInsets.fromLTRB(15,25, 0, 0),
               alignment: Alignment.centerLeft,
               padding: EdgeInsets.fromLTRB(0,0, 0, 0),
               child:  Text('Themes:',style: infoLabelMedium(Theme.of(context).primaryColor))
           ),
           Container(
               margin: EdgeInsets.fromLTRB(15,0, 0, 0),
               alignment: Alignment.centerLeft,
               padding: EdgeInsets.fromLTRB(0,0, 0, 0),
               child:  Text(parseThemesFromSnapShot(l)  ,style: infoValueMedium(Theme.of(context).indicatorColor))
           ),
         ],),
       ),
     );
   }
   Widget lituationTitleWidget(AsyncSnapshot l){
     if(editMode){
       return editableLituationTitleWidget(l);
     }
     return lituationDescription(l);
   }
   Widget editableLituationTitleWidget(l){
     if(tec.text == ''){ tec = new TextEditingController(text: l.data['title']);}
     if(tec2.text == ''){ tec2 = new TextEditingController(text: l.data['description']);}
     return Card(
       elevation: 3,
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
                         cursorColor: Theme.of(context).primaryColor,
                         controller: tec,
                         style: infoValue(Theme.of(context).textSelectionColor),
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
             child: Text("Description:" ,style: TextStyle(color: Theme.of(context).textSelectionColor,fontSize: 16 ,fontWeight: FontWeight.w900),textAlign: TextAlign.left,),
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
                         cursorColor: Theme.of(context).primaryColor,
                         controller: tec2,
                         style: infoValue(Theme.of(context).textSelectionColor),
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
   Widget pendingVibesWidgetProvider(AsyncSnapshot l){
     if(!l.hasData){
       return Align( alignment: Alignment.center,
         child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Theme.of(context).splashColor)),);
     }
     if(l.data['hostID'] == widget.lituationVisit.userID) {
       List<String> pendingIDs = List.from(l.data['pending']);
       List pending = [];
       return StreamBuilder<QuerySnapshot>(
         stream: lp.usersStream(),
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
                   .scaffoldBackgroundColor,
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

   void showGuestList(){
     Navigator.pushNamed(context, GuestListPageRoute, arguments: widget.lituationVisit);
   }

   Widget lituationAboutRowProvider(AsyncSnapshot l){
     String str;
     int vibesCount =  List.from(l.data['vibes']).length;
     DateTime date = dateTimeToTimeStamp(l.data['date']);
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
                         Text(l.data['entry'], style:  infoValue(Theme.of(context).textSelectionColor)),
                       ],
                     )
                 )
             ),
           ),
           calendarWidget(str),
           Expanded( //lo
             child: GestureDetector(
                 onTap: (){

                 },
                 child: Container(
                     padding: EdgeInsets.all(10.0),
                     child:  Column(
                       children: [
                         Icon(Icons.people , color: Theme.of(context).primaryColor,),
                         Text(vibesCount.toString() + ' vibed', style: infoValue(Theme.of(context).textSelectionColor), textAlign: TextAlign.center,),
                       ],
                     )
                 )
             ),
           )
         ],
       ),
     );
   }
   Widget pendingCircularProfileWidget(String url ,String userID , String username , String status){
     bool online = getStatusAsBool(status);
     return GestureDetector(
       onTap: (){if(userID != widget.lituationVisit.userID){
         _viewProfile(userID , username);
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
                         border: Border.all(color: getStatusRingColor(online)),
                         shape: BoxShape.circle,
                         image: DecorationImage(
                           image: imageProvider,
                           fit: BoxFit.cover,
                         ),
                       ),
                     ),
                     placeholder: (context, url) => CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Theme.of(context).splashColor),),
                     errorWidget: (context, url, error) => nullProfileUrl(context),
                   ),
                 ),
                 cancelButton(userID),
               ],
             ),
             Container(
                 margin: EdgeInsets.fromLTRB(15, 5, 0, 0),
                 child: new Text(username ,
                   style: infoValue(Theme.of(context).textSelectionColor),textAlign: TextAlign.center,textScaleFactor: 0.9,)
             ),
           ],
         ),

       ),
     );
   }
   void _viewProfile(String id , String username){
     UserVisit v = UserVisit();
     v.visitorID = widget.lituationVisit.userID;
     v.visitedID = id;
     v.visitNote = username;
     print(v.visitNote);
     Navigator.pushNamed(context, VisitProfilePageRoute , arguments: v);
   }
   Widget cancelButton(String userID){
     if(userID == widget.lituationVisit.userID){
       return Container();
     }
     return Container(
         alignment: Alignment.topRight,
         child: GestureDetector(
           onTap: (){lp.cancelPendingRsvp(userID);},
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
           onTap: (){lp.removeFromGuestList(userID);},
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
           onTap: (){lp.approveUser(userID);},
           child:  Icon(Ionicons.ios_checkmark_circle_outline, size: 20, color: Colors.green,),
         )
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
                     Text(date, style:  infoValue(Theme.of(context).textSelectionColor)),
                   ],
                 )
             )
         )
     );
   }

  Widget lituationCarousel(AsyncSnapshot l) {
    return SizedBox(
        height: MediaQuery.of(context).size.height * 0.40,
        width: MediaQuery.of(context).size.width,
        child: Carousel(
          images: thumbnailsProvider(l),
          dotSize: 1.0,
          dotSpacing: 15.0,
          dotColor: Theme.of(context).buttonColor,
          indicatorBgPadding: 5.0,
          dotBgColor: Theme.of(context).primaryColor.withOpacity(0.5),
          borderRadius: true,
          autoplay: false,
          moveIndicatorFromBottom: 180.0,
          noRadiusForIndicator: true,
        )
    );
  }
  Widget shareButton(){
    return Container(
      padding: EdgeInsets.all(10),
      child:  IconButton(
        icon: Icon(popUpMenu?Icons.cancel:Icons.share,color: Theme.of(context).buttonColor,size: 25,
        ),
        onPressed: (){
          showPopUpMenu();
        },
      ),
    );
  }
  void showPopUpMenu(){
    setState(() {
      popUpMenu = !popUpMenu;
    });
  }
  Widget backButton(){
   return Container(
      padding: EdgeInsets.all(10),
      child:  IconButton(
        icon: Icon(Icons.arrow_back,color: Theme.of(context).buttonColor,size: 25,
        ),
        onPressed: (){Navigator.of(context).pop();},
      ),
    );
  }
  List<Widget> thumbnailsProvider(AsyncSnapshot l){
    List<String> nails = [];
    List<Widget> thumbnails = [];
    for(String img in l.data['thumbnail']){
      if(!nails.contains(img)){
        nails.add(img);
        thumbnails.add(lituationMedia(img));
      }
    }

    return thumbnails;
  }

  Widget lituationMedia(String media) {
    return new CachedNetworkImage(
      imageUrl: media,
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              image: imageProvider,
            )
        ),
      ),
    );
  }
}