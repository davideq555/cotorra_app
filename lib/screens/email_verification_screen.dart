import 'package:flutter/material.dart';
import '../utils/url_launcher_util.dart';

/// Pantalla que se muestra después de registrarse con email y contraseña.
///
/// El backend ya envió el email de verificación; esta pantalla guía al
/// usuario para que lo revise y confirme su cuenta.
///
/// Las cuentas creadas con Google NO pasan por acá: se verifican solas
/// (login directo sin paso de verificación).
///
/// Retornar `true` (pop con resultado) indica que el usuario ya verificó
/// y quiere ir al login.
class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const primaryGreen = Color(0xFF7CB342);

  bool _openingMail = false;

  Future<void> _openMailApp() async {
    setState(() => _openingMail = true);

    final opened = await UrlLauncherUtil.openMailApp();

    if (mounted) {
      setState(() => _openingMail = false);
      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos abrir tu app de correo. '
              'Abrila manualmente y buscá el email de Cotorra.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _goToLogin() {
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Ícono de sobre
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 52,
                    color: primaryGreen,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                '¡Un paso más!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF212121),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Te enviamos un email de verificación a',
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Chip con el email destino
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.email,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: primaryGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Abrí tu casilla, tocá el link del email y confirmá tu '
                'cuenta. Si no lo encontrás, revisá la carpeta de spam.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              // Botón principal: abrir Gmail / app de mail
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _openingMail ? null : _openMailApp,
                icon: _openingMail
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.mail_outline, size: 22),
                label: Text(
                  _openingMail
                      ? 'Abriendo...'
                      : 'Abrir Gmail o mi app de correo',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Botón secundario: ya verifiqué, ir al login
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryGreen,
                  side: const BorderSide(color: primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _goToLogin,
                child: const Text(
                  'Ya verifiqué mi cuenta, ir al login',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
