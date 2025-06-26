class BusRoute {
  final String routeNameZh;

  BusRoute({required this.routeNameZh});

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      routeNameZh: json['RouteName']?['Zh_tw'] ?? '未知路線',
    );
  }
}
