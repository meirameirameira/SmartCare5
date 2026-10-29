import 'package:flutter/foundation.dart';

import '../../core/state/view_state.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

/// Estado da tela de relatório clínico.
///
/// Carrega sob demanda (a tela chama [ensureLoaded] ao abrir): com o back-end
/// no ar, cada carga aciona a consolidação no banco, então não faz sentido
/// dispará-la na inicialização do app.
class ReportProvider extends ChangeNotifier {
  ReportProvider(this._repository);

  final ReportRepository _repository;

  static const periodOptions = <int>[7, 30, 90];

  int selectedPeriod = 30;
  ViewState<ClinicalReport> state = const ViewState.idle();

  ClinicalReport? get report => state.dataOrNull;

  Future<void> ensureLoaded() async {
    if (state is Idle<ClinicalReport>) await load();
  }

  void selectPeriod(int days) {
    if (selectedPeriod == days || state.isLoading) return;
    selectedPeriod = days;
    load();
  }

  Future<void> load() async {
    final previous = state.dataOrNull?.periodDays == selectedPeriod
        ? state.dataOrNull
        : null;
    state = const ViewState.loading();
    notifyListeners();

    final result = await _repository.loadReport(selectedPeriod);
    state = result.when(
      ok: (sourced) => ViewState.ready(
        sourced.value,
        updatedAt: sourced.updatedAt,
        fromCache: sourced.fromCache,
      ),
      err: (failure) => ViewState.failed(failure, staleData: previous),
    );
    notifyListeners();
  }
}
