import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum BannerTone { info, warning, critical, ok }

/// Faixa de status reutilizável (offline, erro, permissão negada).
///
/// Centraliza a forma como o app comunica problemas: antes cada falha era
/// silenciada com `catch (_) {}` e o usuário não sabia por que a tela estava
/// desatualizada.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.icon,
    required this.message,
    this.tone = BannerTone.info,
    this.onAction,
    this.actionLabel,
  });

  final IconData icon;
  final String message;
  final BannerTone tone;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.health;
    final (foreground, background) = switch (tone) {
      BannerTone.critical => (colors.critical, colors.criticalSurface),
      BannerTone.warning => (colors.warning, colors.warningSurface),
      BannerTone.ok => (colors.ok, colors.okSurface),
      BannerTone.info => (colors.info, colors.infoSurface),
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: foreground.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 12, color: foreground),
              ),
            ),
            if (onAction != null && actionLabel != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: foreground,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: Text(actionLabel!, style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}
