import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const SettingsTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 0,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: primaryGreen,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
