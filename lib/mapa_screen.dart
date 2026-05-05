// lib/screens/mapa_screen.dart
import 'package:flutter/material.dart'; // librería base para usar widgets como scaffold, appvar o icon
import 'package:flutter_map/flutter_map.dart'; // librería para mostrar mapas, en este caso, OpenStreetMap
import 'package:latlong2/latlong.dart'; // librería para manejar coordenadas geográficas (latitud y longitud)
import 'package:http/http.dart'
    as http; // librería para hacer peticiones HTTP, en este caso para llamar a la Overpass API y obtener datos de supermercados cercanos
import 'package:geolocator/geolocator.dart'; // librería para acceder al GPS del dispositivo
import 'dart:convert';
import 'dart:async';

class PantallaMapa extends StatefulWidget {
  //es statefulWidget (dinámica) porque la pantalla cambia con el tiempo
  const PantallaMapa({super.key});

  @override
  State<PantallaMapa> createState() =>
      _PantallaMapaState(); // actualiza el widget especifíco que se va a mostrar, como estará en constante cambio
}

class _PantallaMapaState extends State<PantallaMapa> {
  LatLng _ubicacionUsuario = const LatLng(-33.4489,
      -70.6693); // Ubicación por defecto (Santiago) en caso de que no se pueda obtener la ubicación real del usuario

  List<Map<String, dynamic>> _supermercados =
      []; // una lista que se llenará con los supermercados que traiga la API, cada supermercado es un MAP(nombre, latitud y longitud)

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  // Inicializa ubicación y supermercados
  Future<void> _inicializar() async {
    //primero obtiene la ubicación del usuario y luego carga los supermercados cercanos, mientras tanto muestra un indicador de carga
    await _obtenerUbicacion();
    await _cargarSupermercados();
    setState(() => _cargando = false);
  }

  // Obtiene la ubicación real del usuario
  Future<void> _obtenerUbicacion() async {
    try {
      bool servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivo)
        return; // verifica que el GPS está encendido, si está apagado, sale el método return y usa santiago, SI QUEREMOS QUE SI O SI ESTE ACTIVADO, ACÁ SE MUESTRA

      LocationPermission permiso = await Geolocator
          .checkPermission(); // verifica si el usuario dio permiso para acceder a su ubicación, si no dio permiso, se lo solicita, si el usuario sigue negando el permiso, sale el método return y usa santiago
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) return;
      }

      final posicion = await Geolocator
          .getCurrentPosition(); // obtiene la posición real de GPS y actualiza el _unibacionUsuario
      setState(() {
        //el setState redibuja la pantalla con el nuevo valor
        _ubicacionUsuario = LatLng(posicion.latitude, posicion.longitude);
      });
    } catch (e) {
      // Si estás en Linux/desktop, geolocator no funciona
      // Usa la ubicación por defecto (Santiago) y continúa
      debugPrint(
          'GPS no disponible en esta plataforma, usando ubicación por defecto');
    }
  }

  Future<void> _cargarSupermercados() async {
    final lat = _ubicacionUsuario.latitude;
    final lng = _ubicacionUsuario.longitude;

    final query =
        '[out:json][timeout:25];node["shop"="supermarket"](around:2000,$lat,$lng);out body;'; // se puede cambiar el around para buscar en un radio más grande o más pequeños cercanos a la ubicación del usuario

    // Lista de servidores alternativos por si uno falla
    final servidores = [
      'https://overpass.kumi.systems/api/interpreter',
      'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
      'https://overpass-api.de/api/interpreter',
    ];

    for (final servidor in servidores) {
      try {
        debugPrint('Intentando con: $servidor');

        final uri = Uri.parse('$servidor?data=${Uri.encodeComponent(query)}');
        final response =
            await http.get(uri).timeout(const Duration(seconds: 20));

        debugPrint('Status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final elementos = data['elements'] as List;
          debugPrint('Supermercados encontrados: ${elementos.length}');

          setState(() {
            _supermercados = elementos
                .map((e) => {
                      'nombre': e['tags']?['name'] ?? 'Supermercado',
                      'lat': e['lat'],
                      'lng': e['lon'],
                    })
                .toList();
          });

          return; // Si funcionó, salimos del loop
        }
      } catch (e) {
        debugPrint('Error con $servidor: $e');
      }
    }

    // Si todos los servidores fallan, usa datos de prueba
    debugPrint('Todos los servidores fallaron, usando datos de prueba');
    setState(() {
      _supermercados = [
        {'nombre': 'Lider (demo)', 'lat': lat - 0.005, 'lng': lng + 0.005},
        {'nombre': 'Unimarc (demo)', 'lat': lat + 0.003, 'lng': lng - 0.003},
        {
          'nombre': 'Santa Isabel (demo)',
          'lat': lat - 0.002,
          'lng': lng - 0.006
        },
      ];
    });
  }

  // ── Muestra reportes al tocar un supermercado ────────
  void _mostrarReportes(String nombreSupermercado) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              nombreSupermercado,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const Text("Reporte 1: Sospechoso en pasillo 3 - hace 10 min"),
            const SizedBox(height: 8),
            const Text("Reporte 2: Persona con bolso grande - hace 25 min"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar"),
            )
          ],
        ),
      ),
    );
  }

  //UI principal
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mapa de Alertas")),
      body: _cargando // para mostrar un indicador de carga
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              // configura el mapa, dónde empieza y cuánto zoom tiene
              options: MapOptions(
                initialCenter: _ubicacionUsuario,
                initialZoom: 15.0,
              ),
              children: [
                // Capa 1: Mapa minimalista (solo calles)
                TileLayer(
                  // descarga y muestra las imágenes del mapa desde CartoDB, un proveedor de mapas gratuito, con un estilo minimalista llamado "light_all"
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.gate.app',
                ),

                // Capa 2: Marcadores de supermercados
                MarkerLayer(
                  markers: _supermercados.map((super_mercado) {
                    return Marker(
                      point: LatLng(super_mercado['lat'], super_mercado['lng']),
                      width: 60,
                      height: 60,
                      child: GestureDetector(
                        onTap: () => _mostrarReportes(super_mercado['nombre']),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.store, // ícono de tienda
                              color: Colors.red,
                              size: 30,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              color: Colors.white,
                              child: Text(
                                super_mercado['nombre'],
                                style: const TextStyle(fontSize: 9),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
// por cada supermercado de la lista de supermercados, se crea un marcador en el mapa con su ubicación y nombre, al tocar el marcador se muestra un reporte de alertas para ese supermercado, el ícono es una tienda roja y el nombre del supermercado aparece debajo del ícono en un recuadro blanco, si el nombre es muy largo, se corta con puntos suspensivos
// .map() recorre la lista y el .toList() convierte el resultado en una lista de marcadores para el mapa
                // Capa 3: Marcador del usuario
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _ubicacionUsuario,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 30,
                      ),
                    )
                  ],
                ),
              ],
            ),
    );
  }
}
