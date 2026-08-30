import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/notifications/notification_service.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';

/// Tela de preferências — funcionalidade nova desta fase.
///
/// Reúne acessibilidade (escala de texto), aparência (tema) e controle de
/// alertas, tudo persistido no dispositivo via [SettingsProvider].
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Preferências')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(context, 'Aparência'),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Claro'),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_outlined),
                label: Text('Auto'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Escuro'),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (selection) =>
                settings.setThemeMode(selection.first),
          ),
          const SizedBox(height: 24),
          _section(context, 'Acessibilidade'),
          Text('Tamanho do texto',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: SettingsProvider.textScaleOptions
                .map((scale) => ChoiceChip(
                      selected: settings.textScale == scale,
                      onSelected: (_) => settings.setTextScale(scale),
                      label: Text('${(scale * 100).round()}%'),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          _section(context, 'Alertas'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.alertsEnabled,
            onChanged: (value) {
              settings.setAlertsEnabled(value);
              NotificationService.instance.setEnabled(value);
            },
            title: const Text('Notificações de saúde e logística'),
            subtitle: const Text(
                'Lembretes de medicação, alertas de sinais vitais e entregas.'),
          ),
          const SizedBox(height: 24),
          _section(context, 'Dados'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Limpar histórico do assistente'),
            subtitle: const Text('Remove as conversas salvas neste dispositivo.'),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              await context.read<ChatProvider>().clearConversation();
              messenger.showSnackBar(
                const SnackBar(content: Text('Histórico do assistente limpo.')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Colors.grey,
          ),
        ),
      );
}
