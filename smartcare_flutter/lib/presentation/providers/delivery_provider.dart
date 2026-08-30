import 'package:flutter/foundation.dart';

import '../../core/error/failures.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

/// Provider da camada AI Logistics Extension.
class DeliveryProvider extends ChangeNotifier {
  DeliveryProvider(this._repository, {bool autoStart = true}) {
    if (autoStart) load();
  }

  final DeliveryRepository _repository;

  DeliveryOrder? activeOrder;
  HomeCareVisit? nextVisit;
  bool isLoading = true;
  AppFailure? failure;

  Future<void> load() async {
    isLoading = true;
    failure = null;
    notifyListeners();

    final orderResult = await _repository.loadActiveOrder();
    final visitResult = await _repository.loadNextVisit();

    activeOrder = orderResult.valueOrNull ?? activeOrder;
    nextVisit = visitResult.valueOrNull ?? nextVisit;
    failure = orderResult.failureOrNull ?? visitResult.failureOrNull;
    isLoading = false;
    notifyListeners();
  }

  /// Confirma o recebimento do pedido; a falha é exibida na tela em vez de
  /// silenciada.
  Future<void> confirmDelivery(String orderId) async {
    final result = await _repository.confirmDelivery(orderId);
    result.when(
      ok: (order) {
        activeOrder = order;
        failure = null;
      },
      err: (f) => failure = f,
    );
    notifyListeners();
  }
}
