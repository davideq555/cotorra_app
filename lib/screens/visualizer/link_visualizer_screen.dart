import 'package:cotorra_app/models/documento.dart';
import 'package:cotorra_app/utils/url_launcher_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LinkVisualizerScreen extends StatelessWidget {
  final Documento documento;

  const LinkVisualizerScreen({super.key, required this.documento});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF7CB342);
    final urlType = UrlLauncherUtil.getUrlType(documento.archivoUrl);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIcon(urlType),
                  size: 32,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      documento.titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTypeLabel(urlType),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (documento.descripcion != null && documento.descripcion!.isNotEmpty) ...[
            _buildInfoSection(
              'Descripción',
              documento.descripcion!,
              Icons.description_outlined,
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              if (documento.autor != null && documento.autor!.isNotEmpty)
                Expanded(
                  child: _buildInfoChip(
                    Icons.person_outline,
                    documento.autor!,
                  ),
                ),
              if (documento.anoAcademico != null) ...[
                if (documento.autor != null) const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    Icons.calendar_today_outlined,
                    documento.anoAcademico!,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (documento.tipoDocumento != null)
            _buildInfoChip(
              Icons.category_outlined,
              documento.tipoDocumento!.nombre,
            ),
          if (documento.tags != null && documento.tags!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: documento.tags!.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag.nombre,
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: InkWell(
              onTap: () => _copyToClipboard(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        documento.archivoUrl,
                        style: const TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    const Icon(Icons.copy, color: primaryGreen, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _openLink(context),
              icon: const Icon(Icons.open_in_new, color: Colors.white),
              label: const Text(
                'Abrir Enlace',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(UrlType urlType) {
    switch (urlType) {
      case UrlType.youtube:
        return Icons.play_circle_fill;
      case UrlType.googleDrive:
        return Icons.folder_special;
      case UrlType.github:
        return Icons.code;
      case UrlType.other:
        return Icons.link;
    }
  }

  String _getTypeLabel(UrlType urlType) {
    switch (urlType) {
      case UrlType.youtube:
        return 'Video de YouTube';
      case UrlType.googleDrive:
        return 'Archivo de Google Drive';
      case UrlType.github:
        return 'Repositorio de GitHub';
      case UrlType.other:
        return 'Enlace Externo';
    }
  }

  Widget _buildInfoSection(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLink(BuildContext context) async {
    final success = await UrlLauncherUtil.openUrl(documento.archivoUrl);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace')),
      );
    }
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: documento.archivoUrl));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL copiada al portapapeles'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
