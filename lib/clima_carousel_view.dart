import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:intl/intl.dart';

class ClimaCarouselView extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> ciudadesGuardadas;
  final Function(Map<String, dynamic>) actualizaClima;

  const ClimaCarouselView({
    Key? key,
    required this.ciudadesGuardadas,
    required this.actualizaClima,
  }) : super(key: key);

  @override
  State<ClimaCarouselView> createState() => _ClimaCarouselViewState();
}

class _ClimaCarouselViewState extends State<ClimaCarouselView> {
  int _currentIndex = 0;

  IconData _obtenerIconoClima(int simbolo) {
    switch (simbolo) {
      case 1:
        return WeatherIcons.day_sunny;
      case 2:
        return WeatherIcons.day_sunny_overcast;
      case 3:
        return WeatherIcons.day_cloudy;
      case 4:
        return WeatherIcons.cloudy;
      case 5:
        return WeatherIcons.day_rain;
      case 6:
        return WeatherIcons.day_rain_mix;
      case 7:
        return WeatherIcons.day_snow;
      case 8:
        return WeatherIcons.day_showers;
      case 9:
        return WeatherIcons.day_snow;
      case 10:
        return WeatherIcons.day_sleet;
      case 11:
        return WeatherIcons.day_fog;
      case 12:
        return WeatherIcons.fog;
      case 13:
        return WeatherIcons.day_hail;
      case 14:
        return WeatherIcons.day_thunderstorm;
      case 15:
        return WeatherIcons.day_sprinkle;
      case 16:
        return WeatherIcons.sandstorm;
      case 101:
        return WeatherIcons.night_clear;
      case 102:
        return WeatherIcons.night_alt_partly_cloudy;
      case 103:
        return WeatherIcons.night_alt_cloudy;
      case 104:
        return WeatherIcons.night_cloudy;
      case 105:
        return WeatherIcons.night_rain;
      case 106:
        return WeatherIcons.night_rain_mix;
      case 107:
        return WeatherIcons.night_snow;
      case 108:
        return WeatherIcons.night_showers;
      case 109:
        return WeatherIcons.night_alt_snow;
      case 110:
        return WeatherIcons.night_alt_sleet;
      case 111:
        return WeatherIcons.night_fog;
      case 112:
        return WeatherIcons.night_fog;
      case 113:
        return WeatherIcons.night_hail;
      case 114:
        return WeatherIcons.night_thunderstorm;
      case 115:
        return WeatherIcons.night_sprinkle;
      case 116:
        return WeatherIcons.sandstorm;
      default:
        return WeatherIcons.na;
    }
  }

  String _obtenerDescripcionClima(int simbolo) {
    switch (simbolo) {
      case 0:
        return 'Sin datos';
      case 1:
        return 'Despejado';
      case 2:
        return 'Nubes ligeras';
      case 3:
        return 'Parcialmente nublado';
      case 4:
        return 'Nublado';
      case 5:
        return 'Lluvia';
      case 6:
        return 'Lluvia y nieve';
      case 7:
        return 'Nieve';
      case 8:
        return 'Chubascos';
      case 9:
        return 'Chubascos de nieve';
      case 10:
        return 'Aguanieve';
      case 11:
        return 'Niebla ligera';
      case 12:
        return 'Niebla densa';
      case 13:
        return 'Lluvia helada';
      case 14:
        return 'Tormenta eléctrica';
      case 15:
        return 'Llovizna';
      case 16:
        return 'Tormenta de arena';
      case 101:
        return 'Despejado';
      case 102:
        return 'Nubes ligeras';
      case 103:
        return 'Parcialmente nublado';
      case 104:
        return 'Nublado';
      case 105:
        return 'Lluvia';
      case 106:
        return 'Lluvia y nieve';
      case 107:
        return 'Nieve';
      case 108:
        return 'Chubascos';
      case 109:
        return 'Chubascos de nieve';
      case 110:
        return 'Aguanieve';
      case 111:
        return 'Niebla ligera';
      case 112:
        return 'Niebla densa';
      case 113:
        return 'Lluvia helada';
      case 114:
        return 'Tormenta eléctrica';
      case 115:
        return 'Llovizna';
      case 116:
        return 'Tormenta de arena';
      default:
        return 'Desconocido';
    }
  }

  String _formatearHora(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '--:--';
    try {
      final fecha = DateTime.parse(timestamp);
      return DateFormat('HH:mm').format(fecha.toLocal());
    } catch (e) {
      return '--:--';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Detectamos el tema actual
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Color de fondo base (detrás del carrusel) para evitar parpadeos
    final baseColor = isDark ? const Color(0xFF1C1B33) : Colors.blue.shade300;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.ciudadesGuardadas,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _LoadingView(isDark: isDark);
        }
        if (snapshot.hasError) {
          return _ErrorView(error: snapshot.error.toString(), isDark: isDark);
        }

        final ciudades = snapshot.data ?? [];

        if (ciudades.isEmpty) {
          return _EmptyView(isDark: isDark);
        }

        return Stack(
          children: [
            // Fondo base
            Container(color: baseColor),

            PageView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: ciudades.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                widget.actualizaClima(ciudades[index]);
              },
              itemBuilder: (context, index) {
                return _ModernWeatherCard(
                  ciudad: ciudades[index],
                  icono: _obtenerIconoClima(
                    ciudades[index]['simbolo_clima'] ?? 0,
                  ),
                  descripcion: _obtenerDescripcionClima(
                    ciudades[index]['simbolo_clima'] ?? 0,
                  ),
                  horaActualizacion: _formatearHora(
                    ciudades[index]['ultima_actualizacion'],
                  ),
                  isDark: isDark, // Pasamos el modo a la tarjeta
                );
              },
            ),

            // Indicador de páginas (dots)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  ciudades.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ModernWeatherCard extends StatelessWidget {
  final Map<String, dynamic> ciudad;
  final IconData icono;
  final String descripcion;
  final String horaActualizacion;
  final bool isDark;

  const _ModernWeatherCard({
    required this.ciudad,
    required this.icono,
    required this.descripcion,
    required this.horaActualizacion,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final double tempVal = ciudad['temperatura'] ?? 0.0;
    final String tempStr = tempVal.toStringAsFixed(0);
    final String vientoStr = (ciudad['velocidad_viento'] ?? 0.0)
        .toStringAsFixed(1);
    final String nombreCiudad = ciudad['nombre'] ?? 'Desconocida';

    // === DEFINICIÓN DE COLORES SEGÚN TEMA ===

    // Gradiente Oscuro (Noche)
    final darkGradient = const [
      Color(0xFF2E335A), // Azul/Violeta Oscuro
      Color(0xFF1C1B33), // Negro Azulado
    ];

    // Gradiente Claro (Día - Cielo Azul)
    final lightGradient = [
      const Color(0xFF4FACFE), // Azul Cielo Brillante
      const Color(0xFF00F2FE), // Cyan Claro
    ];

    // Colores de los círculos decorativos (Orbes)
    final orb1Color = isDark
        ? const Color(0xFF612FAB).withOpacity(0.4) // Violeta en noche
        : Colors.white.withOpacity(0.3); // Blanco en día

    final orb2Color = isDark
        ? const Color(0xFF48319D).withOpacity(0.4) // Índigo en noche
        : Colors.blue.shade100.withOpacity(0.3); // Azul pálido en día

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark ? darkGradient : lightGradient,
        ),
      ),
      child: Stack(
        children: [
          // Orbe superior izquierda
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: orb1Color,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          // Orbe inferior derecha
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: orb2Color,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Contenido
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ciudad
                    Text(
                      nombreCiudad,
                      style: const TextStyle(
                        color:
                            Colors.white, // Blanco se ve bien en ambos cielos
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Botón de actualización
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Actualizado $horaActualizacion',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Icono
                    BoxedIcon(icono, size: 110, color: Colors.white),

                    // Temperatura
                    Text(
                      '$tempStr°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 100,
                        fontWeight: FontWeight.w200,
                        height: 1.0,
                      ),
                    ),

                    Text(
                      descripcion,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 50),

                    // Detalles
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _GlassBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _DetailItem(
                              icon: WeatherIcons.strong_wind,
                              value: '$vientoStr m/s',
                              label: 'Viento',
                            ),
                            _DetailItem(
                              icon: WeatherIcons.raindrop,
                              value: 'N/A',
                              label: 'Humedad',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBox extends StatelessWidget {
  final Widget child;
  const _GlassBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), // Un poco más visible
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _DetailItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BoxedIcon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  final bool isDark;
  const _LoadingView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF1C1B33) : Colors.blue.shade300,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool isDark;
  const _EmptyView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF1C1B33) : Colors.blue.shade300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_city,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Agrega una ciudad para comenzar',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final bool isDark;
  const _ErrorView({required this.error, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF1C1B33) : Colors.blue.shade300,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Error: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
