import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  List<WeatherData> weatherData = [];
  String cityName = ''; // City name

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
  }

  Future<void> fetchWeatherData() async {
    // Replace with your OpenWeatherMap API key
    const apiKey = 'ae054c56b006a82fa7280121b0aad26a';
    const cityName = 'London';
    final url = Uri.parse('https://api.openweathermap.org/data/2.5/forecast?q=$cityName&appid=$apiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List<dynamic> list = jsonData['list'];
      final city = jsonData['city']; // Get city data
      final cityName = city['name']; // Extract city name
      setState(() {
        weatherData = list.map((item) => WeatherData.fromJson(item)).toList();
        this.cityName = cityName; // Update city name
      });
    } else {
      // Handle error
      print('Error fetching weather data: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group weather data by day
    final Map<String, List<WeatherData>> groupedData = {};
    for (var weather in weatherData) {
      final dateString = weather.dateTime.substring(0, 10); // Extract date only
      groupedData[dateString] = groupedData[dateString] ?? []; // Initialize list if not exists
      groupedData[dateString]!.add(weather);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(cityName), // City name as title
      ),
      body: ListView.builder(
        itemCount: groupedData.length,
        itemBuilder: (context, index) {
          final date = groupedData.keys.toList()[index];
          final dailyWeather = groupedData[date]!;

          // Calculate daily summary (e.g., min/max temperature)
          double minTemp = double.infinity, maxTemp = double.negativeInfinity;
          for (var weather in dailyWeather) {
            minTemp = min(minTemp, weather.temperature);
            maxTemp = max(maxTemp, weather.temperature);
          }

          return ExpansionTile(
            title: Text(date),
            children: [
              ListView.builder(
                shrinkWrap: true, // Avoid unnecessary scrolling
                itemCount: dailyWeather.length,
                itemBuilder: (context, innerIndex) {
                  final weather = dailyWeather[innerIndex];
                  return ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(weather.dateTime.substring(11, 16)), // Extract time
                        Image.network(
                          weather.imageURL,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Weather: ${weather.weatherDescription}'),
                        Text('Temperature: ${weather.temperature.toStringAsFixed(1)}°C'),
                        Text('Humidity: ${weather.humidity}%'),
                      ],
                    ),
                  );
                },
              ),
              Text("Daily Summary: Temp (Min: ${minTemp.toStringAsFixed(1)}°C, Max: ${maxTemp.toStringAsFixed(1)}°C)"), // Add daily summary
            ],
          );
        },
      ),
    );
  }
}

class WeatherData {
  final String dateTime;
  final String weatherDescription;
  final double temperature;
  final double humidity;
  final String imageURL;

  WeatherData.fromJson(Map<String, dynamic> json)
      : dateTime = json['dt_txt'],
        weatherDescription = json['weather'][0]['description'],
        temperature = (json['main']['temp'] as num).toDouble() - 273.15,
        humidity = (json['main']['humidity'] as num).toDouble(),
        imageURL = _getImageURL(json['weather'][0]['icon']);

  static String _getImageURL(String iconCode) {
    return 'http://openweathermap.org/img/wn/$iconCode.png';
  }
}
