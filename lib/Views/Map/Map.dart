
import 'dart:async';

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

  @override
  void dispose(){
    super.dispose();
  }

  getUserLocation() async {
   await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best).then((value){
     setState(() {
       userPosition = value;
     });
   });
  }
  @override
  void initState() {
    mp = new MapProvider(widget.userID);
    getUserLocation();
    _controller = Completer();
    _places = GoogleMapsPlaces(apiKey: MAPS_KEY);
    mapSearchController = TextEditingController();
    placesSearchResults =  [];
    addressResults = [];
    zoom  = 12.0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: liveMapWidget(),
    );

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
          var locationIcon = await getBytesFromAssetFile('assets/images/litlocationicon.png' ,225);
          List<Marker> resultMarkers = [];
          List<PlacesSearchResult> res = [];
          return mp.searchLituation(pattern, BY_ADDRESS).then((results){
            if(results.length > 0) {
              moveCamera(
                  CameraPosition(
                bearing: 0,
                zoom: 10,
                target: latLngFromGeoPoint(results[0].data()['locationLatLng']),
              )
              );
              for(var l in results){
                resultMarkers.add(googleMapMarker(l.data()['title'], BitmapDescriptor.fromBytes(locationIcon), latLngFromGeoPoint(l.data()['locationLatLng'])));
                lituationResults.add(lituationResultCard(context, l.data()['eventID'], l.data()['thumbnail'], l.data()['title'], l.data()['date'], l.data()['entry']));
              }
              drawMarkers(resultMarkers);
              _places.searchByText(pattern).then((value){
               res =  value.results;
             });
            }
            return res;
          });
        }
        ,
        itemBuilder: (context, PlacesSearchResult suggestion) {
          return placeResultTile(context , suggestion);
        },
        onSuggestionSelected: (PlacesSearchResult suggestion) {
          mapSearchController.text = suggestion.name;
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
  Future<void> drawMarker(Marker n) async {
    var locationIcon = await getBytesFromAssetFile('assets/images/litlocationicon.png' ,250);
    Marker k = Marker(markerId: n.markerId , position: n.position , icon: BitmapDescriptor.fromBytes(locationIcon));
    setState(() {
      _mapMarkers.clear();
      _mapMarkers.add(k);
      print(k.markerId);
    });
    return;
  }
  Future<void> drawMarkers(List<Marker> newMarkers) async {
    setState(() {
      _mapMarkers.clear();
      _mapMarkers.addAll(newMarkers);
    });
    return;
  }
}
