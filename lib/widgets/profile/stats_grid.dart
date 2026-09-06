import 'package:flutter/material.dart';

/// Grilla 2x2 de estadísticas del perfil.
/// Fila 1: Subidas | Total descargados — Fila 2: Total favoritos | Karma.
class StatsGrid extends StatelessWidget {
  final int subidas;
  final int descargas;
  final int favoritos;
  final int karma;

  const StatsGrid({
    super.key,
    required this.subidas,
    required this.descargas,
    required this.favoritos,
    required this.karma,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(context, subidas.toString(), 'Subidas'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                descargas.toString(),
                'Total descargados',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                favoritos.toString(),
                'Total favoritos',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard(context, karma.toString(), 'Karma')),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label) {
    final primaryGreen = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
