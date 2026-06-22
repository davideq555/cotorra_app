import 'package:flutter/material.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          const Text(
            'Cuenta',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingsCard(
            children: [
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: 'Editar Perfil',
                subtitle: 'Nombre, correo electrónico, rol',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edición de perfil no disponible en esta demo')),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsTile(
                icon: Icons.lock_outline,
                title: 'Cambiar Contraseña',
                subtitle: 'Actualiza tus credenciales',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cambio de contraseña no disponible en esta demo')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // const Text(
          //   'Preferencias',
          //   style: TextStyle(
          //     fontSize: 14,
          //     fontWeight: FontWeight.bold,
          //     color: Colors.grey,
          //   ),
          // ),
          // const SizedBox(height: 12),
          // _buildSettingsCard(
          //   children: [
          //     SwitchListTile(
          //       activeColor: primaryGreen,
          //       secondary: const Icon(Icons.notifications_none, color: primaryGreen),
          //       title: const Text(
          //         'Notificaciones',
          //         style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          //       ),
          //       subtitle: const Text('Avisar cuando se apruebe mi documento'),
          //       value: _notificationsEnabled,
          //       onChanged: (val) {
          //         setState(() {
          //           _notificationsEnabled = val;
          //         });
          //       },
          //     ),
          //     const Divider(height: 1, indent: 56),
          //     SwitchListTile(
          //       activeColor: primaryGreen,
          //       secondary: const Icon(Icons.dark_mode_outlined, color: primaryGreen),
          //       title: const Text(
          //         'Modo Oscuro',
          //         style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          //       ),
          //       subtitle: const Text('Tema oscuro para la aplicación'),
          //       value: _darkModeEnabled,
          //       onChanged: (val) {
          //         setState(() {
          //           _darkModeEnabled = val;
          //         });
          //       },
          //     ),
          //   ],
          // ),
          const SizedBox(height: 24),
          const Text(
            'Soporte & Legal',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingsCard(
            children: [
              _buildSettingsTile(
                icon: Icons.help_outline,
                title: 'Centro de Ayuda',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: 'Acerca de Kotorra',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Card(
      // color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    const primaryGreen = Color(0xFF7CB342);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          // color: const Color(0xFFF1F8E9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: primaryGreen, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}
