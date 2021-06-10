
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:lit_beta/Extensions/common_functions.dart';
import 'package:lit_beta/Extensions/common_maps_functions.dart';
import 'package:lit_beta/Extensions/common_widgets.dart';
import 'package:lit_beta/Extensions/search_filters.dart';
import 'package:lit_beta/Models/Lituation.dart';
import 'package:lit_beta/Providers/MapProvider/map_provider.dart';
import 'package:lit_beta/Providers/SearchProvider/search_provider.dart';
import 'package:lit_beta/Strings/constants.dart';
import 'package:lit_beta/Strings/hint_texts.dart';
import 'package:lit_beta/Styles/text_styles.dart';
import 'package:lit_beta/Styles/theme_resolver.dart';

class MapPage extends StatefulWidget {
  final String userID;
  MapPage({Key key , this.userID}) : super(key: key);

  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<MapPage> {

  MapProvider mp;
  SearchProvider sp;
  final Set<Marker> _mapMarkers = {};
  MapType _mapType = MapType.normal;
  LatLng userLatLng;
  double zoom;
  Completer<GoogleMapController> _controller;
  GoogleMapsPlaces _places;
  TextEditingController mapSearchController;
  List<PlacesSearchResult> placesSearchResults;
  List<String> addressResults;
  var lituationResults = [];
  Position userPosition;  
  var locationIcon;

  @override
  void dispose(){
    super.dispose();
  }

  getUserLocation() async {
   await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best).then((value){
     if (this.mounted == true)
      setState(() {
        userPosition = value;
      });
   });
  }
  @override
  void initState() {
    mp = new MapProvider(widget.userID);
    sp = new SearchProvider(widget.userID);
    getUserLocation();
    _controller = Completer();
    _places = GoogleMapsPlaces(apiKey: MAPS_KEY);
    mapSearchController = TextEditingController();
    placesSearchResults =  [];
    addressResults = [];
    zoom  = 12.0;
    getBytesFromAssetFile('assets/images/litlocationicon.png' ,225)
      .then((value) => locationIcon = value);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        body: liveMapWidget(),
      )
    );

  } 
  Future<bool> _onWillPop() async {
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      if(!_controller.isCompleted)
        _controller.complete(controller);
    });
  }

  Widget liveMapWidget(){
    return Stack(
      children: [
         mapsWidget(),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: mapsSearchBar(),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: resultsWidget(),
        ),
      ],
    );
  }
Widget resultsWidget(){
    return Container(
      margin: EdgeInsets.only(bottom: 25),
      height: 200,
      width: MediaQuery.of(context).size.width,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: lituationResults.length,
        itemBuilder: (context ,  idx){
          return lituationResults[idx];
        },
      ),
    );
}
  Widget mapsWidget(){
    if(userPosition == null){
      return Center(
        child: Text('loading...'),
      );
    }
        return  GoogleMap(
          markers: _mapMarkers,
          mapType: _mapType,
          mapToolbarEnabled: true,
          zoomGesturesEnabled: true,
          onMapCreated: _onMapCreated,
          myLocationEnabled: true,
          initialCameraPosition: CameraPosition(
              target: LatLng(userPosition.latitude , userPosition.longitude),
              zoom: zoom
          ),
        );
      }


  Widget mapsSearchBar(){
    return Container(
      margin: EdgeInsets.only(top: 50 , left: 5 , right: 5),
      padding: EdgeInsets.only(left: 15 , right: 5),
      decoration:  BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomRight: Radius.circular(15),
            bottomLeft: Radius.circular(15)),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: TypeAheadField(
        textFieldConfiguration: TextFieldConfiguration(
            cursorColor: Theme.of(context).textSelectionColor,
            controller: mapSearchController,
            autofocus: false,
            style: infoValue(Theme.of(context).textSelectionColor),
            decoration: InputDecoration(
                labelText: 'I\'m feeling litty...XD',
                hintStyle: TextStyle(color: Theme.of(context).textSelectionColor , fontSize: 12 , decoration: TextDecoration.none),
                labelStyle: TextStyle(color: Theme.of(context).textSelectionColor , fontSize: 14 ,decoration: TextDecoration.none),
                enabledBorder: UnderlineInputBorder(
                  borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(10),
                      bottomLeft: Radius.circular(10)),
                  borderSide: BorderSide(color: Colors.transparent, width: 0),),
                focusedBorder: UnderlineInputBorder(
                    borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(10),
                        bottomLeft: Radius.circular(10)),
                    borderSide: BorderSide(color: Theme.of(context).textSelectionColor , width: 1))
            )
        ),
        suggestionsCallback: (pattern) async {
          lituationResults.clear();
          return searchAddress(pattern).then((value) async {
            List<Marker> resultMarkers = [];
            List<String> ids = [];
            if(value.length > 0) {
              await mp.searchLituation(pattern, BY_ADDRESS).then((lituations){
                if (lituations.length <= 0)
                  return;
                moveCamera(CameraPosition(
                  bearing: 0,
                  zoom: 11,
                  target:latLngFromGeoPoint(lituations[0].data()['locationLatLng']),
                ));
                for(var event in lituations){
                  if(!ids.contains(event.id)) {
                    ids.add(event.id);
                    lituationResults.add(
                        lituationResult(event.id));
                    resultMarkers.add(googleMapMarker(
                        event.data()['location'],
                        BitmapDescriptor.fromBytes(locationIcon),
                        latLngFromGeoPoint(
                            event.data()['locationLatLng'])));
                  }
                }
              });
              drawMarkers(resultMarkers);
            }
            setState(() {
              
            });
            return value;
          });
        }
        ,
        itemBuilder: (context, PlacesSearchResult suggestion) {
          return placeResultTile(context , suggestion);
        },
        onSuggestionSelected: (PlacesSearchResult suggestion) {
          mapSearchController.text = suggestion.formattedAddress;
          drawMarker(googleMapMarker(suggestion.name, BitmapDescriptor.defaultMarkerWithHue(50), LatLng(suggestion.geometry.location.lat , suggestion.geometry.location.lng)));
          moveCamera(CameraPosition(
            bearing: 0,
            zoom: 16,
            target: LatLng(suggestion.geometry.location.lat , suggestion.geometry.location.lng),
          ));
        },
      ),
    );
  }

  Widget lituationResultCard2(DocumentSnapshot l){
    return Card(
      color: Colors.blue,
      elevation: 3,
      child: Container(
        height: 250,
        width: 175,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Text(l.data()['title'])),
            Expanded(child: Text(l.data()['entry'])),
            Expanded(child: Text(l.data()['location'])),
          ],
        ),
      ),
    );
  }
  Widget resultMarker(){
    return GestureDetector(

      onTap: (){

      },
    );
  }
  bool isWithinNMileRadius(int radius , LatLng lituation){

  }
  Future<List<PlacesSearchResult>> searchAddress(String query) async {
    final result = await _places.searchByText(query);
    _mapMarkers.clear();
    addressResults.clear();
    if(result.status == "OK"){
      placesSearchResults = result.results;
      result.results.forEach((a){
        print(a.formattedAddress);
      });
    }else{
      print(result.status);
    }
    return placesSearchResults;
  }
  Future<void> moveCamera(CameraPosition cameraPosition) async {
    final GoogleMapController ctrl = await _controller.future;
    ctrl.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }
  void drawMarker(Marker n) {
    Marker k = Marker(markerId: n.markerId , position: n.position , icon: BitmapDescriptor.fromBytes(locationIcon));
    setState(() {
      _mapMarkers.clear();
      _mapMarkers.add(k);
      print(k.markerId);
    });
  }
  void drawMarkers(List<Marker> newMarkers) async {
    setState(() {
      _mapMarkers.clear();
      _mapMarkers.addAll(newMarkers);
    });
  }
  Widget lituationResult(String lID){
    return FutureBuilder(
        future: sp.getLituationById(lID),
        builder: (ctx , builder){
          if(!builder.hasData || builder.connectionState != ConnectionState.done){
            return Container();
          }
          Lituation l = builder.data;

          return GestureDetector(
                onTap: (){
                  //_viewLituation(lID , l.data['title']);
                },
                child: Card(
                  color: Theme.of(context).backgroundColor,
                  elevation: 5,
                  child: Container(
                    padding: EdgeInsets.only(bottom: 10),
                    height: 250,
                    width: 275,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5,child: lituationThumbnailWidget(l),),
                        Expanded(flex: 3,child: lituationInfoRow(l),)
                      ],
                    ),
                  ),
                ),
              );
        }
    );
  }
  Widget lituationInfoRow(Lituation l){
    return Container(
      margin: EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(flex: 2,child: lituationDateWidget(context , l),),
          Expanded(flex: 6,child: lituationInfoCardWidget(l),),
        ],
      ),
    );
  }
  Widget lituationInfoCardWidget(Lituation l){
    return Container(
      margin: EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(l.title , style: TextStyle(color: Theme.of(context).textSelectionColor),textScaleFactor: 1.2,),),
          //Expanded(child: Text(parseThemes(l) , textScaleFactor: 0.7 , style: TextStyle(color: Colors.blueAccent),),),
          //Expanded(child: lituationTimeWidget(l),),
          Expanded(child: Text(l.location , style: TextStyle(color: Theme.of(context).textSelectionColor),textScaleFactor: 0.7,),),
        ],
      ),
    );
  }
  Widget lituationTimeWidget(Lituation l){
    String st = parseTime(Timestamp.fromDate(l.date));
    String et = parseTime(Timestamp.fromDate(l.end_date));
    String day = parseDay(true, Timestamp.fromDate(l.date));
    return Text(
        '$day,$st - $et' , style: infoValue(Theme.of(context).textSelectionColor),
    );
  }
}
