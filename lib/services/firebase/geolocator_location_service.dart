import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../interfaces/i_location_service.dart';

class GeolocatorLocationService implements ILocationService {
  @override
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
  }

  @override
  Future<GeoPoint?> getCurrentPosition() async {
    final granted = await requestPermission();
    if (!granted) return null;
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return GeoPoint(pos.latitude, pos.longitude);
  }

  @override
  Stream<GeoPoint> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).map((pos) => GeoPoint(pos.latitude, pos.longitude));
  }
}
