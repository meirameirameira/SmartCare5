import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/home_provider.dart';
import '../core/theme.dart';
import '../widgets/vital_chip.dart';
import '../widgets/alert_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/pulsing_dot.dart';
import '../services/fcm_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<HomeProvider>();

    return Scaffold(
      body: Column(
        children: [
          _TopBar(p: p),
          Expanded(
            child: p.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _Body(p: p),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final HomeProvider p;
  const _TopBar({required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SmartCareTheme.primaryGreenDark,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.greeting,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(p.patient?.name ?? 'SmartHAS',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (p.weatherInfo != null)
            Expanded(
              child: Text(p.weatherInfo!,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 2),
            ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => FcmService.triggerMedicationReminder(),
              ),
              if ((p.patient?.notificationCount ?? 0) > 0)
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(
                        color: SmartCareTheme.dangerRed, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        '${p.patient!.notificationCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 9),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => context.push('/credits'),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final HomeProvider p;
  const _Body({required this.p});

  @override
  Widget build(BuildContext context) {
    final vitals = p.vitals;
    final score = p.healthScore;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health Score Card
          _HealthScoreCard(score: score?.score, label: score?.label, vitals: vitals),
          const SizedBox(height: 16),
          _sectionLabel('sinais vitais agora'),
          Row(children: [
            VitalChip(icon: '❤️', value: '${vitals?.heartRate ?? '--'}',
                unit: 'bpm', color: SmartCareTheme.dangerRed),
            const SizedBox(width: 8),
            VitalChip(icon: '🫁',
                value: vitals != null ? '${vitals.spO2.toStringAsFixed(1)}%' : '--',
                unit: 'SpO₂', color: SmartCareTheme.accentBlue),
            const SizedBox(width: 8),
            VitalChip(icon: '🩸', value: '${vitals?.glucoseLevel ?? '--'}',
                unit: 'mg/dL', color: SmartCareTheme.warnAmber),
          ]),
          const SizedBox(height: 16),
          _sectionLabel('alertas de hoje'),
          ...p.alerts.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AlertCard(alert: a),
          )),
          const SizedBox(height: 8),
          _sectionLabel('ações rápidas'),
          Row(children: [
            QuickActionButton(icon: '🚚', label: 'Rastrear entrega',
                sub: 'Medicamentos', onTap: () => context.go('/delivery')),
            const SizedBox(width: 8),
            QuickActionButton(icon: '📹', label: 'Consulta remota',
                sub: '14h30 hoje', onTap: () => context.go('/consulta')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            QuickActionButton(icon: '📊', label: 'Meus dados',
                sub: '7 dias', onTap: () => context.go('/analytics')),
            const SizedBox(width: 8),
            QuickActionButton(icon: '🤖', label: 'IA de saúde',
                sub: 'Pergunte algo', onTap: () => context.go('/chat')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            QuickActionButton(icon: '🗺️', label: 'Mapa SmartHAS',
                sub: 'Dispositivos', onTap: () => context.go('/map')),
            const SizedBox(width: 8),
            // Botão de push de teste
            Expanded(
              child: GestureDetector(
                onTap: () => FcmService.triggerVitalAlert(),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: SmartCareTheme.dangerRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: SmartCareTheme.dangerRed.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('🔔', style: TextStyle(fontSize: 20)),
                      SizedBox(height: 6),
                      Text('Testar Alerta',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('Push FCM',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text.toUpperCase(),
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            letterSpacing: 1.2, color: Colors.grey)),
  );
}

class _HealthScoreCard extends StatelessWidget {
  final int? score;
  final String? label;
  final dynamic vitals;
  const _HealthScoreCard({this.score, this.label, this.vitals});

  @override
  Widget build(BuildContext context) {
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
                    Text('${score ?? '--'}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 52,
                            fontWeight: FontWeight.w300)),
                    Row(children: [
                      const PulsingDot(color: Colors.white),
                      const SizedBox(width: 6),
                      const Text('Monitoramento ativo — wearable conectado',
                          style: TextStyle(color: Colors.white70, fontSize: 10)),
                    ]),
                  ],
                ),
              ),
              if (label != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(label!,
                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, thickness: 0.5),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat('Freq. cardíaca', '${vitals?.heartRate ?? 72} bpm'),
              const SizedBox(width: 20),
              _stat('SpO₂', '${vitals?.spO2?.toStringAsFixed(1) ?? 98}%'),
              const SizedBox(width: 20),
              _stat('Glicemia', '${vitals?.glucoseLevel ?? 104} mg/dL'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      Text(value, style: const TextStyle(
          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
    ],
  );
}
