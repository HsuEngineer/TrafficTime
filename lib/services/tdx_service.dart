import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/bus_route.dart';

class TDXService {
  String? _accessToken;

  /// ✅ 取得 TDX Token（帶記憶快取）
  Future<String> _getAccessToken() async {
    if (_accessToken != null) return _accessToken!;

    const clientId = 'hsu.work.in.person-9e1a2761-a4e1-4454';
    const clientSecret = 'f0e4fb28-a372-4b32-9ccb-b36eeae6d57e';

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

  /// 📁 快取檔案路徑
  Future<File> _getCacheFile(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$name.json');
  }

  /// ⏱️ 檢查快取是否仍有效
  Future<bool> _isCacheValid(File file, {Duration maxAge = const Duration(days: 1)}) async {
    if (!await file.exists()) return false;
    final lastModified = await file.lastModified();
    return DateTime.now().difference(lastModified) < maxAge;
  }

  /// ✅ 取得公車路線清單（含快取）
  Future<List<BusRoute>> fetchBusRoutesTyped({String city = 'Taipei'}) async {
    final cacheFile = await _getCacheFile('bus_routes_$city');

    if (await _isCacheValid(cacheFile)) {
      print('📄 使用快取資料：${cacheFile.path}');
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
      print('📡 從 TDX API 抓取路線');
      final json = jsonDecode(response.body) as List;
      await cacheFile.writeAsString(jsonEncode(json));
      return json.map((e) => BusRoute.fromJson(e)).toList();
    } else {
      throw Exception('載入路線失敗');
    }
  }

  /// ✅ 取得站牌清單（含快取、安全解析）
  Future<List<String>> fetchRouteStops({required String city, required String routeName}) async {
    final cacheFile = await _getCacheFile('bus_stops_${city}_$routeName');

    if (await _isCacheValid(cacheFile)) {
      print('📄 使用快取站牌資料：${cacheFile.path}');
      final json = jsonDecode(await cacheFile.readAsString()) as List;
      return _extractStopNames(json);
    }

    final token = await _getAccessToken();
    final encodedRouteName = Uri.encodeComponent(routeName);
    final url = 'https://tdx.transportdata.tw/api/basic/v2/Bus/StopOfRoute/City/$city/$encodedRouteName?\$format=JSON';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      print('📡 從 TDX API 抓取站牌：$routeName');
      final json = jsonDecode(response.body) as List;
      await cacheFile.writeAsString(jsonEncode(json));
      return _extractStopNames(json);
    } else {
      throw Exception('載入站牌失敗');
    }
  }

  /// 🔍 從 Stops 陣列中擷取站名（安全且去重）
  List<String> _extractStopNames(List data) {
    final stopNames = <String>{};

    for (var item in data) {
      final stops = item['Stops'];
      if (stops is List) {
        for (var stop in stops) {
          final name = stop['StopName']?['Zh_tw'];
          if (name is String) {
            stopNames.add(name);
          }
        }
      }
    }

    return stopNames.toList();
  }

  /// 🧹 清除所有快取
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
