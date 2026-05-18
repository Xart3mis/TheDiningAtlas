import 'package:cloud_firestore/cloud_firestore.dart';
import '../interfaces/i_location_service.dart';

class MockLocationService implements ILocationService {
  @override
  Future<GeoPoint?> getCurrentPosition() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const GeoPoint(35.6654, 139.7707); // Tokyo
  }

  @override
  Future<bool> requestPermission() async => true;

  @override
  Stream<GeoPoint> positionStream() => Stream.value(const GeoPoint(35.6654, 139.7707));
}
