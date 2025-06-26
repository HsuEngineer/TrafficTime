import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../services/tdx_service.dart';
import '../services/location_service.dart';
import '../models/bus_route.dart';

class BusPage extends StatefulWidget {
  const BusPage({super.key});

  @override
  State<BusPage> createState() => _BusPageState();
}

class _BusPageState extends State<BusPage> {
  final TDXService _tdxService = TDXService();

  String? selectedCity;
  BusRoute? selectedBus;
  String? selectedStart;
  String? selectedEnd;

  List<BusRoute> busList = [];
  List<String> stopList = [];

  final Map<String, String> cityMap = {
    '台北市': 'Taipei',
    '新北市': 'NewTaipei',
    '桃園市': 'Taoyuan',
    '台中市': 'Taichung',
    '台南市': 'Tainan',
    '高雄市': 'Kaohsiung',
    '基隆市': 'Keelung',
    '新竹市': 'Hsinchu',
    '嘉義市': 'Chiayi',
  };

  @override
  void initState() {
    super.initState();
    _initLocationAndLoadRoutes();
  }

  Future<void> _initLocationAndLoadRoutes() async {
    try {
      final cityZh = await LocationService.getCurrentCity();
      final cityEn = cityMap[cityZh] ?? 'Taipei';

      setState(() {
        selectedCity = cityEn;
      });

      await _loadBusRoutes();
    } catch (e) {
      print('❌ 自動取得縣市失敗: $e');
    }
  }

  Future<void> _loadBusRoutes() async {
    if (selectedCity == null) return;
    try {
      final routes = await _tdxService.fetchBusRoutesTyped(city: selectedCity!);
      routes.sort((a, b) => _naturalCompare(a.routeNameZh, b.routeNameZh));

      setState(() {
        busList = [...routes];
        selectedBus = null;
        stopList = [];
        selectedStart = null;
        selectedEnd = null;
      });
    } catch (e) {
      print('❌ 載入公車路線失敗: $e');
    }
  }

  Future<void> _loadStopsForSelectedBus() async {
    if (selectedCity == null || selectedBus == null) return;

    try {
      final stops = await _tdxService.fetchRouteStops(
        city: selectedCity!,
        routeName: selectedBus!.routeNameZh,
      );
      setState(() {
        stopList = stops;
        selectedStart = null;
        selectedEnd = null;
      });
    } catch (e) {
      print('❌ 載入站牌失敗: $e');
    }
  }

  int _naturalCompare(String a, String b) {
    final reg = RegExp(r'(\d+)|(\D+)');
    final aMatches = reg.allMatches(a);
    final bMatches = reg.allMatches(b);
    final len = aMatches.length < bMatches.length ? aMatches.length : bMatches.length;

    for (int i = 0; i < len; i++) {
      final aMatch = aMatches.elementAt(i).group(0)!;
      final bMatch = bMatches.elementAt(i).group(0)!;

      final aNum = int.tryParse(aMatch);
      final bNum = int.tryParse(bMatch);

      if (aNum != null && bNum != null) {
        if (aNum != bNum) return aNum.compareTo(bNum);
      } else {
        final cmp = aMatch.compareTo(bMatch);
        if (cmp != 0) return cmp;
      }
    }

    return a.length.compareTo(b.length);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('縣市'),
        DropdownButton<String>(
          key: const ValueKey('cityDropdown'),
          value: selectedCity,
          isExpanded: true,
          onChanged: (value) {
            setState(() {
              selectedCity = value!;
            });
            _loadBusRoutes();
          },
          items: cityMap.entries
              .map((entry) => DropdownMenuItem(
                    value: entry.value,
                    child: Text(entry.key),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),

        const Text('選擇公車路線'),
        DropdownSearch<BusRoute>(
          key: const ValueKey('busDropdownSearch'),
          selectedItem: selectedBus,
          items: busList,
          itemAsString: (route) => route.routeNameZh,
          dropdownDecoratorProps: const DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: '請輸入或選擇路線',
              border: OutlineInputBorder(),
            ),
          ),
          onChanged: (route) {
            setState(() {
              selectedBus = route;
            });
            _loadStopsForSelectedBus();
          },
          popupProps: const PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(hintText: '輸入車號（如932）'),
            ),
          ),
          compareFn: (a, b) => a.routeNameZh == b.routeNameZh,
        ),
        const SizedBox(height: 12),

        const Text('起點站'),
        DropdownButton<String>(
          key: const ValueKey('startDropdown'),
          value: selectedStart,
          isExpanded: true,
          hint: const Text('請選擇起點'),
          onChanged: (value) {
            setState(() {
              selectedStart = value;
            });
          },
          items: stopList.map((stop) {
            return DropdownMenuItem(value: stop, child: Text(stop));
          }).toList(),
        ),
        const SizedBox(height: 12),

        const Text('終點站'),
        DropdownButton<String>(
          key: const ValueKey('endDropdown'),
          value: selectedEnd,
          isExpanded: true,
          hint: const Text('請選擇終點'),
          onChanged: (value) {
            setState(() {
              selectedEnd = value;
            });
          },
          items: stopList.map((stop) {
            return DropdownMenuItem(value: stop, child: Text(stop));
          }).toList(),
        ),
      ],
    );
  }
}
