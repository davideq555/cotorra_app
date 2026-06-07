import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/screens/document_view_screen.dart';
import 'package:cotorra_app/widgets/statusChip.dart';
import 'package:flutter/material.dart';

class DocumentCard extends StatelessWidget{
  final Documento doc;
  StatusChip? trailing;

  DocumentCard({
    super.key,
    required this.doc,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF7CB342);
    final isBook = doc.titulo.contains('Física') || doc.titulo.contains('Libro') || doc.titulo.contains('Análisis');
    final isGrad = doc.titulo.contains('Tesis') || doc.titulo.contains('Proyecto') || doc.titulo.contains('Final');

    IconData icon = Icons.description;
    if (isBook) icon = Icons.menu_book;
    if (isGrad) icon = Icons.school;
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentViewScreen(documento: doc),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryGreen, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.titulo,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8E9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            doc.materia?.nombre ?? 'General',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.fiber_manual_record, size: 4, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            doc.autor ?? 'Anónimo',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Hace 2 días',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Icon(Icons.thumb_up, size: 12, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${doc.descargas}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ]
            ],
          ),
        ),
      ),
    );
  }
}

// Widget buildDocumentCard(Documento doc, {Widget? trailing}) {
//   const primaryGreen = Color(0xFF7CB342);
//   final isBook = doc.titulo.contains('Física') || doc.titulo.contains('Libro') || doc.titulo.contains('Análisis');
//   final isGrad = doc.titulo.contains('Tesis') || doc.titulo.contains('Proyecto') || doc.titulo.contains('Final');
//
//   IconData icon = Icons.description;
//   if (isBook) icon = Icons.menu_book;
//   if (isGrad) icon = Icons.school;
//   return Card(
//     color: Colors.white,
//     elevation: 0,
//     margin: const EdgeInsets.only(bottom: 14),
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(16),
//       side: BorderSide(color: Colors.grey.shade100, width: 1),
//     ),
//     child: InkWell(
//       borderRadius: BorderRadius.circular(16),
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => DocumentViewScreen(documento: doc),
//           ),
//         );
//       },
//       child: Padding(
//         padding: const EdgeInsets.all(14.0),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               width: 48,
//               height: 48,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFF1F8E9),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(icon, color: primaryGreen, size: 24),
//             ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     doc.titulo,
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 6),
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFF1F8E9),
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                         child: Text(
//                           doc.materia?.nombre ?? 'General',
//                           style: const TextStyle(
//                             fontSize: 10,
//                             fontWeight: FontWeight.bold,
//                             color: primaryGreen,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       const Icon(Icons.fiber_manual_record, size: 4, color: Colors.grey),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           doc.autor ?? 'Anónimo',
//                           style: const TextStyle(
//                             fontSize: 11,
//                             color: Colors.grey,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     children: [
//                       const Icon(Icons.access_time, size: 12, color: Colors.grey),
//                       const SizedBox(width: 4),
//                       Text(
//                         'Hace 2 días',
//                         style: TextStyle(
//                           fontSize: 11,
//                           color: Colors.grey.shade500,
//                         ),
//                       ),
//                       const SizedBox(width: 14),
//                       const Icon(Icons.thumb_up, size: 12, color: Colors.amber),
//                       const SizedBox(width: 4),
//                       Text(
//                         '${doc.descargas}',
//                         style: TextStyle(
//                           fontSize: 11,
//                           color: Colors.grey.shade500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             if (trailing != null) ...[
//               const SizedBox(width: 8),
//               trailing,
//             ]
//           ],
//         ),
//       ),
//     ),
//   );
// }