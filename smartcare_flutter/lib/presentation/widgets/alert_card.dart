import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';

/// Cartão de alerta de saúde.
///
/// Agora lê cores do tema (funciona em modo escuro) e expõe rótulos de
/// acessibilidade em vez de depender só do emoji para indicar severidade.
class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.alert, this.onAction});

  final HealthAlert alert;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.health;

    final (color, semanticLabel) = switch (alert.type) {
      AlertType.urgent => (colors.critical, 'Alerta urgente'),
      AlertType.warning => (colors.warning, 'Atenção'),
      AlertType.ok => (colors.ok, 'Tudo certo'),
      AlertType.info => (colors.info, 'Informação'),
    };

    return Semantics(
      label: '$semanticLabel: ${alert.title}',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        alert.timeLabel,
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.description,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                  ),
                  if (alert.actionLabel != null && onAction != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: onAction,
                        style: TextButton.styleFrom(
                          foregroundColor: color,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                        ),
                        child: Text(alert.actionLabel!),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
