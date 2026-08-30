import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../providers/home_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/alert_card.dart';
import '../widgets/pulsing_dot.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/status_banner.dart';
import '../widgets/vital_chip.dart';

/// Dashboard do paciente.
///
/// Novidades desta fase: pull-to-refresh, aviso de dados em cache (offline),
/// tratamento visível de erro com retry, chips de sinais vitais coloridos pela
/// classificação clínica e alternância de tema direto na barra superior.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();

    return Scaffold(
      body: Column(
        children: [
          _TopBar(provider: provider),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: provider.refresh,
                    child: _Body(provider: provider),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.provider});

  final HomeProvider provider;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final settings = context.read<SettingsProvider>();
    final patient = provider.patient;

    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      padding:
          EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider.greeting,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(patient?.name ?? 'SmartCare',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                if (provider.weatherInfo != null)
                  Text(provider.weatherInfo!,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            tooltip: brightness == Brightness.dark
                ? 'Usar tema claro'
                : 'Usar tema escuro',
            icon: Icon(
              brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: Colors.white,
            ),
            onPressed: () => settings.toggleBrightness(brightness),
          ),
          Stack(
            children: [
              IconButton(
                tooltip: 'Enviar alerta de teste',
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white),
                onPressed: () {
                  final alerts = provider.alerts;
                  if (alerts.isEmpty) {
                    NotificationService.instance.medicationReminder();
                  } else {
                    NotificationService.instance.pushHealthAlert(alerts.first);
                  }
                },
              ),
              if ((patient?.notificationCount ?? 0) > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: SmartCareTheme.dangerRed, shape: BoxShape.circle),
                    child: Center(
                      child: Text('${patient!.notificationCount}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 9)),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Preferências',
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => context.push(Routes.settings),
          ),
          IconButton(
            tooltip: 'Sobre o projeto',
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => context.push(Routes.credits),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.provider});

  final HomeProvider provider;

  @override
  Widget build(BuildContext context) {
    final vitals = provider.vitals;
    final score = provider.healthScore;
    final failure = provider.failure;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: StatusBanner(
                icon: Icons.error_outline,
                message: failure.message,
                tone: BannerTone.critical,
                onAction: failure.isRetryable ? provider.refresh : null,
                actionLabel: 'Tentar novamente',
              ),
            )
          else if (provider.isOffline)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: StatusBanner(
                icon: Icons.cloud_off_outlined,
                message: 'Sem conexão com o gateway. Exibindo a última leitura '
                    'salva${_updatedLabel(provider.lastUpdated)}.',
                tone: BannerTone.warning,
                onAction: provider.refresh,
                actionLabel: 'Atualizar',
              ),
            ),
          _HealthScoreCard(score: score, vitals: vitals, provider: provider),
          const SizedBox(height: 16),
          _sectionLabel('sinais vitais agora'),
          if (vitals != null) _VitalRow(provider: provider, vitals: vitals),
          const SizedBox(height: 16),
          _sectionLabel('alertas gerados pela IA'),
          ...provider.alerts.map((alert) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AlertCard(alert: alert),
              )),
          const SizedBox(height: 8),
          _sectionLabel('ações rápidas'),
          Row(children: [
            QuickActionButton(
                icon: '🚚',
                label: 'Rastrear entrega',
                sub: 'Medicamentos',
                onTap: () => context.go(Routes.delivery)),
            const SizedBox(width: 8),
            QuickActionButton(
                icon: '📹',
                label: 'Consulta remota',
                sub: '14h30 hoje',
                onTap: () => context.go(Routes.consulta)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            QuickActionButton(
                icon: '📊',
                label: 'Meus dados',
                sub: '7 dias',
                onTap: () => context.go(Routes.analytics)),
            const SizedBox(width: 8),
            QuickActionButton(
                icon: '🤖',
                label: 'IA de saúde',
                sub: 'Pergunte algo',
                onTap: () => context.go(Routes.chat)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            QuickActionButton(
                icon: '🗺️',
                label: 'Mapa SmartCare',
                sub: 'Dispositivos',
                onTap: () => context.go(Routes.map)),
            const SizedBox(width: 8),
            QuickActionButton(
                icon: '⚙️',
                label: 'Preferências',
                sub: 'Tema e acessibilidade',
                onTap: () => context.push(Routes.settings)),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static String _updatedLabel(DateTime? at) => at == null
      ? ''
      : ' às ${at.hour.toString().padLeft(2, '0')}:'
          '${at.minute.toString().padLeft(2, '0')}';

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Colors.grey)),
      );
}

/// Chips de sinais vitais coloridos conforme a classificação do motor de regras.
class _VitalRow extends StatelessWidget {
  const _VitalRow({required this.provider, required this.vitals});

  final HomeProvider provider;
  final VitalReading vitals;

  @override
  Widget build(BuildContext context) {
    Color colorFor(String metric) {
      final evaluation = provider.evaluations
          .where((e) => e.metric == metric)
          .cast<VitalEvaluation?>()
          .firstWhere((e) => true, orElse: () => null);
      return switch (evaluation?.status) {
        VitalStatus.critical => context.health.critical,
        VitalStatus.attention => context.health.warning,
        _ => context.health.ok,
      };
    }

    return Row(children: [
      VitalChip(
        icon: '❤️',
        value: '${vitals.heartRate}',
        unit: 'bpm',
        color: colorFor('Freq. cardíaca'),
      ),
      const SizedBox(width: 8),
      VitalChip(
        icon: '🫁',
        value: '${vitals.spO2.toStringAsFixed(1)}%',
        unit: 'SpO₂',
        color: colorFor('SpO₂'),
      ),
      const SizedBox(width: 8),
      VitalChip(
        icon: '🩸',
        value: '${vitals.glucoseLevel}',
        unit: 'mg/dL',
        color: colorFor('Glicemia'),
      ),
    ]);
  }
}

class _HealthScoreCard extends StatelessWidget {
  const _HealthScoreCard({
    required this.score,
    required this.vitals,
    required this.provider,
  });

  final HealthScore? score;
  final VitalReading? vitals;
  final HomeProvider provider;

  @override
  Widget build(BuildContext context) {
    final worstPenalty = (score?.penalties.entries.toList() ?? [])
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [SmartCareTheme.primaryGreen, SmartCareTheme.primaryGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Score de saúde',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${score?.score ?? '--'}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 52,
                                fontWeight: FontWeight.w300)),
                        if (score != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14, left: 6),
                            child: Icon(
                              switch (score!.trend) {
                                TrendDirection.up => Icons.trending_up,
                                TrendDirection.down => Icons.trending_down,
                                TrendDirection.stable => Icons.trending_flat,
                              },
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                    Row(children: [
                      PulsingDot(
                          color: provider.isOffline
                              ? Colors.orangeAccent
                              : Colors.white),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          provider.isOffline
                              ? 'Dados em cache — reconectando ao wearable'
                              : 'Monitoramento ativo — wearable conectado',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              if (score != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(score!.label,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, thickness: 0.5),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat('Freq. cardíaca', '${vitals?.heartRate ?? '--'} bpm'),
              const SizedBox(width: 20),
              _stat('SpO₂', '${vitals?.spO2.toStringAsFixed(1) ?? '--'}%'),
              const SizedBox(width: 20),
              _stat('Glicemia', '${vitals?.glucoseLevel ?? '--'} mg/dL'),
            ],
          ),
          if (worstPenalty.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Maior impacto no score: ${worstPenalty.first.key} '
              '(−${worstPenalty.first.value} pts)',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 10)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      );
}
