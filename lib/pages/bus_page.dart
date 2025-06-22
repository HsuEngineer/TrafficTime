import 'package:flutter/material.dart';
import '../services/tdx_service.dart';

class BusPage extends StatefulWidget {
  const BusPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BusPageState createState() => _BusPageState();
}

class _BusPageState extends State<BusPage> {
  final TDXService tdxService = TDXService();

  String city = 'Taipei'; // 可擴充為下拉選單切換縣市

  String? selectedBus;
  String? selectedStart;
  String? selectedEnd;

  List<String> busList = [];
  List<String> stationList = [];

  @override
  void initState() {
    super.initState();
    _loadBusRoutes();
  }

  Future<void> _loadBusRoutes() async {
    try {
      final routes = await tdxService.fetchBusRoutes(city: city);
      print('🚍 獲取到 ${routes.length} 條公車路線');
      print('前幾筆: ${routes.take(10).toList()}');
      setState(() {
        busList = routes;
      });
    } catch (e) {
      print('❌ 載入公車路線失敗: $e');
    }
  }

  Future<void> _loadBusStops(String routeName) async {
    try {
      final stops = await tdxService.fetchRouteStops(city: city, routeName: routeName);
      setState(() {
        stationList = stops;
        selectedStart = null;
        selectedEnd = null;
      });
    } catch (e) {
      print('❌ 載入站牌失敗: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("公車路線選擇", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                /// 選擇公車路線
                DropdownButtonFormField<String>(
                  key: ValueKey('bus_$selectedBus'),
                  decoration: InputDecoration(
                    labelText: "公車路線",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  value: selectedBus,
                  items: busList.map((bus) {
                    return DropdownMenuItem(value: bus, child: Text(bus));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedBus = value;
                      stationList = [];
                      selectedStart = null;
                      selectedEnd = null;
                    });
                    if (value != null) {
                      _loadBusStops(value);
                    }
                  },
                ),

                const SizedBox(height: 20),

                /// 出發地站牌
                DropdownButtonFormField<String>(
                  key: ValueKey('start_$selectedBus'),
                  decoration: InputDecoration(
                    labelText: "出發站",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  value: selectedStart,
                  items: stationList.map((station) {
                    return DropdownMenuItem(value: station, child: Text(station));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStart = value;
                    });
                  },
                ),

                const SizedBox(height: 20),

                /// 目的地站牌
                DropdownButtonFormField<String>(
                  key: ValueKey('end_$selectedBus'),
                  decoration: InputDecoration(
                    labelText: "目的地",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  value: selectedEnd,
                  items: stationList.map((station) {
                    return DropdownMenuItem(value: station, child: Text(station));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedEnd = value;
                    });
                  },
                ),

                const SizedBox(height: 30),

                /// 執行按鈕
                ElevatedButton.icon(
                  onPressed: () {
                    if (selectedBus != null &&
                        selectedStart != null &&
                        selectedEnd != null) {
                      print('追蹤 $selectedBus，從 $selectedStart 到 $selectedEnd');
                      // TODO: 加入追蹤功能或跳轉頁面
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('請選擇完整的路線與站牌')),
                      );
                    }
                  },
                  icon: Icon(Icons.directions_bus),
                  label: Text("開始追蹤公車"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
