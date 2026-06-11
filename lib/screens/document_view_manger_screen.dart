import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/screens/visualizer/ImageVisualizerScreen.dart';
import 'package:cotorra_app/screens/visualizer/link_visualizer_screen.dart';
import 'package:cotorra_app/screens/visualizer/pdfVisualizerScreen.dart';
import 'package:flutter/material.dart';

class DocumentViewScreen extends StatefulWidget {
  final Documento documento;

  const DocumentViewScreen({super.key, required this.documento});

  @override
  State<DocumentViewScreen> createState() => _DocumentViewScreenState();
}

class _DocumentViewScreenState extends State<DocumentViewScreen> {
  // Widget ImageVisualizer() {
    // const primaryGreen = Color(0xFF7CB342);
    //
    // return Container(
    //   // color: Colors.black,
    //   child: Column(
    //     children: [
    //       Expanded(
    //         child: Center(
    //           child: Image.asset(
    //             'assets/images/placeholder_doc.png',
    //             fit: BoxFit.contain,
    //             errorBuilder: (context, error, stackTrace) => Container(
    //               width: 280,
    //               height: 380,
    //               decoration: BoxDecoration(
    //                 // color: Colors.white,
    //                 borderRadius: BorderRadius.circular(16),
    //                 boxShadow: [
    //                   BoxShadow(color: Colors.white24, blurRadius: 3),
    //                 ],
    //               ),
    //               child: Column(
    //                 mainAxisAlignment: MainAxisAlignment.center,
    //                 children: [
    //                   const Icon(Icons.image, size: 80, color: primaryGreen),
    //                   const SizedBox(height: 20),
    //                   Text(
    //                     widget.documento.titulo,
    //                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    //                     textAlign: TextAlign.center,
    //                   ),
    //                   const SizedBox(height: 8),
    //                   const Text(
    //                     '[ Simulación de Visualización de Imagen ]',
    //                     style: TextStyle(color: Colors.grey, fontSize: 12),
    //                   ),
    //                 ],
    //               ),
    //             ),
    //           ),
    //         ),
    //       ),
    //       Container(
    //         padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    //         // color: Colors.white,
    //         child: Row(
    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //           children: [
    //             const Text(
    //               'Tipo: Imagen (PNG/JPG)',
    //               style: TextStyle(fontWeight: FontWeight.w600),
    //             ),
    //             ElevatedButton.icon(
    //               style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
    //               onPressed: () {},
    //               icon: const Icon(Icons.download, size: 18, color: Colors.white),
    //               label: const Text('Descargar', style: TextStyle(color: Colors.white)),
    //             ),
    //           ],
    //         ),
    //       )
    //     ],
    //   ),
    // );
  // }


  @override
  Widget build(BuildContext context) {
    // Determine visualizer type based on mock rules
    final isImage = widget.documento.titulo.contains('Laboratorio') || widget.documento.titulo.contains('Imagen');
    final isLink = widget.documento.titulo.contains('Tesis') || widget.documento.titulo.contains('Final') || widget.documento.archivoUrl.startsWith('http');
    
    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.documento.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isImage 
          ? ImageVisualizerScreen(documento: widget.documento)
          : isLink 
              ?  LinkVisualizerScreen()//LinkVisualizer()
              : PdfVisualizerScreen(documento: widget.documento) //PdfVisualizer(),
    );
  }
}

// Inline constant substitution to bypass missing color definition
extension ColorsExtension on Colors {
  static const Color blackDE = Color(0xDE000000);
}
