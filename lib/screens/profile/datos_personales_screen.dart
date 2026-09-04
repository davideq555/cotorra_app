import 'package:cotorra_app/models/admin_models.dart';
import 'package:cotorra_app/providers/auth_provider.dart';
import 'package:cotorra_app/services/api/users_service.dart';
import 'package:cotorra_app/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Edición de datos personales: nombre, username y bio.
/// Persiste en el backend (PUT /usuarios/me/perfil) y actualiza la sesión.
class DatosPersonalesScreen extends StatefulWidget {
  const DatosPersonalesScreen({super.key});

  @override
  State<DatosPersonalesScreen> createState() => _DatosPersonalesScreenState();
}

class _DatosPersonalesScreenState extends State<DatosPersonalesScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  bool _isSaving = false;

  static const int _bioMaxLen = 280;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nombreController = TextEditingController(text: auth.userName ?? '');
    _usernameController = TextEditingController(text: auth.userUsername ?? '');
    _bioController = TextEditingController(text: auth.userBio ?? '');
    // El LoginResponse no trae username ni bio, así que la sesión puede
    // arrancar con esos campos vacíos: traemos el usuario completo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatosFrescos();
    });
  }

  /// GET /auth/me — rellena los campos que quedaron vacíos (el username y la
  /// bio no viajan en el login) y sincroniza el AuthProvider con el usuario
  /// completo, de modo que también se corrije la sesión persistida.
  Future<void> _cargarDatosFrescos() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null || token.isEmpty) return;

    final hayCamposVacios =
        _nombreController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _bioController.text.trim().isEmpty;
    if (!hayCamposVacios) return;

    try {
      final client = ApiClient();
      client.setToken(token);
      final me = await UsersService(client).getMe();
      // Aplica y persiste el usuario completo para el resto de la app.
      await auth.applyUpdatedUser(me);
      if (!mounted) return;
      setState(() {
        // Solo rellena lo que sigue vacío: no pisa lo que el usuario tipeó.
        if (_nombreController.text.trim().isEmpty && me.nombre.isNotEmpty) {
          _nombreController.text = me.nombre;
        }
        if (_usernameController.text.trim().isEmpty && me.username.isNotEmpty) {
          _usernameController.text = me.username;
        }
        if (_bioController.text.trim().isEmpty && me.bio != null) {
          _bioController.text = me.bio!;
        }
      });
    } catch (_) {
      // Falla silenciosa: los campos igual quedan editables para guardar.
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iniciá sesión para guardar los cambios')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);

    try {
      final client = ApiClient();
      client.setToken(token);
      final updated = await UsersService(client).updatePerfil(
        UsuarioPerfilUpdate(
          nombre: _nombreController.text.trim(),
          username: _usernameController.text.trim(),
          bio: _bioController.text.trim(),
        ),
      );

      await auth.applyUpdatedUser(updated);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tus datos se actualizaron'),
          backgroundColor: Color(0xFF7CB342),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(_saveErrorMessage(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _saveErrorMessage(Object e) {
    if (e is ApiException) {
      if (e.statusCode == 401) {
        return 'Tu sesión expiró, volvé a iniciar sesión.';
      }
      final message = e.message.trim();
      if (message.isNotEmpty) return message;
    }
    if (e.toString().contains('SocketException') ||
        e.toString().contains('Connection')) {
      return 'Verificá tu conexión a internet.';
    }
    return 'No se pudo guardar. Intentá de nuevo más tarde.';
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Datos personales',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            TextFormField(
              controller: _nombreController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Tu nombre visible',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                final name = value?.trim() ?? '';
                if (name.isEmpty) return 'Contanos cómo te llamás';
                if (name.length < 2) return 'El nombre es muy corto';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Usuario',
                hintText: 'sin espacios, para iniciar sesión',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              validator: (value) {
                final username = value?.trim() ?? '';
                if (username.isEmpty) return 'El usuario no puede quedar vacío';
                final valid = RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(username);
                if (!valid) {
                  return 'Solo letras, números, punto y guion bajo';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              maxLines: 4,
              maxLength: _bioMaxLen,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Contá algo sobre vos (materia, carrera, hobbies…)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Guardar cambios'),
            ),
            const SizedBox(height: 12),
            Text(
              'El nombre de usuario debe estar disponible; si otro lo tiene, '
              'el servidor te avisa.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
