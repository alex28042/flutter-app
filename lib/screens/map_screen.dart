import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../database/database_helper.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Marker> markers = [];
  List<LatLng> routeCoordinates = [];

  @override
  void initState() {
    super.initState();
    loadMarkers();
    loadRouteCoordinates();
  }

  Future<void> loadMarkers() async {
    final dbMarkers = await DatabaseHelper.instance.getCoordinates();
    List<Marker> loadedMarkers = dbMarkers.map((record) {
      return Marker(
        point: LatLng(record['latitude'], record['longitude']),
        width: 80,
        height: 80,
        child: const Icon(
          Icons.location_pin,
          size: 60,
          color: Colors.red,
        ),
      );
    }).toList();
    setState(() {
      markers = loadedMarkers;
    });
  }

  void loadRouteCoordinates() {
    routeCoordinates = [
      LatLng(40.4168, -3.7038), // Puerta del Sol
      LatLng(40.4155, -3.7074), // Plaza Mayor
      LatLng(40.4154, -3.6842), // Retiro Park
      LatLng(40.4194, -3.6936), // Prado Museum
      LatLng(40.4190, -3.6884), // Atocha Station
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map View')),
      body: content(),
    );
  }

  Widget content() {
    return FlutterMap(
      options: const MapOptions(
          initialCenter: LatLng(40.4168, -3.7038), // Coordinates for the center of Madrid
          initialZoom: 15,
          interactionOptions: InteractionOptions(flags: InteractiveFlag.all)),
      children: [
        openStreetMapTileLayer,
        MarkerLayer(markers: markers),
        PolylineLayer(
          polylines: [
            Polyline(
              points: routeCoordinates,
              color: Colors.pink,
              strokeWidth: 8.0,
            ),
          ],
        ),
      ],
    );
  }

  TileLayer get openStreetMapTileLayer => TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'dev.fleaflet.flutter_map.example',
  );
}