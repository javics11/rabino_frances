import 'package:flutter/material.dart';

import '../services/player_name_settings.dart';

class SettingsScreen extends StatefulWidget {
  final PlayerNameSettingsPersistence persistence;

  const SettingsScreen({
    super.key,
    this.persistence = const SharedPreferencesPlayerNameSettings(),
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController bottomController = TextEditingController();
  late final TextEditingController rightController = TextEditingController();
  late final TextEditingController topController = TextEditingController();
  late final TextEditingController leftController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await widget.persistence.load();
    if (!mounted) return;
    bottomController.text = settings.bottom;
    rightController.text = settings.right;
    topController.text = settings.top;
    leftController.text = settings.left;
    setState(() {});
  }

  Future<void> _save() async {
    await widget.persistence.save(PlayerNameSettings(
      bottom: bottomController.text,
      right: rightController.text,
      top: topController.text,
      left: leftController.text,
    ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    bottomController.dispose();
    rightController.dispose();
    topController.dispose();
    leftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Ajustes')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _field('Tu nombre', bottomController, 'settings-bottom-name'),
              _field('Jugador a tu derecha', rightController, 'settings-right-name'),
              _field('Jugador enfrente', topController, 'settings-top-name'),
              _field('Jugador a tu izquierda', leftController, 'settings-left-name'),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const ValueKey('save-player-names-button'),
                onPressed: _save,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      );

  Widget _field(String label, TextEditingController controller, String key) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          key: ValueKey(key),
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );
}
