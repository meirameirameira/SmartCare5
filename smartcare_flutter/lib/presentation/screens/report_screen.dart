import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../providers/report_provider.dart';
import '../widgets/status_banner.dart';

/// Relatório clínico consolidado do paciente.
///
/// Com o back-end no perfil `oracle`, cada número desta tela sai das rotinas
/// PL/SQL do banco (`PRC_CONSOLIDAR_RELATORIO`, `FN_CALCULAR_SCORE_SAUDE`,
/// `FN_TEMPO_NA_FAIXA` e `FN_FORMATAR_RESUMO_PACIENTE`); o selo no topo diz
/// ao usuário quem calculou o relatório.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<ReportProvider>().ensureLoaded());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório clínico'),
        actions: [
          IconButton(
            tooltip: 'Atualizar relatório',
            onPressed: provider.state.isLoading ? null : provider.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _PeriodSelector(provider: provider),
          Expanded(
            child: provider.state.when(
              idle: () => const Center(child: CircularProgressIndicator()),
              loading: () => const Center(child: CircularProgressIndicator()),
              ready: (data, updatedAt, fromCache) =>
                  _ReportBody(report: data, fromCache: fromCache, onRetry: provider.load),
              failed: (failure, stale) => stale == null
                  ? _ErrorState(message: failure.message, onRetry: provider.load)
                  : _ReportBody(
                      report: stale,
                      fromCache: true,
                      errorMessage: failure.message,
                      onRetry: provider.load,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.provider});

  final ReportProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).appBarTheme.backgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: [
          for (final days in ReportProvider.periodOptions)
            ChoiceChip(
              label: Text('$days dias'),
              selected: provider.selectedPeriod == days,
              onSelected: (_) => provider.selectPeriod(days),
            ),
        ],
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({
    required this.report,
    required this.fromCache,
    required this.onRetry,
    this.errorMessage,
  });

  final ClinicalReport report;
  final bool fromCache;
  final String? errorMessage;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final averages = report.averages;

    return RefreshIndicator(
      onRefresh: onRetry,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (fromCache) ...[
            StatusBanner(
              icon: Icons.cloud_off_outlined,
              tone: BannerTone.warning,
              message: errorMessage ??
                  'Sem conexão: exibindo o último relatório salvo no aparelho.',
              actionLabel: 'Tentar de novo',
              onAction: onRetry,
            ),
            const SizedBox(height: 12),
          ],
          _EngineBadge(engine: report.engine),
          const SizedBox(height: 12),
          _ScoreCard(report: report),
          const SizedBox(height: 16),
          _section(report.engine == ReportEngine.oraclePlsql
              ? 'resumo formatado no banco (PL/SQL)'
              : 'resumo do período'),
          _Panel(
            child: SelectableText(
              report.summary.replaceAll(' | ', '\n'),
              style: const TextStyle(fontSize: 13, height: 1.45),
            ),
          ),
          const SizedBox(height: 16),
          _section('médias do período · ${report.readings} leituras'),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.15,
            children: [
              _AverageTile(label: 'Freq. cardíaca', value: _fmt(averages.heartRate, 0), unit: 'bpm'),
              _AverageTile(label: 'SpO₂', value: _fmt(averages.spO2, 1), unit: '%'),
              _AverageTile(label: 'Glicemia', value: _fmt(averages.glucose, 0), unit: 'mg/dL'),
              _AverageTile(label: 'Sistólica', value: _fmt(averages.systolic, 0), unit: 'mmHg'),
              _AverageTile(label: 'Diastólica', value: _fmt(averages.diastolic, 0), unit: 'mmHg'),
              _AverageTile(label: 'Temperatura', value: _fmt(averages.temperature, 1), unit: '°C'),
            ],
          ),
          const SizedBox(height: 16),
          _section('glicemia na faixa (time in range)'),
          _RangeBar(percent: report.glucoseTimeInRange),
          const SizedBox(height: 16),
          _section('alertas e consumo de medicamentos'),
          Row(
            children: [
              Expanded(
                child: _CounterTile(
                  icon: Icons.notifications_active_outlined,
                  value: '${report.openAlerts}',
                  label: report.urgentAlerts > 0
                      ? 'abertos · ${report.urgentAlerts} urgente${report.urgentAlerts > 1 ? 's' : ''}'
                      : 'alertas abertos',
                  color: report.urgentAlerts > 0
                      ? context.health.critical
                      : report.openAlerts > 0
                          ? context.health.warning
                          : context.health.ok,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CounterTile(
                  icon: Icons.local_shipping_outlined,
                  value: '${report.deliveriesDelivered}/${report.deliveriesTotal}',
                  label: 'pedidos entregues',
                  color: context.health.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Gerado em ${_dateTime(report.generatedAt)} · '
            '${report.alertsInPeriod} alerta(s) emitido(s) em ${report.periodDays} dias',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Colors.grey)),
      );

  static String _fmt(double? value, int decimals) => value == null
      ? '--'
      : value.toStringAsFixed(decimals).replaceAll('.', ',');

  static String _dateTime(DateTime at) {
    String two(int v) => v.toString().padLeft(2, '0');
    final local = at.toLocal();
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

/// Selo de origem: deixa explícito se o relatório saiu do Oracle.
class _EngineBadge extends StatelessWidget {
  const _EngineBadge({required this.engine});

  final ReportEngine engine;

  @override
  Widget build(BuildContext context) {
    final colors = context.health;
    final (icon, text, foreground, background) = switch (engine) {
      ReportEngine.oraclePlsql => (
          Icons.storage_rounded,
          'Consolidado no Oracle por procedures PL/SQL',
          colors.ok,
          colors.okSurface,
        ),
      ReportEngine.server => (
          Icons.dns_outlined,
          'Calculado pela API Smart HAS',
          colors.info,
          colors.infoSurface,
        ),
      ReportEngine.device => (
          Icons.phone_android,
          'Modo demonstração: calculado no aparelho',
          colors.warning,
          colors.warningSurface,
        ),
    };

    return Semantics(
      label: text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 8),
            Flexible(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 12, color: foreground, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.report});

  final ClinicalReport report;

  @override
  Widget build(BuildContext context) {
    final average = report.averageScore;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [SmartCareTheme.primaryGreen, SmartCareTheme.primaryGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Score atual',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('${report.latestScore ?? '--'}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 48, fontWeight: FontWeight.w300)),
                Text(
                  average == null
                      ? 'Sem leituras no período'
                      : 'Média do período: ${average.toStringAsFixed(1).replaceAll('.', ',')}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(report.riskLevel,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _AverageTile extends StatelessWidget {
  const _AverageTile({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value $unit',
      excludeSemantics: true,
      child: _Panel(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ),
            Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _RangeBar extends StatelessWidget {
  const _RangeBar({required this.percent});

  final double? percent;

  @override
  Widget build(BuildContext context) {
    final colors = context.health;
    final value = percent;
    // Meta usual de Time in Range para diabetes: acima de 70% das leituras.
    final color = value == null
        ? Colors.grey
        : value >= 70
            ? colors.ok
            : value >= 50
                ? colors.warning
                : colors.critical;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                value == null ? '--' : '${value.toStringAsFixed(1).replaceAll('.', ',')}%',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('das leituras entre 70 e 120 mg/dL',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value == null ? 0 : value / 100,
              minHeight: 10,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
              semanticsLabel: 'Glicemia na faixa',
              semanticsValue: value == null ? 'sem dados' : '${value.round()}%',
            ),
          ),
          const SizedBox(height: 6),
          const Text('Meta de referência: acima de 70%',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _CounterTile extends StatelessWidget {
  const _CounterTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
                Text(label,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_late_outlined, size: 48, color: context.health.warning),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
