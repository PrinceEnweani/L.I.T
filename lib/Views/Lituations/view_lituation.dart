
import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_pro/carousel_pro.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
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

class ViewLituation extends StatefulWidget{
  final LituationVisit lituationVisit;
  ViewLituation({Key key, this.lituationVisit}) : super(key: key);

  @override
  _ViewLituationState createState() => new _ViewLituationState();

}

class _ViewLituationState extends State<ViewLituation>{

   TextEditingController titleController;
   TextEditingController descriptionController;
   TextEditingController themesController;
   TextEditingController addressController;
   TextEditingController tec;
   TextEditingController tec2;

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
  @override
  void initState(){
    titleController = new TextEditingController();
    descriptionController = new TextEditingController();
    themesController = new TextEditingController();
    addressController = new TextEditingController();
    updatedLituation = Lituation();
    tec = new TextEditingController();
    tec2 = new TextEditingController();
    lp = LituationProvider(widget.lituationVisit.lituationID, widget.lituationVisit.userID);
    editMode = false;
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
      return lituationDetailPage();
  }

  Widget lituationDetailPage() {
    return StreamBuilder(
      stream: lp.lituationStream(),
      builder: (context , lituation){
        if(!lituation.hasData || lituation.connectionState == ConnectionState.waiting){
          return loadingWidget(context);
        }
        return lituationDetailsProvider(lituation);
      },
    );
  }

  Widget lituationDetailsProvider(AsyncSnapshot l){
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: topNav(backButton(), pageTitle(l.data['title'], Theme.of(context).textSelectionColor), [shareButton()], Theme.of(context).scaffoldBackgroundColor),
      //bottomNavigationBar: bottomButtons(l),
      body:  ListView(
        padding: EdgeInsets.fromLTRB(0,0, 0, 50),
        children: <Widget>[
          lituationCarousel(l),
          lituationDateDetailsProvider(l),
          pendingVibesWidgetProvider(l),
          lituationTitleWidget(l),
          /*hostInfoProvider(l.data['hostID']),
          attendeesWidgetProvider(l),
          lituationTimeProvider(l),
          lituationInfo("Entry" , l.data['entry'] , MaterialCommunityIcons.door),
          lituationCapacityProvider(l),
          lituationAddressInfo(l , Icons.location_on),
          observersWidget(l),*/
        ],
      ),
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

   Widget lituationDateDetailsProvider(AsyncSnapshot l){
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
         _viewProfile(widget.lituationVisit.userID, userID);
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
                   style: Theme.of(context).primaryTextTheme.headline4,textAlign: TextAlign.center,textScaleFactor: 0.9,)
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
        icon: Icon(Icons.share,color: Theme.of(context).buttonColor,size: 25,
        ),
        onPressed: (){},
      ),
    );
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