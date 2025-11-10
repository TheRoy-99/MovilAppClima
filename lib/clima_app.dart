import 'dart:convert';
import 'dart:async';
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
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String latitud = "";
  String longitud = "";
  String temperatura = "";
  bool permisoGPS = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("App Clima con GPS"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              obtenerBotonGPS(),
              SizedBox(height: 20),
              obtenerCampoLatitud(),
              SizedBox(height: 15),
              obtenerCampoLongitud(),
              SizedBox(height: 20),
              obtenerBotonConsultar(),
              SizedBox(height: 30),
              obtenerResultadoTemperatura(),
            ],
          ),
        ),
      ),
    );
  }

  Widget obtenerBotonGPS() {
    return ElevatedButton.icon(
      onPressed: obtenerUbicacion,
      icon: Icon(Icons.location_on),
      label: Text("Obtener Ubicación GPS"),
      style: ElevatedButton.styleFrom(padding: EdgeInsets.all(15)),
    );
  }

  Widget obtenerCampoLatitud() {
    return TextFormField(
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(
        labelText: "Latitud",
        hintText: "Ej: 6.2447 o -6.2447",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.map),
      ),
      initialValue: latitud,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "La latitud es obligatoria";
        }
        double? lat = double.tryParse(value);
        if (lat == null) {
          return "Ingresa un número válido";
        }
        if (lat < -90 || lat > 90) {
          return "La latitud debe estar entre -90 y 90";
        }
        return null;
      },
      onSaved: (value) {
        this.latitud = value!;
      },
    );
  }

  Widget obtenerCampoLongitud() {
    return TextFormField(
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(
        labelText: "Longitud",
        hintText: "Ej: -75.5748 o 75.5748",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.map),
      ),
      initialValue: longitud,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "La longitud es obligatoria";
        }
        double? lon = double.tryParse(value);
        if (lon == null) {
          return "Ingresa un número válido";
        }
        if (lon < -180 || lon > 180) {
          return "La longitud debe estar entre -180 y 180";
        }
        return null;
      },
      onSaved: (value) {
        this.longitud = value!;
      },
    );
  }

  Widget obtenerBotonConsultar() {
    return ElevatedButton.icon(
      onPressed: () {
        if (formKey.currentState!.validate()) {
          formKey.currentState!.save();
          obtenerTemperatura();
        }
      },
      icon: Icon(Icons.cloud),
      label: Text("Consultar Temperatura"),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.all(15),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget obtenerResultadoTemperatura() {
    if (temperatura.isEmpty) {
      return Container();
    }
    return Card(
      color: Colors.blue.shade50,
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          temperatura,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> obtenerUbicacion() async {
    bool servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      mostrarMensaje("Activa el GPS o ingresa coordenadas manualmente");
      return;
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.deniedForever ||
        permiso == LocationPermission.denied) {
      mostrarMensaje("Permiso de ubicación denegado, ingresa manualmente");
      permisoGPS = false;
    } else {
      permisoGPS = true;
      Position pos = await Geolocator.getCurrentPosition();
      setState(() {
        latitud = pos.latitude.toString();
        longitud = pos.longitude.toString();
      });
      mostrarMensaje("Ubicación obtenida exitosamente");
    }
  }

  Future<void> obtenerTemperatura() async {
    double lat = double.parse(latitud);
    double lon = double.parse(longitud);

    // Validación de conectividad
    var conectividad = await Connectivity().checkConnectivity();
    if (conectividad == ConnectivityResult.none) {
      setState(() {
        temperatura =
            "Sin conexión a Internet\nTemperatura: 17 °C\n(Temperatura promedio en el planeta)";
      });
      return;
    }

    // Llamado a la API
    consultarAPIClima(lat, lon);
  }

  Future<void> consultarAPIClima(double lat, double lon) async {
    // URL
    String url =
        "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature";

    try {
      var respuesta = await http.get(Uri.parse(url));

      if (respuesta.statusCode == 200) {
        var data = jsonDecode(respuesta.body);

        // Acceder a "temperature"
        double temp = data["current"]["temperature"];

        setState(() {
          temperatura = "Temperatura actual: $temp °C";
        });
      } else {
        setState(() {
          temperatura =
              "Error al consultar la API (Código: ${respuesta.statusCode})";
        });
      }
    } catch (e) {
      // Si hay error de conexión, retornar el valor por defecto
      setState(() {
        temperatura =
            "Sin conexión a Internet\nTemperatura: 17 °C\n(Temperatura promedio en el planeta)";
      });
    }
  }

  void mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }
}
