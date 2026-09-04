import 'package:cotorra_app/models/carrera.dart';
import 'package:cotorra_app/models/facultad.dart';
import 'package:cotorra_app/models/usuarioCreate.dart';
import 'package:cotorra_app/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/facultad_dropdown.dart';
import '../widgets/common/carrera_dropdown.dart';
import 'email_verification_screen.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  Facultad? _selectedFacultad;
  Carrera? _selectedCarrera;
  final GlobalKey<CarreraDropdownState> _carreraDropdownKey =
      GlobalKey<CarreraDropdownState>();

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isLogin && _selectedCarrera == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccioná tu carrera'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = false;
    String? registeredEmail;

    if (_isLogin) {
      success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      final userCreate = UsuarioCreate(
        nombre: _nombreController.text.trim(),
        email: _emailController.text.trim(),
        rol: RolEnum.ALUMNO,
        contrasena: _passwordController.text,
        carreraIds: [_selectedCarrera!.id],
      );
      success = await authProvider.register(userCreate);
      if (success) registeredEmail = userCreate.email;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      final errorMsg = authProvider.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg ??
                (_isLogin ? 'Error al iniciar sesión' : 'Error al registrarse'),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Registro normal: mostrar pantalla de verificación de email.
    // (Las cuentas de Google loguean directo, sin este paso.)
    if (registeredEmail != null) {
      final wentToLogin = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(email: registeredEmail!),
        ),
      );
      // Si el usuario verificó y volvió, pasamos el formulario a login
      // y limpiamos la contraseña para que la vuelva a escribir.
      if (wentToLogin == true && mounted) {
        setState(() {
          _isLogin = true;
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      }
    }
  }

  void _signInWithGoogle() async {
    debugPrint('[GoogleAuth] Botón "Continuar con Google" presionado.');
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    debugPrint('[GoogleAuth] Resultado en AuthScreen: success=$success');
    if (!success && mounted) {
      final errorMsg = authProvider.errorMessage;
      // No mostrar error si el usuario canceló
      if (errorMsg != null && !errorMsg.contains('canceló')) {
        debugPrint('[GoogleAuth] Mostrando SnackBar de error: "$errorMsg"');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
        );
      } else {
        debugPrint(
          '[GoogleAuth] Sin SnackBar (cancelación del usuario). '
          'errorMsg=${errorMsg == null ? "null" : '"$errorMsg"'}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF7CB342);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Image(
                  image: AssetImage('assets/images/logotipo.png'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cotorra',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: primaryGreen,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Tu plataforma colaborativa universitaria',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isLogin ? 'Iniciar Sesión' : 'Registrarse',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      if (!_isLogin) ...[
                        const Text(
                          'Nombre completo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nombreController,
                          decoration: InputDecoration(
                            hintText: 'Tu nombre',
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) => value!.isEmpty
                              ? 'Por favor ingresa tu nombre'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Facultad',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FacultadDropdown(
                          value: _selectedFacultad,
                          onChanged: (facultad) {
                            setState(() {
                              _selectedFacultad = facultad;
                              _selectedCarrera = null;
                            });
                            if (facultad != null) {
                              _carreraDropdownKey.currentState?.resetAndLoad(
                                facultad.id,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Carrera',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CarreraDropdown(
                          key: _carreraDropdownKey,
                          value: _selectedCarrera,
                          enabled: _selectedFacultad != null,
                          onChanged: (carrera) {
                            setState(() {
                              _selectedCarrera = carrera;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'tu.email@universidad.edu',
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu email';
                          }
                          final emailRegex = RegExp(
                            r'^[\w.-]+@[\w.-]+\.\w{2,}$',
                            caseSensitive: false,
                          );
                          if (!emailRegex.hasMatch(value)) {
                            return 'Ingresá un email válido';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),
                      const Text(
                        'Contraseña',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9]'),
                          ),
                        ],
                        decoration: InputDecoration(
                          hintText: 'Tu contraseña',
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu contraseña';
                          }
                          if (value.length < 8) {
                            return 'La contraseña debe tener al menos 8 caracteres';
                          }
                          final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
                          final hasNumber = RegExp(r'[0-9]').hasMatch(value);
                          if (!hasLetter || !hasNumber) {
                            return 'Debe contener letras y números';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Link de recuperación: solo tiene sentido en login.
                      if (_isLogin) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(
                                color: primaryGreen,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (!_isLogin) ...[
                        const Text(
                          'Confirmar Contraseña',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _confirmPasswordController,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9]'),
                            ),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Repetí tu contraseña',
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscureConfirmPassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor confirmá tu contraseña';
                            }
                            if (value != _passwordController.text) {
                              return 'Las contraseñas no coinciden';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 4),
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: primaryGreen,
                              ),
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _submit,
                              child: Text(
                                _isLogin ? 'Iniciar Sesión' : 'Registrarse',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                      const SizedBox(height: 14),
                      // ─── Divider con "o" ───
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Colors.grey)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'o',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // ─── Botón Google Sign-In ───
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon: Image.asset(
                            'assets/images/logo-google.png',
                            height: 24,
                            width: 24,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback si la imagen no está en el bundle
                              return const Icon(
                                Icons.g_mobiledata,
                                size: 24,
                                color: Colors.blue,
                              );
                            },
                          ),
                          label: Text(
                            'Continuar con Google',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(
                          _isLogin
                              ? '¿No tienes cuenta? Regístrate'
                              : '¿Ya tienes cuenta? Inicia Sesión',
                          style: const TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
