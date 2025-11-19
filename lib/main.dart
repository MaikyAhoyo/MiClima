import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/creditos.dart';
import 'package:weather_app/clima_carousel_view.dart';
import 'theme_provider.dart';
import 'agregar_ciudades_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint(
      "No se encontró archivo .env, usando valores por defecto o vacíos.",
    );
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Weather App',
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      themeMode: themeProvider.themeMode,
      home: const MainWindow(),
    );
  }
}

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  int _pageIndex = 0;
  bool _isLoading = true;

  Future<List<Map<String, dynamic>>> ciudadesGuardadas =
      Future<List<Map<String, dynamic>>>.value([]);

  static String get apiTokenUrl =>
      dotenv.env['meteomatics_api_url'] ??
      'https://login.meteomatics.com/api/v1/token';
  static String get username => dotenv.env['meteomatics_user'] ?? '';
  static String get password => dotenv.env['meteomatics_pwd'] ?? '';

  String apiToken = '';

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    debugPrint('=== 🚀 Iniciando aplicación Material ===');
    await obtenToken();
    final ciudades = await _ciudadesGuardadas(); // Carga segura inicial
    if (mounted) {
      setState(() {
        ciudadesGuardadas = Future.value(ciudades);
      });
    }

    if (ciudades.isNotEmpty && apiToken.isNotEmpty) {
      await _actualizaClima(ciudades[0]);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper para leer siempre fresco del disco
  Future<List<Map<String, dynamic>>> _ciudadesGuardadas() async {
    final prefs = await SharedPreferences.getInstance();
    final ciudadesString = prefs.getStringList('ciudades') ?? [];
    return ciudadesString
        .map((ciudad) => json.decode(ciudad) as Map<String, dynamic>)
        .toList();
  }

  Future<void> obtenToken() async {
    if (apiToken.isNotEmpty) return;
    if (username.isEmpty || password.isEmpty) {
      debugPrint('⚠ Falta usuario/password en .env');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(apiTokenUrl),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$username:$password'))}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        apiToken = data['access_token'];
      }
    } catch (e) {
      debugPrint('❌ Error token: $e');
    }
  }

  Future<void> _actualizaClima(
    Map<String, dynamic> ciudad, {
    bool forzarActualizacion = false,
  }) async {
    if (apiToken.isEmpty) return;

    bool actualizar = forzarActualizacion;
    double latitud = ciudad['latitud'] ?? 0.0;
    double longitud = ciudad['longitud'] ?? 0.0;

    if (!forzarActualizacion) {
      if (ciudad['ultima_actualizacion'] == null) {
        actualizar = true;
      } else {
        DateTime ultimaActualizacionDT = DateTime.parse(
          ciudad['ultima_actualizacion'],
        );
        DateTime ahoraZ = DateTime.now().toUtc();
        if (ahoraZ.difference(ultimaActualizacionDT).inMinutes >= 60) {
          actualizar = true;
        }
      }
    }

    if (!actualizar) return;

    String hora_actualZ = DateTime.now().toUtc().toIso8601String();
    String url =
        'https://api.meteomatics.com/$hora_actualZ/t_2m:C,wind_speed_10m:ms,weather_symbol_1h:idx/$latitud,$longitud/json?access_token=$apiToken';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final climaData = json.decode(response.body);
        final data = climaData['data'];

        // Actualizamos los datos en el objeto temporal
        ciudad['temperatura'] = data[0]['coordinates'][0]['dates'][0]['value'];
        ciudad['velocidad_viento'] =
            data[1]['coordinates'][0]['dates'][0]['value'];
        ciudad['simbolo_clima'] =
            data[2]['coordinates'][0]['dates'][0]['value'];
        ciudad['ultima_actualizacion'] =
            data[0]['coordinates'][0]['dates'][0]['date'];

        // === CORRECCIÓN DE PERSISTENCIA AQUÍ ===
        final prefs = await SharedPreferences.getInstance();

        // 1. Leemos la lista REAL del disco (para no perder ciudades nuevas)
        final listaDisco = prefs.getStringList('ciudades') ?? [];

        // 2. Actualizamos SOLO la ciudad correspondiente en esa lista
        final listaActualizada = listaDisco.map((ciudadStr) {
          final c = json.decode(ciudadStr) as Map<String, dynamic>;
          if (c['nombre'] == ciudad['nombre']) {
            // Si es la ciudad que acabamos de actualizar, guardamos los nuevos datos
            return json.encode(ciudad);
          }
          return ciudadStr; // Si no, dejamos la ciudad como estaba
        }).toList();

        // 3. Guardamos la lista completa y correcta
        await prefs.setStringList('ciudades', listaActualizada);

        // 4. Actualizamos la UI
        if (mounted) {
          setState(() {
            // Recargamos la vista desde lo que acabamos de guardar
            ciudadesGuardadas = Future.value(
              listaActualizada
                  .map((s) => json.decode(s) as Map<String, dynamic>)
                  .toList(),
            );
          });
        }
        debugPrint('✅ Clima actualizado y guardado para ${ciudad['nombre']}');
      }
    } catch (e) {
      debugPrint('❌ Error actualizando clima: $e');
    }
  }

  Future<void> _refreshCiudades() async {
    // Simplemente recargamos del disco
    final ciudadesActualizadas = await _ciudadesGuardadas();
    if (mounted) {
      setState(() {
        ciudadesGuardadas = Future.value(ciudadesActualizadas);
      });
    }
    // Si hay una ciudad nueva sin datos, la actualizamos
    if (ciudadesActualizadas.isNotEmpty) {
      final ultimaCiudad = ciudadesActualizadas.last;
      if (ultimaCiudad['temperatura'] == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _actualizaClima(ultimaCiudad);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: IndexedStack(
        index: _pageIndex,
        children: [
          _buildClimaPage(),
          AgregarCiudadesPage(onCiudadAgregada: _refreshCiudades),
          const CreditosPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _pageIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud),
            label: 'Clima',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_location_alt_outlined),
            selectedIcon: Icon(Icons.add_location_alt),
            label: 'Ciudades',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'Créditos',
          ),
        ],
      ),
    );
  }

  Widget _buildClimaPage() {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Clima'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar datos',
            onPressed: () async {
              final ciudades = await ciudadesGuardadas;
              if (ciudades.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Actualizando clima...')),
                );
                // Usamos el índice del carrusel si tuviéramos acceso,
                // por defecto actualizamos la primera o podríamos actualizar todas.
                // Aquí actualizamos la primera como ejemplo seguro.
                await _actualizaClima(ciudades[0], forzarActualizacion: true);
              }
            },
          ),
          IconButton(
            icon: Icon(
              Provider.of<ThemeProvider>(context).isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Cambiar tema',
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: ClimaCarouselView(
        ciudadesGuardadas: ciudadesGuardadas,
        actualizaClima: _actualizaClima,
      ),
    );
  }
}