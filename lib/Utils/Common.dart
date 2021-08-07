import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:latlong/latlong.dart';
import 'package:lit_beta/Models/Lituation.dart';
import 'package:lit_beta/Strings/constants.dart';
import 'package:uuid/uuid.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

double distance(double l1, double d1, double l2, double d2) {
  Distance distance = new Distance();
  double d = distance(new LatLng(l1, d1), new LatLng(l2, d2));
  return d;
}

Future<String> downloadFile(String url, String dir, String ext) async {
  HttpClient httpClient = new HttpClient();
  File file;
  String filePath = '';
  String fileName;
  String id = Uuid().v4().toString();
  fileName = "$id.$ext";

  try {
    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    if (response.statusCode == 200) {
      var bytes = await consolidateHttpClientResponseBytes(response);
      filePath = '$dir/$fileName';
      file = File(filePath);
      await file.writeAsBytes(bytes);
    } else
      filePath = 'Error code: ' + response.statusCode.toString();
  } catch (ex) {
    filePath = 'Can not fetch url';
  }

  return filePath;
}

void addEvent2Calendar(Lituation lit) {
  Event e = Event(
    title: lit.title,
    description: lit.description,
    location: lit.location,
    startDate: lit.date,
    endDate: lit.end_date,
    allDay: false,
    iosParams: IOSParams(
      reminder: Duration(minutes: 40),
    ),
    androidParams: AndroidParams(),
    recurrence: null,
  );
  Add2Calendar.addEvent2Cal(e);
}

Future<String> sendEmail(Lituation lit) async {
  String body = """
    <p>I'd like to invite you ${lit.title}.</p>

    <p>Address: ${lit.location}</p>
    <p>Start: ${lit.date.toString()}\n</p>
    <p>End: ${lit.end_date.toString()}\n</p>
  """;
  final Email email = Email(
    body: body,
    subject: "Invite to " + lit.title,
    recipients: [],
    isHTML: true,
  );

  String platformResponse;

  try {
    await FlutterEmailSender.send(email);
    platformResponse = 'success';
  } catch (error) {
    platformResponse = error.toString();
  }
  return platformResponse;
}

String lituationStatus(String status) {
  if (status == LIT_PENDING)
    return "pending";
  else if (status == LIT_ONGOING)
    return "has already started.";
  else if (status == LIT_ALMOSTOVER)
    return "will end soon.";
  else if (status == LIT_OVER)
    return "over";
  else
    return "";
}
