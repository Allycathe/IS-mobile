// lib/mapa_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PantallaMapa extends StatelessWidget {
  const PantallaMapa({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mapa de Alertas")),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(-33.4489, -70.6693),
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.gate.app',
          ),
        ],
      ),
    );
  }
}
