import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../services/tdx_service.dart';
import '../models/bus_route.dart';

class BusPage extends StatefulWidget {
  const BusPage({super.key});

  @override
  State<BusPage> createState() => _BusPageState();
}

class _BusPageState extends State<BusPage> {
  final TDXService tdxService = TDXService();
  final Map<int, String> typeMap = {
    11: '市區公車',
    14: '快速公車',
    21: '觀光巴士',
  };

  String city = 'Taipei';
  String keyword = '';
  int? selectedType;
  String? selectedBus;
  String? selectedStart;
  String? selectedEnd;

  List<BusRoute> allRoutes = [];
  List<String> filteredRoutes = [];
  List<String> stationList = [];

  @override
  void initState() {
    super.initState();
    _loadBusRoutes();
  }

  Future<void> _loadBusRoutes() async {
    try {
      final routes = await tdxService.fetchBusRoutesTyped(city: city);
      setState(() {
        allRoutes = routes;
        _applyFilter();
      });
    } catch (e) {
      print('❌ 載入公車路線失敗: $e');
    }
  }

  void _applyFilter() {
    final result = allRoutes.where((route) {
      final matchesType = selectedType == null || route.type == selectedType;
      final matchesKeyword = keyword.isEmpty || route.name.contains(keyword);
      return matchesType && matchesKeyword;
    }).map((e) => e.name).toSet().toList();

    setState(() {
      filteredRoutes = result;
      if (!filteredRoutes.contains(selectedBus)) selectedBus = null;
    });
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
    return Scaffold(
      backgroundColor: Colors.purple[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Card(
            elevation: 8,
            shadowColor: Colors.purple[200],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "公車路線選擇",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // 類型下拉
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: '公車類型',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    value: selectedType,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('全部')),
                      ...typeMap.entries.map((e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value))),
                    ],
                    onChanged: (value) {
                      selectedType = value;
                      _applyFilter();
                    },
                  ),
                  const SizedBox(height: 20),

                  // dropdown_search for 公車選擇
                  DropdownSearch<String>(
                    key: ValueKey('bus_$selectedBus'),
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      showSelectedItems: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: "請輸入路線名稱",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: "公車路線",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    items: filteredRoutes,
                    selectedItem: selectedBus,
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

                  // 出發地
                  DropdownButtonFormField<String>(
                    key: ValueKey('start_$selectedBus'),
                    decoration: InputDecoration(
                      labelText: "出發站",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

                  // 目的地
                  DropdownButtonFormField<String>(
                    key: ValueKey('end_$selectedBus'),
                    decoration: InputDecoration(
                      labelText: "目的地",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

                  // 開始追蹤按鈕
                  ElevatedButton.icon(
                    onPressed: (selectedBus != null &&
                            selectedStart != null &&
                            selectedEnd != null)
                        ? () {
                            print('🚀 追蹤 $selectedBus：從 $selectedStart 到 $selectedEnd');
                            // TODO: 實作跳轉追蹤頁面
                          }
                        : null,
                    icon: const Icon(Icons.search),
                    label: const Text("開始追蹤公車"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
