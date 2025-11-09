import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class ClimaApp extends StatefulWidget {
  const ClimaApp({super.key});

  @override
  State<StatefulWidget> createState() => _ClimaApp();
}

class _ClimaApp extends State<ClimaApp> {
  TextEditingController latitude = TextEditingController();
  TextEditingController longitude = TextEditingController();
  String temperatura = "";
  bool permisoGPS = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("App Clima con GPS")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: obtenerUbicacion,
              child: Text("Obtener Ubicación"),
            ),
            SizedBox(height: 20),
            TextField(
              controller: latitude,
              keyboardType: TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: "Latitud",
                hintText: "Ej: 6.2447 o -6.2447",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: longitude,
              keyboardType: TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: "Longitud",
                hintText: "Ej: -75.5748 o 75.5748",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: obtenerTemperatura,
              child: Text("Consultar Temperatura"),
            ),
            SizedBox(height: 20),
            Text(
              temperatura,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> obtenerUbicacion() async {
    bool servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Activa el GPS o ingresa coordenadas manualmente"),
        ),
      );
      return;
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.deniedForever ||
        permiso == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Permiso de ubicación denegado, ingresa manualmente"),
        ),
      );
      permisoGPS = false;
    } else {
      permisoGPS = true;
      Position pos = await Geolocator.getCurrentPosition();
      setState(() {
        latitude.text = pos.latitude.toString();
        longitude.text = pos.longitude.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ubicación obtenida exitosamente")),
      );
    }
  }

  Future<void> obtenerTemperatura() async {
    double? lat = double.tryParse(latitude.text);
    double? lon = double.tryParse(longitude.text);

    if (lat == null || lon == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Coordenadas inválidas")));
      return;
    }

    var conectividad = await Connectivity().checkConnectivity();
    if (conectividad == ConnectivityResult.none) {
      setState(() {
        temperatura = "Sin conexión. Temperatura: 17 °C";
      });
      return;
    }

    // CORRECCIÓN: Usar temperature_2m en lugar de temperature
    String url =
        "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m";

    try {
      var respuesta = await http.get(Uri.parse(url));
      if (respuesta.statusCode == 200) {
        var data = jsonDecode(respuesta.body);
        // CORRECCIÓN: Acceder a temperature_2m
        double temp = data["current"]["temperature_2m"];
        setState(() {
          temperatura = "Temperatura actual: $temp °C";
        });
      } else {
        setState(() {
          temperatura = "Error al consultar la API";
        });
      }
    } catch (e) {
      setState(() {
        temperatura = "Sin conexión. Temperatura: 17 °C";
      });
    }
  }

  @override
  void dispose() {
    latitude.dispose();
    longitude.dispose();
    super.dispose();
  }
}
