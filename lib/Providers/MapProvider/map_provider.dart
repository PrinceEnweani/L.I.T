import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lit_beta/DBC/Auth.dart';
import 'package:lit_beta/Extensions/common_functions.dart';
import 'package:lit_beta/Extensions/search_filters.dart';
import 'package:lit_beta/Models/Lituation.dart';

class MapProvider {
  Auth db = Auth();
  final String userID;
  MapProvider(this.userID);

  Future<LatLng> getUserLocation() async {
  var s = await db.getUserSnapShot(userID);
  return latLngFromGeoPoint(s.data()['userLocLatLng']);
  }

  getUser(){
    return db.getUser(userID);
  }

  Future<List<DocumentSnapshot>> searchLituation(String query , String filter) async {
    List<String> resultIDs = [];
    List<DocumentSnapshot> lituationResults = [];
    await db.getAllLituationsSnapShot().then((value){
      var lituations = List.from(value.docs);
      if(query != ''){
        String title;
        String date;
        String lID;
        String theme;
        String address;
        for(DocumentSnapshot l in lituations){ 
          title = l.data()['title'].toString().toLowerCase();
          date = l.data()['date'].toString().toLowerCase();
          theme = l.data()['themes'].toString().toLowerCase();
          address = l.data()['location'].toString().toLowerCase();
          lID = l.data()['eventID'];
          if(filter == "*"){
            if(title.contains(query) || date.contains(query) || theme.contains(query) || address.contains(query)){
              if (!resultIDs.contains(l.data()['eventID'])){
                resultIDs.add(lID);
                lituationResults.add(l);
              }
            }
          }
          if(filter == BY_TITLE){
            if(l.data()['title'].toString().toLowerCase().contains(query.toLowerCase()) && !resultIDs.contains(l.data()['eventID'])){
              lituationResults.add(l);
              resultIDs.add(l.data()['eventID']);
            }
          }
          if(filter == BY_DATE){
            //TODO Fix
            if(l.data()['date'].toString().toLowerCase().contains(query.toLowerCase()) && !resultIDs.contains(l.data()['eventID'])){
              lituationResults.add(l);
              resultIDs.add(l.data()['eventID']);
            }
          }
          if(filter == BY_HOST){
            if(l.data()['hostID'].toString().toLowerCase().contains(query.toLowerCase()) && !resultIDs.contains(l.data()['eventID'])){
              lituationResults.add(l);
              resultIDs.add(l.data()['eventID']);
            }
          }
          if(filter == BY_THEME){
            if(l.data()['themes'].toString().toLowerCase().contains(query.toLowerCase()) && !resultIDs.contains(l.data()['eventID'])){
              lituationResults.add(l);
              resultIDs.add(l.data()['eventID']);
            }
          }
          if(filter == BY_ADDRESS){
            if((address.contains(query.toLowerCase()) || title.contains(query)) && !resultIDs.contains(l.data()['eventID'])){
              lituationResults.add(l);
              resultIDs.add(l.data()['eventID']);
            }
          }
        }
      }else{
        for(DocumentSnapshot l in lituations){
          if(!resultIDs.contains(l.data()['eventID'])){
            resultIDs.add(l.data()['eventID']);
            lituationResults.add(l);
          }
        }
      }
    });
    return lituationResults;
  }
  MapStream(){

  }
  getLituation(String id){
    return db.getLituationByID(id);
  }

}