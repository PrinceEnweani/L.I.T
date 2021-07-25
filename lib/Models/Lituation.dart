import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lit_beta/Models/User.dart';
import 'package:lit_beta/Strings/constants.dart';

class UserRate {
  String from;
  String to;
  int rate;
  DateTime createdAt;
  UserRate(this.from, this.to, this.rate, this.createdAt);
  Map<String, dynamic> toJSON() {
    return {'from': from, 'to': to, 'rate': rate, 'createdAt': createdAt};
  }
  UserRate.fromJSON(Map<String, dynamic> json) {
    this.from = json['from'] ?? "";
    this.to = json['to'] ?? "";
    this.rate = json['rate'] ?? 0;
    this.createdAt = json['createdAt']?.toDate()??DateTime.now();
  }
}

class Lituation {
  String _capacity;
  DateTime _date;
  DateTime _end_date;
  DateTime _dateCreated;
  String _description;
  String _title;
  String _entry;
  String _eventID;
  String _hostID;
  User _host;
  String _fee;
  String _location;
  LatLng _locationLatLng;
  List<String> _musicGenres;
  List<String> _requirements;
  String _themes;
  String _status;
  int _clout;
  List<String> _specialGuests;
  List<String> _observers;
  List<String> _invited;
  List<String> _vibes;
  List<String> _pending;
  List<String> _thumbnailURLs;
  List<String> _likes;
  List<String> _dislikes;
  List<UserRate> _rates;

  Lituation(
      {String capacity,
      DateTime date,
      DateTime end_date,
      DateTime dateCreated,
      String description,
      String title,
      String entry,
      String eventID,
      String hostID,
      String fee,
      String location,
      LatLng locationLatLng,
      List<String> musicGenres,
      List<String> requirements,
      String themes,
      String status,
      int clout,
      List<String> specialGuests,
      List<String> observers,
      List<String> vibes,
      List<String> invited,
      List<String> pending,
      List<String> thumbnailURLs,
      List<String> likes,
      List<String> dislikes,
      List<UserRate> rates}) {
    this._capacity = capacity;
    this._date = date;
    this._end_date = end_date;
    this._dateCreated = dateCreated;
    this._description = description;
    this._title = title;
    this._entry = entry;
    this._eventID = eventID;
    this._hostID = hostID;
    this._fee = fee;
    this._location = location;
    this._locationLatLng = locationLatLng;
    this._status = status;
    this._musicGenres = musicGenres;
    this._requirements = requirements;
    this._themes = themes;
    this._clout = clout;
    this._specialGuests = specialGuests;
    this._observers = observers;
    this._vibes = vibes;
    this._invited = invited;
    this._thumbnailURLs = thumbnailURLs;
    this._likes = likes;
    this._dislikes = dislikes;
    this._rates = rates;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['capacity'] = this._capacity;
    data['date'] = Timestamp.fromDate(this._date);
    data['end_date'] = Timestamp.fromDate(this._end_date);
    data['dateCreated'] = Timestamp.fromDate(this._dateCreated);
    data['description'] = this._description;
    data['title'] = this._title;
    data['entry'] = this._entry;
    data['hostID'] = this._hostID;
    data['eventID'] = this._eventID;
    data['status'] = this._status;
    data['fee'] = this._fee;
    data['clout'] = this._clout;
    data['location'] = this._location;
    data['locationLatLng'] =
        GeoPoint(this._locationLatLng.latitude, this._locationLatLng.longitude);
    data['musicGenres'] = this._musicGenres;
    data['requirements'] = this._requirements;
    data['themes'] = this._themes;
    data['specialGuests'] = this._specialGuests;
    data['observers'] = this._observers;
    data['vibes'] = this._vibes;
    data['invited'] = this._invited;
    data['pending'] = this._pending;
    data['thumbnail'] = this._thumbnailURLs;
    data['likes'] = this._likes;
    data['dislikes'] = this._dislikes;
    data['rates'] = this._rates?.map((e) => e.toJSON())??[];

    return data;
  }

  Lituation.fromJson(Map<String, dynamic> json) {
    this._capacity = json['capacity'];
    this._date = json['date'].toDate();
    this._end_date = json['end_date'].toDate();
    this._dateCreated = json['dateCreated'].toDate();
    this._description = json['description'];
    this._title = json['title'];
    this._entry = json['entry'];
    this._hostID = json['hostID'];
    this._eventID = json['eventID'];
    this._status = json['status'];
    this._fee = json['fee'];
    this._clout = json['clout'];
    this._location = json['location'];
    this._locationLatLng = LatLng(
        json['locationLatLng'].latitude, json['locationLatLng'].longitude);
    this._musicGenres = List<String>.from(json['musicGenres']);
    this._requirements = List<String>.from(json['requirements']);
    this._themes = json['themes'];
    this._specialGuests = List<String>.from(json['specialGuests']);
    this._observers = List<String>.from(json['observers']);
    this._vibes = List<String>.from(json['vibes']);
    this._invited = List<String>.from(json['invited'] ?? []);
    this._pending = List<String>.from(json['pending']);
    this._thumbnailURLs = List<String>.from(json['thumbnail']);
    this._likes = List<String>.from(json['likes'] ?? []);
    this._dislikes = List<String>.from(json['dislikes'] ?? []);
    this._rates = List<UserRate>.from((json['rates'] ?? []).map((element) => UserRate.fromJSON(element)));
  }

  DateTime get date => _date;

  set date(DateTime value) {
    _date = value;
  }

  DateTime get dateCreated => _dateCreated;
  DateTime get end_date => _end_date;
  set dateCreated(DateTime value) {
    _dateCreated = value;
  }

  String get description => _description;

  set description(String value) {
    _description = value;
  }

  String get title => _title;

  set title(String value) {
    _title = value;
  }

  LatLng get locationLatLng => _locationLatLng;

  set locationLatLng(LatLng value) {
    _locationLatLng = value;
  }

  set end_date(DateTime value) {
    _end_date = value;
  }

  String get capacity => _capacity;

  set capacity(String value) {
    _capacity = value;
  }

  String get entry => _entry;

  set entry(String value) {
    _entry = value;
  }

  String get eventID => _eventID;

  set eventID(String value) {
    _eventID = value;
  }

  String get hostID => _hostID;

  set hostID(String value) {
    _hostID = value;
  }

  User get host => _host;
  set host(User u) {
    _host = u;
  }

  int get clout => _clout;

  set clout(int value) {
    _clout = value;
  }

  String get location => _location;

  set location(String value) {
    _location = value;
  }

  List<String> get musicGenres => _musicGenres;

  set musicGenres(List<String> value) {
    _musicGenres = value;
  }

  List<String> get requirements => _requirements;

  set requirements(List<String> value) {
    _requirements = value;
  }

  String get themes => _themes;

  set themes(String value) {
    _themes = value;
  }

  String get fee {
    if (_fee == "") return "0";
    return _fee;
  }

  set fee(String value) {
    _fee = value;
  }

  String get status => _status;

  set status(String value) {
    _status = value;
  }

  List<String> get specialGuests => _specialGuests;

  set specialGuests(List<String> value) {
    _specialGuests = value;
  }

  List<String> get vibes => _vibes;
  List<String> get invited => _invited;

  set vibes(List<String> value) {
    _vibes = value;
  }

  set invited(List<String> value) {
    _invited = value;
  }

  List<String> get thumbnailURLs {
    if (_thumbnailURLs.length > 0)
      return _thumbnailURLs;
    else
      return [litPlaceHolder];
  }

  set thumbnailURLs(List<String> value) {
    _thumbnailURLs = value;
  }

  List<String> get observers => _observers;

  set observers(List<String> value) {
    _observers = value;
  }

  List<String> get pending => _pending;

  set pending(List<String> value) {
    _pending = value;
  }

  List<String> get likes => _likes;

  set likes(List<String> value) {
    _likes = value;
  }

  List<String> get dislikes => _dislikes;

  set dislikes(List<String> value) {
    _dislikes = value;
  }
  List<UserRate> get rates => _rates;
}

class InviteVisit{
  String userID;
  Lituation lit;

  InviteVisit(
      {  String userID,
        Lituation lit
      }) {
    this.userID = userID;    
    this.lit = lit;
  }

}