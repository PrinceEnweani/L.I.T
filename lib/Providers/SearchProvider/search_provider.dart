import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lit_beta/DBC/Auth.dart';
import 'package:lit_beta/Extensions/search_filters.dart';
import 'package:lit_beta/Models/Lituation.dart';

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
  Future<dynamic> searchUser(String username) async {
    List<String> results = [];
   var users = [];
    await db.getUsers().then((value){
      for(var d in value.docs){
        if(d.data()['username'].toString().toLowerCase().contains(username.toLowerCase())){
          if(!results.contains(d.data()[userID])){
            results.add(d.data()['userID']);
            users.add(d);
          }
        }
      }
    });
    return users;
  }

  //filters determine if the query is for title, date or other field.
  //Filter options:date , title, host.
   searchLituation(String query , String filter) async {
    List<String> resultIDs = [];
    var lituationResults = [];
    await db.getAllLituationsSnapShot().then((value){
      var lituations = List.from(value.docs);
      if(query != ''){
        for(DocumentSnapshot l in lituations){
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
          if((l.data()['address'].toString().toLowerCase().contains(query.toLowerCase()) || l.data()['title'].toString().toLowerCase().contains(query.toLowerCase()))&& !resultIDs.contains(l.data()['eventID'])){
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
}