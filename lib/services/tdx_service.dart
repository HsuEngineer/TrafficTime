import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

class TDXService {
  final String clientId = 'hsu.work.in.person-9e1a2761-a4e1-4454';
  final String clientSecret = 'f0e4fb28-a372-4b32-9ccb-b36eeae6d57e';

  String? _accessToken;
  DateTime? _tokenExpiry;

  /// 取得 TDX Access Token
  Future<String> _getAccessToken() async {
    // 如果 Token 尚未過期，直接使用
    if (_accessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

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
      final expiresIn = int.tryParse(data['expires_in'].toString()) ?? 1800;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
      return _accessToken!;
    } else {
      throw Exception('取得 AccessToken 失敗: ${response.body}');
    }
  }

  /// 取得指定城市的公車路線名稱清單
  Future<List<String>> fetchBusRoutes({String city = 'Taipei'}) async {
    final token = await _getAccessToken();
    final url = 'https://tdx.transportdata.tw/api/basic/v2/Bus/Route/City/$city?%24format=JSON';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map<String>((e) => e['RouteName']['Zh_tw'].toString()).toList();
    } else {
      throw Exception('載入路線失敗: ${response.statusCode}');
    }
  }

  /// 根據城市與路線取得站牌名稱清單
  Future<List<String>> fetchRouteStops({
    required String city,
    required String routeName,
  }) async {
    final token = await _getAccessToken();
    final encodedRouteName = Uri.encodeComponent(routeName);
    final url = 'https://tdx.transportdata.tw/api/basic/v2/Bus/StopOfRoute/City/$city/$encodedRouteName?\$format=JSON';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      if (data.isNotEmpty && data[0]['Stops'] != null) {
        final List stops = data[0]['Stops'];
        return stops.map<String>((e) => e['StopName']['Zh_tw'].toString()).toList();
      }
      return [];
    } else {
      throw Exception('載入站牌失敗: ${response.statusCode}');
    }
  }
}
