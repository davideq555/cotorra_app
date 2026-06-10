import 'package:flutter/material.dart';

class LinkVisualizerScreen  extends StatefulWidget{

  LinkVisualizerScreen({super.key});

  @override
  State<StatefulWidget> createState() => _LinkVisualizerScreenState();

}
class _LinkVisualizerScreenState extends State<LinkVisualizerScreen>{
  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF7CB342);

    return Container(
      // color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.link, size: 64, color: primaryGreen),
          ),
          const SizedBox(height: 24),
          const Text(
            'Enlace Externo',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Este documento se encuentra alojado en un enlace de internet externo.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.language, color: Colors.grey),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'https://drive.google.com/file/d/apuntes-universidad',
                      style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {},
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            label: const Text('Abrir en el Navegador', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }

}