import 'package:flutter/material.dart';
import '../../screens/upload_screen.dart';
import '../../services/api/documents_service.dart';
import '../../services/api_client.dart';

class DashboardHeader extends StatefulWidget {
  const DashboardHeader({super.key});

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  late final Future<int?> _totalFuture;

  @override
  void initState() {
    super.initState();
    _totalFuture = _fetchDocumentosTotal();
  }

  Future<int?> _fetchDocumentosTotal() async {
    try {
      return await DocumentsService(ApiClient()).getDocumentosTotal();
    } catch (_) {
      return null; // fallback: la UI muestra '—'
    }
  }

  String _formatTotal(int total) {
    return total.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 40, bottom: 24),
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
                    color: Colors.white.withValues(alpha: 0.2),
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
                      'Cotorra',
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
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 22),
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
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Material disponible',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<int?>(
                  future: _totalFuture,
                  builder: (context, snapshot) {
                    String label;
                    if (snapshot.connectionState != ConnectionState.done) {
                      label = '…';
                    } else if (snapshot.hasError || snapshot.data == null) {
                      label = '—';
                    } else {
                      label = _formatTotal(snapshot.data!);
                    }
                    return Text(
                      '$label documentos',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
