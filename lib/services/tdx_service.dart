import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/bus_route.dart';

class TDXService {
  String? _accessToken;

  /// 取得 TDX Token
  Future<String> _getAccessToken() async {
    if (_accessToken != null) return _accessToken!;

    const clientId = '你的ClientID';
    const clientSecret = '你的ClientSecret';

    final response = await http.post(
      Uri.parse('https://tdx.transportdata.tw/auth/realms/TDXConnect/protocol/openid-connect/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'client_credentials',
        'client_id': clientId,
        'client_secret': clientSecret,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
      return _accessToken!;
    } else {
      throw Exception('取得 TDX token 失敗');
    }
  }

  /// 🔹 檔案快取 helper
  Future<File> _getCacheFile(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$name.json');
  }

  /// 🔸 檢查快取是否還有效（預設 1 天）
  Future<bool> _isCacheValid(File file, {Duration maxAge = const Duration(days: 1)}) async {
    if (!await file.exists()) return false;
    final lastModified = await file.lastModified();
    return DateTime.now().difference(lastModified) < maxAge;
  }

  /// ✅ 取得公車路線（含快取）
  Future<List<BusRoute>> fetchBusRoutesTyped({String city = 'Taipei'}) async {
    final cacheFile = await _getCacheFile('bus_routes_$city');

    if (await _isCacheValid(cacheFile)) {
      final json = jsonDecode(await cacheFile.readAsString()) as List;
      return json.map((e) => BusRoute.fromJson(e)).toList();
    }

    final token = await _getAccessToken();
    final url = 'https://tdx.transportdata.tw/api/basic/v2/Bus/Route/City/$city?\$format=JSON';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as List;
      await cacheFile.writeAsString(jsonEncode(json));
      return json.map((e) => BusRoute.fromJson(e)).toList();
    } else {
      throw Exception('載入路線失敗');
    }
  }

  /// ✅ 取得公車站牌（含快取）
  Future<List<String>> fetchRouteStops({required String city, required String routeName}) async {
    final cacheFile = await _getCacheFile('bus_stops_${city}_$routeName');

    if (await _isCacheValid(cacheFile)) {
      final json = jsonDecode(await cacheFile.readAsString()) as List;
      return json.map<String>((e) => e['StopName']['Zh_tw'] as String).toList();
    }

    final token = await _getAccessToken();
    final url =
        'https://tdx.transportdata.tw/api/basic/v2/Bus/StopOfRoute/City/$city/$routeName?\$format=JSON';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as List;
      await cacheFile.writeAsString(jsonEncode(json));
      return json.map<String>((e) => e['StopName']['Zh_tw'] as String).toList();
    } else {
      throw Exception('載入站牌失敗');
    }
  }

  /// （選配）清除所有快取
  Future<void> clearCache() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync();
    for (var file in files) {
      if (file is File && file.path.endsWith('.json')) {
        await file.delete();
      }
    }
  }
}
