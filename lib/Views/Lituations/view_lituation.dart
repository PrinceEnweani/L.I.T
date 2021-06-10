
import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_pro/carousel_pro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:lit_beta/Extensions/common_widgets.dart';
import 'package:lit_beta/Models/User.dart';
import 'package:lit_beta/Providers/ProfileProvider/lituation_provider.dart';
import 'package:lit_beta/Strings/constants.dart';

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

  @override
  void initState(){
    titleController = new TextEditingController();
    descriptionController = new TextEditingController();
    themesController = new TextEditingController();
    addressController = new TextEditingController();
    lp = LituationProvider(widget.lituationVisit.lituationID, widget.lituationVisit.userID);
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
      backgroundColor: Theme.of(context).primaryColor,
      appBar: topNav(backButton(), pageTitle(l.data['title'], Theme.of(context).primaryColor), [shareButton()], Theme.of(context).scaffoldBackgroundColor),
      //bottomNavigationBar: bottomButtons(l),
      body:  ListView(
        padding: EdgeInsets.fromLTRB(0,0, 0, 50),
        children: <Widget>[
          SizedBox(
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
          ),
          /*aboutRow(l.data['entry'], dateTimeToTimeStamp(l.data['date']), List.from(l.data['vibes']).length.toString()),
          pendingWidgetProvider(l),
          lituationTitleWidget(l),
          hostInfoProvider(l.data['hostID']),
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