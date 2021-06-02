import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dialog_context/dialog_context.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lit_beta/Styles/text_styles.dart';

String parseVibes(String vibes){
  if(vibes == null){
    return '0';
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
String parseThemes(AsyncSnapshot l){
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

showConfirmationDialog(BuildContext context ,String title , String message , List<Widget> actions ){
  showDialog(
      context: context,
      builder: (_) => new CupertinoAlertDialog(
        title: new Text(title , style: infoLabel(Theme.of(context).buttonColor),),
        content: new Text(message , style: infoValue(Theme.of(context).textSelectionColor),),
        actions: actions
      ));
}