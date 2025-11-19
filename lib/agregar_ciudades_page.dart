import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AgregarCiudadesPage extends StatefulWidget {
  final VoidCallback? onCiudadAgregada;

  const AgregarCiudadesPage({super.key, this.onCiudadAgregada});

  @override
  State<AgregarCiudadesPage> createState() => _AgregarCiudadesPageState();
}

class _AgregarCiudadesPageState extends State<AgregarCiudadesPage> {
  final TextEditingController _cityController = TextEditingController();
  final MapController _mapController = MapController();
  List ciudadData = [];
  double selectedLat = 29.0948207;
  double selectedLon = -110.9692202;
  int? selectedIndex;
  Future<List<Map<String, dynamic>>> ciudadesGuardadas =
      Future<List<Map<String, dynamic>>>.value([]);

  @override
  void initState() {
    super.initState();
    ciudadesGuardadas = _ciudadesGuardadas();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Ciudades')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campo de búsqueda Material
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'Nombre de la ciudad',
                hintText: 'Ej. Hermosillo',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _realizarBusqueda,
                ),
              ),
              onSubmitted: (_) => _realizarBusqueda(),
            ),

            const SizedBox(height: 16),

            // Resultados de búsqueda
            if (ciudadData.isNotEmpty) ...[
              const Text(
                'Resultados:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  itemCount: ciudadData.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final ciudadInfo = ciudadData[index];
                    final isSelected = selectedIndex == index;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      leading: const Icon(Icons.location_on),
                      title: Text(
                        ciudadInfo['display_name'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'Lat: ${ciudadInfo['lat']}, Lon: ${ciudadInfo['lon']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                          _cityController.text = ciudadInfo['display_name'];
                          selectedLat = double.parse(ciudadInfo['lat']);
                          selectedLon = double.parse(ciudadInfo['lon']);
                          _mapController.move(
                            LatLng(selectedLat, selectedLon),
                            10,
                          );
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Botón agregar
            FilledButton.icon(
              onPressed: selectedIndex != null
                  ? () {
                      _agregarCiudad(
                        _cityController.text,
                        selectedLat,
                        selectedLon,
                      );
                    }
                  : null,
              icon: const Icon(Icons.add),
              label: const Text("Agregar ciudad seleccionada"),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Lista de ciudades guardadas
            const Text(
              'Mis Ciudades',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: ciudadesGuardadas,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('No tienes ciudades guardadas.'),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final ciudad = data[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.location_city),
                        title: Text(ciudad['nombre'].toString()),
                        subtitle: Text(
                          'Lat: ${ciudad["latitud"]}, Lon: ${ciudad["longitud"]}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _eliminarCiudad(index, ciudad['nombre'].toString());
                          },
                        ),
                        onTap: () {
                          _mapController.move(
                            LatLng(ciudad["latitud"], ciudad["longitud"]),
                            10,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // Mapa
            const Text(
              'Vista previa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(selectedLat, selectedLon),
                    initialZoom: 10,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.weather_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(selectedLat, selectedLon),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _realizarBusqueda() async {
    final ciudad = _cityController.text;
    if (ciudad.isNotEmpty) {
      final resultados = await _buscarCiudad(ciudad);
      if (!mounted) return;
      setState(() {
        ciudadData = resultados;
      });
    }
  }

  Future<List> _buscarCiudad(String nombreCiudad) async {
    final url =
        'https://nominatim.openstreetmap.org/search?q=$nombreCiudad&format=json&addressdetails=1';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'WeatherApp/1.0 (Flutter Material)',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    return [];
  }

  void _agregarCiudad(String nombre, double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> listaciudadesGuardadas = prefs.getStringList('ciudades') ?? [];

    String ciudadString = json.encode({
      'nombre': nombre,
      'latitud': lat,
      'longitud': lon,
    });

    listaciudadesGuardadas.add(ciudadString);
    await prefs.setStringList('ciudades', listaciudadesGuardadas);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$nombre agregada exitosamente')));

    setState(() {
      ciudadesGuardadas = _ciudadesGuardadas();
      selectedIndex = null;
      _cityController.clear();
      ciudadData = [];
    });

    widget.onCiudadAgregada?.call();
  }

  void _eliminarCiudad(int index, String nombreCiudad) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> listaciudadesGuardadas = prefs.getStringList('ciudades') ?? [];

    if (index >= 0 && index < listaciudadesGuardadas.length) {
      listaciudadesGuardadas.removeAt(index);
      await prefs.setStringList('ciudades', listaciudadesGuardadas);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$nombreCiudad eliminada')));

      setState(() {
        ciudadesGuardadas = _ciudadesGuardadas();
      });

      widget.onCiudadAgregada?.call();
    }
  }

  Future<List<Map<String, dynamic>>> _ciudadesGuardadas() async {
    final prefs = await SharedPreferences.getInstance();
    final ciudadesString = prefs.getStringList('ciudades') ?? [];
    return ciudadesString
        .map((ciudadStr) => json.decode(ciudadStr) as Map<String, dynamic>)
        .toList();
  }
}
