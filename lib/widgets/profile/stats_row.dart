import 'package:flutter/material.dart';

class StatsRow extends StatelessWidget {
  final int favoritosCount;
  final int documentosCount;

  const StatsRow({
    super.key,
    required this.favoritosCount,
    required this.documentosCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStatCard(context, favoritosCount.toString(), 'Favoritos'),
        const SizedBox(width: 16),
        _buildStatCard(context, documentosCount.toString(), 'Documentos'),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label) {
    final primaryGreen = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
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
      ),
    );
  }
}
