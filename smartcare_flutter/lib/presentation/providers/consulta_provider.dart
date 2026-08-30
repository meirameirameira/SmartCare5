import 'package:flutter/foundation.dart';

import '../../core/error/failures.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

/// Provider de teleconsulta e fila de enfermagem.
class ConsultaProvider extends ChangeNotifier {
  ConsultaProvider(this._repository, {bool autoStart = true}) {
    if (autoStart) load();
  }

  final ConsultaRepository _repository;

  Appointment? nextAppointment;
  List<Doctor> availableDoctors = const [];
  NursingQueue? nursingQueue;
  bool isLoading = true;
  bool inQueue = false;
  AppFailure? failure;

  /// Posição estimada do paciente após entrar na fila.
  int? get queuePosition =>
      inQueue && nursingQueue != null ? nursingQueue!.queueSize + 1 : null;

  Future<void> load() async {
    isLoading = true;
    failure = null;
    notifyListeners();

    final appointment = await _repository.loadNextAppointment();
    final doctors = await _repository.loadAvailableDoctors();
    final queue = await _repository.loadNursingQueue();

    nextAppointment = appointment.valueOrNull ?? nextAppointment;
    availableDoctors = doctors.valueOrNull ?? availableDoctors;
    nursingQueue = queue.valueOrNull ?? nursingQueue;
    failure = appointment.failureOrNull ??
        doctors.failureOrNull ??
        queue.failureOrNull;
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
