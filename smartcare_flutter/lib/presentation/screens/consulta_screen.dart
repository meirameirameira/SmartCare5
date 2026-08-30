import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/consulta_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';

class ConsultaScreen extends StatelessWidget {
  const ConsultaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ConsultaProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Consultas & Telemedicina')),
      body: p.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.nextAppointment != null) ...[
                    _label('próxima consulta'),
                    _AppointmentCard(appointment: p.nextAppointment!),
                    const SizedBox(height: 20),
                  ],
                  _label('médicos disponíveis'),
                  ...p.availableDoctors.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DoctorCard(doctor: d),
                  )),
                  const SizedBox(height: 20),
                  _label('fila de enfermagem inteligente'),
                  if (p.nursingQueue != null)
                    _NursingQueueCard(
                      queue: p.nursingQueue!,
                      inQueue: p.inQueue,
                      onJoin: p.joinQueue,
                      onLeave: p.leaveQueue,
                    ),
                ],
              ),
            ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text.toUpperCase(),
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            letterSpacing: 1.2, color: Colors.grey)),
  );
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final doc = appointment.doctor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [SmartCareTheme.primaryGreen, SmartCareTheme.primaryGreenDark],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text(doc.initials, style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.name, style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                    Text(doc.specialty, style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
                    Text(doc.crm, style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('✅ Confirmada',
                    style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.videocam, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(appointment.dateTimeLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.videocam),
              label: const Text('Entrar na consulta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: SmartCareTheme.primaryGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;
  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: doctor.available
                ? SmartCareTheme.primaryGreenLight
                : Colors.grey.shade100,
            child: Text(doctor.initials,
                style: TextStyle(
                    color: doctor.available
                        ? SmartCareTheme.primaryGreen
                        : Colors.grey)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(doctor.specialty,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: doctor.available
                  ? SmartCareTheme.primaryGreenLight
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              doctor.available ? '● Disponível' : '○ Ocupado',
              style: TextStyle(
                fontSize: 11,
                color: doctor.available ? SmartCareTheme.primaryGreen : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NursingQueueCard extends StatelessWidget {
  final NursingQueue queue;
  final bool inQueue;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  const _NursingQueueCard({
    required this.queue,
    required this.inQueue,
    required this.onJoin,
    required this.onLeave,
  });

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
              const Text('🤖', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Fila Inteligente — IA',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              if (queue.aiUpdating)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: SmartCareTheme.primaryGreenLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('IA ativa',
                      style: TextStyle(
                          fontSize: 10, color: SmartCareTheme.primaryGreen)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _queueStat('Na fila', '${queue.queueSize} pessoas'),
              const SizedBox(width: 20),
              _queueStat('Espera estimada', '~${queue.estimatedWaitMinutes} min'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: inQueue ? onLeave : onJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: inQueue ? Colors.red.shade400 : SmartCareTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(inQueue ? 'Sair da fila' : 'Entrar na fila'),
            ),
          ),
          if (inQueue)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                '🤖 IA monitorando fila — você será notificado quando for sua vez.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _queueStat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      Text(value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
              color: SmartCareTheme.primaryGreen)),
    ],
  );
}
