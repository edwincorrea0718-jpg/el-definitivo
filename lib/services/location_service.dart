import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'Los servicios de ubicación están desactivados.',
        LocationErrorType.serviceDisabled,
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException(
          'Permiso de ubicación denegado.',
          LocationErrorType.permissionDenied,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Permisos denegados permanentemente. Ve a Configuración.',
        LocationErrorType.permissionDeniedForever,
      );
    }

    // ✅ FIX: geolocator ^11 usa desiredAccuracy directamente
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static Stream<Position> getPositionStream() {
    // ✅ FIX: usar LocationSettings correctamente
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  static Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }
}

enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unknown,
}

class LocationException implements Exception {
  final String message;
  final LocationErrorType type;
  LocationException(this.message, this.type);
}
