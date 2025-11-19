import 'package:flutter/material.dart';

class CreditosPage extends StatelessWidget {
  const CreditosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créditos y Acerca de')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSeccion(
              context,
              titulo: 'Servicios Utilizados',
              children: [
                _buildItemLista(
                  icono: Icons.cloud,
                  titulo: 'Meteomatics',
                  subtitulo: 'Datos meteorológicos precisos y confiables.',
                ),
                _buildItemLista(
                  icono: Icons.map,
                  titulo: 'OpenStreetMap',
                  subtitulo: 'Información geográfica abierta y colaborativa.',
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSeccion(
              context,
              titulo: 'Integrantes del Equipo',
              children: [
                _buildItemLista(
                  icono: Icons.person,
                  titulo: 'Arroyo Lopez Miguel Angel',
                ),
                _buildItemLista(
                  icono: Icons.person,
                  titulo: 'Borchardt Castellanos Gael Humberto',
                ),
                _buildItemLista(
                  icono: Icons.person,
                  titulo: 'Perez Ibarra Angel Francisco',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccion(
    BuildContext context, {
    required String titulo,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.2),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildItemLista({
    required IconData icono,
    required String titulo,
    String? subtitulo,
  }) {
    return ListTile(
      leading: Icon(icono, color: Colors.blue),
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitulo != null
          ? Text(subtitulo, style: const TextStyle(color: Colors.grey))
          : null,
    );
  }
}
