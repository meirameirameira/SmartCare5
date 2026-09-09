import 'package:flutter/foundation.dart';

import '../../core/error/failures.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

/// Provider do mapa de dispositivos IoT.
class MapProvider extends ChangeNotifier {
  MapProvider(this._repository, {bool autoStart = true}) {
    if (autoStart) load();
  }

  final DeviceRepository _repository;

  static const defaultLat = -23.5505;
  static const defaultLng = -46.6333;

  List<SmartDevice> devices = const [];
  SmartDevice? selectedDevice;
  bool isLoading = true;

  /// Falha de localização: exibida como aviso não bloqueante no mapa.
  AppFailure? locationFailure;

  /// Falha ao buscar os pontos de atendimento, com opção de tentar de novo.
  AppFailure? searchFailure;

  double? _lat;
  double? _lng;

  double get centerLat => _lat ?? defaultLat;
  double get centerLng => _lng ?? defaultLng;

  /// `true` quando o mapa está centrado na posição real do paciente.
  bool get hasUserLocation => _lat != null && _lng != null;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    // A posição vem primeiro: é ela que define onde procurar atendimento.
    final location = await _repository.currentLocation();
    location.when(
      ok: (coords) {
        _lat = coords.lat;
        _lng = coords.lng;
        locationFailure = null;
      },
      err: (f) {
        locationFailure = f;
        debugPrint('[MapProvider] usando localização padrão: ${f.message}');
      },
    );

    await _loadCarePoints();

    isLoading = false;
    notifyListeners();
  }

  /// Refaz a busca em volta do centro atual — usado pela ação de tentar de novo.
  Future<void> retrySearch() async {
    isLoading = true;
    notifyListeners();

    await _loadCarePoints();

    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadCarePoints() async {
    final result = await _repository.nearbyCarePoints(
      lat: centerLat,
      lng: centerLng,
    );

    result.when(
      ok: (found) {
        devices = found;
        searchFailure = null;
      },
      err: (f) {
        devices = const [];
        searchFailure = f;
        debugPrint('[MapProvider] busca de atendimento falhou: ${f.message}');
      },
    );

    // Um ponto selecionado antes da nova busca pode nao existir mais na lista.
    if (selectedDevice != null &&
        !devices.any((d) => d.id == selectedDevice!.id)) {
      selectedDevice = null;
    }
  }

  void selectDevice(SmartDevice? device) {
    selectedDevice = device;
    notifyListeners();
  }

  /// Filtra os dispositivos por tipo — usado pelos chips de filtro do mapa.
  List<SmartDevice> devicesOfType(DeviceType? type) =>
      type == null ? devices : devices.where((d) => d.type == type).toList();
}
