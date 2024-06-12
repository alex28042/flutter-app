import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_project/screens/main_screen.dart';
import 'package:flutter_project/screens/second_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<Position>? _positionStreamSubscription;
  final logger = Logger();
  final _uidController = TextEditingController();
  final _tokenController = TextEditingController();
  String? _uid;
  String? _token;
  DatabaseHelper db = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String? uid = prefs.getString('uid');
    String? token = prefs.getString('token');
    if (uid == null || token == null) {
      _showInputDialog();
    } else {
      setState(() {
        _uid = uid;
        _token = token;
      });
      logger.d("UID: $uid, Token: $token");
    }
  }

  Future<void> _showInputDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter UID and Token'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _uidController,
                  decoration: const InputDecoration(hintText: "UID"),
                ),
                TextField(
                  controller: _tokenController,
                  decoration: const InputDecoration(hintText: "Token"),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('uid', _uidController.text);
                await prefs.setString('token', _tokenController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HelloWorldFt for MAD'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SecondScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_uid != null && _token != null)
              Text('UID: $_uid, Token: $_token'),
            const Text('Welcome to the Home Screen!'),
            Switch(
              value: _positionStreamSubscription != null,
              onChanged: (value) {
                setState(() {
                  if (value) {
                    startTracking();
                  } else {
                    stopTracking();
                  }
                });
              },
            ),
            ElevatedButton(
              onPressed: () {
                insertCoordinatesToDatabase();

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: Colors.greenAccent, // Color de fondo verde
                      title: Text('Successful Insertion', style: TextStyle(color: Colors.white)),
                      content: Text('Coordinates have been inserted.', style: TextStyle(color: Colors.white),),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Cerrar el diálogo
                          },
                          child: Text('Cerrar'),
                        ),
                      ],
                    );
                  },
                );
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.deepPurpleAccent),
              ),
              child: const Text(
                'Insert Madrid Coordinates',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void startTracking() async {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high, // Adjust the accuracy as needed
      distanceFilter: 10, // Distance in meters before an update is triggered
    );
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
        writePositionToFile(position);
      },
    );
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
        db.insertCoordinate(position);
      },
    );
  }
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
  Future<void> writePositionToFile(Position position) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/gps_coordinates.csv');
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await file.writeAsString('${timestamp};${position.latitude};${position.longitude}\n', mode: FileMode.append);
  }
  @override
  void dispose() {
    _uidController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> insertCoordinatesToDatabase() async {
    // Insert 5 coordinates of the center of Madrid into the database
    final madridCoordinates = [
      const LatLng(40.4168, -3.7038), // Puerta del Sol
      const LatLng(40.4155, -3.7074), // Plaza Mayor
      const LatLng(40.4154, -3.6842), // Retiro Park
      const LatLng(40.4194, -3.6936), // Prado Museum
      const LatLng(40.4190, -3.6884), // Atocha Station
    ];

    for (final coordinate in madridCoordinates) {
      final position = Position(
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
        timestamp: DateTime.now(),
        accuracy: 0, // Add appropriate values for accuracy, altitude, etc. if available
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      db.insertCoordinate(position);
    }
  }
}
