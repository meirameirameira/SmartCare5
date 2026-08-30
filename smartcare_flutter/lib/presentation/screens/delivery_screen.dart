import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/delivery_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../../core/notifications/notification_service.dart';

class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DeliveryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entregas & Home Care'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () => NotificationService.instance.deliveryAlert(),
            tooltip: 'Simular alerta de entrega',
          ),
        ],
      ),
      body: p.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.activeOrder != null) ...[
                    _sectionLabel('pedido ativo'),
                    _OrderCard(order: p.activeOrder!,
                        onConfirm: () => p.confirmDelivery(p.activeOrder!.id)),
                    const SizedBox(height: 20),
                  ],
                  if (p.nextVisit != null) ...[
                    _sectionLabel('próxima visita home care'),
                    _VisitCard(visit: p.nextVisit!),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text.toUpperCase(),
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            letterSpacing: 1.2, color: Colors.grey)),
  );
}

class _OrderCard extends StatelessWidget {
  final DeliveryOrder order;
  final VoidCallback onConfirm;
  const _OrderCard({required this.order, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final steps = order.steps;
    final delivered = order.status == DeliveryStatus.delivered;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderCode,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(order.pharmacyName,
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: delivered
                      ? SmartCareTheme.primaryGreenLight
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  delivered ? '✅ Entregue' : '🚚 Em rota',
                  style: TextStyle(
                      fontSize: 11,
                      color: delivered
                          ? SmartCareTheme.primaryGreen
                          : SmartCareTheme.warnAmber,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(order.description,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),

          // Steps
          Row(
            children: steps.asMap().entries.map((e) {
              final i = e.key;
              final step = e.value;
              return Expanded(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: step.done
                                ? SmartCareTheme.primaryGreen
                                : step.current
                                    ? SmartCareTheme.warnAmber
                                    : Colors.grey.shade200,
                          ),
                          child: Center(
                            child: Text(
                              step.done ? '✓' : '${i + 1}',
                              style: TextStyle(
                                  color: (step.done || step.current)
                                      ? Colors.white
                                      : Colors.grey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(step.label,
                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                            textAlign: TextAlign.center),
                      ],
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 18),
                          color: step.done
                              ? SmartCareTheme.primaryGreen
                              : Colors.grey.shade200,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),

          if (!delivered) ...[
            const SizedBox(height: 16),
            if (order.proactiveMessage != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(order.proactiveMessage!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF1976D2))),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('ETA: ${order.etaFrom} – ${order.etaTo}  · '
                    '${order.distanceKm} km',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Spacer(),
                if (order.minutesAway != null)
                  Text('~${order.minutesAway} min',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: SmartCareTheme.primaryGreen)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SmartCareTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Confirmar recebimento'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  final HomeCareVisit visit;
  const _VisitCard({required this.visit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: SmartCareTheme.primaryGreenLight,
                child: Text(visit.professionalName.substring(0, 1),
                    style: const TextStyle(color: SmartCareTheme.primaryGreen)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(visit.professionalName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(visit.specialty,
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SmartCareTheme.primaryGreenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${visit.confidencePercent}% conf.',
                    style: const TextStyle(
                        fontSize: 10, color: SmartCareTheme.primaryGreen,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(visit.description,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
              const SizedBox(width: 5),
              Text(visit.scheduledDateTime,
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 12),
              const Icon(Icons.timer_outlined, size: 13, color: Colors.grey),
              const SizedBox(width: 5),
              Text('~${visit.estimatedMinutes} min',
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
