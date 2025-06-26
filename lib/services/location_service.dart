import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// 取得目前 GPS 座標
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('請開啟定位功能');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('使用者未授權定位');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('定位權限永久被拒');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// 反查地址，取得縣市
  static Future<String> getCityFromPosition(Position position) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      final placemark = placemarks.first;
      return placemark.administrativeArea ?? '未知地區';
    } else {
      throw Exception('找不到地區名稱');
    }
  }

  /// ✅ 一鍵取得目前縣市名稱
  static Future<String> getCurrentCity() async {
    final position = await getCurrentPosition();
    return await getCityFromPosition(position);
  }
}
