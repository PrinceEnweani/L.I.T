import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lit_beta/DBC/Auth.dart';
import 'package:lit_beta/Extensions/search_filters.dart';
import 'package:lit_beta/Models/Lituation.dart';
import 'package:lit_beta/Models/User.dart';
import 'package:lit_beta/Utils/Common.dart';

class SearchProvider {
  Auth db = Auth();
  final String userID;

  SearchProvider(this.userID);

  lituationStream(){}

  Future<DocumentSnapshot> getCategories(){
    return db.getLituationCategories();
  }
  getUserStreamByID(String id){
    return db.getUser(id);
  }

  bool filterCompare(String filter, String query, Lituation lit) {
    if(filter == BY_TITLE && lit.title.toLowerCase().contains(query.toLowerCase()))
      return true;
    if(filter == BY_DATE && lit.date.toString().toLowerCase().contains(query.toLowerCase()))
      return true;
    if(filter == BY_HOST && lit.hostID.toLowerCase().contains(query.toLowerCase()))
      return true;
    if(filter == BY_THEME && lit.themes.toLowerCase().contains(query.toLowerCase()))
      return true;
    if(filter == BY_ADDRESS && lit.location.toLowerCase().contains(query.toLowerCase()))
      return true;
    return false;
  }
  Future<List<User>> searchUser(String username, String userID) async {
    List<String> results = [];
    List<User> users = [];
    DocumentSnapshot meSnap = await db.getUserSnapShot(userID);
    User me = User.fromJson(meSnap.data());
    await db.getUsers().then((value){
      for(var d in value.docs){
        User u = User.fromJson(d.data());
        if(u.username.toLowerCase().contains(username.toLowerCase()) && u.userID != userID){
          if(!results.contains(u.userID)){
            results.add(u.userID);
            users.add(u);
          }
        }
      }
    });
    users.sort((a, b) {
      double d1 = distance(a.userLocLatLng.latitude, a.userLocLatLng.longitude, me.userLocLatLng.latitude, me.userLocLatLng.longitude);
      double d2 = distance(b.userLocLatLng.latitude, b.userLocLatLng.longitude, me.userLocLatLng.latitude, me.userLocLatLng.longitude);
      if (d1 > d2)
        return 1;
      return -1;
    });
    return users;
  }

  //filters determine if the query is for title, date or other field.
  //Filter options:date , title, host.
   Future<List<Lituation>> searchLituation(String query , String filter) async {
    List<String> resultIDs = [];
    List<Lituation> lituationResults = [];
    await db.getAllLituationsSnapShot().then((value) async {
      var lituations = List.from(value.docs);
      for(DocumentSnapshot l in lituations){          
        Lituation lit = Lituation.fromJson(l.data());
        DocumentSnapshot snap = await db.getUserSnapShot(lit.hostID);
        if (snap.exists == true) {
          User host = User.fromJson(snap.data());
          lit.host = host;
        }
        if (query == '' || (filterCompare(filter, query, lit) && !resultIDs.contains(lit.eventID))) {
          lituationResults.add(lit);
          resultIDs.add(lit.eventID);
        }
      }
    });
    return lituationResults;
  }

  Future<String> getVibingStatus(String id) async {
    String v = '';
    await db.getVibing(userID).toList().then((value){
      if(value.contains(id)){
        v = 'vibing/+\n';
      }
    });
    await db.getVibed(userID).toList().then((value){
      if(value.contains(id)){
        v += 'vibed';
      }
   });
    return v;
  }

  Future<List<String>> friendList() async {
    List<String> friends = [];
    List users = await db.getVibed(userID).toList();
    users.add(await db.getVibing(userID).toList());
    for(var u in users){
      if (!friends.contains(u.data()['userID'])){
        friends.add(u.data()['userID']);
      }
    }
    return friends;

  }

  getLituation(String id){
    return db.getLituationByID(id);
  }

  Future<Lituation> getLituationById(String id) async {
    DocumentSnapshot l = await db.getLituationSnapshotByID(id);
    Lituation lit = Lituation.fromJson(l.data());
    DocumentSnapshot snap = await db.getUserSnapShot(lit.hostID);
    if(snap.exists == true) {
      User host = User.fromJson(snap.data());
      lit.host = host;
    }
    return lit;
  }

  Future<List<Lituation>> getRecommendLituations() async {
    List<Lituation> lituationResults = [];
    await db.getAllLituationsSnapShot().then((value)async {
      var lituations = List.from(value.docs);
      for(DocumentSnapshot l in lituations){
        Lituation lit = Lituation.fromJson(l.data());
        DocumentSnapshot snap = await db.getUserSnapShot(lit.hostID);
        if (snap.exists == true) {
          User host = User.fromJson(snap.data());
          lit.host = host;
        }
        lituationResults.add(lit);
        if (lituationResults.length >= 5)
          break;
      }
    });
    return lituationResults;
  }  

  Future<List<Lituation>> getTrendingLituations() async {    
    DocumentSnapshot meSnap = await db.getUserSnapShot(userID);
    User me = User.fromJson(meSnap.data());
    List<Lituation> lituationResults = [];
    await db.getAllLituationsSnapShot().then((value)async {
      var lituations = List.from(value.docs);
      for(DocumentSnapshot l in lituations){
        Lituation lit = Lituation.fromJson(l.data());
        DocumentSnapshot snap = await db.getUserSnapShot(lit.hostID);
        User host = User.fromJson(snap.data());
        lit.host = host;
        lituationResults.add(lit);
        if (lituationResults.length >= 5)
          break;
      }
    });
    return lituationResults;
  }

}