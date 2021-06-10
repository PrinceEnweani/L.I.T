import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lit_beta/DBC/Auth.dart';
import 'package:lit_beta/Models/Lituation.dart';

class ChatProvider {
  Auth db = Auth();
  final String userID;

  ChatProvider(this.userID);

  chatStream(){}

  Future<dynamic> searchChatRooms(String query) async {
    List<String> results = [];
    var rooms = [];
    await db.getUserChatRooms(userID).then((value){
      for(var d in value.docs){
        if(d.data()['room_name'].toString().toLowerCase().contains(query.toLowerCase())){
          if(!results.contains(d.data()['room_name'])){
              results.add(d.data()['room_name']);
              rooms.add(d);
          }
        }
      }
    });
    return rooms;
  }

  Future<dynamic> getUserChatRooms() async {
    var rooms = [];
    List<String> results = [];
    await db.getUserChatRooms(userID).then((value){
      for(var room in value.docs){
        if(!results.contains(room.data()['room_id'])){
          results.add(room.data()['room_id']);
          rooms.add(room);
        }
      }
    });
    return rooms;
  }

  getChatRoom(String id) {
    return db.getChatRoomParty(id);
  }
  getUser(String id){
    return db.getUser(id);
  }
}