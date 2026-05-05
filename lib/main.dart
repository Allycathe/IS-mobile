// lib/main.dart
import 'package:flutter/material.dart';
import 'mapa_screen.dart';

void main() => runApp(const MiAppMapa());

class MiAppMapa extends StatelessWidget {
  const MiAppMapa({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PantallaInicio(),
    );
  }
}

class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("GATE")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PantallaMapa()),
            );
          },
          child: const Text("Ver mapa"),
        ),
      ),
    );
  }
}
