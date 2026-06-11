import 'package:cotorra_app/models/documento.dart';
import 'package:flutter/material.dart';

class ImageVisualizerScreen extends StatefulWidget {
  final Documento documento;
  ImageVisualizerScreen({super.key, required this.documento});

  @override
  State<StatefulWidget> createState() => _ImageVisualizerScreenState();
}

class _ImageVisualizerScreenState extends State<ImageVisualizerScreen> {
  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF7CB342);

    return Container(
      // color: Colors.black,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/placeholder_doc.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 280,
                  height: 380,
                  decoration: BoxDecoration(
                    // color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.white24, blurRadius: 3),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image, size: 80, color: primaryGreen),
                      const SizedBox(height: 20),
                      Text(
                        widget.documento.titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '[ Simulación de Visualización de Imagen ]',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            // color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tipo: Imagen (PNG/JPG)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: EdgeInsetsGeometry.all(5)
                  ),
                  onPressed: () {},
                  icon: const Icon(
                    Icons.download,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Descargar',
                    style: TextStyle(color: Colors.white),
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
