import 'package:cotorra_app/models/models.dart';
import 'package:cotorra_app/screens/document_view_manger_screen.dart';
import 'package:flutter/material.dart';

class DocumentCard extends StatelessWidget {
  final Documento doc;
  final Widget? trailing;

  const DocumentCard({
    super.key,
    required this.doc,
    this.trailing,
  });

  IconData _getIcon() {
    final nombre = doc.formato?.nombre.toLowerCase() ?? '';
    final ext = doc.formato?.extensiones?.toLowerCase() ?? '';

    if (doc.formato?.esEnlace == true) {
      if (nombre.contains('youtube')) {
        return Icons.play_circle_fill;
      } else if (nombre.contains('drive')) {
        return Icons.cloud;
      } else {
        return Icons.link;
      }
    } else if (ext.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (ext.contains('doc') || ext.contains('docx')) {
      return Icons.article;
    } else if (ext.contains('xls') || ext.contains('xlsx')) {
      return Icons.table_chart;
    } else if (ext.contains('ppt') || ext.contains('pptx')) {
      return Icons.slideshow;
    } else if (ext.contains('zip') || ext.contains('rar')) {
      return Icons.folder_zip;
    } else if (ext.contains('jpg') || ext.contains('png') || ext.contains('jpeg') || ext.contains('gif')) {
      return Icons.image;
    }
    return Icons.description;
  }

  String _getTimeAgo() {
    if (doc.fechaSubida == null || doc.fechaSubida!.isEmpty) {
      return 'Fecha desconocida';
    }

    try {
      final fecha = DateTime.parse(doc.fechaSubida!);
      final ahora = DateTime.now().toUtc();
      final diferencia = ahora.difference(fecha);

      if (diferencia.inMinutes < 1) {
        return 'Hace un momento';
      } else if (diferencia.inMinutes < 60) {
        return 'Hace ${diferencia.inMinutes} min';
      } else if (diferencia.inHours < 24) {
        return 'Hace ${diferencia.inHours} h';
      } else if (diferencia.inDays < 30) {
        return 'Hace ${diferencia.inDays} días';
      } else if (diferencia.inDays < 365) {
        final meses = (diferencia.inDays / 30).floor();
        return 'Hace $meses mes${meses > 1 ? "es" : ""}';
      } else {
        final anios = (diferencia.inDays / 365).floor();
        return 'Hace $anios anio${anios > 1 ? "s" : ""}';
      }
    } catch (e) {
      return 'Fecha desconocida';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Theme.of(context).colorScheme.primary;
    final icon = _getIcon();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
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
                  color: primaryGreen.withOpacity(0.1),
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
                            color: primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            doc.materia?.nombre ?? 'General',
                            style: TextStyle(
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            doc.tipoDocumento?.nombre ?? '',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.access_time, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _getTimeAgo(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.download, size: 12, color: Colors.grey),
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
