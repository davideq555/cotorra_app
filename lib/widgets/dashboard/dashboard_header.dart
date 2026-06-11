import 'package:flutter/material.dart';
import '../../screens/upload_screen.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 40,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Little Parrot Logo
              SizedBox(
                width: 44,
                height: 44,
                child: Image.asset(
                  'assets/images/free.png',
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.white.withOpacity(0.2),
                    child: const Icon(
                      Icons.pets,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kotorra',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '¡Hola de nuevo! Comparte tu conocimiento',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              // Plus Button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UploadScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Material disponible Card
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 24,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Material disponible',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '1,247 documentos',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
