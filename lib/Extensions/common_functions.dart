import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dialog_context/dialog_context.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lit_beta/Models/Lituation.dart';
import 'package:lit_beta/Strings/constants.dart';
import 'package:lit_beta/Models/User.dart';
import 'package:lit_beta/Styles/text_styles.dart';
import 'package:http/http.dart' as http;

String parseVibes(String vibes){
  if(vibes == null){
    return '0';
  }
  if(vibes.length > 3){
    return vibes.substring(0 , 1) + " k";
  }
  return vibes;
}


showSnackBar(BuildContext context , SnackBar bar){
  Scaffold.of(context).showSnackBar(bar);
}
LatLng latLngFromGeoPoint(GeoPoint gp){
  LatLng l = new LatLng(gp.latitude, gp.longitude);
  return l;
}
String parseThemes(Lituation l){
  List<String> themes = l.themes.split(',');
  List<String> themes2 = [];
  String themesStr = "";
  for(String t in themes){
    if(!themes2.contains('@'+t)) {
      t = '@' + t;
      themes2.add(t);
    }
  }
  themesStr = themes2.toString().replaceAll('[', '').replaceAll(']', '');
  return themesStr;
}
String parseDateToEndDate(Timestamp sd , Timestamp ed){
  int c = 1000;
  DateTime sdate = DateTime.fromMicrosecondsSinceEpoch(sd.millisecondsSinceEpoch * c);
  DateTime edate = DateTime.fromMicrosecondsSinceEpoch(ed.millisecondsSinceEpoch * c);
  return DateFormat.jm().format(sdate) + " - " + DateFormat.jm().format(edate);
}
String getSenderIdFromInvitation(String id){
  return id.split(':')[0];
}
String getLituationIdFromInvitation(String id){
  return id.split(':')[1];
}
String getRecipientIdFromInvitation(String id){
  return id.split(':')[2];
}

String parseThemesFromSnapShot(AsyncSnapshot l){
  List<String> themes = l.data['themes'].split(',');
  List<String> themes2 = [];
  String themesStr = "";
  for(String t in themes){
    if(!themes2.contains('@'+t)) {
      t = '@' + t;
      themes2.add(t);
    }
  }
  themesStr = themes2.toString().replaceAll('[', '').replaceAll(']', '');
  return themesStr;
}
String parseThemesFrom(Lituation l){
  List<String> themes = l.themes.split(',');
  List<String> themes2 = [];
  String themesStr = "";
  for(String t in themes){
    if(!themes2.contains('@'+t)) {
      t = '@' + t;
      themes2.add(t);
    }
  }
  themesStr = themes2.toString().replaceAll('[', '').replaceAll(']', '');
  return themesStr;
}
String parseTime(Timestamp sd){
  int c = 1000;
  DateTime sdate = DateTime.fromMicrosecondsSinceEpoch(sd.millisecondsSinceEpoch * c);
  return DateFormat.j().format(sdate);
}
String parseDay(bool cut , Timestamp date){
  int c = 1000;
  DateTime d = DateTime.fromMicrosecondsSinceEpoch(date.microsecondsSinceEpoch * c);
  String parsedDate = DateFormat('EEEE').format(d);
  if(cut){
    return parsedDate.substring(0 , 3);
  }
  return parsedDate;
}
String parseDate(Timestamp d){
  int c = 1000;
  DateTime date = DateTime.fromMicrosecondsSinceEpoch(d.millisecondsSinceEpoch * c);
  return DateFormat.yMd().addPattern('\n').add_jm().format(date);
}
DateTime dateTimeToTimeStamp(Timestamp d){
  return  DateTime.fromMicrosecondsSinceEpoch(d.millisecondsSinceEpoch * 1000);
}
bool getStatusAsBool(String status){
  //Online , Live , etc
  if(status!= null && (status.contains('online') || status.contains('live'))){
    return true;
  }
  return false;
}
Color getStatusRingColor(bool online){
  if(online){
    return Colors.green;
  }
  return Colors.red;
}
showConfirmationDialog(BuildContext context ,String title , String message , List<Widget> actions ){
  showDialog(
      context: context,
      builder: (_) => new CupertinoAlertDialog(
        title: new Text(title , style: infoLabel(Theme.of(context).buttonColor),),
        content: new Text(message , style: infoValue(Theme.of(context).buttonColor),),
        actions: actions
      ));
}

Future<String> getStripeIntent(String paymentID, String amount, String currency) async {
    http.Response response = await http.post(
      'https://api.stripe.com/v1/payment_intents',
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Bearer ${stripe_secrete_key}',
      },
      body: <String, dynamic>{
          "amount": amount,
          "currency": currency,
          "payment_method_types[]": "card"
        },
    );
    if (response.statusCode == 200)
      return response.body;
    return "";
  }

Future<String> sendTicketEmail(String subject, String email, String userid, Lituation lit) async {
    try {
      http.Response response = await http.post(
        '${emailServiceUrl}',
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode({        
          "dest": email,
          "subject": subject,
          "content": "<p>Thanks for your particiate.</p><img src='${ticketImageUrl}?userid=${userid}&eventid=${lit.eventID}' alt='invite'/><p>Period: ${DateFormat.yMEd().format(lit.date)} ${DateFormat.Hm().format(lit.date)} ~ ${DateFormat.yMEd().format(lit.end_date)} ${DateFormat.Hm().format(lit.end_date)}</p>"
        })
      );      
      if (response.statusCode == 200)
        return response.body;
      return response.body;
    } catch (e) {
      print(e.toString());
      return "";
    }
  }