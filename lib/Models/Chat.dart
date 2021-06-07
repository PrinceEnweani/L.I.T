import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  String _room_id;
  DateTime _date_created;
  String _room_name;
  List<String> _party;
  List<String> _messages;

  ChatRoomModel(
      { String room_id,
      DateTime date_created,
      String room_name,
      List<String> party,
      List<String> messages,
      }) {
   this._room_id = room_id;
   this._date_created = _date_created;
   this._room_name = room_name;
   this._party = party;
   this._messages = messages;
  }

  String get room_id => _room_id;
  set room_id(String room_id) => _room_id = room_id;
  DateTime get date_created => date_created = _date_created;
  set date_created(DateTime date_created) => _date_created = date_created;
  String get room_name => _room_name;
  set room_name(String room_name) => _room_name = room_name;
  List<String> get party => _party;
  set party(List<String> party) => _party = party;
  List<String> get messages => _messages;
  set messages(List<String> messages) => _messages = messages;

  ChatRoomModel.fromJson(Map<String, dynamic> json) {
    _room_id = json['roomID'];
    _date_created = json['date_created'];
    _room_name = json['room_name'];
    _party = json['party'];
    _messages = json['messages'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['roomID'] = this._room_id;
    data['date_created'] = this._date_created;
    data['room_name'] = this._room_name;
    data['party'] = this._party;
    data['messages'] = this._messages;
    return data;
  }

}


class MessageModel {
  String _room_id;
  DateTime _time_sent;
  String _sender_id;
  String  _message;

  MessageModel(
      {String room_id,
      DateTime time_sent,
      String sender_id,
      String  message,
      }) {
    this._room_id;
    this._time_sent;
    this._sender_id;
    this._message;
  }

  String get room_id => _room_id;
  set room_id(String room_id) => _room_id = room_id;
  DateTime get time_sent => time_sent= _time_sent;
  set time_sent(DateTime time_sent) => _time_sent = time_sent;
  String get sender_id => _sender_id;
  set sender_id(String sender_id) => _sender_id = sender_id;
  String get message => _message;
  set message(String message) => _message = message;

  MessageModel.fromJson(Map<String, dynamic> json) {
    _room_id = json['roomID'];
    _time_sent = json['time_sent'];
    _sender_id = json['senderID'];
    _message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['roomID'] = this._room_id;
    data['time_sent'] = Timestamp.fromDate(this._time_sent);
    data['senderID'] = this._sender_id;
    data['message'] = this._message;
    return data;
  }

}

class ChatVisit{
  String visitorID;
  String visitedID;
  String roomID;
  String roomname;

  ChatVisit(
      {  String visitorID,
        String visitedID,
        String roomID,
        String roomname,
      }) {
    this.visitorID = visitorID;
    this.visitedID = visitedID;
    this.roomID = roomID;
    this.roomname = roomname;

  }

}
class ChatArgs{
  String userID;
  String roomID;
  String username;
  String visitedID;

  ChatWithUser({
    String userID,
    String roomID,
    String username,
    String visitedID,

}){
    this.userID = userID;
    this.roomID = roomID;
    this.username = username;
    this.visitedID = visitedID;
  }
}