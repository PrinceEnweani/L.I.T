import 'package:latlong/latlong.dart';

double distance(double l1, double d1, double l2, double d2) {
  Distance distance = new Distance();  
  double d = distance(new LatLng(l1, d1), new LatLng(l2, d2));
  return d;
}