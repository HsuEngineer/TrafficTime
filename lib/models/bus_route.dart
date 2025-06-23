class BusRoute {
  final String name;
  final int type;

  BusRoute({required this.name, required this.type});

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      name: json['RouteName']['Zh_tw'],
      type: json['BusRouteType'],
    );
  }
}
