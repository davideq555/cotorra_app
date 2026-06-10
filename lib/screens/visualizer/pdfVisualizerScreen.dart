import 'package:cotorra_app/models/documento.dart';
import 'package:flutter/material.dart';

class PdfVisualizerScreen extends StatefulWidget{
  final Documento documento;

  PdfVisualizerScreen({super.key, required this.documento});

  @override
  State<StatefulWidget> createState() => _PdfVisualerScreenState();

}

class _PdfVisualerScreenState extends State<PdfVisualizerScreen>{
  int _currentPage = 1;
  final int _totalPages = 14; // Simulated PDF pages

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF7CB342);

    return Column(
      children: [
        // Top Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          // color: Colors.grey.shade100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Página $_currentPage de $_totalPages',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.zoom_out, size: 20),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_in, size: 20),
                    onPressed: () {},
                  ),
                ],
              )
            ],
          ),
        ),
        // Simulated Page Content
        Expanded(
          child: Container(
            // color: Colors.grey.shade300,
            padding: const EdgeInsets.all(16),
            child: Card(
              // color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.documento.titulo} - Pág. $_currentPage',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),// color titulo texto , color: primaryGreen
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey.shade200),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\n\nDuis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n\nCurabitur pretium tincidunt lacus. Nulla gravida orci a odio. Nullam varius, turpis et commodo pharetra, est eros bibendum elit, nec luctus magna felis sollicitudin mauris. Integer in mauris eu nibh euismod gravida. Duis ac tellus et risus vulputate vehicula. Donec lobortis risus a elit. Etiam tempor. Ut ullamcorper, ligula eu tempor congue, eros est euismod turpis, id tincidunt sapien risus a vulputate.',
                          style: TextStyle(fontSize: 14, height: 1.6),//, color: Colors.grey.shade800
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Bottom controller
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            // color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.navigate_before),
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Descargando archivo...'), backgroundColor: primaryGreen),
                  );
                },
                icon: const Icon(Icons.download, size: 18, color: Colors.white),
                label: const Text('Descargar', style: TextStyle(color: Colors.white)),
              ),
              IconButton(
                icon: const Icon(Icons.navigate_next),
                onPressed: _currentPage < _totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
            ],
          ),
        )
      ],
    );
  }

}