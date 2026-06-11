import 'package:flutter/material.dart';

class PlaceholderWidget extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderWidget({
    super.key,
    required this.title,
    this.icon = Icons.construction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
