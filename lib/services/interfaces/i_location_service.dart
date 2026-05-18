import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ILocationService {
  Future<GeoPoint?> getCurrentPosition();
  Future<bool> requestPermission();
  Stream<GeoPoint> positionStream();
}
