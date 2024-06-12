import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';

class ThirdScreen extends StatefulWidget {
  @override
  _ThirdScreenState createState() => _ThirdScreenState();
}


class _ThirdScreenState extends State<ThirdScreen> {
  List<List<String>> _coordinates = [];
  List<List<String>> _dbCoordinates = []; // For coordinates from the database
  @override
  void initState() {
    super.initState();
    _loadCoordinates();
    _loadDbCoordinates();
  }
  Future<void> _loadCoordinates() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/gps_coordinates.csv');
    List<String> lines = await file.readAsLines();
    setState(() {
      _coordinates = lines.map((line) => line.split(';')).toList();
    });
  }
  Future<void> _loadDbCoordinates() async {
    List<Map<String, dynamic>> dbCoords = await DatabaseHelper.instance.getCoordinates(); // Corrected
    setState(() {
      _dbCoordinates = dbCoords.map((c) => [
        c['timestamp'].toString(), // Corrected
        c['latitude'].toString(), // Corrected
        c['longitude'].toString() // Corrected
      ]).toList();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Second Screen'),
      ),
      body: ListView.builder(
        itemCount: _dbCoordinates.length, // Solo usamos las coordenadas de la base de datos
        itemBuilder: (context, index) {
          var coord = _dbCoordinates[index];
          return ListTile(
            title: Text('DB Timestamp: ${coord[0]}', style: TextStyle(color: Colors.blue)),
            subtitle: Text('Latitude: ${coord[1]}, Longitude: ${coord[2]}', style: TextStyle(color: Colors.blue)),
          );
        },
      ),
    );
  }

}