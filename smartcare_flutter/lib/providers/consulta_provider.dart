import 'package:flutter/foundation.dart';
import '../models/models.dart';

class ConsultaProvider extends ChangeNotifier {
  Appointment? nextAppointment;
  List<Doctor> availableDoctors = [];
  NursingQueue? nursingQueue;
  bool isLoading = true;
  bool inQueue = false;

  ConsultaProvider() {
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 700));

    nextAppointment = const Appointment(
      id: 'ap001',
      doctor: Doctor(
        id: 'dr001',
        name: 'Dr. Ricardo Alves',
        initials: 'RA',
        specialty: 'Endocrinologia',
        crm: 'CRM/SP 87432',
        available: false,
      ),
      dateTimeLabel: 'Hoje, 14h30 — Teleconsulta',
      dateTimeShort: '14h30',
      isToday: true,
      status: AppointmentStatus.confirmed,
    );

    availableDoctors = const [
      Doctor(id: 'dr002', name: 'Dra. Ana Lima', initials: 'AL',
             specialty: 'Clínica Geral', crm: 'CRM/SP 54210', available: true),
      Doctor(id: 'dr003', name: 'Dr. Paulo Neto', initials: 'PN',
             specialty: 'Cardiologia', crm: 'CRM/SP 33091', available: false),
    ];

    nursingQueue = const NursingQueue(
      queueSize: 4,
      estimatedWaitMinutes: 22,
      aiUpdating: true,
    );

    isLoading = false;
    notifyListeners();
  }

  void joinQueue() {
    inQueue = true;
    notifyListeners();
  }

  void leaveQueue() {
    inQueue = false;
    notifyListeners();
  }
}
