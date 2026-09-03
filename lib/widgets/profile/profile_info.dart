import 'package:flutter/material.dart';

class ProfileInfo extends StatelessWidget {
  final String nombre;
  final String email;
  final String rol;
  final String inicial;

  const ProfileInfo({
    super.key,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.inicial,
  });

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: primaryGreen,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              inicial,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          nombre,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(email, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            rol,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
        ),
      ],
    );
  }
}
