import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:latlong/latlong.dart';
import 'package:uuid/uuid.dart';

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
    if(response.statusCode == 200) {
      var bytes = await consolidateHttpClientResponseBytes(response);
      filePath = '$dir/$fileName';
      file = File(filePath);
      await file.writeAsBytes(bytes);
    }
    else
      filePath = 'Error code: '+response.statusCode.toString();
  }
  catch(ex){
    filePath = 'Can not fetch url';
  }

  return filePath;
}