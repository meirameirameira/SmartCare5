import 'package:flutter/foundation.dart';
import '../models/models.dart';

class DeliveryProvider extends ChangeNotifier {
  DeliveryOrder? activeOrder;
  HomeCareVisit? nextVisit;
  bool isLoading = true;

  DeliveryProvider() {
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 500));

    activeOrder = const DeliveryOrder(
      id: 'd001',
      orderCode: '#SC-2024-0412',
      description: 'Metformina 500mg (60cp) + Losartana 50mg (30cp)',
      pharmacyName: 'Farmácia Leroy Health',
      status: DeliveryStatus.inTransit,
      currentStep: 2,
      etaFrom: '14h20',
      etaTo: '15h00',
      distanceKm: 3.2,
      proactiveMessage: '🤖 IA detectou trânsito na Av. Paulista — rota alternativa ativa. ETA mantido.',
      minutesAway: 28,
    );

    nextVisit = const HomeCareVisit(
      id: 'v001',
      professionalName: 'Enf. Carla Souza',
      specialty: 'Enfermagem Home Care',
      description: 'Verificação de sinais vitais + troca de curativo',
      scheduledDateTime: 'Amanhã, 09h00',
      estimatedMinutes: 45,
      confidencePercent: 94,
    );

    isLoading = false;
    notifyListeners();
  }

  void confirmDelivery(String orderId) {
    if (activeOrder?.id == orderId) {
      activeOrder = DeliveryOrder(
        id: activeOrder!.id,
        orderCode: activeOrder!.orderCode,
        description: activeOrder!.description,
        pharmacyName: activeOrder!.pharmacyName,
        status: DeliveryStatus.delivered,
        currentStep: 3,
        etaFrom: activeOrder!.etaFrom,
        etaTo: activeOrder!.etaTo,
        distanceKm: activeOrder!.distanceKm,
      );
      notifyListeners();
    }
  }
}
