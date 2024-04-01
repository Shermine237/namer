import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const apiKey = '3b8801a04a269716ee8c11e1f0b021e6';

class Meteo extends StatefulWidget {
  const Meteo({super.key});

  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<Meteo> {
  final _formKey = GlobalKey<FormState>();

  String _cityName = '';
  WeatherData? _weatherData;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meteo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Ville',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Entrez le nom d'une Ville";
                  }
                  return null;
                },
                onSaved: (value) {
                  _cityName = value!;
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _fetchWeatherData();
                  }
                },
                child: const Text('Afficher Meteo'),
              ),
              const SizedBox(height: 16.0),
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_weatherData != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ville: ${_weatherData!.cityName}'),
                    Text('Temperature: ${_weatherData!.temperature}°C'),
                    Text('Meteo: ${_weatherData!.weatherDescription}'),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      _isLoading = true;
    });

    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$_cityName&appid=$apiKey&units=metric';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final weatherData = WeatherData.fromJson(jsonData);
        setState(() {
          _weatherData = weatherData;
        });
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erreur'),
            content: const Text("Échec de l'extraction des données météorologiques"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (error) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erreur'),
          content: const Text("Échec de l'extraction des données météorologiques"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }
}

class WeatherData {
  final String cityName;
  final double temperature;
  final String weatherDescription;

  WeatherData({
    required this.cityName,
    required this.temperature,
    required this.weatherDescription,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final cityName = json['name'];
    final main = json['main'];
    final temperature = main['temp'];
    final weather = json['weather'][0];
    final weatherDescription = weather['description'];

    return WeatherData(
      cityName: cityName,
      temperature: temperature.toDouble(),
      weatherDescription: weatherDescription,
    );
  }
}
